from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base


class IrrigationSchedule(Base):
    __tablename__ = "irrigation_schedules"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    date = Column(String(20))  # YYYY-MM-DD
    time = Column(String(50))  # e.g., '06:00 AM'
    duration = Column(String(50))
    is_enabled = Column(Boolean, default=True)
    water_liters = Column(Float, nullable=True)  # estimated water usage
    created_at = Column(DateTime, default=datetime.utcnow)


class IrrigationEvent(Base):
    __tablename__ = "irrigation_events"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    event_type = Column(String(50))  # e.g., 'watered', 'prediction_saved'
    details = Column(String(500))
    water_liters = Column(Float, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)


class WaterUsage(Base):
    __tablename__ = "water_usage"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    date = Column(String(20))  # YYYY-MM-DD
    liters = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
