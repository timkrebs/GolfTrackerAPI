"""
Hole Score Pydantic schemas
"""
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field


class HoleScoreBase(BaseModel):
    """Base hole score schema"""
    hole_number: int = Field(..., ge=1, le=27, description="Hole number")
    par: int = Field(..., ge=3, le=5, description="Par for the hole")
    score: int = Field(..., ge=1, le=15, description="Score for the hole")
    
    # Shot details
    fairway_hit: Optional[bool] = Field(None, description="Whether fairway was hit (par 4/5 only)")
    green_in_regulation: Optional[bool] = Field(None, description="Whether green was hit in regulation")
    putts: Optional[int] = Field(None, ge=0, le=10, description="Number of putts")
    
    # Penalty strokes
    penalty_strokes: int = Field(0, ge=0, le=5, description="Number of penalty strokes")
    
    # Shot tracking
    tee_shot_club: Optional[str] = Field(None, max_length=20, description="Club used for tee shot")
    approach_shots: int = Field(0, ge=0, le=5, description="Number of approach shots")
    chip_shots: int = Field(0, ge=0, le=5, description="Number of chip shots")
    sand_shots: int = Field(0, ge=0, le=3, description="Number of sand shots")
    
    # Notes
    notes: Optional[str] = Field(None, max_length=255, description="Notes for the hole")


class HoleScoreCreate(HoleScoreBase):
    """Schema for creating a hole score"""
    golf_round_id: int = Field(..., description="Golf round ID")


class HoleScoreUpdate(BaseModel):
    """Schema for updating a hole score"""
    hole_number: Optional[int] = Field(None, ge=1, le=27)
    par: Optional[int] = Field(None, ge=3, le=5)
    score: Optional[int] = Field(None, ge=1, le=15)
    fairway_hit: Optional[bool] = None
    green_in_regulation: Optional[bool] = None
    putts: Optional[int] = Field(None, ge=0, le=10)
    penalty_strokes: Optional[int] = Field(None, ge=0, le=5)
    tee_shot_club: Optional[str] = Field(None, max_length=20)
    approach_shots: Optional[int] = Field(None, ge=0, le=5)
    chip_shots: Optional[int] = Field(None, ge=0, le=5)
    sand_shots: Optional[int] = Field(None, ge=0, le=3)
    notes: Optional[str] = Field(None, max_length=255)


class HoleScore(HoleScoreBase):
    """Schema for returning hole score data"""
    id: int
    golf_round_id: int
    
    model_config = ConfigDict(from_attributes=True)


class HoleScoreList(BaseModel):
    """Schema for list of hole scores"""
    items: List[HoleScore]
    total: int


class RoundScorecard(BaseModel):
    """Complete scorecard for a round"""
    golf_round_id: int
    hole_scores: List[HoleScore]
    front_nine_total: int
    back_nine_total: int
    total_score: int
    total_par: int
    score_to_par: int
