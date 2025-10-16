# backend/app/routes/auth.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import bcrypt
from jose import jwt
from datetime import datetime, timedelta
from pydantic import BaseModel

from app import database, config
from app.models.user import User

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

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=config.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, config.SECRET_KEY, algorithm=config.ALGORITHM)

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
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}
