from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from supabase import Client
from app.database import get_supabase
from app.crud import GolfCourseCRUD
from app.models import (
    GolfCourse, 
    GolfCourseCreate, 
    GolfCourseUpdate, 
    GolfCourseList,
    DifficultyLevel
)
import math

router = APIRouter(prefix="/golf-courses", tags=["Golf Courses"])


def get_golf_course_crud(supabase: Client = Depends(get_supabase)) -> GolfCourseCRUD:
    return GolfCourseCRUD(supabase)


@router.post("/", response_model=GolfCourse, status_code=201)
async def create_golf_course(
    golf_course: GolfCourseCreate,
    crud: GolfCourseCRUD = Depends(get_golf_course_crud)
):
    """Neuen Golfplatz erstellen"""
    try:
        return await crud.create_golf_course(golf_course)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{course_id}", response_model=GolfCourse)
async def get_golf_course(
    course_id: int,
    crud: GolfCourseCRUD = Depends(get_golf_course_crud)
):
    """Golfplatz anhand der ID abrufen"""
    course = await crud.get_golf_course(course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Golfplatz nicht gefunden")
    return course


@router.get("/", response_model=GolfCourseList)
async def get_golf_courses(
    page: int = Query(1, ge=1, description="Seitennummer"),
    per_page: int = Query(10, ge=1, le=100, description="Anzahl pro Seite"),
    city: Optional[str] = Query(None, description="Filter nach Stadt"),
    country: Optional[str] = Query(None, description="Filter nach Land"),
    difficulty: Optional[DifficultyLevel] = Query(None, description="Filter nach Schwierigkeit"),
    is_active: Optional[bool] = Query(None, description="Filter nach aktiven Plätzen"),
    crud: GolfCourseCRUD = Depends(get_golf_course_crud)
):
    """Alle Golfplätze mit Paginierung und Filtern abrufen"""
    skip = (page - 1) * per_page
    
    try:
        courses, total = await crud.get_golf_courses(
            skip=skip, 
            limit=per_page,
            city=city,
            country=country,
            difficulty=difficulty.value if difficulty else None,
            is_active=is_active
        )
        
        pages = math.ceil(total / per_page) if total > 0 else 1
        
        return GolfCourseList(
            courses=courses,
            total=total,
            page=page,
            per_page=per_page,
            pages=pages
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{course_id}", response_model=GolfCourse)
async def update_golf_course(
    course_id: int,
    golf_course_update: GolfCourseUpdate,
    crud: GolfCourseCRUD = Depends(get_golf_course_crud)
):
    """Golfplatz aktualisieren"""
    try:
        course = await crud.update_golf_course(course_id, golf_course_update)
        if not course:
            raise HTTPException(status_code=404, detail="Golfplatz nicht gefunden")
        return course
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{course_id}", status_code=204)
async def delete_golf_course(
    course_id: int,
    crud: GolfCourseCRUD = Depends(get_golf_course_crud)
):
    """Golfplatz löschen"""
    try:
        success = await crud.delete_golf_course(course_id)
        if not success:
            raise HTTPException(status_code=404, detail="Golfplatz nicht gefunden")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/search/", response_model=List[GolfCourse])
async def search_golf_courses(
    q: str = Query(..., min_length=1, description="Suchbegriff"),
    limit: int = Query(50, ge=1, le=100, description="Maximale Anzahl Ergebnisse"),
    crud: GolfCourseCRUD = Depends(get_golf_course_crud)
):
    """Golfplätze durchsuchen"""
    try:
        return await crud.search_golf_courses(q, limit)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
