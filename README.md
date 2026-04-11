# MediSecure — Fullstack Application

> Secure medical appointment & records management system  
> **ESTIAM — Master Développement Web & Mobile / CCNS — 2025-2026**

**Mobile Developer: Ahmad Sanoh**

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile / Web Frontend | Flutter 3.x (Dart) |
| Backend API | Python 3.11 + FastAPI |
| Database | PostgreSQL 16+ |
| Authentication | JWT (access + refresh tokens) |
| Password Hashing | bcrypt via passlib |
| ORM | SQLAlchemy 2.0 (async) |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP Client | Dio |

---

## Features

- 🔐 Secure login / register with JWT — 3 roles: Patient, Doctor, Admin
- 📅 Appointment booking with 4-step wizard, double-booking prevention
- 📋 Medical records — antecedents, allergies, prescriptions, consultations, lab results
- 💊 Doctor can write prescriptions and consultation notes
- 🔔 Notifications system with auto reminders
- 🛡️ Admin panel — user management, activity logs, RBAC
- 📊 Role-adaptive dashboards for each user type
- 🔒 Full audit trail — every record access is logged with IP

---

## Prerequisites

Before you start, install these:

### 1. Python 3.11
Download from: https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe

During install:
- Click **"Customize installation"**
- Set install path to `C:\Python311`
- Finish install

### 2. PostgreSQL 16+
Download from: https://www.postgresql.org/download/windows/

During install:
- Remember the password you set for the `postgres` user
- Keep default port 5432

### 3. Flutter 3.x
Download from: https://flutter.dev/docs/get-started/install/windows

Follow the install guide and add Flutter to your PATH.

### 4. Git
Download from: https://git-scm.com/download/win

---

## Installation & Setup

### Clone the repository

```bash
git clone https://github.com/Ahmadsanoh/medisecure.git
cd medisecure
```

---

### Backend Setup

#### 1. Create the PostgreSQL database

Open PowerShell and run:

```powershell
psql -U postgres
```

Inside psql, run:

```sql
CREATE DATABASE medisecure_db;
CREATE USER medisecure WITH PASSWORD 'medisecure_pass';
GRANT ALL PRIVILEGES ON DATABASE medisecure_db TO medisecure;
\c medisecure_db
GRANT ALL ON SCHEMA public TO medisecure;
\q
```

#### 2. Create Python virtual environment

```powershell
cd medisecure/backend
"C:\Program Files\Python311\python.exe" -m venv .venv
.venv\Scripts\activate
```

#### 3. Install Python packages

```powershell
pip install -r requirements.txt
pip install bcrypt==4.0.1
```

#### 4. Start the API

```powershell
uvicorn main:app --reload --port 8000 --host 0.0.0.0
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

#### 5. Load demo data (open a second terminal)

```powershell
cd medisecure/backend
.venv\Scripts\activate
python seed.py
```

#### 6. Verify backend is working

Open your browser at: http://localhost:8000/docs

You should see the interactive API documentation.

---

### Mobile / Web Frontend Setup

#### 1. Install Flutter dependencies

```powershell
cd medisecure/mobile
flutter pub get
```

#### 2. Enable platforms

```powershell
flutter create --platforms=windows,web,android .
```

#### 3. Configure API URL

Open `lib/services/api_client.dart` and set:

```dart
// For Chrome / Web browser:
const _baseUrl = 'http://localhost:8000/api';

// For Android Emulator:
const _baseUrl = 'http://10.0.2.2:8000/api';

// For physical Android device (use your PC local IP):
const _baseUrl = 'http://192.168.1.X:8000/api';
```

#### 4. Run the app

```powershell
# In Chrome browser:
flutter run -d chrome

# On Windows desktop (requires Developer Mode enabled):
flutter run -d windows

