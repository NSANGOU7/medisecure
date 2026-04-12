"""
MediSecure — models.py (VERSION CORRIGÉE)
All ORM models — 3NF normalised, matching the MCD.
"""
import enum
import os
from datetime import datetime
from cryptography.fernet import Fernet
from sqlalchemy import (
    Column, Integer, String, Text, DateTime, Boolean, Enum,
    ForeignKey, Date, Float, func,
)
from sqlalchemy.orm import relationship
from database import Base

# ✅ FIX #1 — Clé de chiffrement Fernet pour les données médicales sensibles
FERNET_KEY = os.getenv("FERNET_KEY")
if not FERNET_KEY:
    raise RuntimeError(
        "❌ FERNET_KEY non définie ! "
        "Ajoutez-la dans vos variables d'environnement (.env)"
    )
fernet = Fernet(FERNET_KEY.encode())


def encrypt(value: str) -> str:
    """Chiffre une valeur sensible avant stockage en base."""
    if not value:
        return value
    return fernet.encrypt(value.encode()).decode()


def decrypt(value: str) -> str:
    """Déchiffre une valeur sensible après lecture depuis la base."""
    if not value:
        return value
    return fernet.decrypt(value.encode()).decode()


# ── Enumerations ─────────────────────────────────────────────────────────────

class RoleEnum(str, enum.Enum):
    patient = "patient"
    doctor  = "doctor"
    nurse   = "nurse"
    admin   = "admin"


class AppointmentStatus(str, enum.Enum):
    pending   = "pending"
    confirmed = "confirmed"
    cancelled = "cancelled"
    completed = "completed"


class NotifType(str, enum.Enum):
    reminder     = "reminder"
    confirmation = "confirmation"
    cancellation = "cancellation"
    system       = "system"
    prescription = "prescription"


class NotifStatus(str, enum.Enum):
    sent   = "sent"
    read   = "read"
    failed = "failed"


class UserStatus(str, enum.Enum):
    active    = "active"
    suspended = "suspended"
    pending   = "pending"


# ✅ FIX #4 — Enum dédié pour le statut des résultats de laboratoire
class LabStatus(str, enum.Enum):
    normal = "normal"
    high   = "high"
    low    = "low"


# ── Base User ─────────────────────────────────────────────────────────────────

class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    nom             = Column(String(100), nullable=False)
    prenom          = Column(String(100), nullable=False)
    email           = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role            = Column(Enum(RoleEnum), nullable=False)
    telephone       = Column(String(20))
    statut          = Column(Enum(UserStatus), default=UserStatus.active)
    date_creation   = Column(DateTime, default=datetime.utcnow)
    last_login      = Column(DateTime)
    failed_attempts = Column(Integer, default=0)
    locked_until    = Column(DateTime, nullable=True)

    patient_profile = relationship("Patient",      back_populates="user", uselist=False, cascade="all, delete-orphan")
    doctor_profile  = relationship("Doctor",       back_populates="user", uselist=False, cascade="all, delete-orphan")
    admin_profile   = relationship("Admin",        back_populates="user", uselist=False, cascade="all, delete-orphan")
    notifications   = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    activity_logs   = relationship("ActivityLog",  back_populates="user", cascade="all, delete-orphan")


# ── Patient ───────────────────────────────────────────────────────────────────

class Patient(Base):
    __tablename__ = "patients"

    id             = Column(Integer, primary_key=True, index=True)
    user_id        = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    date_naissance = Column(Date)
    sexe           = Column(String(10))
    adresse        = Column(Text)
    groupe_sanguin = Column(String(5))

    user           = relationship("User",          back_populates="patient_profile")
    appointments   = relationship("Appointment",   back_populates="patient", cascade="all, delete-orphan")
    medical_record = relationship("MedicalRecord", back_populates="patient", uselist=False, cascade="all, delete-orphan")


# ── Specialty ─────────────────────────────────────────────────────────────────

class Specialty(Base):
    __tablename__ = "specialties"

    id          = Column(Integer, primary_key=True, index=True)
    nom         = Column(String(100), unique=True, nullable=False)
    description = Column(Text)

    doctors     = relationship("Doctor", back_populates="specialty")


# ── Clinic ────────────────────────────────────────────────────────────────────

class Clinic(Base):
    __tablename__ = "clinics"

    id        = Column(Integer, primary_key=True, index=True)
    nom       = Column(String(200), nullable=False)
    adresse   = Column(Text)
    telephone = Column(String(20))

    doctors   = relationship("Doctor", back_populates="clinic")


# ── Doctor ────────────────────────────────────────────────────────────────────

class Doctor(Base):
    __tablename__ = "doctors"

    id             = Column(Integer, primary_key=True, index=True)
    user_id        = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    specialty_id   = Column(Integer, ForeignKey("specialties.id"))
    clinic_id      = Column(Integer, ForeignKey("clinics.id"))
    numero_licence = Column(String(50), unique=True)
    bio            = Column(Text)
    # ✅ FIX #3 — Rating en Float au lieu de String
    rating         = Column(Float, default=5.0)

    user           = relationship("User",        back_populates="doctor_profile")
    specialty      = relationship("Specialty",   back_populates="doctors")
    clinic         = relationship("Clinic",      back_populates="doctors")
    appointments   = relationship("Appointment", back_populates="doctor")


