import os
import uuid
import asyncio
from fastapi import HTTPException
from app.services.file_service import file_service

class FallbackTTSService:
    """Альтернативный TTS сервис для разработки без Google Cloud"""
    
    async def generate_speech(self, text: str, language_code: str = "ru-RU") -> str:
        """Генерирует заглушку для аудио файла (для разработки)"""
        
        if len(text) > 5000:
            raise HTTPException(status_code=400, detail="Текст слишком длинный")
        
        try:
            # Создаем заглушку - в реальном приложении здесь будет TTS
            # Для демонстрации создаем пустой аудио файл или используем предзаписанные фразы
            
            filename = f"{uuid.uuid4()}.mp3"
            file_path = os.path.join(file_service.audio_dir, filename)
            
            # Создаем простой текстовый файл с информацией о TTS
            # В реальном приложении здесь будет генерация аудио
            with open(file_path, "w") as f:
                f.write(f"TTS Audio Stub for: {text}")
            
            # Переименовываем в .txt для ясности, что это заглушка
            txt_file_path = file_path.replace('.mp3', '.txt')
            os.rename(file_path, txt_file_path)
            
            return f"/api/v1/media/files/uploads/audio/{filename.replace('.mp3', '.txt')}"
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Ошибка генерации TTS: {str(e)}")
    
    def is_available(self) -> bool:
        """Всегда доступен для разработки"""
        return True

fallback_tts_service = FallbackTTSService()
