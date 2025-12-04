# backend/app/routes/auth.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import bcrypt
import secrets
from datetime import datetime, timedelta
from pydantic import BaseModel

from app import database, config
from app.models.user import User
from app.models.token import Token

class SignupRequest(BaseModel):
    name: str
    phone: str
    email: str | None = None
    password: str
    state: str
    district: str
    location: str
    language: str

class LoginRequest(BaseModel):
    identifier: str
    password: str

router = APIRouter()

def get_password_hash(password):
    return bcrypt.hashpw(password[:72].encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password, hashed_password):
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

def generate_token():
    return secrets.token_urlsafe(32)

# ---------------- ROUTES ----------------
@router.post("/signup")
def signup(request: SignupRequest, db: Session = Depends(database.get_db)):
    if db.query(User).filter(User.phone == request.phone).first():
        raise HTTPException(status_code=400, detail="Phone already registered")
    if request.email and db.query(User).filter(User.email == request.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed_pw = get_password_hash(request.password)
    new_user = User(
        name=request.name,
        phone=request.phone,
        email=request.email,
        password=hashed_pw,
        state=request.state,
        district=request.district,
        location=request.location,
        language=request.language,
        role="farmer"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"msg": "User created successfully"}

@router.post("/login")
def login(request: LoginRequest, db: Session = Depends(database.get_db)):
    user = db.query(User).filter(
        (User.email == request.identifier) | (User.phone == request.identifier)
    ).first()
    if not user or not verify_password(request.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # Clean up old tokens for this user
    db.query(Token).filter(Token.user_id == user.id).delete()

    # Create new tokens
    access_token_str = generate_token()
    refresh_token_str = generate_token()

    access_expires = datetime.utcnow() + timedelta(minutes=config.ACCESS_TOKEN_EXPIRE_MINUTES)
    refresh_expires = datetime.utcnow() + timedelta(days=config.REFRESH_TOKEN_EXPIRE_DAYS)

    access_token = Token(token=access_token_str, user_id=user.id, expires_at=access_expires, token_type="access")
    refresh_token = Token(token=refresh_token_str, user_id=user.id, expires_at=refresh_expires, token_type="refresh")

    db.add(access_token)
    db.add(refresh_token)
    db.commit()

    return {"access_token": access_token_str, "refresh_token": refresh_token_str, "token_type": "bearer"}

class RefreshRequest(BaseModel):
    refresh_token: str

@router.post("/refresh")
def refresh_token_endpoint(request: RefreshRequest, db: Session = Depends(database.get_db)):
    token_entry = db.query(Token).filter(Token.token == request.refresh_token, Token.token_type == "refresh").first()
    if not token_entry or token_entry.expires_at < datetime.utcnow():
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    user = token_entry.user

    # Clean up old tokens
    db.query(Token).filter(Token.user_id == user.id).delete()

    # Create new tokens
    access_token_str = generate_token()
    refresh_token_str = generate_token()

    access_expires = datetime.utcnow() + timedelta(minutes=config.ACCESS_TOKEN_EXPIRE_MINUTES)
    refresh_expires = datetime.utcnow() + timedelta(days=config.REFRESH_TOKEN_EXPIRE_DAYS)

    access_token = Token(token=access_token_str, user_id=user.id, expires_at=access_expires, token_type="access")
    refresh_token = Token(token=refresh_token_str, user_id=user.id, expires_at=refresh_expires, token_type="refresh")

    db.add(access_token)
    db.add(refresh_token)
    db.commit()

    return {"access_token": access_token_str, "refresh_token": refresh_token_str, "token_type": "bearer"}
