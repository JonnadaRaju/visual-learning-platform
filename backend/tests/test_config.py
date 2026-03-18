import os
import tempfile
from unittest.mock import patch, MagicMock


def test_settings_from_environment():
    from config import Settings
    
    env_vars = {
        'APP_NAME': 'TestApp',
        'APP_ENV': 'test',
        'APP_PORT': '8000',
        'DEBUG': 'True',
        'DATABASE_URL': 'postgresql://user:pass@localhost/testdb',
        'REDIS_URL': 'redis://localhost:6379',
        'REDIS_TTL': '300',
        'ALLOWED_ORIGINS': 'http://localhost:3000,http://localhost:8080',
    }
    
    with patch.dict(os.environ, env_vars, clear=True):
        settings = Settings.from_environment()
        
        assert settings.app_name == 'TestApp'
        assert settings.app_env == 'test'
        assert settings.app_port == 8000
        assert settings.debug is True
        assert settings.database_url == 'postgresql://user:pass@localhost/testdb'
        assert settings.redis_url == 'redis://localhost:6379'
        assert settings.redis_ttl == 300
        assert 'http://localhost:3000' in settings.allowed_origins
        assert 'http://localhost:8080' in settings.allowed_origins


def test_settings_caching():
    from config import get_settings
    
    env_vars = {
        'APP_NAME': 'CachedApp',
        'APP_ENV': 'test',
        'APP_PORT': '9000',
        'DEBUG': 'False',
        'DATABASE_URL': 'postgresql://user:pass@localhost/testdb',
        'REDIS_URL': 'redis://localhost:6379',
        'REDIS_TTL': '600',
        'ALLOWED_ORIGINS': '*',
    }
    
    get_settings.cache_clear()
    
    with patch.dict(os.environ, env_vars, clear=True):
        settings1 = get_settings()
        settings2 = get_settings()
        
        assert settings1 is settings2


def test_settings_allowed_origins_empty():
    from config import Settings
    
    env_vars = {
        'APP_NAME': 'TestApp',
        'APP_ENV': 'test',
        'APP_PORT': '8000',
        'DEBUG': 'True',
        'DATABASE_URL': 'postgresql://user:pass@localhost/testdb',
        'REDIS_URL': 'redis://localhost:6379',
        'REDIS_TTL': '300',
        'ALLOWED_ORIGINS': '',
    }
    
    with patch.dict(os.environ, env_vars, clear=True):
        settings = Settings.from_environment()
        
        assert settings.allowed_origins == []
