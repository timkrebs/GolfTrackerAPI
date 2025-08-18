"""
Group Round SQLAlchemy models
"""
from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class GroupRound(Base):
    """Group round model for organizing rounds with multiple players"""
    __tablename__ = "group_rounds"

    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign Keys
    organizer_id = Column(Integer, ForeignKey("user_profiles.id"), nullable=False)
    golf_course_id = Column(Integer, ForeignKey("golf_courses.id"), nullable=False)
    
    # Event details
    name = Column(String(100), nullable=False)
    description = Column(Text)
    scheduled_date = Column(DateTime(timezone=True), nullable=False)
    tee_time = Column(DateTime(timezone=True))
    
    # Round settings
    max_participants = Column(Integer, default=4)
    current_participants = Column(Integer, default=1)  # Organizer is automatically included
    
    # Pricing and rules
    cost_per_person = Column(Float)
    payment_required = Column(Boolean, default=False)
    handicap_requirement = Column(String(50))  # e.g., "Under 20", "Any", "15-25"
    
    # Status
    status = Column(String(20), default="open")  # open, full, cancelled, completed
    is_private = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    organizer = relationship("UserProfile")
    golf_course = relationship("GolfCourse")
    participants = relationship("GroupRoundParticipant", back_populates="group_round")


class GroupRoundParticipant(Base):
    """Participants in group rounds"""
    __tablename__ = "group_round_participants"

    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign Keys
    group_round_id = Column(Integer, ForeignKey("group_rounds.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("user_profiles.id"), nullable=False)
    
    # Participation details
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    status = Column(String(20), default="confirmed")  # confirmed, waitlist, cancelled
    payment_status = Column(String(20), default="pending")  # pending, paid, refunded
    
    # Performance tracking (filled after round completion)
    final_score = Column(Integer)
    relative_to_par = Column(Integer)
    
    # Relationships
    group_round = relationship("GroupRound", back_populates="participants")
    user = relationship("UserProfile", back_populates="group_round_participations")
