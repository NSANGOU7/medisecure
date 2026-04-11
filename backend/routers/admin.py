"""
MediSecure — routers/admin.py
Admin-only: user management, logs, system stats.
"""
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from database import get_db
import models, schemas
from security import require_admin, log_action, get_current_user

router = APIRouter()


@router.get("/stats", response_model=schemas.SystemStats)
async def get_stats(
    db: AsyncSession = Depends(get_db),
    _: models.User = Depends(require_admin),
):
    total_users   = (await db.execute(select(func.count(models.User.id)))).scalar()
    active_pat    = (await db.execute(
        select(func.count(models.Patient.id))
    )).scalar()
    active_doc    = (await db.execute(
        select(func.count(models.Doctor.id))
    )).scalar()
    total_appt    = (await db.execute(select(func.count(models.Appointment.id)))).scalar()
    today_start   = datetime.combine(date.today(), datetime.min.time())
    today_appt    = (await db.execute(
        select(func.count(models.Appointment.id))
        .where(models.Appointment.date_rdv >= today_start)
    )).scalar()
    pending_appt  = (await db.execute(
        select(func.count(models.Appointment.id))
        .where(models.Appointment.statut == models.AppointmentStatus.pending)
    )).scalar()
    return schemas.SystemStats(
        total_users=total_users,
        active_patients=active_pat,
        active_doctors=active_doc,
        total_appointments=total_appt,
        appointments_today=today_appt,
        pending_appointments=pending_appt,
    )


@router.get("/users", response_model=list[schemas.UserOut])
async def list_all_users(
    db: AsyncSession = Depends(get_db),
    _: models.User = Depends(require_admin),
):
    res = await db.execute(select(models.User).order_by(models.User.date_creation.desc()))
    return res.scalars().all()


@router.put("/users/{user_id}", response_model=schemas.UserOut)
async def admin_update_user(
    user_id: int,
    payload: schemas.AdminUserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(require_admin),
):
    res = await db.execute(select(models.User).where(models.User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Utilisateur introuvable")
    if payload.statut:
        user.statut = models.UserStatus(payload.statut)
    if payload.role:
        user.role = models.RoleEnum(payload.role)
    await log_action(db, current_user.id, f"Admin: modification utilisateur #{user_id}")
    return user


@router.delete("/users/{user_id}", status_code=204)
async def admin_delete_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(require_admin),
):
    res = await db.execute(select(models.User).where(models.User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Utilisateur introuvable")
    await db.delete(user)
    await log_action(db, current_user.id, f"Admin: suppression utilisateur #{user_id}")


@router.get("/logs", response_model=list[dict])
async def get_activity_logs(
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    _: models.User = Depends(require_admin),
):
    res = await db.execute(
        select(models.ActivityLog)
        .order_by(models.ActivityLog.date_action.desc())
        .limit(limit)
    )
    logs = res.scalars().all()
    return [
        {
            "id":          l.id,
            "user_id":     l.user_id,
            "action":      l.action,
            "date_action": l.date_action.isoformat() if l.date_action else None,
            "adresse_ip":  l.adresse_ip,
            "details":     l.details,
        }
        for l in logs
    ]
