"""
Hole Score SQLAlchemy model
"""
from sqlalchemy import Column, Integer, ForeignKey, Boolean, String
from sqlalchemy.orm import relationship
from app.database import Base


class HoleScore(Base):
    """Individual hole score model"""
    __tablename__ = "hole_scores"

    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign Keys
    golf_round_id = Column(Integer, ForeignKey("golf_rounds.id"), nullable=False)
    
    # Hole details
    hole_number = Column(Integer, nullable=False)  # 1-18
    par = Column(Integer, nullable=False)  # 3, 4, or 5
    score = Column(Integer, nullable=False)
    
    # Shot details
    fairway_hit = Column(Boolean)  # Only applicable for par 4 and 5
    green_in_regulation = Column(Boolean)
    putts = Column(Integer)
    
    # Penalty strokes
    penalty_strokes = Column(Integer, default=0)
    
    # Shot tracking (optional detailed tracking)
    tee_shot_club = Column(String(20))
    approach_shots = Column(Integer, default=0)
    chip_shots = Column(Integer, default=0)
    sand_shots = Column(Integer, default=0)
    
    # Notes for the hole
    notes = Column(String(255))
    
    # Relationships
    golf_round = relationship("GolfRound", back_populates="hole_scores")
