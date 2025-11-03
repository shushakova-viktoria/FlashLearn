from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Float
from sqlalchemy.sql import func
from datetime import datetime
from app.database import Base

class Card(Base):
    __tablename__ = "cards"
    
    id = Column(Integer, primary_key=True, index=True)
    question = Column(Text, nullable=False)
    answer = Column(Text, nullable=False)
    deck_id = Column(Integer, ForeignKey("decks.id"), nullable=False)
    
    # Медиа поля
    question_image = Column(String(500), nullable=True)  # URL к изображению вопроса
    answer_image = Column(String(500), nullable=True)    # URL к изображению ответа
    question_audio = Column(String(500), nullable=True)  # URL к аудио вопроса (TTS)
    answer_audio = Column(String(500), nullable=True)    # URL к аудио ответа (TTS)
    
    # SRS поля
    ease_factor = Column(Float, default=2.5)
    interval = Column(Integer, default=0)
    repetitions = Column(Integer, default=0)
    next_review = Column(DateTime, default=datetime.utcnow)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
