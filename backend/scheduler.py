"""
MediSecure — scheduler.py
Background job: scans appointments 24 h out and sends reminder notifications.
Run alongside the API:  python scheduler.py
"""
import asyncio
from datetime import datetime, timedelta

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from sqlalchemy import select, and_

from database import AsyncSessionLocal
import models


async def send_reminders():
    """Find appointments starting in the next 24 hours and create reminder notifications."""
    async with AsyncSessionLocal() as db:
        window_start = datetime.utcnow()
        window_end   = window_start + timedelta(hours=24)

        res = await db.execute(
            select(models.Appointment).where(
                and_(
                    models.Appointment.date_rdv >= window_start,
                    models.Appointment.date_rdv <= window_end,
                    models.Appointment.statut == models.AppointmentStatus.confirmed,
                )
            )
        )
        appts = res.scalars().all()

        for appt in appts:
            # fetch patient's user_id
            pat_res = await db.execute(
                select(models.Patient).where(models.Patient.id == appt.patient_id)
            )
            patient = pat_res.scalar_one_or_none()
            if not patient:
                continue

            # avoid duplicate notifications
            existing = await db.execute(
                select(models.Notification).where(
                    and_(
                        models.Notification.user_id == patient.user_id,
                        models.Notification.type == models.NotifType.reminder,
                        models.Notification.message.contains(str(appt.id)),
                    )
                )
            )
            if existing.scalar_one_or_none():
                continue

            notif = models.Notification(
                user_id=patient.user_id,
                titre="Rappel de rendez-vous",
                message=(
                    f"Rappel : vous avez un rendez-vous demain le "
                    f"{appt.date_rdv.strftime('%d/%m/%Y à %H:%M')} "
                    f"(RDV #{appt.id})."
                ),
                type=models.NotifType.reminder,
            )
            db.add(notif)

        await db.commit()
        print(f"[{datetime.utcnow()}] Reminders sent for {len(appts)} appointment(s).")


if __name__ == "__main__":
    scheduler = AsyncIOScheduler()
    scheduler.add_job(send_reminders, "interval", hours=1)
    scheduler.start()
    print("Scheduler started — checking reminders every hour.")
    try:
        asyncio.get_event_loop().run_forever()
    except (KeyboardInterrupt, SystemExit):
        pass
