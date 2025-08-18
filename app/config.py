import os
from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings with environment variable support"""
    
    # Database settings
    database_url: str = "sqlite:///./golf_courses.db"  # Default to SQLite for local development
    
    # API settings
    api_title: str = "Golf Course API"
    api_description: str = "A CRUD API for managing golf course data"
    api_version: str = "1.0.0"
    
    # Environment
    environment: str = "development"
    debug: bool = True
    
    # AWS settings (when deployed)
    aws_region: str = "us-east-1"
    
    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


# Database URL construction for different environments
def get_database_url() -> str:
    """Get database URL based on environment variables"""
    settings = get_settings()
    
    # If DATABASE_URL is explicitly set, use it
    if "DATABASE_URL" in os.environ:
        return os.environ["DATABASE_URL"]
    
    # For AWS/production, construct PostgreSQL URL
    if settings.environment == "production":
        db_host = os.getenv("DB_HOST", "localhost")
        db_port = os.getenv("DB_PORT", "5432")
        db_name = os.getenv("DB_NAME", "golf_courses")
        db_user = os.getenv("DB_USER", "postgres")
        db_password = os.getenv("DB_PASSWORD", "")
        
        return f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    
    # Default to SQLite for development
    return settings.database_url
