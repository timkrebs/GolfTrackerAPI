from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import Optional
from uuid import UUID
import os

from app.models import (
    GolfCourse,
    GolfCourseCreate,
    GolfCourseUpdate,
    GolfCourseResponse,
    GolfCoursesListResponse
)
from app.config import get_settings
from app.database_new import get_db, DatabaseService, create_tables, init_sample_data
from app.database import db as memory_db  # Fallback for development

settings = get_settings()

app = FastAPI(
    title=settings.api_title,
    description=settings.api_description,
    version=settings.api_version,
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    try:
        # Create tables
        create_tables()
        
        # Initialize sample data only if not in production
        if settings.environment != "production":
            init_sample_data()
            
    except Exception as e:
        print(f"Error during startup: {e}")
        # Continue anyway - the app might still work

def get_database_service(db: Session = Depends(get_db)) -> DatabaseService:
    """Get database service instance"""
    return DatabaseService(db)

def get_fallback_service():
    """Get fallback in-memory database service"""
    return memory_db


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Golf Course API",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc"
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "message": "API is running"}


@app.get("/golf-courses", response_model=GolfCoursesListResponse, tags=["Golf Courses"])
async def get_all_golf_courses(
    search: Optional[str] = Query(None, description="Search by name, location, or country"),
    db_service: DatabaseService = Depends(get_database_service)
):
    """Get all golf courses with optional search"""
    try:
        if search:
            courses = db_service.search_courses(search)
        else:
            courses = db_service.get_all_courses()
        
        return GolfCoursesListResponse(
            success=True,
            message="Golf courses retrieved successfully",
            data=courses,
            total=len(courses)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.get("/golf-courses/{course_id}", response_model=GolfCourseResponse, tags=["Golf Courses"])
async def get_golf_course(
    course_id: UUID,
    db_service: DatabaseService = Depends(get_database_service)
):
    """Get a specific golf course by ID"""
    try:
        course = db_service.get_course_by_id(course_id)
        if not course:
            raise HTTPException(status_code=404, detail="Golf course not found")
        
        return GolfCourseResponse(
            success=True,
            message="Golf course retrieved successfully",
            data=course
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.post("/golf-courses", response_model=GolfCourseResponse, tags=["Golf Courses"])
async def create_golf_course(
    course_data: GolfCourseCreate,
    db_service: DatabaseService = Depends(get_database_service)
):
    """Create a new golf course"""
    try:
        # Validate that the number of holes matches total_holes
        if len(course_data.holes) != course_data.total_holes:
            raise HTTPException(
                status_code=400, 
                detail=f"Number of holes ({len(course_data.holes)}) doesn't match total_holes ({course_data.total_holes})"
            )
        
        # Validate hole numbers are sequential and unique
        hole_numbers = [hole.hole_number for hole in course_data.holes]
        expected_numbers = list(range(1, course_data.total_holes + 1))
        if sorted(hole_numbers) != expected_numbers:
            raise HTTPException(
                status_code=400,
                detail="Hole numbers must be sequential from 1 to total_holes"
            )
        
        # Create golf course with auto-generated ID
        new_course = GolfCourse(**course_data.model_dump())
        created_course = db_service.create_course(new_course)
        
        return GolfCourseResponse(
            success=True,
            message="Golf course created successfully",
            data=created_course
        )
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.put("/golf-courses/{course_id}", response_model=GolfCourseResponse, tags=["Golf Courses"])
async def update_golf_course(
    course_id: UUID,
    course_data: GolfCourseUpdate,
    db_service: DatabaseService = Depends(get_database_service)
):
    """Update an existing golf course"""
    try:
        # Check if course exists
        existing_course = db_service.get_course_by_id(course_id)
        if not existing_course:
            raise HTTPException(status_code=404, detail="Golf course not found")
        
        # Create updated course data
        update_data = course_data.model_dump(exclude_unset=True)
        updated_course_data = existing_course.model_dump()
        updated_course_data.update(update_data)
        
        # Validate holes if provided
        if course_data.holes is not None and course_data.total_holes is not None:
            if len(course_data.holes) != course_data.total_holes:
                raise HTTPException(
                    status_code=400,
                    detail=f"Number of holes ({len(course_data.holes)}) doesn't match total_holes ({course_data.total_holes})"
                )
            
            hole_numbers = [hole.hole_number for hole in course_data.holes]
            expected_numbers = list(range(1, course_data.total_holes + 1))
            if sorted(hole_numbers) != expected_numbers:
                raise HTTPException(
                    status_code=400,
                    detail="Hole numbers must be sequential from 1 to total_holes"
                )
        
        updated_course = GolfCourse(**updated_course_data)
        result = db_service.update_course(course_id, updated_course)
        
        return GolfCourseResponse(
            success=True,
            message="Golf course updated successfully",
            data=result
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.delete("/golf-courses/{course_id}", tags=["Golf Courses"])
async def delete_golf_course(
    course_id: UUID,
    db_service: DatabaseService = Depends(get_database_service)
):
    """Delete a golf course"""
    try:
        success = db_service.delete_course(course_id)
        if not success:
            raise HTTPException(status_code=404, detail="Golf course not found")
        
        return {
            "success": True,
            "message": "Golf course deleted successfully"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.get("/golf-courses/{course_id}/holes", tags=["Holes"])
async def get_course_holes(
    course_id: UUID,
    db_service: DatabaseService = Depends(get_database_service)
):
    """Get all holes for a specific golf course"""
    try:
        course = db_service.get_course_by_id(course_id)
        if not course:
            raise HTTPException(status_code=404, detail="Golf course not found")
        
        return {
            "success": True,
            "message": "Course holes retrieved successfully",
            "data": course.holes,
            "total": len(course.holes)
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.get("/golf-courses/{course_id}/holes/{hole_number}", tags=["Holes"])
async def get_specific_hole(
    course_id: UUID,
    hole_number: int,
    db_service: DatabaseService = Depends(get_database_service)
):
    """Get a specific hole from a golf course"""
    try:
        course = db_service.get_course_by_id(course_id)
        if not course:
            raise HTTPException(status_code=404, detail="Golf course not found")
        
        hole = next((h for h in course.holes if h.hole_number == hole_number), None)
        if not hole:
            raise HTTPException(status_code=404, detail=f"Hole {hole_number} not found")
        
        return {
            "success": True,
            "message": f"Hole {hole_number} retrieved successfully",
            "data": hole
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")