# MediSecure — Fullstack Application

> Secure medical appointment & records management — ESTIAM 2025-2026  
> Stack: **FastAPI + PostgreSQL** (backend) · **Flutter** (mobile)

---

## Project Structure

```
medisecure/
├── backend/          # Python FastAPI REST API
│   ├── main.py
│   ├── database.py
│   ├── models.py          # SQLAlchemy ORM (3NF)
│   ├── schemas.py         # Pydantic v2 request/response
│   ├── security.py        # JWT, bcrypt, RBAC guards
│   ├── scheduler.py       # APScheduler — reminder notifications
│   ├── routers/
│   │   ├── auth.py            # Login, register, refresh, forgot/reset password
│   │   ├── users.py           # Profile management, doctors list, specialties
│   │   ├── appointments.py    # CRUD + double-booking prevention + slots
│   │   ├── medical_records.py # Records, prescriptions, consultations, lab results
│   │   ├── notifications.py   # List, mark read, unread count
│   │   └── admin.py           # User management, stats, activity logs
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
│
└── mobile/           # Flutter app (iOS + Android)
    └── lib/
        ├── main.dart          # App entry — Material3 theme + Riverpod
        ├── router.dart        # GoRouter — auth guard + named routes
        ├── models/            # Dart data models (UserModel, AppointmentModel…)
        ├── services/          # API calls via Dio + Riverpod providers
        ├── screens/
        │   ├── auth/          # Login, Register, Forgot Password
        │   ├── home/          # Role-adaptive dashboard (Patient/Doctor/Admin)
        │   ├── appointments/  # List (calendar strip), Booking wizard, Detail
        │   ├── records/       # Medical record (expandable), Prescriptions
        │   ├── notifications/ # Notification feed + mark read
        │   ├── profile/       # Settings, 2FA toggle, Edit profile
        │   └── admin/         # Dashboard, User management, Activity logs
        └── widgets/           # MsButton, MsTextField, AppointmentCard, StatCard…
```

---

## Backend — Quick Start

### Prerequisites
- Python 3.12+
- PostgreSQL 16+  *(or use Docker)*

### Option A — Docker Compose (recommended)

```bash
cd backend
docker compose up --build
```

API available at **http://localhost:8000**  
Interactive docs: **http://localhost:8000/docs**

### Option B — Local

```bash
cd backend
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Create the database
createdb medisecure_db

# Set environment variables (or create a .env file)
export DATABASE_URL="postgresql+asyncpg://user:pass@localhost:5432/medisecure_db"
export SECRET_KEY="your_long_random_secret_key_here"

# Run API
uvicorn main:app --reload --port 8000

# Run scheduler (separate terminal)
python scheduler.py
```

### Environment Variables

| Variable       | Default                                              | Description                  |
|----------------|------------------------------------------------------|------------------------------|
| `DATABASE_URL` | `postgresql+asyncpg://medisecure:medisecure_pass@localhost:5432/medisecure_db` | PostgreSQL async URL |
| `SECRET_KEY`   | `CHANGE_ME_IN_PRODUCTION_...`                        | JWT signing secret (change!) |

### API Endpoints Summary

