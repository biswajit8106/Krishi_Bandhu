from sqlalchemy import Column, Integer, String, Float, DateTime, Text
from datetime import datetime
from app.database import Base


class CropPrediction(Base):
    __tablename__ = "crop_predictions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    crop_type = Column(String(100))
    predicted_class = Column(String(200))
    confidence = Column(Float)
    probabilities = Column(Text, nullable=True)  # JSON string of class->probability
    recommendation = Column(Text, nullable=True)
    prevention = Column(Text, nullable=True)
    details = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
