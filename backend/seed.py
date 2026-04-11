"""
MediSecure — seed.py
Creates demo accounts and sample data for development/testing.

Usage:
    python seed.py
"""
import asyncio
from datetime import datetime, timedelta

from database import AsyncSessionLocal, engine, Base
from security import hash_password
import models


async def seed():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:

        # ── Specialties ───────────────────────────────────────────────────
        specs = [
            models.Specialty(nom="Cardiologie",    description="Maladies du cœur"),
            models.Specialty(nom="Neurologie",      description="Maladies du système nerveux"),
            models.Specialty(nom="Généraliste",     description="Médecine générale"),
            models.Specialty(nom="Dermatologie",    description="Maladies de la peau"),
            models.Specialty(nom="Ophtalmologie",   description="Maladies des yeux"),
            models.Specialty(nom="Orthopédie",      description="Maladies osseuses et articulaires"),
        ]
        for s in specs:
            db.add(s)
        await db.flush()

        # ── Clinic ────────────────────────────────────────────────────────
        clinic = models.Clinic(
            nom="Clinique Saint-Louis",
            adresse="12 rue de la Paix, 75001 Paris",
            telephone="+33 1 42 00 00 00",
        )
        db.add(clinic)
        await db.flush()

        # ── Admin user ────────────────────────────────────────────────────
        admin_user = models.User(
            nom="Admin", prenom="Super",
            email="admin@medisecure.fr",
            hashed_password=hash_password("Admin1234!"),
            role=models.RoleEnum.admin,
            telephone="+33 6 00 00 00 00",
        )
        db.add(admin_user)
        await db.flush()
        db.add(models.Admin(user_id=admin_user.id, niveau_acces=3))

        # ── Doctor user ───────────────────────────────────────────────────
        doctor_user = models.User(
            nom="Martin", prenom="Sophie",
            email="s.martin@medisecure.fr",
            hashed_password=hash_password("Doctor1234!"),
            role=models.RoleEnum.doctor,
            telephone="+33 6 11 11 11 11",
        )
        db.add(doctor_user)
        await db.flush()
        doctor = models.Doctor(
            user_id=doctor_user.id,
            specialty_id=specs[0].id,
            clinic_id=clinic.id,
            numero_licence="MED-2024-001",
            bio="Cardiologue expérimentée, 15 ans de pratique.",
            rating="4.9",
        )
        db.add(doctor)
        await db.flush()

        # ── Doctor 2 ──────────────────────────────────────────────────────
        doctor2_user = models.User(
            nom="Chen", prenom="James",
            email="j.chen@medisecure.fr",
            hashed_password=hash_password("Doctor1234!"),
            role=models.RoleEnum.doctor,
            telephone="+33 6 22 22 22 22",
        )
        db.add(doctor2_user)
        await db.flush()
        doctor2 = models.Doctor(
            user_id=doctor2_user.id,
            specialty_id=specs[2].id,
            clinic_id=clinic.id,
            numero_licence="MED-2024-002",
            bio="Médecin généraliste, spécialisé en médecine préventive.",
            rating="4.7",
        )
        db.add(doctor2)
        await db.flush()

        # ── Patient user ──────────────────────────────────────────────────
        patient_user = models.User(
            nom="Bernard", prenom="Emma",
            email="e.bernard@email.com",
            hashed_password=hash_password("Patient1234!"),
            role=models.RoleEnum.patient,
            telephone="+33 6 33 33 33 33",
        )
        db.add(patient_user)
        await db.flush()
        patient = models.Patient(
            user_id=patient_user.id,
            date_naissance=datetime(1990, 3, 12).date(),
            sexe="Féminin",
            adresse="5 avenue des Roses, 75008 Paris",
            groupe_sanguin="A+",
        )
        db.add(patient)
        await db.flush()

        # Medical record
        record = models.MedicalRecord(
            patient_id=patient.id,
            antecedents="Hypertension artérielle diagnostiquée en 2019.",
            allergies="Allergie à la pénicilline (CRITIQUE)",
            traitements="Amlodipine 5mg, Ramipril 5mg",
        )
        db.add(record)
        await db.flush()

        # Prescriptions
        db.add(models.Prescription(
            record_id=record.id, doctor_id=doctor.id,
            medicament="Amlodipine", dosage="5mg",
            posologie="1 comprimé/jour",
            date_debut=datetime(2025, 1, 1).date(),
            date_fin=datetime(2025, 6, 30).date(),
            is_active=True,
        ))
        db.add(models.Prescription(
            record_id=record.id, doctor_id=doctor.id,
            medicament="Ramipril", dosage="5mg",
            posologie="1 comprimé le matin",
            date_debut=datetime(2025, 1, 1).date(),
            date_fin=datetime(2025, 6, 30).date(),
            is_active=True,
        ))

        # Consultation
        db.add(models.Consultation(
            record_id=record.id, doctor_id=doctor.id,
            date_consult=datetime(2025, 4, 5, 10, 30),
            diagnostic="Hypertension bien contrôlée",
            observations="Tension 125/80. Renouvellement traitement.",
        ))

        # Lab results
        for exam in [
            ("Cholestérol total", "4.8", "mmol/L", "<5.0", "normal"),
            ("Glycémie à jeun",   "4.9", "mmol/L", "<5.5", "normal"),
            ("Hémoglobine",       "11.2", "g/dL",  "12-16", "low"),
            ("Créatinine",        "85",   "μmol/L", "45-90", "normal"),
        ]:
            db.add(models.LabResult(
                record_id=record.id,
                examen=exam[0], valeur=exam[1], unite=exam[2],
                norme=exam[3], statut=exam[4],
                date_examen=datetime(2025, 3, 28),
            ))

        # ── Appointments ──────────────────────────────────────────────────
        now = datetime.utcnow()
        appts = [
            models.Appointment(
                patient_id=patient.id, doctor_id=doctor.id,
                date_rdv=now + timedelta(days=1, hours=2),
                duration=30, statut=models.AppointmentStatus.confirmed,
                motif="Contrôle tension artérielle",
            ),
            models.Appointment(
                patient_id=patient.id, doctor_id=doctor2.id,
                date_rdv=now + timedelta(days=3, hours=5),
                duration=45, statut=models.AppointmentStatus.pending,
                motif="Bilan annuel",
            ),
            models.Appointment(
                patient_id=patient.id, doctor_id=doctor.id,
                date_rdv=now - timedelta(days=5),
                duration=30, statut=models.AppointmentStatus.completed,
                motif="Douleur thoracique légère",
                notes="RAS, patient en bonne santé.",
            ),
        ]
        for a in appts:
            db.add(a)

        # ── Notifications ─────────────────────────────────────────────────
        notifs = [
            models.Notification(
                user_id=patient_user.id,
                titre="Rappel de rendez-vous",
                message="Votre RDV avec Dr. Martin est demain à 10h30.",
                type=models.NotifType.reminder,
            ),
            models.Notification(
                user_id=patient_user.id,
                titre="RDV confirmé",
                message="Dr. Chen a confirmé votre consultation.",
                type=models.NotifType.confirmation,
                statut=models.NotifStatus.read,
            ),
            models.Notification(
                user_id=patient_user.id,
                titre="Nouvelle ordonnance",
                message="Une ordonnance pour Amlodipine 5mg a été émise.",
                type=models.NotifType.prescription,
            ),
        ]
        for n in notifs:
            db.add(n)

        # ── Activity logs ─────────────────────────────────────────────────
        db.add(models.ActivityLog(
            user_id=admin_user.id, action="Compte admin créé",
            adresse_ip="127.0.0.1",
        ))
        db.add(models.ActivityLog(
            user_id=doctor_user.id, action="Consultation dossier patient#1",
            adresse_ip="192.168.1.12",
        ))

        await db.commit()
        print("✅ Seed completed successfully!")
        print("\nDemo accounts:")
        print("  Admin:   admin@medisecure.fr   / Admin1234!")
        print("  Doctor:  s.martin@medisecure.fr / Doctor1234!")
        print("  Patient: e.bernard@email.com    / Patient1234!")


if __name__ == "__main__":
    asyncio.run(seed())
