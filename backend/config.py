from typing import List

import os
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv
from pydantic import BaseModel, Field, ValidationError

ROOT_DIR = Path(__file__).resolve().parent.parent
BACKEND_DIR = Path(__file__).resolve().parent
ENV_PATHS = [ROOT_DIR / '.env', BACKEND_DIR / '.env']

class Settings(BaseModel):
    app_name: str = Field(alias='APP_NAME')
    app_env: str = Field(alias='APP_ENV')
    app_port: int = Field(alias='APP_PORT')
    debug: bool = Field(alias='DEBUG')
    database_url: str = Field(alias='DATABASE_URL')
    redis_url: str = Field(alias='REDIS_URL')
    redis_ttl: int = Field(alias='REDIS_TTL')
    allowed_origins: List[str]

    @classmethod
    def from_environment(cls) -> 'Settings':
        env_path = next((path for path in ENV_PATHS if path.exists()), None)
        if env_path is None:
            searched = ', '.join(str(path) for path in ENV_PATHS)
            raise RuntimeError(f'Missing .env file. Create one at one of: {searched}')
        load_dotenv(env_path, override=False)
        data = {
            'APP_NAME': os.getenv('APP_NAME'),
            'APP_ENV': os.getenv('APP_ENV'),
            'APP_PORT': os.getenv('APP_PORT'),
            'DEBUG': os.getenv('DEBUG'),
            'DATABASE_URL': os.getenv('DATABASE_URL'),
            'REDIS_URL': os.getenv('REDIS_URL'),
            'REDIS_TTL': os.getenv('REDIS_TTL'),
            'allowed_origins': [item.strip() for item in os.getenv('ALLOWED_ORIGINS', '').split(',') if item.strip()],
        }
        try:
            return cls.model_validate(data)
        except ValidationError as exc:
            raise RuntimeError(f'Invalid environment configuration: {exc}') from exc

@lru_cache
def get_settings() -> Settings:
    return Settings.from_environment()
