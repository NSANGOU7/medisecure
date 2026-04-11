"""
MediSecure — FastAPI Backend  main.py
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from database import engine, Base
from routers import auth, users, appointments, medical_records, notifications, admin
import models  # noqa: F401  — registers all ORM models


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(
    title="MediSecure API",
    description="Secure medical appointment & records management",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,            prefix="/api/auth",          tags=["Auth"])
app.include_router(users.router,           prefix="/api/users",         tags=["Users"])
app.include_router(appointments.router,    prefix="/api/appointments",   tags=["Appointments"])
app.include_router(medical_records.router, prefix="/api/records",        tags=["Medical Records"])
app.include_router(notifications.router,   prefix="/api/notifications",  tags=["Notifications"])
app.include_router(admin.router,           prefix="/api/admin",          tags=["Admin"])


@app.get("/", tags=["Health"])
async def root():
    return {"status": "ok", "service": "MediSecure API v1.0"}
