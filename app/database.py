from typing import Dict, List, Optional
from uuid import UUID, uuid4
from app.models import GolfCourse, Hole


class InMemoryDatabase:
    """Simple in-memory database for golf courses"""
    
    def __init__(self):
        self.golf_courses: Dict[UUID, GolfCourse] = {}
        self._initialize_sample_data()
    
    def _initialize_sample_data(self):
        """Initialize the database with sample golf course data"""
        sample_course = GolfCourse(
            id=uuid4(),
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
        
        sample_course_2 = GolfCourse(
            id=uuid4(),
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
        
        self.golf_courses[sample_course.id] = sample_course
        self.golf_courses[sample_course_2.id] = sample_course_2
    
    def get_all_courses(self) -> List[GolfCourse]:
        """Get all golf courses"""
        return list(self.golf_courses.values())
    
    def get_course_by_id(self, course_id: UUID) -> Optional[GolfCourse]:
        """Get a golf course by ID"""
        return self.golf_courses.get(course_id)
    
    def create_course(self, course: GolfCourse) -> GolfCourse:
        """Create a new golf course"""
        if course.id in self.golf_courses:
            raise ValueError(f"Course with ID {course.id} already exists")
        self.golf_courses[course.id] = course
        return course
    
    def update_course(self, course_id: UUID, updated_course: GolfCourse) -> Optional[GolfCourse]:
        """Update an existing golf course"""
        if course_id not in self.golf_courses:
            return None
        updated_course.id = course_id  # Ensure ID consistency
        self.golf_courses[course_id] = updated_course
        return updated_course
    
    def delete_course(self, course_id: UUID) -> bool:
        """Delete a golf course by ID"""
        if course_id in self.golf_courses:
            del self.golf_courses[course_id]
            return True
        return False
    
    def search_courses(self, query: str) -> List[GolfCourse]:
        """Search golf courses by name, location, or country"""
        query_lower = query.lower()
        results = []
        for course in self.golf_courses.values():
            if (query_lower in course.name.lower() or 
                query_lower in course.location.lower() or 
                query_lower in course.country.lower()):
                results.append(course)
        return results


# Global database instance
db = InMemoryDatabase()
