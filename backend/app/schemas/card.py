from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class CardBase(BaseModel):
    question: str
    answer: str

class CardCreate(CardBase):
    deck_id: int

class CardResponse(CardBase):
    id: int
    deck_id: int
    ease_factor: float
    interval: int
    repetitions: int
    next_review: datetime
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class CardUpdate(BaseModel):
    question: Optional[str] = None
    answer: Optional[str] = None


class ReviewRequest(BaseModel):
    quality: int  # 0-5

class ReviewResponse(BaseModel):
    card_id: int
    new_interval: int
    new_repetitions: int
    new_ease_factor: float
    next_review: datetime

class ReviewCard(BaseModel):
    id: int
    question: str
    answer: str
    deck_id: int
    
    class Config:
        from_attributes = True
