"""
Golf Course Pydantic schemas
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class GolfCourseBase(BaseModel):
    """Base golf course schema"""
    name: str = Field(..., min_length=1, max_length=255, description="Golf course name")
    address: Optional[str] = Field(None, description="Course address")
    city: Optional[str] = Field(None, max_length=100, description="City")
    country: Optional[str] = Field(None, max_length=100, description="Country")
    phone: Optional[str] = Field(None, max_length=50, description="Phone number")
    email: Optional[str] = Field(None, max_length=100, description="Email address")
    website: Optional[str] = Field(None, max_length=255, description="Website URL")
    
    # Course details
    num_holes: int = Field(18, ge=9, le=27, description="Number of holes")
    par: Optional[int] = Field(None, ge=54, le=108, description="Course par")
    course_rating: Optional[float] = Field(None, ge=50.0, le=85.0, description="Course rating")
    slope_rating: Optional[int] = Field(None, ge=55, le=155, description="Slope rating")
    
    # Pricing
    green_fee_weekday: Optional[float] = Field(None, ge=0, description="Weekday green fee")
    green_fee_weekend: Optional[float] = Field(None, ge=0, description="Weekend green fee")
    cart_fee: Optional[float] = Field(None, ge=0, description="Cart rental fee")
    
    # Additional info
    description: Optional[str] = Field(None, description="Course description")
    facilities: Optional[str] = Field(None, description="Available facilities (JSON string)")
    dress_code: Optional[str] = Field(None, description="Dress code requirements")
    booking_required: bool = Field(True, description="Whether booking is required")


class GolfCourseCreate(GolfCourseBase):
    """Schema for creating a golf course"""
    pass


class GolfCourseUpdate(BaseModel):
    """Schema for updating a golf course"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    address: Optional[str] = None
    city: Optional[str] = Field(None, max_length=100)
    country: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=50)
    email: Optional[str] = Field(None, max_length=100)
    website: Optional[str] = Field(None, max_length=255)
    num_holes: Optional[int] = Field(None, ge=9, le=27)
    par: Optional[int] = Field(None, ge=54, le=108)
    course_rating: Optional[float] = Field(None, ge=50.0, le=85.0)
    slope_rating: Optional[int] = Field(None, ge=55, le=155)
    green_fee_weekday: Optional[float] = Field(None, ge=0)
    green_fee_weekend: Optional[float] = Field(None, ge=0)
    cart_fee: Optional[float] = Field(None, ge=0)
    description: Optional[str] = None
    facilities: Optional[str] = None
    dress_code: Optional[str] = None
    booking_required: Optional[bool] = None


class GolfCourse(GolfCourseBase):
    """Schema for returning golf course data"""
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)


class GolfCourseList(BaseModel):
    """Schema for paginated golf course list"""
    items: List[GolfCourse]
    total: int
    page: int
    per_page: int
    total_pages: int
