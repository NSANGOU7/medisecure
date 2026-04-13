"""
MediSecure — routers/auth.py (VERSION CORRIGÉE)
Login, register, token refresh, forgot/reset password.
"""
from datetime import datetime, timedelta
import re
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


# -----------------------------------------------------------------------
# Validation mot de passe
# -----------------------------------------------------------------------

# ✅ FIX #4 — Validation de la force du mot de passe
def validate_password(password: str):
    if len(password) < 8:
        raise HTTPException(400, "Mot de passe trop court (min 8 caractères)")
    if not re.search(r"[A-Z]", password):
        raise HTTPException(400, "Le mot de passe doit contenir au moins une majuscule")
    if not re.search(r"[0-9]", password):
        raise HTTPException(400, "Le mot de passe doit contenir au moins un chiffre")
    if not re.search(r"[!@#$%^&*]", password):
        raise HTTPException(400, "Le mot de passe doit contenir au moins un caractère spécial (!@#$%^&*)")


# ✅ FIX #2 — Token dédié pour le reset de mot de passe
def create_reset_token(user_id: int) -> str:
    from jose import jwt
    import os
    SECRET_KEY = os.getenv("SECRET_KEY")
    to_encode = {
        "sub": str(user_id),
        "type": "reset",
        "exp": datetime.utcnow() + timedelta(hours=1)
    }
    return jwt.encode(to_encode, SECRET_KEY, algorithm="HS256")


# -----------------------------------------------------------------------
# Register
# -----------------------------------------------------------------------

@router.post("/register", response_model=schemas.UserOut, status_code=201)
async def register(payload: schemas.UserCreate, db: AsyncSession = Depends(get_db)):

    # ✅ FIX #5 — Bloquer l'inscription avec un rôle admin
    ALLOWED_ROLES = [models.RoleEnum.patient, models.RoleEnum.doctor]
    try:
        role = models.RoleEnum(payload.role)
    except ValueError:
        raise HTTPException(400, "Rôle invalide")

    if role not in ALLOWED_ROLES:
        raise HTTPException(400, "Rôle non autorisé à l'inscription publique")

    # ✅ FIX #4 — Valider le mot de passe
    validate_password(payload.password)

    # Vérifier email dupliqué
    exists = await db.execute(select(models.User).where(models.User.email == payload.email))
    if exists.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    user = models.User(
        nom=payload.nom,
        prenom=payload.prenom,
        email=payload.email,
        hashed_password=hash_password(payload.password),
        role=role,
        telephone=payload.telephone,
    )
    db.add(user)
    await db.flush()

    # ✅ FIX #1 — Création du profil et dossier médical correctement liés
    if user.role == models.RoleEnum.patient:
        pat = models.Patient(user_id=user.id)
        db.add(pat)
        await db.flush()
        db.add(models.MedicalRecord(patient_id=pat.id))

    elif user.role in (models.RoleEnum.doctor, models.RoleEnum.nurse):
        db.add(models.Doctor(user_id=user.id))

    elif user.role == models.RoleEnum.admin:
        db.add(models.Admin(user_id=user.id))

    await db.flush()
    await log_action(db, user.id, f"Compte créé — rôle {user.role.value}")
    return user


# -----------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------

@router.post("/login", response_model=schemas.TokenResponse)
async def login(payload: schemas.LoginRequest, request: Request, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.User).where(models.User.email == payload.email))
    user = res.scalar_one_or_none()

    if user and user.locked_until and user.locked_until > datetime.utcnow():
        raise HTTPException(
            status_code=423,
            detail="Compte temporairem