# On Android emulator or device:
flutter run
```

---

## Demo Accounts

After running `python seed.py`:

| Role | Email | Password |
|---|---|---|
| 👤 Patient | e.bernard@email.com | Patient1234! |
| 👨‍⚕️ Doctor | s.martin@medisecure.fr | Doctor1234! |
| 🛡️ Admin | admin@medisecure.fr | Admin1234! |

---

## Project Structure

```
medisecure/
├── backend/                    # Python FastAPI REST API
│   ├── main.py                 # App entry point
│   ├── database.py             # Async SQLAlchemy engine
│   ├── models.py               # All ORM models (3NF)
│   ├── schemas.py              # Pydantic request/response models
│   ├── security.py             # JWT, bcrypt, RBAC guards
│   ├── scheduler.py            # Auto reminder notifications
│   ├── seed.py                 # Demo data loader
│   ├── requirements.txt        # Python dependencies
│   └── routers/
│       ├── auth.py             # Login, register, token refresh
│       ├── users.py            # User profiles, doctors list
│       ├── appointments.py     # Booking CRUD + slot availability
│       ├── medical_records.py  # Records, prescriptions, labs
│       ├── notifications.py    # Notification management
│       └── admin.py            # User management, logs, stats
│
└── mobile/                     # Flutter app
    └── lib/
        ├── main.dart           # App entry + Material3 theme
        ├── router.dart         # GoRouter navigation
        ├── models/             # Dart data models
        ├── services/           # API calls + Riverpod providers
        ├── screens/
        │   ├── auth/           # Login, Register, Forgot Password
        │   ├── home/           # Role-adaptive dashboards
        │   ├── appointments/   # Calendar, booking wizard, detail
        │   ├── records/        # Medical record viewer
        │   ├── notifications/  # Notification feed
        │   ├── profile/        # Settings + edit profile
        │   └── admin/          # Admin panel screens
        └── widgets/            # Reusable UI components
```

---

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | Public | Create account |
| POST | `/api/auth/login` | Public | Login → JWT |
| POST | `/api/auth/refresh` | Refresh token | Renew access token |
| POST | `/api/auth/forgot-password` | Public | Send reset email |
| GET | `/api/users/me` | Bearer | My profile |
| GET | `/api/users/doctors` | Bearer | List doctors |
| GET | `/api/appointments/` | Bearer | My appointments |
| POST | `/api/appointments/` | Bearer | Book appointment |
| DELETE | `/api/appointments/{id}` | Bearer | Cancel appointment |
| GET | `/api/records/my` | Bearer | My medical record |
| GET | `/api/records/{patient_id}` | Doctor/Admin | Patient record |
| POST | `/api/records/{id}/prescriptions` | Doctor | Add prescription |
| GET | `/api/notifications/` | Bearer | My notifications |
| GET | `/api/admin/stats` | Admin | System statistics |
| GET | `/api/admin/users` | Admin | All users |
| GET | `/api/admin/logs` | Admin | Activity logs |

Full interactive docs available at: http://localhost:8000/docs

---

## Running Everything — Quick Reference

Open 2 terminals:

**Terminal 1 — Backend:**
```powershell
cd medisecure/backend
.venv\Scripts\activate
uvicorn main:app --reload --port 8000 --host 0.0.0.0
```

**Terminal 2 — Frontend:**
```powershell
cd medisecure/mobile
flutter run -d chrome
```

---

## Troubleshooting

**`bcrypt` error when running seed.py**
```powershell
pip install bcrypt==4.0.1
```

**`asyncpg` build error**
Make sure you are using Python 3.11, not 3.13:
```powershell
"C:\Program Files\Python311\python.exe" -m venv .venv
```

**Flutter symlink error on Windows**
Enable Developer Mode: Settings → Privacy & Security → For Developers → Developer Mode → On

**App shows blank screen / login does not work**
Make sure `api_client.dart` uses `http://localhost:8000/api` for web/Chrome.

**PostgreSQL connection refused**
Open Windows Services → find `postgresql-x64-XX` → right-click → Start
