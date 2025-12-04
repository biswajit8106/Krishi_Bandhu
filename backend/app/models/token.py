from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime, timedelta

class Token(Base):
    __tablename__ = "tokens"

    id = Column(Integer, primary_key=True, index=True)
    token = Column(String(255), unique=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    expires_at = Column(DateTime)
    token_type = Column(String(50))  # 'access' or 'refresh'

    user = relationship("User")
