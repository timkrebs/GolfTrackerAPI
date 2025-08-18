"""
Group Round Pydantic schemas
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class GroupRoundBase(BaseModel):
    """Base group round schema"""
    golf_course_id: int = Field(..., description="Golf course ID")
    name: str = Field(..., min_length=1, max_length=100, description="Group round name")
    description: Optional[str] = Field(None, description="Group round description")
    scheduled_date: datetime = Field(..., description="Scheduled date and time")
    tee_time: Optional[datetime] = Field(None, description="Specific tee time")
    
    # Round settings
    max_participants: int = Field(4, ge=2, le=8, description="Maximum number of participants")
    
    # Pricing and rules
    cost_per_person: Optional[float] = Field(None, ge=0, description="Cost per person")
    payment_required: bool = Field(False, description="Whether payment is required")
    handicap_requirement: Optional[str] = Field(None, max_length=50, description="Handicap requirement")
    
    # Privacy
    is_private: bool = Field(False, description="Whether round is private")


class GroupRoundCreate(GroupRoundBase):
    """Schema for creating a group round"""
    pass


class GroupRoundUpdate(BaseModel):
    """Schema for updating a group round"""
    golf_course_id: Optional[int] = None
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    scheduled_date: Optional[datetime] = None
    tee_time: Optional[datetime] = None
    max_participants: Optional[int] = Field(None, ge=2, le=8)
    cost_per_person: Optional[float] = Field(None, ge=0)
    payment_required: Optional[bool] = None
    handicap_requirement: Optional[str] = Field(None, max_length=50)
    status: Optional[str] = None
    is_private: Optional[bool] = None


class GroupRound(GroupRoundBase):
    """Schema for returning group round data"""
    id: int
    organizer_id: int
    current_participants: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)


class GroupRoundWithDetails(GroupRound):
    """Group round with additional details"""
    organizer_username: str
    golf_course_name: str
    spots_available: int
    
    model_config = ConfigDict(from_attributes=True)


class GroupRoundParticipantBase(BaseModel):
    """Base group round participant schema"""
    status: str = Field("confirmed", description="Participation status")
    payment_status: str = Field("pending", description="Payment status")


class GroupRoundParticipantCreate(GroupRoundParticipantBase):
    """Schema for joining a group round"""
    pass


class GroupRoundParticipantUpdate(BaseModel):
    """Schema for updating participant status"""
    status: Optional[str] = None
    payment_status: Optional[str] = None
    final_score: Optional[int] = Field(None, ge=18, le=300)
    relative_to_par: Optional[int] = None


class GroupRoundParticipant(GroupRoundParticipantBase):
    """Schema for returning participant data"""
    id: int
    group_round_id: int
    user_id: int
    joined_at: datetime
    final_score: Optional[int] = None
    relative_to_par: Optional[int] = None
    
    model_config = ConfigDict(from_attributes=True)


class GroupRoundParticipantWithUser(GroupRoundParticipant):
    """Participant with user information"""
    username: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    handicap: Optional[float] = None
    profile_picture_url: Optional[str] = None
    
    model_config = ConfigDict(from_attributes=True)


class GroupRoundList(BaseModel):
    """Schema for paginated group round list"""
    items: List[GroupRoundWithDetails]
    total: int
    page: int
    per_page: int
    total_pages: int
