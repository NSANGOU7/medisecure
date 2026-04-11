"""
MediSecure — routers/notifications.py
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from database import get_db
import models, schemas
from security import get_current_user

router = APIRouter()


@router.get("/", response_model=list[schemas.NotificationOut])
async def list_notifications(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    res = await db.execute(
        select(models.Notification)
        .where(models.Notification.user_id == current_user.id)
        .order_by(models.Notification.date_envoi.desc())
    )
    return res.scalars().all()


@router.put("/{notif_id}/read")
async def mark_read(
    notif_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    await db.execute(
        update(models.Notification)
        .where(models.Notification.id == notif_id, models.Notification.user_id == current_user.id)
        .values(statut=models.NotifStatus.read)
    )
    return {"message": "Notification marquée comme lue"}


@router.put("/read-all")
async def mark_all_read(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    await db.execute(
        update(models.Notification)
        .where(models.Notification.user_id == current_user.id)
        .values(statut=models.NotifStatus.read)
    )
    return {"message": "Toutes les notifications marquées comme lues"}


@router.get("/unread-count")
async def unread_count(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    res = await db.execute(
        select(models.Notification).where(
            models.Notification.user_id == current_user.id,
            models.Notification.statut == models.NotifStatus.sent,
        )
    )
    return {"count": len(res.scalars().all())}
