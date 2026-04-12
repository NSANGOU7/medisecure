"""
MediSecure — FastAPI Backend main.py (VERSION CORRIGÉE)
"""
import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from database import engine, Base
from routers import auth, users, appointments, medical_records, notifications, admin
import models  # noqa: F401

# ✅ FIX #2 — Environnement (development ou production)
ENV = os.getenv("ENV", "development")

# ✅ FIX #3 — Rate limiting global
limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


# ✅ FIX #2 — Doc publique désactivée en production
app = FastAPI(
    title="MediSecure API",
    description="Secure medical appointment & records management",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs"         if ENV == "development" else None,
    redoc_url="/redoc"       if ENV == "development" else None,
    openapi_url="/openapi.json" if ENV == "development" else None,
)

# ✅ FIX #3 — Attacher le rate limiter à l'app
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# ✅ FIX #1 — CORS restreint aux origines autorisées uniquement
ALLOWED_ORIGINS = [
    "http://localhost:8080",
    "http://localhost:3000",
    "http://localhost:8000",
]

# En production, ajouter le vrai domaine
if ENV == "production":
    ALLOWED_ORIGINS = [
        "https://medisecure.fr",
        "https://app.medisecure.fr",
    ]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,      # ✅ Plus de wildcard "*"
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["Authorization", "Content-Type"],
)


# ✅ FIX #4 — Headers de sécurité HTTP sur toutes les réponses
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"]      = "nosniff"
    response.headers["X-Frame-Options"]             = "DENY"
    response.headers["X-XSS-Protection"]            = "1; mode=block"
    response.headers["Strict-Transport-Security"]   = "max-age=31536000; includeSubDomains"
    response.headers["Referrer-Policy"]             = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"]          = "geolocation=(), microphone=(), camera=()"
    return response


# Routers
app.include_router(auth.router,            prefix="/api/auth",         tags=["Auth"])
app.include_router(users.router,           prefix="/api/users",        tags=["Users"])
app.include_router(appointments.router,    prefix="/api/appointments", tags=["Appointments"])
app.include_router(medical_records.router, prefix="/api/records",      tags=["Medical Records"])
app.include_router(notifications.router,   prefix="/api/notifications",tags=["Notifications"])
app.include_router(admin.router,           prefix="/api/admin",        tags=["Admin"])


@app.get("/", tags=["Health"])
async def root():
    return {"status": "ok", "service": "MediSecure API v1.0"}
