from typing import List, Optional
from supabase import Client
from app.models import GolfCourse, GolfCourseCreate, GolfCourseUpdate
import logging

logger = logging.getLogger(__name__)


class GolfCourseCRUD:
    def __init__(self, supabase_client: Client):
        self.client = supabase_client
        self.table_name = "golf_courses"
    
    async def create_golf_course(self, golf_course: GolfCourseCreate) -> GolfCourse:
        """Neuen Golfplatz erstellen"""
        try:
            # Daten für Supabase vorbereiten
            course_data = golf_course.model_dump()
            
            # Einfügen in Supabase
            result = self.client.table(self.table_name).insert(course_data).execute()
            
            if result.data:
                return GolfCourse(**result.data[0])
            else:
                raise Exception("Fehler beim Erstellen des Golfplatzes")
                
        except Exception as e:
            logger.error(f"Fehler beim Erstellen des Golfplatzes: {e}")
            raise
    
    async def get_golf_course(self, course_id: int) -> Optional[GolfCourse]:
        """Golfplatz anhand der ID abrufen"""
        try:
            result = self.client.table(self.table_name).select("*").eq("id", course_id).execute()
            
            if result.data:
                return GolfCourse(**result.data[0])
            return None
            
        except Exception as e:
            logger.error(f"Fehler beim Abrufen des Golfplatzes {course_id}: {e}")
            raise
    
    async def get_golf_courses(
        self, 
        skip: int = 0, 
        limit: int = 100,
        city: Optional[str] = None,
        country: Optional[str] = None,
        difficulty: Optional[str] = None,
        is_active: Optional[bool] = None
    ) -> tuple[List[GolfCourse], int]:
        """Alle Golfplätze mit optionalen Filtern abrufen"""
        try:
            query = self.client.table(self.table_name).select("*", count="exact")
            
            # Filter anwenden
            if city:
                query = query.ilike("city", f"%{city}%")
            if country:
                query = query.ilike("country", f"%{country}%")
            if difficulty:
                query = query.eq("difficulty", difficulty)
            if is_active is not None:
                query = query.eq("is_active", is_active)
            
            # Paginierung
            query = query.range(skip, skip + limit - 1)
            
            result = query.execute()
            
            courses = [GolfCourse(**course) for course in result.data]
            total_count = result.count if result.count else 0
            
            return courses, total_count
            
        except Exception as e:
            logger.error(f"Fehler beim Abrufen der Golfplätze: {e}")
            raise
    
    async def update_golf_course(self, course_id: int, golf_course_update: GolfCourseUpdate) -> Optional[GolfCourse]:
        """Golfplatz aktualisieren"""
        try:
            # Nur Felder aktualisieren, die nicht None sind
            update_data = golf_course_update.model_dump(exclude_unset=True)
            
            if not update_data:
                # Keine Daten zum Aktualisieren
                return await self.get_golf_course(course_id)
            
            result = self.client.table(self.table_name).update(update_data).eq("id", course_id).execute()
            
            if result.data:
                return GolfCourse(**result.data[0])
            return None
            
        except Exception as e:
            logger.error(f"Fehler beim Aktualisieren des Golfplatzes {course_id}: {e}")
            raise
    
    async def delete_golf_course(self, course_id: int) -> bool:
        """Golfplatz löschen"""
        try:
            result = self.client.table(self.table_name).delete().eq("id", course_id).execute()
            return len(result.data) > 0
            
        except Exception as e:
            logger.error(f"Fehler beim Löschen des Golfplatzes {course_id}: {e}")
            raise
    
    async def search_golf_courses(self, query: str, limit: int = 50) -> List[GolfCourse]:
        """Golfplätze durchsuchen"""
        try:
            result = self.client.table(self.table_name).select("*").or_(
                f"name.ilike.%{query}%,"
                f"description.ilike.%{query}%,"
                f"city.ilike.%{query}%,"
                f"country.ilike.%{query}%"
            ).limit(limit).execute()
            
            return [GolfCourse(**course) for course in result.data]
            
        except Exception as e:
            logger.error(f"Fehler bei der Suche nach Golfplätzen: {e}")
            raise
