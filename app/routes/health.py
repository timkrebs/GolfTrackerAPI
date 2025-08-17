from fastapi import APIRouter, Depends
from datetime import datetime
from supabase import Client
from app.database import get_supabase
from app.models import HealthCheck

router = APIRouter(prefix="/health", tags=["Health"])


@router.get("/", response_model=HealthCheck)
async def health_check(supabase: Client = Depends(get_supabase)):
    """Health Check Endpoint"""
    try:
        # Einfache Datenbankverbindung testen
        result = supabase.table("golf_courses").select("id").limit(1).execute()
        
        return HealthCheck(
            status="healthy",
            timestamp=datetime.utcnow()
        )
    except Exception as e:
        return HealthCheck(
            status=f"unhealthy: {str(e)}",
            timestamp=datetime.utcnow()
        )
