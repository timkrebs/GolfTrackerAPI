from supabase import create_client, Client
from app.config import settings
import logging

logger = logging.getLogger(__name__)


class SupabaseClient:
    def __init__(self):
        self.client: Client = None
        self.connect()
    
    def connect(self):
        """Verbindung zur Supabase-Datenbank herstellen"""
        try:
            self.client = create_client(settings.supabase_url, settings.supabase_key)
            logger.info("Erfolgreich mit Supabase verbunden")
        except Exception as e:
            logger.error(f"Fehler bei der Verbindung zu Supabase: {e}")
            raise
    
    def get_client(self) -> Client:
        """Supabase Client zurückgeben"""
        if not self.client:
            self.connect()
        return self.client


# Singleton-Instanz
supabase_client = SupabaseClient()


def get_supabase() -> Client:
    """Dependency für FastAPI"""
    return supabase_client.get_client()
