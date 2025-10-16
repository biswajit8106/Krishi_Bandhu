# backend/app/models/user.py
from sqlalchemy import Column, Integer, String
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100))
    phone = Column(String(20), unique=True, index=True)
    email = Column(String(100), unique=True, index=True, nullable=True)
    password = Column(String(255))
    state = Column(String(50))
    district = Column(String(50))
    location = Column(String(100))  # City or village name
    language = Column(String(50))
    role = Column(String(50))  # e.g., 'farmer', 'expert', 'admin'
