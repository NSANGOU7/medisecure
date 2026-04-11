"""
MediSecure — routers/appointments.py
Create, list, update, cancel appointments. Prevent double-booking.
"""
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload

from database import get_db
import models, schemas
from security import get_current_user, log_action

router = APIRouter()


async def _get_patient(db, user_id):
    res = await db.execute(select(models.Patient).where(models.Patient.user_id == user_id))
    p = res.scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Profil patient introuvable")
    return p


@router.post("/", response_model=schemas.AppointmentOut, status_code=201)
async def create_appointment(
    payload: schemas.AppointmentCreate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    patient = await _get_patient(db, current_user.id)

    # Check for exact same timeslot with same doctor (double-booking prevention)
    conflict = await db.execute(
        select(models.Appointment).where(
            and_(
                models.Appointment.doctor_id == payload.doctor_id,
                models.Appointment.statut.notin_([models.AppointmentStatus.cancelled]),
                models.Appointment.date_rdv == payload.date_rdv,
            )
        )
    )
    if conflict.scalar_one_or_none():
        raise HTTPException(409, "Ce creneau est deja pris. Veuillez choisir un autre horaire.")

    appt = models.Appointment(
        patient_id=patient.id,
        doctor_id=payload.doctor_id,
        date_rdv=payload.date_rdv,
        duration=payload.duration,
        motif=payload.motif,
    )
    db.add(appt)
    await db.flush()

    # Auto-notification to patient
    notif = models.Notification(
        user_id=current_user.id,
        titre="Rendez-vous reserve",
        message=f"Votre rendez-vous du {payload.date_rdv.strftime('%d/%m/%Y a %H:%M')} a ete enregistre.",
        type=models.NotifType.confirmation,
    )
    db.add(notif)

    await log_action(db, current_user.id, f"Rendez-vous cree #{appt.id}", request)
    return appt


@router.get("/", response_model=list[schemas.AppointmentOut])
async def list_appointments(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if current_user.role == models.RoleEnum.patient:
        patient = await _get_patient(db, current_user.id)
        q = select(models.Appointment).where(models.Appointment.patient_id == patient.id)
    elif current_user.role in (models.RoleEnum.doctor, models.RoleEnum.nurse):
        res = await db.execute(select(models.Doctor).where(models.Doctor.user_id == current_user.id))
        doc = res.scalar_one_or_none()
        if not doc:
            return []
        q = select(models.Appointment).where(models.Appointment.doctor_id == doc.id)
    else:
        q = select(models.Appointment)

    q = q.order_by(models.Appointment.date_rdv.asc())
    result = await db.execute(q)
    return result.scalars().all()


@router.get("/slots/{doctor_id}")
async def get_available_slots(
    doctor_id: int,
    date: str,
    db: AsyncSession = Depends(get_db),
    _: models.User = Depends(get_current_user),
):
    target = datetime.strptime(date, "%Y-%m-%d")
    slots = []
    for hour in range(9, 17):
        for minute in (0, 30):
            slot_time = target.replace(hour=hour, minute=minute, second=0)
            res = await db.execute(
                select(models.Appointment).where(
                    and_(
                        models.Appointment.doctor_id == doctor_id,
                        models.Appointment.date_rdv == slot_time,
                        models.Appointment.statut != models.AppointmentStatus.cancelled,
                    )
                )
            )
            taken = res.scalar_one_or_none() is not None
            slots.append({"time": slot_time.strftime("%H:%M"), "available": not taken})
    return slots


@router.get("/{appt_id}", response_model=schemas.AppointmentOut)
async def get_appointment(
    appt_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    res = await db.execute(select(models.Appointment).where(models.Appointment.id == appt_id))
    appt = res.scalar_one_or_none()
    if not appt:
        raise HTTPException(404, "Rendez-vous introuvable")
    return appt


@router.put("/{appt_id}", response_model=schemas.AppointmentOut)
async def update_appointment(
    appt_id: int,
    payload: schemas.AppointmentUpdate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    res = await db.execute(select(models.Appointment).where(models.Appointment.id == appt_id))
    appt = res.scalar_one_or_none()
    if not appt:
        raise HTTPException(404, "Rendez-vous introuvable")

    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(appt, k, v)

    await log_action(db, current_user.id, f"Rendez-vous #{appt_id} mis a jour", request)
    return appt


@router.delete("/{appt_id}", status_code=204)
async def cancel_appointment(
    appt_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    res = await db.execute(select(models.Appointment).where(models.Appointment.id == appt_id))
    appt = res.scalar_one_or_none()
    if not appt:
        raise HTTPException(404, "Rendez-vous introuvable")

    appt.statut = models.AppointmentStatus.cancelled

    notif = models.Notification(
        user_id=current_user.id,
        titre="Rendez-vous annule",
        message=f"Votre rendez-vous du {appt.date_rdv.strftime('%d/%m/%Y a %H:%M')} a ete annule.",
        type=models.NotifType.cancellation,
    )
    db.add(notif)
    await log_action(db, current_user.id, f"Rendez-vous #{appt_id} annule", request)
