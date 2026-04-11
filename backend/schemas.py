"""
MediSecure — schemas.py
Pydantic v2 request / response models.
"""
from __future__ import annotations
from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, field_validator
import re

# ── Auth ──────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: str
    user_id: int

class RefreshRequest(BaseModel):
    refresh_token: str

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str

# ── User ──────────────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    nom: str
    prenom: str
    email: EmailStr
    password: str
    role: str
    telephone: Optional[str] = None

    @field_validator("password")
    @classmethod
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError("Le mot de passe doit contenir au moins 8 caractères")
        return v

class UserUpdate(BaseModel):
    nom:       Optional[str] = None
    prenom:    Optional[str] = None
    telephone: Optional[str] = None

class UserOut(BaseModel):
    id:           int
    nom:          str
    prenom:       str
    email:        str
    role:         str
    telephone:    Optional[str]
    statut:       str
    date_creation: datetime
    model_config = {"from_attributes": True}

# ── Patient profile ───────────────────────────────────────────────────────────

class PatientProfileUpdate(BaseModel):
    date_naissance: Optional[date]   = None
    sexe:           Optional[str]    = None
    adresse:        Optional[str]    = None
    groupe_sanguin: Optional[str]    = None

class PatientOut(BaseModel):
    id:             int
    user_id:        int
    date_naissance: Optional[date]
    sexe:           Optional[str]
    adresse:        Optional[str]
    groupe_sanguin: Optional[str]
    user:           UserOut
    model_config = {"from_attributes": True}

# ── Specialty ─────────────────────────────────────────────────────────────────

class SpecialtyOut(BaseModel):
    id:  int
    nom: str
    model_config = {"from_attributes": True}

# ── Doctor ────────────────────────────────────────────────────────────────────

class DoctorOut(BaseModel):
    id:             int
    user_id:        int
    numero_licence: Optional[str]
    bio:            Optional[str]
    rating:         Optional[str]
    specialty:      Optional[SpecialtyOut]
    user:           UserOut
    model_config = {"from_attributes": True}

# ── Appointment ───────────────────────────────────────────────────────────────

class AppointmentCreate(BaseModel):
    doctor_id:  int
    date_rdv:   datetime
    duration:   int = 30
    motif:      Optional[str] = None

class AppointmentUpdate(BaseModel):
    date_rdv: Optional[datetime] = None
    statut:   Optional[str]      = None
    notes:    Optional[str]      = None

class AppointmentOut(BaseModel):
    id:         int
    date_rdv:   datetime
    duration:   int
    statut:     str
    motif:      Optional[str]
    notes:      Optional[str]
    created_at: datetime
    patient_id: int
    doctor_id:  int
    model_config = {"from_attributes": True}

# ── Medical Record ────────────────────────────────────────────────────────────

class MedicalRecordUpdate(BaseModel):
    antecedents:   Optional[str] = None
    allergies:     Optional[str] = None
    traitements:   Optional[str] = None
    notes_medecin: Optional[str] = None

class PrescriptionCreate(BaseModel):
    medicament: str
    dosage:     Optional[str] = None
    posologie:  Optional[str] = None
    date_debut: Optional[date] = None
    date_fin:   Optional[date] = None

class PrescriptionOut(BaseModel):
    id:         int
    medicament: str
    dosage:     Optional[str]
    posologie:  Optional[str]
    date_debut: Optional[date]
    date_fin:   Optional[date]
    is_active:  bool
    created_at: datetime
    model_config = {"from_attributes": True}

class ConsultationCreate(BaseModel):
    date_consult:  datetime
    diagnostic:    Optional[str] = None
    observations:  Optional[str] = None

class ConsultationOut(BaseModel):
    id:           int
    date_consult:  datetime
    diagnostic:    Optional[str]
    observations:  Optional[str]
    created_at:    datetime
    model_config = {"from_attributes": True}

class LabResultCreate(BaseModel):
    examen:      str
    valeur:      Optional[str] = None
    unite:       Optional[str] = None
    norme:       Optional[str] = None
    statut:      Optional[str] = None
    date_examen: Optional[datetime] = None

class LabResultOut(BaseModel):
    id:          int
    examen:      str
    valeur:      Optional[str]
    unite:       Optional[str]
    norme:       Optional[str]
    statut:      Optional[str]
    date_examen: Optional[datetime]
    model_config = {"from_attributes": True}

class MedicalRecordOut(BaseModel):
    id:            int
    patient_id:    int
    antecedents:   Optional[str]
    allergies:     Optional[str]
    traitements:   Optional[str]
    notes_medecin: Optional[str]
    date_creation: datetime
    prescriptions: List[PrescriptionOut] = []
    consultations: List[ConsultationOut] = []
    lab_results:   List[LabResultOut]    = []
    model_config = {"from_attributes": True}

# ── Notification ──────────────────────────────────────────────────────────────

class NotificationOut(BaseModel):
    id:         int
    titre:      Optional[str]
    message:    str
    type:       str
    statut:     str
    date_envoi: datetime
    model_config = {"from_attributes": True}

# ── Admin ─────────────────────────────────────────────────────────────────────

class AdminUserUpdate(BaseModel):
    statut: Optional[str] = None
    role:   Optional[str] = None

class SystemStats(BaseModel):
    total_users:          int
    active_patients:      int
    active_doctors:       int
    total_appointments:   int
    appointments_today:   int
    pending_appointments: int
