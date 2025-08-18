"""
Friendship Pydantic schemas
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class FriendshipBase(BaseModel):
    """Base friendship schema"""
    friend_id: int = Field(..., description="ID of the user to befriend")


class FriendshipCreate(FriendshipBase):
    """Schema for creating a friendship"""
    pass


class FriendshipUpdate(BaseModel):
    """Schema for updating friendship status"""
    status: str = Field(..., description="Friendship status: pending, accepted, declined, blocked")


class Friendship(BaseModel):
    """Schema for returning friendship data"""
    id: int
    user_id: int
    friend_id: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    accepted_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)


class FriendshipWithUser(Friendship):
    """Friendship with user information"""
    friend_username: str
    friend_first_name: Optional[str] = None
    friend_last_name: Optional[str] = None
    friend_profile_picture_url: Optional[str] = None
    
    model_config = ConfigDict(from_attributes=True)


class FriendshipList(BaseModel):
    """Schema for paginated friendship list"""
    items: List[FriendshipWithUser]
    total: int
    page: int
    per_page: int
    total_pages: int


class FriendRequest(BaseModel):
    """Schema for friend request"""
    id: int
    requester_id: int
    requester_username: str
    requester_first_name: Optional[str] = None
    requester_last_name: Optional[str] = None
    requester_profile_picture_url: Optional[str] = None
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
