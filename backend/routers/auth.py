"""
MediSecure — routers/auth.py
Login, register, token refresh, forgot/reset password.
"""
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database import get_db
import models, schemas
from security import (
    hash_password, verify_password,
    create_access_token, create_refresh_token, decode_token,
    log_action, MAX_FAILED_ATTEMPTS, LOCKOUT_MINUTES,
)

router = APIRouter()


@router.post("/register", response_model=schemas.UserOut, status_code=201)
async def register(payload: schemas.UserCreate, db: AsyncSession = Depends(get_db)):
    # check duplicate email
    exists = await db.execute(select(models.User).where(models.User.email == payload.email))
    if exists.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    user = models.User(
        nom=payload.nom,
        prenom=payload.prenom,
        email=payload.email,
        hashed_password=hash_password(payload.password),
        role=models.RoleEnum(payload.role),
        telephone=payload.telephone,
    )
    db.add(user)
    await db.flush()  # get user.id

    # create role-specific profile
    if user.role == models.RoleEnum.patient:
        db.add(models.Patient(user_id=user.id))
        db.add(models.MedicalRecord(patient_id=None))   # linked after flush below
    elif user.role in (models.RoleEnum.doctor, models.RoleEnum.nurse):
        db.add(models.Doctor(user_id=user.id))
    elif user.role == models.RoleEnum.admin:
        db.add(models.Admin(user_id=user.id))

    await db.flush()

    # for patients — link medical record
    if user.role == models.RoleEnum.patient:
        pat_res = await db.execute(select(models.Patient).where(models.Patient.user_id == user.id))
        pat = pat_res.scalar_one()
        rec_res = await db.execute(
            select(models.MedicalRecord).where(models.MedicalRecord.patient_id == None)
            .order_by(models.MedicalRecord.id.desc())
        )
        rec = rec_res.scalars().first()
        if rec:
            rec.patient_id = pat.id

    await log_action(db, user.id, f"Compte créé — rôle {user.role.value}")
    return user


@router.post("/login", response_model=schemas.TokenResponse)
async def login(payload: schemas.LoginRequest, request: Request, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.User).where(models.User.email == payload.email))
    user = res.scalar_one_or_none()

    # lockout check
    if user and user.locked_until and user.locked_until > datetime.utcnow():
        raise HTTPException(status_code=423, detail="Compte temporairement bloqué. Réessayez plus tard.")

    if not user or not verify_password(payload.password, user.hashed_password):
        if user:
            user.failed_attempts += 1
            if user.failed_attempts >= MAX_FAILED_ATTEMPTS:
                user.locked_until = datetime.utcnow() + timedelta(minutes=LOCKOUT_MINUTES)
                await log_action(db, user.id, "Compte bloqué — trop de tentatives", request)
        raise HTTPException(status_code=401, detail="Identifiants incorrects")

    if user.statut != models.UserStatus.active:
        raise HTTPException(status_code=403, detail="Compte suspendu ou inactif")

    # reset failed attempts
    user.failed_attempts = 0
    user.locked_until = None
    user.last_login = datetime.utcnow()

    token_data = {"sub": str(user.id), "role": user.role.value}
    await log_action(db, user.id, "Connexion réussie", request)

    return schemas.TokenResponse(
        access_token=create_access_token(token_data),
        refresh_token=create_refresh_token(token_data),
        role=user.role.value,
        user_id=user.id,
    )


@router.post("/refresh", response_model=schemas.TokenResponse)
async def refresh_token(payload: schemas.RefreshRequest, db: AsyncSession = Depends(get_db)):
    data = decode_token(payload.refresh_token)
    if data.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Token de rafraîchissement invalide")

    res = await db.execute(select(models.User).where(models.User.id == int(data["sub"])))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="Utilisateur introuvable")

    token_data = {"sub": str(user.id), "role": user.role.value}
    return schemas.TokenResponse(
        access_token=create_access_token(token_data),
        refresh_token=create_refresh_token(token_data),
        role=user.role.value,
        user_id=user.id,
    )


@router.post("/forgot-password")
async def forgot_password(payload: schemas.ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    # In production: generate a signed token, persist it, send via SMTP/SendGrid
    res = await db.execute(select(models.User).where(models.User.email == payload.email))
    user = res.scalar_one_or_none()
    # Always return 200 to avoid email enumeration
    if user:
        reset_token = create_access_token({"sub": str(user.id), "purpose": "reset"}, timedelta(hours=1))
        # TODO: send_email(user.email, reset_token)
        _ = reset_token  # would be emailed
    return {"message": "Si cet email existe, un lien de réinitialisation a été envoyé."}


@router.post("/reset-password")
async def reset_password(payload: schemas.ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    data = decode_token(payload.token)
    if data.get("purpose") != "reset":
        raise HTTPException(status_code=400, detail="Token invalide")
    res = await db.execute(select(models.User).where(models.User.id == int(data["sub"])))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")
    user.hashed_password = hash_password(payload.new_password)
    user.failed_attempts = 0
    user.locked_until = None
    await log_action(db, user.id, "Mot de passe réinitialisé")
    return {"message": "Mot de passe mis à jour avec succès"}