| Method | Path                                    | Auth         | Description                        |
|--------|-----------------------------------------|--------------|------------------------------------|
| POST   | `/api/auth/register`                    | Public       | Create account                     |
| POST   | `/api/auth/login`                       | Public       | Login → JWT tokens                 |
| POST   | `/api/auth/refresh`                     | Refresh token| Renew access token                 |
| POST   | `/api/auth/forgot-password`             | Public       | Send reset email                   |
| POST   | `/api/auth/reset-password`              | Public       | Reset with token                   |
| GET    | `/api/users/me`                         | Bearer       | Current user profile               |
| PUT    | `/api/users/me`                         | Bearer       | Update profile                     |
| GET    | `/api/users/doctors`                    | Bearer       | List doctors (filter by specialty) |
| GET    | `/api/users/specialties`                | Bearer       | List specialties                   |
| GET    | `/api/appointments/`                    | Bearer       | My appointments                    |
| POST   | `/api/appointments/`                    | Bearer       | Create appointment                 |
| PUT    | `/api/appointments/{id}`                | Bearer       | Update appointment                 |
| DELETE | `/api/appointments/{id}`                | Bearer       | Cancel appointment                 |
| GET    | `/api/appointments/slots/{doctor_id}`   | Bearer       | Available slots for a date         |
| GET    | `/api/records/my`                       | Bearer       | Patient's own medical record       |
| GET    | `/api/records/{patient_id}`             | Doctor/Admin | Read patient record                |
| PUT    | `/api/records/{patient_id}`             | Doctor/Admin | Update record                      |
| POST   | `/api/records/{patient_id}/prescriptions` | Doctor     | Add prescription                   |
| POST   | `/api/records/{patient_id}/consultations` | Doctor     | Add consultation note              |
| POST   | `/api/records/{patient_id}/lab-results`   | Doctor     | Add lab result                     |
| GET    | `/api/notifications/`                   | Bearer       | My notifications                   |
| PUT    | `/api/notifications/{id}/read`          | Bearer       | Mark as read                       |
| PUT    | `/api/notifications/read-all`           | Bearer       | Mark all read                      |
| GET    | `/api/admin/stats`                      | Admin        | System statistics                  |
| GET    | `/api/admin/users`                      | Admin        | All users                          |
| PUT    | `/api/admin/users/{id}`                 | Admin        | Update user role/status            |
| DELETE | `/api/admin/users/{id}`                 | Admin        | Delete user                        |
| GET    | `/api/admin/logs`                       | Admin        | Activity logs                      |

---

## Mobile — Flutter Setup

### Prerequisites
- Flutter SDK 3.22+ (`flutter --version`)
- Android Studio / Xcode
- A running backend instance

### Setup

```bash
cd mobile
flutter pub get
```

### Configure API URL

Edit `lib/services/api_client.dart`:

```dart
// Android emulator
const _baseUrl = 'http://10.0.2.2:8000/api';

// iOS simulator
const _baseUrl = 'http://localhost:8000/api';

// Physical device (use your machine's local IP)
const _baseUrl = 'http://192.168.1.X:8000/api';
```

### Run

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Generate code (Riverpod, Freezed)
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Roles & Permissions (RBAC)

| Feature                        | Patient | Doctor | Nurse | Admin |
|-------------------------------|---------|--------|-------|-------|
| Login / Register               | ✅      | ✅     | ✅    | ✅    |
| View own appointments          | ✅      | ✅     | ✅    | ✅    |
| Book appointment               | ✅      | ❌     | ❌    | ✅    |
| View own medical record        | ✅      | ❌     | ❌    | ❌    |
| View any patient record        | ❌      | ✅     | ✅    | ✅    |
| Add prescription / consult     | ❌      | ✅     | ✅    | ❌    |
| Manage all users               | ❌      | ❌     | ❌    | ✅    |
| View activity logs             | ❌      | ❌     | ❌    | ✅    |
| System stats                   | ❌      | ❌     | ❌    | ✅    |

---

## Database Schema (simplified)

```
users ──< patients ──< appointments >── doctors >── specialties
                  └──  medical_records ──< prescriptions
                                       ──< consultations
                                       ──< lab_results
users ──< notifications
users ──< activity_logs
doctors >── clinics
```

---

## Security Features

- Passwords hashed with **bcrypt** (never stored in plain text)
- **JWT** access tokens (60 min) + refresh tokens (7 days)
- Account **lockout** after 5 failed login attempts (15 min)
- **RBAC** — role checked on every protected endpoint
- **Audit log** — every record access and modification is logged with IP
- Medical data fields designed for **field-level encryption** (plug in Fernet/AES)
- CORS configured (tighten `allow_origins` in production)

---

## Team

| Name                        | Role                                      |
|-----------------------------|-------------------------------------------|
| Antoine Leng                | Front-End Developer                       |
| Ahmad Sanoh                 | Mobile Developer                          |
| Tchoufong Super Abel        | Back-End / Full-Stack Developer           |
| Zayd Zayani                 | Cybersecurity — Auth & Encryption         |
| Mahmoud Maigari Nsangou Njikam | Cybersecurity — Network & Monitoring  |
