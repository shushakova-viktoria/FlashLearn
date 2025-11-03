from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class DeckBase(BaseModel):
    title: str
    description: Optional[str] = None

class DeckCreate(DeckBase):
    pass

class DeckResponse(DeckBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
