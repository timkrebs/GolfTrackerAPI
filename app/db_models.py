from sqlalchemy import Column, String, Integer, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import uuid

Base = declarative_base()


class GolfCourseDB(Base):
    """SQLAlchemy model for golf courses"""
    __tablename__ = "golf_courses"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(200), nullable=False, index=True)
    location = Column(String(100), nullable=False)
    country = Column(String(50), nullable=False, index=True)
    total_holes = Column(Integer, nullable=False, default=18)
    description = Column(Text, nullable=True)
    
    # Relationship to holes
    holes = relationship("HoleDB", back_populates="golf_course", cascade="all, delete-orphan")


class HoleDB(Base):
    """SQLAlchemy model for individual holes"""
    __tablename__ = "holes"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    golf_course_id = Column(UUID(as_uuid=True), ForeignKey("golf_courses.id"), nullable=False)
    hole_number = Column(Integer, nullable=False)
    par = Column(Integer, nullable=False)
    distance_meters = Column(Integer, nullable=False)
    handicap = Column(Integer, nullable=False)
    
    # Relationship to golf course
    golf_course = relationship("GolfCourseDB", back_populates="holes")
    
    def __repr__(self):
        return f"<Hole(course_id={self.golf_course_id}, number={self.hole_number}, par={self.par})>"
