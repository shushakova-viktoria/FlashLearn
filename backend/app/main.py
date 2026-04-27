from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.database import engine, Base
from app import models
from app.api.endpoints import users, decks, cards, auth 

app = FastAPI(
    title="FlashLearn API",
    description="Backend для системы интервального повторения с Flutter фронтендом",
    version="0.2.0"
)

# CORS для Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

settings.API_V1_PREFIX = "/api/v1"
Base.metadata.create_all(bind=engine)

app.include_router(auth.router, prefix="/api/v1", tags=["Auth"])  # 🔹 Добавить
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(decks.router, prefix=settings.API_V1_PREFIX, tags=["decks"])
app.include_router(cards.router, prefix=settings.API_V1_PREFIX, tags=["cards"])


@app.get("/")
async def root(request: Request):
    base_url = str(request.base_url)
    return {
        "message": "🚀 FlashLearn API с Flutter фронтендом работает!",
        "docs_url": f"{base_url}docs",
        "redoc_url": f"{base_url}redoc",
        "health_check": f"{base_url}health"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "debug": settings.DEBUG}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )

print("✅ Все роутеры подключены! Сервер запущен.")