from pydantic import BaseModel
from datetime import datetime

class UserBase(BaseModel):
    email: str
    username: str

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):  # 🔹 ДОБАВИТЬ
    username: str
    password: str

class Token(BaseModel):  # 🔹 ДОБАВИТЬ
    access_token: str
    token_type: str = "bearer"

class UserResponse(UserBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
