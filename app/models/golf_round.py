"""
Golf Round SQLAlchemy model
"""
from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class GolfRound(Base):
    """Golf Round model"""
    __tablename__ = "golf_rounds"

    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign Keys
    user_id = Column(Integer, ForeignKey("user_profiles.id"), nullable=False)
    golf_course_id = Column(Integer, ForeignKey("golf_courses.id"), nullable=False)
    
    # Round details
    date_played = Column(DateTime(timezone=True), nullable=False)
    tee_used = Column(String(20))  # Championship, Regular, Senior, etc.
    total_score = Column(Integer)
    total_par = Column(Integer, default=72)
    score_relative_to_par = Column(Integer)  # +/- par
    
    # Round statistics
    fairways_hit = Column(Integer)
    total_fairways = Column(Integer, default=14)  # Usually 14 fairways in 18 holes
    greens_in_regulation = Column(Integer)
    total_greens = Column(Integer, default=18)
    total_putts = Column(Integer)
    
    # Additional round info
    weather_conditions = Column(String(100))
    course_conditions = Column(String(100))
    playing_partners = Column(Text)  # Comma-separated list or JSON
    notes = Column(Text)
    
    # Round type
    round_type = Column(String(50), default="casual")  # casual, tournament, practice
    is_official = Column(Boolean, default=False)  # For handicap calculation
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("UserProfile", back_populates="golf_rounds")
    golf_course = relationship("GolfCourse", back_populates="golf_rounds")
    hole_scores = relationship("HoleScore", back_populates="golf_round")
