from pydantic_settings import BaseSettings
from typing import Optional
import os
import boto3
import json
from functools import lru_cache
import logging

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    # Basic configuration
    environment: str = "development"
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    
    # Secrets - will be loaded from various sources
    supabase_url: Optional[str] = None
    supabase_key: Optional[str] = None
    database_url: Optional[str] = None
    
    # AWS Configuration
    aws_region: str = "eu-central-1"
    project_name: str = "golf-tracker"
    
    # Secret loading preferences
    use_aws_secrets: bool = False
    use_aws_ssm: bool = False
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        
    def model_post_init(self, __context) -> None:
        """Load secrets after initialization"""
        if self.environment == "production" or self.use_aws_secrets or self.use_aws_ssm:
            self._load_aws_secrets()
    
    def _load_aws_secrets(self):
        """Load secrets from AWS (Secrets Manager or SSM Parameter Store)"""
        try:
            if self.use_aws_secrets:
                self._load_from_secrets_manager()
            elif self.use_aws_ssm or self.environment == "production":
                self._load_from_ssm_parameter_store()
        except Exception as e:
            logger.error(f"Failed to load AWS secrets: {e}")
            if self.environment == "production":
                raise
    
    def _load_from_secrets_manager(self):
        """Load from AWS Secrets Manager"""
        try:
            session = boto3.session.Session()
            client = session.client(
                service_name='secretsmanager',
                region_name=self.aws_region
            )
            
            # Load Supabase credentials
            secret_name = f"{self.project_name}-{self.environment}/supabase"
            response = client.get_secret_value(SecretId=secret_name)
            secrets = json.loads(response['SecretString'])
            
            self.supabase_url = secrets.get('supabase_url')
            self.supabase_key = secrets.get('supabase_key')
            self.database_url = secrets.get('database_url')
            
            logger.info("Successfully loaded secrets from AWS Secrets Manager")
            
        except Exception as e:
            logger.error(f"Failed to load from Secrets Manager: {e}")
            raise
    
    def _load_from_ssm_parameter_store(self):
        """Load from AWS SSM Parameter Store"""
        try:
            session = boto3.session.Session()
            client = session.client(
                service_name='ssm',
                region_name=self.aws_region
            )
            
            # Parameter names
            params = {
                'supabase_url': f"/{self.project_name}/{self.environment}/supabase_url",
                'supabase_key': f"/{self.project_name}/{self.environment}/supabase_key",
                'database_url': f"/{self.project_name}/{self.environment}/database_url"
            }
            
            # Get all parameters
            response = client.get_parameters(
                Names=list(params.values()),
                WithDecryption=True
            )
            
            # Map back to settings
            param_map = {v: k for k, v in params.items()}
            for param in response['Parameters']:
                attr_name = param_map[param['Name']]
                setattr(self, attr_name, param['Value'])
            
            logger.info("Successfully loaded secrets from AWS SSM Parameter Store")
            
        except Exception as e:
            logger.error(f"Failed to load from SSM Parameter Store: {e}")
            raise
    
    @property
    def is_production(self) -> bool:
        return self.environment == "production"
    
    @property
    def is_development(self) -> bool:
        return self.environment == "development"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


# Global settings instance
settings = get_settings()
