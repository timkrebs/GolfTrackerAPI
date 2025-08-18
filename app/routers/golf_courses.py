"""
Golf Courses CRUD router
"""
from typing import List
from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from app.dependencies import DatabaseDep
from app.models.golf_course import GolfCourse
from app.schemas.golf_course import (
    GolfCourse as GolfCourseSchema,
    GolfCourseCreate,
    GolfCourseUpdate,
    GolfCourseList
)

router = APIRouter()


@router.get("/", response_model=GolfCourseList)
async def get_golf_courses(
    db: DatabaseDep,
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(10, ge=1, le=100, description="Number of records to return"),
    search: str = Query(None, description="Search by course name or city"),
    country: str = Query(None, description="Filter by country"),
    min_holes: int = Query(None, ge=9, le=27, description="Minimum number of holes"),
    max_holes: int = Query(None, ge=9, le=27, description="Maximum number of holes")
):
    """Get all golf courses with optional filtering and pagination"""
    
    # Build query with filters
    query = select(GolfCourse)
    
    if search:
        search_filter = f"%{search}%"
        query = query.where(
            (GolfCourse.name.ilike(search_filter)) |
            (GolfCourse.city.ilike(search_filter))
        )
    
    if country:
        query = query.where(GolfCourse.country.ilike(f"%{country}%"))
    
    if min_holes:
        query = query.where(GolfCourse.num_holes >= min_holes)
    
    if max_holes:
        query = query.where(GolfCourse.num_holes <= max_holes)
    
    # Get total count
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Apply pagination and ordering
    query = query.order_by(GolfCourse.name).offset(skip).limit(limit)
    
    result = await db.execute(query)
    courses = result.scalars().all()
    
    total_pages = (total + limit - 1) // limit
    
    return GolfCourseList(
        items=courses,
        total=total,
        page=(skip // limit) + 1,
        per_page=limit,
        total_pages=total_pages
    )


@router.get("/{course_id}", response_model=GolfCourseSchema)
async def get_golf_course(course_id: int, db: DatabaseDep):
    """Get a specific golf course by ID"""
    
    query = select(GolfCourse).where(GolfCourse.id == course_id)
    result = await db.execute(query)
    course = result.scalar_one_or_none()
    
    if not course:
        raise HTTPException(status_code=404, detail="Golf course not found")
    
    return course


@router.post("/", response_model=GolfCourseSchema, status_code=201)
async def create_golf_course(course_data: GolfCourseCreate, db: DatabaseDep):
    """Create a new golf course"""
    
    # Check if course with same name and city already exists
    existing_query = select(GolfCourse).where(
        and_(
            GolfCourse.name == course_data.name,
            GolfCourse.city == course_data.city
        )
    )
    existing_result = await db.execute(existing_query)
    existing_course = existing_result.scalar_one_or_none()
    
    if existing_course:
        raise HTTPException(
            status_code=400,
            detail="Golf course with this name and city already exists"
        )
    
    # Create new course
    course = GolfCourse(**course_data.model_dump())
    db.add(course)
    await db.commit()
    await db.refresh(course)
    
    return course


@router.put("/{course_id}", response_model=GolfCourseSchema)
async def update_golf_course(
    course_id: int,
    course_data: GolfCourseUpdate,
    db: DatabaseDep
):
    """Update a golf course"""
    
    # Get existing course
    query = select(GolfCourse).where(GolfCourse.id == course_id)
    result = await db.execute(query)
    course = result.scalar_one_or_none()
    
    if not course:
        raise HTTPException(status_code=404, detail="Golf course not found")
    
    # Update only provided fields
    update_data = course_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(course, field, value)
    
    await db.commit()
    await db.refresh(course)
    
    return course


@router.delete("/{course_id}", status_code=204)
async def delete_golf_course(course_id: int, db: DatabaseDep):
    """Delete a golf course"""
    
    query = select(GolfCourse).where(GolfCourse.id == course_id)
    result = await db.execute(query)
    course = result.scalar_one_or_none()
    
    if not course:
        raise HTTPException(status_code=404, detail="Golf course not found")
    
    # Check if course has associated rounds
    from app.models.golf_round import GolfRound
    rounds_query = select(func.count()).where(GolfRound.golf_course_id == course_id)
    rounds_result = await db.execute(rounds_query)
    rounds_count = rounds_result.scalar()
    
    if rounds_count > 0:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot delete golf course. It has {rounds_count} associated rounds."
        )
    
    await db.delete(course)
    await db.commit()


@router.get("/{course_id}/stats")
async def get_course_stats(course_id: int, db: DatabaseDep):
    """Get statistics for a specific golf course"""
    
    # Verify course exists
    course_query = select(GolfCourse).where(GolfCourse.id == course_id)
    course_result = await db.execute(course_query)
    course = course_result.scalar_one_or_none()
    
    if not course:
        raise HTTPException(status_code=404, detail="Golf course not found")
    
    # Get round statistics
    from app.models.golf_round import GolfRound
    
    stats_query = select(
        func.count(GolfRound.id).label("total_rounds"),
        func.avg(GolfRound.total_score).label("average_score"),
        func.min(GolfRound.total_score).label("best_score"),
        func.max(GolfRound.total_score).label("worst_score")
    ).where(GolfRound.golf_course_id == course_id)
    
    stats_result = await db.execute(stats_query)
    stats = stats_result.first()
    
    return {
        "course_id": course_id,
        "course_name": course.name,
        "total_rounds": stats.total_rounds or 0,
        "average_score": round(stats.average_score, 2) if stats.average_score else None,
        "best_score": stats.best_score,
        "worst_score": stats.worst_score,
        "par": course.par
    }
