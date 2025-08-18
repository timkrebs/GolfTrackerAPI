"""
Golf Course SQLAlchemy model
"""
from sqlalchemy import Column, Integer, String, Text, Float, DateTime, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class GolfCourse(Base):
    """Golf Course model"""
    __tablename__ = "golf_courses"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    address = Column(Text)
    city = Column(String(100))
    country = Column(String(100))
    phone = Column(String(50))
    email = Column(String(100))
    website = Column(String(255))
    
    # Course details
    num_holes = Column(Integer, default=18)
    par = Column(Integer)
    course_rating = Column(Float)
    slope_rating = Column(Integer)
    
    # Pricing
    green_fee_weekday = Column(Float)
    green_fee_weekend = Column(Float)
    cart_fee = Column(Float)
    
    # Additional info
    description = Column(Text)
    facilities = Column(Text)  # JSON string for facilities list
    dress_code = Column(Text)
    booking_required = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    golf_rounds = relationship("GolfRound", back_populates="golf_course")
