from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime

class AssistantQuery(Base):
    __tablename__ = "assistant_queries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    query_type = Column(String(20), nullable=False)  # 'text' or 'voice'
    user_input = Column(Text, nullable=False)
    assistant_response = Column(Text, nullable=False)
    language = Column(String(10), default="en")
    audio_url = Column(String(255), nullable=True)  # For voice responses
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship with User
    user = relationship("User", back_populates="assistant_queries")

    def __repr__(self):
        return f"<AssistantQuery(id={self.id}, user_id={self.user_id}, query_type={self.query_type})>"
