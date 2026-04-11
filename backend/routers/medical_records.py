"""
MediSecure — routers/medical_records.py
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from database import get_db
import models, schemas
from security import get_current_user, require_medical, log_action

router = APIRouter()


async def _get_record_or_404(db, patient_id):
    res = await db.execute(
        select(models.MedicalRecord)
        .where(models.MedicalRecord.patient_id == patient_id)
        .options(
            selectinload(models.MedicalRecord.prescriptions),
            selectinload(models.MedicalRecord.consultations),
            selectinload(models.MedicalRecord.lab_results),
        )
    )
    rec = res.scalar_one_or_none()
    if not rec:
        raise HTTPException(404, "Dossier medical introuvable")
    return rec


@router.get("/my", response_model=schemas.MedicalRecordOut)
async def get_my_record(
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    res = await db.execute(select(models.Patient).where(models.Patient.user_id == current_user.id))
    patient = res.scalar_one_or_none()
    if not patient:
        raise HTTPException(404, "Profil patient introuvable")
    rec = await _get_record_or_404(db, patient.id)
    await log_action(db, current_user.id, f"Consultation dossier medical patient#{patient.id}", request)
    return rec


@router.get("/{patient_id}", response_model=schemas.MedicalRecordOut)
async def get_record_by_patient(
    patient_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(require_medical),
):
    rec = await _get_record_or_404(db, patient_id)
    await log_action(db, current_user.id, f"Consultation dossier medical patient#{patient_id}", request)
    return rec


@router.put("/{patient_id}", response_model=schemas.MedicalRecordOut)
async def update_record(
    patient_id: int,
    payload: schemas.MedicalRecordUpdate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(require_medical),
):
    rec = await _get_record_or_404(db, patient_id)
    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(rec, k, v)
    await log_action(db, current_user.id, f"Modification dossier medical patient#{patient_id}", request)
    return rec


@router.post("/{patient_id}/prescriptions", response_model=schemas.PrescriptionOut, status_code=201)
async def add_prescription(
    patient_id: int,
    payload: schemas.PrescriptionCreate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(require_medical),
):
    rec = await _get_record_or_404(db, patient_id)
    res = await db.execute(select(models.Doctor).where(models.Doctor.user_id == current_user.id))
    doc = res.scalar_one_or_none()

    rx = models.Prescription(
        record_id=rec.id,
        doctor_id=doc.id if doc else None,
        **payload.model_dump(),
    )
    db.add(rx)
    await db.flush()
    await log_action(db, current_user.id, f"Ordonnance creee patient#{patient_id}", request)
    return rx


@router.delete("/{patient_id}/prescriptions/{rx_id}", status_code=204)
async def deactivate_prescription(
    patient_id: int,
    rx_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(require_medical),
):
    res = await db.execute(select(models.Prescription).where(models.Prescription.id == rx_id))
    rx = res.scalar_one_or_none()
    if not rx:
        raise HTTPException(404, "Ordonnance introuvable")
    rx.is_active = False


@router.post("/{patient_id}/consultations", response_model=schemas.ConsultationOut, status_code=201)
async def add_consultation(
    patient_id: int,
    payload: schemas.ConsultationCreate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(require_medical),
):
    rec = await _get_record_or_404(db, patient_id)
    res = await db.execute(select(models.Doctor).where(models.Doctor.user_id == current_user.id))
    doc = res.scalar_one_or_none()

    consult = models.Consultation(
        record_id=rec.id,
        doctor_id=doc.id if doc else None,
        **payload.model_dump(),
    )
    db.add(consult)
    await db.flush()
    await log_action(db, current_user.id, f"Consultation enregistree patient#{patient_id}", request)
    return consult


@router.post("/{patient_id}/lab-results", response_model=schemas.LabResultOut, status_code=201)
async def add_lab_result(
    patient_id: int,
    payload: schemas.LabResultCreate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(require_medical),
):
    rec = await _get_record_or_404(db, patient_id)
    lab = models.LabResult(record_id=rec.id, **payload.model_dump())
    db.add(lab)
    await db.flush()
    await log_action(db, current_user.id, f"Resultat labo ajoute patient#{patient_id}", request)
    return lab