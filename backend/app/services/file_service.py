import os
import uuid
from fastapi import UploadFile, HTTPException
from PIL import Image
import shutil

class FileService:
    def __init__(self):
        self.upload_dir = "uploads"
        self.images_dir = os.path.join(self.upload_dir, "images")
        self.audio_dir = os.path.join(self.upload_dir, "audio")
        self._create_directories()
    
    def _create_directories(self):
        """Создает необходимые директории для файлов"""
        os.makedirs(self.images_dir, exist_ok=True)
        os.makedirs(self.audio_dir, exist_ok=True)
    
    async def save_image(self, file: UploadFile) -> str:
        """Сохраняет изображение и возвращает путь к файлу"""
        # Проверяем что файл является изображением
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="Файл должен быть изображением")
        
        # Генерируем уникальное имя файла
        file_extension = file.filename.split('.')[-1]
        filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = os.path.join(self.images_dir, filename)
        
        # Сохраняем файл
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Создаем thumbnail (опционально)
        self._create_thumbnail(file_path)
        
        return f"/uploads/images/{filename}"
    
    async def save_audio(self, file: UploadFile) -> str:
        """Сохраняет аудио файл и возвращает путь"""
        if not file.content_type.startswith('audio/'):
            raise HTTPException(status_code=400, detail="Файл должен быть аудио")
        
        file_extension = file.filename.split('.')[-1]
        filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = os.path.join(self.audio_dir, filename)
        
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        return f"/uploads/audio/{filename}"
    
    def _create_thumbnail(self, image_path: str, size: tuple = (200, 200)):
        """Создает thumbnail для изображения"""
        try:
            with Image.open(image_path) as img:
                img.thumbnail(size)
                base, ext = os.path.splitext(image_path)
                thumbnail_path = f"{base}_thumb{ext}"
                img.save(thumbnail_path)
        except Exception as e:
            print(f"Ошибка создания thumbnail: {e}")
    
    def get_file_path(self, file_url: str) -> str:
        """Возвращает полный путь к файлу по URL"""
        if file_url.startswith('/uploads/'):
            return file_url[1:]  # Убираем первый слеш
        return file_url

file_service = FileService()
