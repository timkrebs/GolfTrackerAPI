"""
Golf Round Pydantic schemas
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class GolfRoundBase(BaseModel):
    """Base golf round schema"""
    golf_course_id: int = Field(..., description="Golf course ID")
    date_played: datetime = Field(..., description="Date and time when round was played")
    tee_used: Optional[str] = Field(None, max_length=20, description="Tee box used")
    total_score: Optional[int] = Field(None, ge=18, le=300, description="Total score")
    total_par: int = Field(72, ge=54, le=108, description="Total par for the round")
    
    # Round statistics
    fairways_hit: Optional[int] = Field(None, ge=0, le=18, description="Fairways hit")
    total_fairways: int = Field(14, ge=0, le=18, description="Total fairways available")
    greens_in_regulation: Optional[int] = Field(None, ge=0, le=18, description="Greens in regulation")
    total_greens: int = Field(18, ge=9, le=27, description="Total greens")
    total_putts: Optional[int] = Field(None, ge=18, le=72, description="Total putts")
    
    # Additional round info
    weather_conditions: Optional[str] = Field(None, max_length=100, description="Weather conditions")
    course_conditions: Optional[str] = Field(None, max_length=100, description="Course conditions")
    playing_partners: Optional[str] = Field(None, description="Playing partners")
    notes: Optional[str] = Field(None, description="Round notes")
    
    # Round type
    round_type: str = Field("casual", description="Type of round: casual, tournament, practice")
    is_official: bool = Field(False, description="Whether round counts for handicap")


class GolfRoundCreate(GolfRoundBase):
    """Schema for creating a golf round"""
    pass


class GolfRoundUpdate(BaseModel):
    """Schema for updating a golf round"""
    golf_course_id: Optional[int] = None
    date_played: Optional[datetime] = None
    tee_used: Optional[str] = Field(None, max_length=20)
    total_score: Optional[int] = Field(None, ge=18, le=300)
    total_par: Optional[int] = Field(None, ge=54, le=108)
    fairways_hit: Optional[int] = Field(None, ge=0, le=18)
    total_fairways: Optional[int] = Field(None, ge=0, le=18)
    greens_in_regulation: Optional[int] = Field(None, ge=0, le=18)
    total_greens: Optional[int] = Field(None, ge=9, le=27)
    total_putts: Optional[int] = Field(None, ge=18, le=72)
    weather_conditions: Optional[str] = Field(None, max_length=100)
    course_conditions: Optional[str] = Field(None, max_length=100)
    playing_partners: Optional[str] = None
    notes: Optional[str] = None
    round_type: Optional[str] = None
    is_official: Optional[bool] = None


class GolfRound(GolfRoundBase):
    """Schema for returning golf round data"""
    id: int
    user_id: int
    score_relative_to_par: Optional[int] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)


class GolfRoundWithCourse(GolfRound):
    """Golf round with course information"""
    golf_course_name: str
    
    model_config = ConfigDict(from_attributes=True)


class GolfRoundList(BaseModel):
    """Schema for paginated golf round list"""
    items: List[GolfRoundWithCourse]
    total: int
    page: int
    per_page: int
    total_pages: int
