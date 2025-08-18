from pydantic import BaseModel, Field
from typing import List, Optional
from uuid import UUID, uuid4


class Hole(BaseModel):
    """Model representing a single hole on a golf course"""
    hole_number: int = Field(..., ge=1, le=18, description="Hole number (1-18)")
    par: int = Field(..., ge=3, le=5, description="Par for the hole (3-5)")
    distance_meters: int = Field(..., gt=0, description="Distance in meters")
    handicap: int = Field(..., ge=1, le=18, description="Handicap rating (1-18)")


class GolfCourseBase(BaseModel):
    """Base model for golf course data"""
    name: str = Field(..., min_length=1, max_length=200, description="Golf course name")
    location: str = Field(..., min_length=1, max_length=100, description="City and state/region")
    country: str = Field(..., min_length=1, max_length=50, description="Country name")
    total_holes: int = Field(18, ge=9, le=18, description="Total number of holes")
    holes: List[Hole] = Field(..., description="List of holes on the course")


class GolfCourseCreate(GolfCourseBase):
    """Model for creating a new golf course"""
    pass


class GolfCourseUpdate(BaseModel):
    """Model for updating an existing golf course"""
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    location: Optional[str] = Field(None, min_length=1, max_length=100)
    country: Optional[str] = Field(None, min_length=1, max_length=50)
    total_holes: Optional[int] = Field(None, ge=9, le=18)
    holes: Optional[List[Hole]] = None


class GolfCourse(GolfCourseBase):
    """Model representing a golf course with ID"""
    id: UUID = Field(default_factory=uuid4, description="Unique identifier")

    class Config:
        from_attributes = True


class GolfCourseResponse(BaseModel):
    """Response model for API responses"""
    success: bool
    message: str
    data: Optional[GolfCourse] = None


class GolfCoursesListResponse(BaseModel):
    """Response model for list endpoints"""
    success: bool
    message: str
    data: List[GolfCourse]
    total: int
