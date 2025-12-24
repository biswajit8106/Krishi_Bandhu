# backend/app/routes/auth.py
from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
import bcrypt
import secrets
from datetime import datetime, timedelta
from pydantic import BaseModel
import os
import shutil
from pathlib import Path

from app import database, config
from app.models.user import User
from app.models.token import Token
from app.utils.auth_utils import get_current_user

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

@router.post("/update-profile")
def update_profile(
    name: str = Form(...),
    email: str = Form(...),
    phone: str = Form(...),
    location: str = Form(...),
    district: str = Form(...),
    state: str = Form(...),
    profile_image: UploadFile = File(None),
    db: Session = Depends(database.get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if phone or email is already taken by another user
    if phone != current_user.phone and db.query(User).filter(User.phone == phone).first():
        raise HTTPException(status_code=400, detail="Phone number already in use")
    if email != current_user.email and db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already in use")

    # Update user fields
    current_user.name = name
    current_user.email = email
    current_user.phone = phone
    current_user.location = location
    current_user.district = district
    current_user.state = state

    # Handle profile image upload
    if profile_image:
        # Create profile_images directory if it doesn't exist
        profile_images_dir = Path("static/profile_images")
        profile_images_dir.mkdir(exist_ok=True)

        # Generate unique filename
        file_extension = Path(profile_image.filename).suffix
        unique_filename = f"{current_user.id}_{secrets.token_hex(8)}{file_extension}"
        file_path = profile_images_dir / unique_filename

        # Save the uploaded file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(profile_image.file, buffer)

        # Update user's profile_image path
        current_user.profile_image = f"/static/profile_images/{unique_filename}"

    db.commit()
    db.refresh(current_user)
    return {"message": "Profile updated successfully"}

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

@router.post("/change-password")
def change_password(
    request: ChangePasswordRequest,
    db: Session = Depends(database.get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify old password
    if not verify_password(request.old_password, current_user.password):
        raise HTTPException(status_code=400, detail="Old password is incorrect")

    # Check if new password is different from old
    if request.old_password == request.new_password:
        raise HTTPException(status_code=400, detail="New password must be different from old password")

    # Validate new password length
    if len(request.new_password) < 6:
        raise HTTPException(status_code=400, detail="New password must be at least 6 characters long")

    # Hash new password and update
    hashed_new_password = get_password_hash(request.new_password)
    current_user.password = hashed_new_password

    db.commit()
    return {"msg": "Password changed successfully"}
