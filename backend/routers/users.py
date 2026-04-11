"""
MediSecure — routers/users.py
Current user profile, patient & doctor profiles, specialties.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from database import get_db
import models, schemas
from security import get_current_user, log_action

router = APIRouter()


@router.get("/me", response_model=schemas.UserOut)
async def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user


@router.put("/me", response_model=schemas.UserOut)
async def update_me(
    payload: schemas.UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(current_user, k, v)
    await log_action(db, current_user.id, "Profil mis à jour")
    return current_user


# ── Patient profile ───────────────────────────────────────────────────────────

@router.get("/patient/profile", response_model=schemas.PatientOut)
async def get_patient_profile(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    res = await db.execute(
        select(models.Patient)
        .where(models.Patient.user_id == current_user.id)
        .options(selectinload(models.Patient.user))
    )
    patient = res.scalar_one_or_none()
    if not patient:
        raise HTTPException(404, "Profil patient introuvable")
    return patient


@router.put("/patient/profile", response_model=schemas.PatientOut)
async def update_patient_profile(
    payload: schemas.PatientProfileUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    res = await db.execute(select(models.Patient).where(models.Patient.user_id == current_user.id))
    patient = res.scalar_one_or_none()
    if not patient:
        raise HTTPException(404, "Profil patient introuvable")
    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(patient, k, v)
    await log_action(db, current_user.id, "Profil patient mis à jour")
    return patient


# ── Doctors list ──────────────────────────────────────────────────────────────

@router.get("/doctors", response_model=list[schemas.DoctorOut])
async def list_doctors(
    specialty_id: int = None,
    db: AsyncSession = Depends(get_db),
    _: models.User = Depends(get_current_user),
):
    q = select(models.Doctor).options(
        selectinload(models.Doctor.user),
        selectinload(models.Doctor.specialty),
    )
    if specialty_id:
        q = q.where(models.Doctor.specialty_id == specialty_id)
    res = await db.execute(q)
    return res.scalars().all()


# ── Specialties ───────────────────────────────────────────────────────────────

@router.get("/specialties", response_model=list[schemas.SpecialtyOut])
async def list_specialties(db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(models.Specialty))
    return res.scalars().all()