# ── Admin ─────────────────────────────────────────────────────────────────────

class Admin(Base):
    __tablename__ = "admins"

    id           = Column(Integer, primary_key=True, index=True)
    user_id      = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    niveau_acces = Column(Integer, default=1)

    user         = relationship("User", back_populates="admin_profile")


# ── Appointment ───────────────────────────────────────────────────────────────

class Appointment(Base):
    __tablename__ = "appointments"

    id         = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    doctor_id  = Column(Integer, ForeignKey("doctors.id"),  nullable=False)
    date_rdv   = Column(DateTime, nullable=False)
    duration   = Column(Integer, default=30)
    statut     = Column(Enum(AppointmentStatus), default=AppointmentStatus.pending)
    motif      = Column(Text)
    notes      = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

    patient    = relationship("Patient", back_populates="appointments")
    doctor     = relationship("Doctor",  back_populates="appointments")


# ── Medical Record ────────────────────────────────────────────────────────────

class MedicalRecord(Base):
    __tablename__ = "medical_records"

    id            = Column(Integer, primary_key=True, index=True)
    patient_id    = Column(Integer, ForeignKey("patients.id"), unique=True, nullable=False)
    # ✅ FIX #1 — Chiffrement réel des données médicales sensibles
    _antecedents  = Column("antecedents",   Text)
    _allergies    = Column("allergies",     Text)
    _traitements  = Column("traitements",   Text)
    notes_medecin = Column(Text)
    date_creation = Column(DateTime, default=datetime.utcnow)
    updated_at    = Column(DateTime, onupdate=datetime.utcnow)

    patient       = relationship("Patient",      back_populates="medical_record")
    prescriptions = relationship("Prescription", back_populates="record", cascade="all, delete-orphan")
    consultations = relationship("Consultation", back_populates="record", cascade="all, delete-orphan")
    lab_results   = relationship("LabResult",    back_populates="record", cascade="all, delete-orphan")

    # Propriétés qui chiffrent/déchiffrent automatiquement
    @property
    def antecedents(self) -> str:
        return decrypt(self._antecedents)

    @antecedents.setter
    def antecedents(self, value: str):
        self._antecedents = encrypt(value)

    @property
    def allergies(self) -> str:
        return decrypt(self._allergies)

    @allergies.setter
    def allergies(self, value: str):
        self._allergies = encrypt(value)

    @property
    def traitements(self) -> str:
        return decrypt(self._traitements)

    @traitements.setter
    def traitements(self, value: str):
        self._traitements = encrypt(value)


class Prescription(Base):
    __tablename__ = "prescriptions"

    id          = Column(Integer, primary_key=True, index=True)
    record_id   = Column(Integer, ForeignKey("medical_records.id"), nullable=False)
    doctor_id   = Column(Integer, ForeignKey("doctors.id"))
    medicament  = Column(String(200), nullable=False)
    dosage      = Column(String(100))
    posologie   = Column(String(200))
    date_debut  = Column(Date)
    date_fin    = Column(Date)
    is_active   = Column(Boolean, default=True)
    created_at  = Column(DateTime, default=datetime.utcnow)

    record      = relationship("MedicalRecord", back_populates="prescriptions")


class Consultation(Base):
    __tablename__ = "consultations"

    id           = Column(Integer, primary_key=True, index=True)
    record_id    = Column(Integer, ForeignKey("medical_records.id"), nullable=False)
    doctor_id    = Column(Integer, ForeignKey("doctors.id"))
    date_consult = Column(DateTime, nullable=False)
    diagnostic   = Column(Text)
    observations = Column(Text)
    created_at   = Column(DateTime, default=datetime.utcnow)

    record       = relationship("MedicalRecord", back_populates="consultations")


class LabResult(Base):
    __tablename__ = "lab_results"

    id          = Column(Integer, primary_key=True, index=True)
    record_id   = Column(Integer, ForeignKey("medical_records.id"), nullable=False)
    examen      = Column(String(200), nullable=False)
    valeur      = Column(String(100))
    unite       = Column(String(50))
    norme       = Column(String(100))
    # ✅ FIX #4 — Enum dédié pour le statut
    statut      = Column(Enum(LabStatus))
    date_examen = Column(DateTime)
    created_at  = Column(DateTime, default=datetime.utcnow)

    record      = relationship("MedicalRecord", back_populates="lab_results")


# ── Notification ──────────────────────────────────────────────────────────────

class Notification(Base):
    __tablename__ = "notifications"

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False)
    titre      = Column(String(200))
    message    = Column(Text, nullable=False)
    type       = Column(Enum(NotifType),   default=NotifType.system)
    statut     = Column(Enum(NotifStatus), default=NotifStatus.sent)
    date_envoi = Column(DateTime, default=datetime.utcnow)

    user       = relationship("User", back_populates="notifications")


# ── Activity Log ──────────────────────────────────────────────────────────────

class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id"))
    action      = Column(String(500), nullable=False)
    date_action = Column(DateTime, default=func.now())
    # ✅ FIX #5 — Taille contrainte à 45 chars (IPv6 max)
    adresse_ip  = Column(String(45))
    details     = Column(Text)

    user        = relationship("User", back_populates="activity_logs")
