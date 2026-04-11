"""
MediSecure — security.py
JWT creation/verification, bcrypt hashing, RBAC dependency guards.
"""
import os
from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database import get_db
import models

SECRET_KEY      = os.getenv("SECRET_KEY", "CHANGE_ME_IN_PRODUCTION_super_secret_32_chars")
ALGORITHM       = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES  = 60
REFRESH_TOKEN_EXPIRE_DAYS    = 7
MAX_FAILED_ATTEMPTS          = 5
LOCKOUT_MINUTES              = 15

pwd_context   = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide ou expire",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> models.User:
    payload = decode_token(token)
    user_id: int = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token invalide")
    result = await db.execute(select(models.User).where(models.User.id == int(user_id)))
    user = result.scalar_one_or_none()
    if not user or user.statut != models.UserStatus.active:
        raise HTTPException(status_code=401, detail="Utilisateur introuvable ou suspendu")
    return user


class RoleChecker:
    def __init__(self, *roles: models.RoleEnum):
        self.roles = roles

    async def __call__(self, current_user: models.User = Depends(get_current_user)):
        if current_user.role not in self.roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Acces refuse.",
            )
        return current_user


require_patient = RoleChecker(models.RoleEnum.patient)
require_doctor  = RoleChecker(models.RoleEnum.doctor, models.RoleEnum.nurse)
require_medical = RoleChecker(models.RoleEnum.doctor, models.RoleEnum.nurse, models.RoleEnum.admin)
require_admin   = RoleChecker(models.RoleEnum.admin)


async def log_action(db: AsyncSession, user_id: int, action: str, request: Request = None, details: str = None):
    ip = request.client.host if request else "unknown"
    log = models.ActivityLog(user_id=user_id, action=action, adresse_ip=ip, details=details)
    db.add(log)
    await db.flush()