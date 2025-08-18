"""
User Profile SQLAlchemy model
"""
from sqlalchemy import Column, Integer, String, Text, Float, DateTime, Boolean, Date
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class UserProfile(Base):
    """User Profile model"""
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    first_name = Column(String(50))
    last_name = Column(String(50))
    
    # Golf-specific info
    handicap = Column(Float)
    preferred_tee = Column(String(20))  # Championship, Regular, Senior, etc.
    home_course_id = Column(Integer)  # Reference to golf course
    
    # Personal info
    date_of_birth = Column(Date)
    phone = Column(String(20))
    bio = Column(Text)
    profile_picture_url = Column(String(255))
    
    # Account settings
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    privacy_level = Column(String(20), default="public")  # public, friends, private
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True))
    
    # Relationships
    golf_rounds = relationship("GolfRound", back_populates="user")
    friendships_initiated = relationship("Friendship", foreign_keys="Friendship.user_id", back_populates="user")
    friendships_received = relationship("Friendship", foreign_keys="Friendship.friend_id", back_populates="friend")
    group_round_participations = relationship("GroupRoundParticipant", back_populates="user")
