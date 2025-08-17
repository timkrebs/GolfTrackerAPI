from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class DifficultyLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    CHAMPIONSHIP = "championship"


class GolfCourseBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200, description="Name des Golfplatzes")
    description: Optional[str] = Field(None, max_length=1000, description="Beschreibung des Golfplatzes")
    address: str = Field(..., min_length=1, max_length=300, description="Adresse des Golfplatzes")
    city: str = Field(..., min_length=1, max_length=100, description="Stadt")
    country: str = Field(..., min_length=1, max_length=100, description="Land")
    postal_code: Optional[str] = Field(None, max_length=20, description="Postleitzahl")
    phone: Optional[str] = Field(None, max_length=20, description="Telefonnummer")
    email: Optional[str] = Field(None, max_length=100, description="E-Mail Adresse")
    website: Optional[str] = Field(None, max_length=200, description="Website URL")
    holes: int = Field(..., ge=9, le=27, description="Anzahl der Löcher (9, 18, oder 27)")
    par: int = Field(..., ge=27, le=108, description="Par des Platzes")
    yardage: Optional[int] = Field(None, ge=1000, le=8000, description="Gesamtlänge in Yards")
    difficulty: DifficultyLevel = Field(..., description="Schwierigkeitsgrad")
    green_fee: Optional[float] = Field(None, ge=0, description="Green Fee in Euro")
    latitude: Optional[float] = Field(None, ge=-90, le=90, description="Breitengrad")
    longitude: Optional[float] = Field(None, ge=-180, le=180, description="Längengrad")
    is_active: bool = Field(True, description="Ist der Platz aktiv/verfügbar")


class GolfCourseCreate(GolfCourseBase):
    pass


class GolfCourseUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    address: Optional[str] = Field(None, min_length=1, max_length=300)
    city: Optional[str] = Field(None, min_length=1, max_length=100)
    country: Optional[str] = Field(None, min_length=1, max_length=100)
    postal_code: Optional[str] = Field(None, max_length=20)
    phone: Optional[str] = Field(None, max_length=20)
    email: Optional[str] = Field(None, max_length=100)
    website: Optional[str] = Field(None, max_length=200)
    holes: Optional[int] = Field(None, ge=9, le=27)
    par: Optional[int] = Field(None, ge=27, le=108)
    yardage: Optional[int] = Field(None, ge=1000, le=8000)
    difficulty: Optional[DifficultyLevel] = None
    green_fee: Optional[float] = Field(None, ge=0)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    is_active: Optional[bool] = None


class GolfCourse(GolfCourseBase):
    id: int = Field(..., description="Eindeutige ID des Golfplatzes")
    created_at: datetime = Field(..., description="Erstellungszeitpunkt")
    updated_at: datetime = Field(..., description="Letzte Aktualisierung")

    class Config:
        from_attributes = True


class GolfCourseList(BaseModel):
    courses: List[GolfCourse]
    total: int
    page: int
    per_page: int
    pages: int


class HealthCheck(BaseModel):
    status: str
    timestamp: datetime
    version: str = "1.0.0"
