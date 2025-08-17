from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
from app.config import settings
from app.routes import golf_courses, health

# Logging konfigurieren
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application Lifespan Manager"""
    logger.info("Golf Tracker Analytics API startet...")
    try:
        # Hier könnten Startup-Tasks eingefügt werden
        yield
    finally:
        logger.info("Golf Tracker Analytics API wird heruntergefahren...")


# FastAPI App erstellen
app = FastAPI(
    title="Golf Tracker Analytics API",
    description="Eine CRUD API für Golfplätze mit Supabase Integration",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS Middleware hinzufügen
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In Produktion spezifische Origins angeben
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Router registrieren
app.include_router(health.router)
app.include_router(golf_courses.router, prefix="/api/v1")


@app.get("/", tags=["Root"])
async def root():
    """Root Endpoint"""
    return {
        "message": "Golf Tracker Analytics API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }


@app.exception_handler(404)
async def not_found_handler(request, exc):
    return HTTPException(status_code=404, detail="Endpoint nicht gefunden")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=settings.environment == "development"
    )
