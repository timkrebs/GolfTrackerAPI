from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from typing import List, Optional
from uuid import UUID
import logging

from app.config import get_database_url
from app.db_models import Base, GolfCourseDB, HoleDB
from app.models import GolfCourse, Hole

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database setup
DATABASE_URL = get_database_url()
logger.info(f"Connecting to database: {DATABASE_URL.split('@')[0]}@***")

engine = create_engine(
    DATABASE_URL,
    echo=False,  # Set to True for SQL query logging
    pool_pre_ping=True,  # Verify connections before use
    pool_recycle=300,    # Recycle connections every 5 minutes
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def create_tables():
    """Create database tables"""
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Error creating tables: {e}")
        raise


def get_db() -> Session:
    """Get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class DatabaseService:
    """Service class for database operations"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_all_courses(self) -> List[GolfCourse]:
        """Get all golf courses"""
        try:
            db_courses = self.db.query(GolfCourseDB).all()
            return [self._convert_to_pydantic(course) for course in db_courses]
        except Exception as e:
            logger.error(f"Error getting all courses: {e}")
            raise
    
    def get_course_by_id(self, course_id: UUID) -> Optional[GolfCourse]:
        """Get a golf course by ID"""
        try:
            db_course = self.db.query(GolfCourseDB).filter(GolfCourseDB.id == course_id).first()
            if db_course:
                return self._convert_to_pydantic(db_course)
            return None
        except Exception as e:
            logger.error(f"Error getting course by ID {course_id}: {e}")
            raise
    
    def create_course(self, course: GolfCourse) -> GolfCourse:
        """Create a new golf course"""
        try:
            # Create golf course
            db_course = GolfCourseDB(
                id=course.id,
                name=course.name,
                location=course.location,
                country=course.country,
                total_holes=course.total_holes
            )
            
            self.db.add(db_course)
            self.db.flush()  # Get the ID
            
            # Create holes
            for hole in course.holes:
                db_hole = HoleDB(
                    golf_course_id=db_course.id,
                    hole_number=hole.hole_number,
                    par=hole.par,
                    distance_meters=hole.distance_meters,
                    handicap=hole.handicap
                )
                self.db.add(db_hole)
            
            self.db.commit()
            self.db.refresh(db_course)
            
            return self._convert_to_pydantic(db_course)
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error creating course: {e}")
            raise
    
    def update_course(self, course_id: UUID, updated_course: GolfCourse) -> Optional[GolfCourse]:
        """Update an existing golf course"""
        try:
            db_course = self.db.query(GolfCourseDB).filter(GolfCourseDB.id == course_id).first()
            if not db_course:
                return None
            
            # Update course fields
            db_course.name = updated_course.name
            db_course.location = updated_course.location
            db_course.country = updated_course.country
            db_course.total_holes = updated_course.total_holes
            
            # Delete existing holes and create new ones
            self.db.query(HoleDB).filter(HoleDB.golf_course_id == course_id).delete()
            
            for hole in updated_course.holes:
                db_hole = HoleDB(
                    golf_course_id=course_id,
                    hole_number=hole.hole_number,
                    par=hole.par,
                    distance_meters=hole.distance_meters,
                    handicap=hole.handicap
                )
                self.db.add(db_hole)
            
            self.db.commit()
            self.db.refresh(db_course)
            
            return self._convert_to_pydantic(db_course)
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error updating course {course_id}: {e}")
            raise
    
    def delete_course(self, course_id: UUID) -> bool:
        """Delete a golf course"""
        try:
            db_course = self.db.query(GolfCourseDB).filter(GolfCourseDB.id == course_id).first()
            if not db_course:
                return False
            
            self.db.delete(db_course)
            self.db.commit()
            return True
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error deleting course {course_id}: {e}")
            raise
    
    def search_courses(self, query: str) -> List[GolfCourse]:
        """Search golf courses by name, location, or country"""
        try:
            search_pattern = f"%{query.lower()}%"
            db_courses = self.db.query(GolfCourseDB).filter(
                (GolfCourseDB.name.ilike(search_pattern)) |
                (GolfCourseDB.location.ilike(search_pattern)) |
                (GolfCourseDB.country.ilike(search_pattern))
            ).all()
            
            return [self._convert_to_pydantic(course) for course in db_courses]
        except Exception as e:
            logger.error(f"Error searching courses with query '{query}': {e}")
            raise
    
    def _convert_to_pydantic(self, db_course: GolfCourseDB) -> GolfCourse:
        """Convert SQLAlchemy model to Pydantic model"""
        holes = [
            Hole(
                hole_number=hole.hole_number,
                par=hole.par,
                distance_meters=hole.distance_meters,
                handicap=hole.handicap
            )
            for hole in sorted(db_course.holes, key=lambda h: h.hole_number)
        ]
        
        return GolfCourse(
            id=db_course.id,
            name=db_course.name,
            location=db_course.location,
            country=db_course.country,
            total_holes=db_course.total_holes,
            holes=holes
        )


def init_sample_data():
    """Initialize database with sample data"""
    try:
        db = SessionLocal()
        db_service = DatabaseService(db)
        
        # Check if data already exists
        existing_courses = db_service.get_all_courses()
        if existing_courses:
            logger.info("Sample data already exists, skipping initialization")
            return
        
        # Sample course 1
        sample_course_1 = GolfCourse(
            name="Golf-Club Bad Kissingen e.V. - Thuringia Course",
            location="Bad Kissingen, Bavaria",
            country="Germany",
            total_holes=18,
            holes=[
                Hole(hole_number=1, par=5, distance_meters=473, handicap=7),
                Hole(hole_number=2, par=3, distance_meters=217, handicap=9),
                Hole(hole_number=3, par=4, distance_meters=302, handicap=13),
                Hole(hole_number=4, par=3, distance_meters=168, handicap=11),
                Hole(hole_number=5, par=4, distance_meters=410, handicap=5),
                Hole(hole_number=6, par=4, distance_meters=359, handicap=3),
                Hole(hole_number=7, par=5, distance_meters=537, handicap=1),
                Hole(hole_number=8, par=3, distance_meters=168, handicap=17),
                Hole(hole_number=9, par=4, distance_meters=301, handicap=15),
                Hole(hole_number=10, par=4, distance_meters=296, handicap=14),
                Hole(hole_number=11, par=4, distance_meters=373, handicap=8),
                Hole(hole_number=12, par=4, distance_meters=350, handicap=4),
                Hole(hole_number=13, par=3, distance_meters=141, handicap=18),
                Hole(hole_number=14, par=4, distance_meters=270, handicap=16),
                Hole(hole_number=15, par=4, distance_meters=397, handicap=2),
                Hole(hole_number=16, par=3, distance_meters=154, handicap=10),
                Hole(hole_number=17, par=5, distance_meters=447, handicap=12),
                Hole(hole_number=18, par=4, distance_meters=336, handicap=6)
            ]
        )
        
        # Sample course 2
        sample_course_2 = GolfCourse(
            name="Augusta National Golf Club",
            location="Augusta, Georgia",
            country="United States",
            total_holes=18,
            holes=[
                Hole(hole_number=1, par=4, distance_meters=411, handicap=10),
                Hole(hole_number=2, par=5, distance_meters=520, handicap=16),
                Hole(hole_number=3, par=4, distance_meters=320, handicap=4),
                Hole(hole_number=4, par=3, distance_meters=205, handicap=14),
                Hole(hole_number=5, par=4, distance_meters=411, handicap=6),
                Hole(hole_number=6, par=3, distance_meters=164, handicap=12),
                Hole(hole_number=7, par=4, distance_meters=411, handicap=2),
                Hole(hole_number=8, par=5, distance_meters=520, handicap=18),
                Hole(hole_number=9, par=4, distance_meters=430, handicap=8),
                Hole(hole_number=10, par=4, distance_meters=466, handicap=9),
                Hole(hole_number=11, par=4, distance_meters=466, handicap=5),
                Hole(hole_number=12, par=3, distance_meters=141, handicap=15),
                Hole(hole_number=13, par=5, distance_meters=466, handicap=3),
                Hole(hole_number=14, par=4, distance_meters=411, handicap=7),
                Hole(hole_number=15, par=5, distance_meters=493, handicap=1),
                Hole(hole_number=16, par=3, distance_meters=155, handicap=11),
                Hole(hole_number=17, par=4, distance_meters=411, handicap=17),
                Hole(hole_number=18, par=4, distance_meters=411, handicap=13)
            ]
        )
        
        db_service.create_course(sample_course_1)
        db_service.create_course(sample_course_2)
        
        logger.info("Sample data initialized successfully")
        
    except Exception as e:
        logger.error(f"Error initializing sample data: {e}")
        raise
    finally:
        db.close()
