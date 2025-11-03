import os
from typing import List
from dotenv import load_dotenv

load_dotenv()


class Settings:
    """Настройки приложения для Flutter фронтенда"""

    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./flashlearn.db")

    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "fallback-secret-key-for-development")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))  # 24 часа

    # CORS - полный доступ для Flutter и мобильных приложений
    ALLOWED_ORIGINS: List[str] = ["*"]  # Разрешить все origins для Flutter

    # Server
    HOST: str = os.getenv("HOST", "0.0.0.0")  # Доступ с любого интерфейса
    PORT: int = int(os.getenv("PORT", "8000"))

    # Media settings
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "uploads")
    MAX_FILE_SIZE: int = int(os.getenv("MAX_FILE_SIZE", "10485760"))  # 10MB
    ALLOWED_EXTENSIONS: List[str] = ["jpg", "jpeg", "png", "gif", "mp3", "wav", "ogg"]

    # API settings
    API_V1_PREFIX: str = "/api/v1"

    # Development flags
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"

    @property
    def database_url(self) -> str:
        """Get database URL with async support for SQLite"""
        if self.DATABASE_URL.startswith("sqlite"):
            return self.DATABASE_URL.replace("sqlite:///", "sqlite+aiosqlite:///")
        return self.DATABASE_URL

    @property
    def media_url(self) -> str:
        """Get base URL for media files"""
        return "/uploads"


settings = Settings()

# Создаем директорию для загрузок, если её нет
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
