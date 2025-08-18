"""
User Profile Pydantic schemas
"""
from typing import Optional
from datetime import datetime, date
from pydantic import BaseModel, ConfigDict, Field, EmailStr


class UserProfileBase(BaseModel):
    """Base user profile schema"""
    username: str = Field(..., min_length=3, max_length=50, description="Username")
    email: EmailStr = Field(..., description="Email address")
    first_name: Optional[str] = Field(None, max_length=50, description="First name")
    last_name: Optional[str] = Field(None, max_length=50, description="Last name")
    
    # Golf-specific info
    handicap: Optional[float] = Field(None, ge=-10.0, le=54.0, description="Golf handicap")
    preferred_tee: Optional[str] = Field(None, max_length=20, description="Preferred tee box")
    home_course_id: Optional[int] = Field(None, description="Home golf course ID")
    
    # Personal info
    date_of_birth: Optional[date] = Field(None, description="Date of birth")
    phone: Optional[str] = Field(None, max_length=20, description="Phone number")
    bio: Optional[str] = Field(None, max_length=1000, description="User biography")
    profile_picture_url: Optional[str] = Field(None, max_length=255, description="Profile picture URL")
    
    # Account settings
    privacy_level: str = Field("public", description="Privacy level: public, friends, private")


class UserProfileCreate(UserProfileBase):
    """Schema for creating a user profile"""
    pass


class UserProfileUpdate(BaseModel):
    """Schema for updating a user profile"""
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = None
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    handicap: Optional[float] = Field(None, ge=-10.0, le=54.0)
    preferred_tee: Optional[str] = Field(None, max_length=20)
    home_course_id: Optional[int] = None
    date_of_birth: Optional[date] = None
    phone: Optional[str] = Field(None, max_length=20)
    bio: Optional[str] = Field(None, max_length=1000)
    profile_picture_url: Optional[str] = Field(None, max_length=255)
    privacy_level: Optional[str] = None


class UserProfile(UserProfileBase):
    """Schema for returning user profile data"""
    id: int
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    last_login: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)


class UserProfilePublic(BaseModel):
    """Public user profile schema (limited information)"""
    id: int
    username: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    handicap: Optional[float] = None
    profile_picture_url: Optional[str] = None
    
    model_config = ConfigDict(from_attributes=True)


class UserStats(BaseModel):
    """User statistics schema"""
    total_rounds: int
    average_score: Optional[float] = None
    best_score: Optional[int] = None
    worst_score: Optional[int] = None
    rounds_this_month: int
    rounds_this_year: int
    favorite_course: Optional[str] = None
    handicap_trend: Optional[str] = None  # improving, stable, declining
