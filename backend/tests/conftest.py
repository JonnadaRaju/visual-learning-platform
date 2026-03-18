import os
import sys
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@pytest.fixture
def mock_settings():
    with patch('config.get_settings') as mock:
        settings = MagicMock()
        settings.app_name = 'EduViz'
        settings.app_env = 'test'
        settings.app_port = 8000
        settings.debug = True
        settings.database_url = 'postgresql://test:test@localhost/testdb'
        settings.redis_url = 'redis://localhost:6379'
        settings.redis_ttl = 600
        settings.allowed_origins = ['http://localhost:3000']
        mock.return_value = settings
        yield settings


@pytest.fixture
def mock_db_connection():
    mock_conn = MagicMock()
    mock_cursor = MagicMock()
    mock_conn.cursor.return_value.__enter__ = MagicMock(return_value=mock_cursor)
    mock_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)
    return mock_conn, mock_cursor


@pytest.fixture
def mock_redis():
    with patch('cache.redis_client') as mock:
        mock.ping.return_value = True
        mock.get.return_value = None
        mock.setex.return_value = True
        yield mock


@pytest.fixture
def sample_simulations():
    return [
        {
            'id': '123e4567-e89b-12d3-a456-426614174000',
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': 'Projectile Motion',
            'slug': 'projectile-motion',
            'emoji': '🏏',
            'class_range': '9,10,11,12',
            'description': 'Projectile motion simulation',
            'is_active': True,
            'parameter_id': None,
            'param_name': None,
            'param_label': None,
            'unit': None,
            'min_value': None,
            'max_value': None,
            'default_value': None,
            'step_size': None,
        },
        {
            'id': '223e4567-e89b-12d3-a456-426614174001',
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': 'Waves / SHM',
            'slug': 'waves-shm',
            'emoji': '🌊',
            'class_range': '9,10,11,12',
            'description': 'Waves and simple harmonic motion',
            'is_active': True,
            'parameter_id': None,
            'param_name': None,
            'param_label': None,
            'unit': None,
            'min_value': None,
            'max_value': None,
            'default_value': None,
            'step_size': None,
        },
        {
            'id': '323e4567-e89b-12d3-a456-426614174002',
            'subject_id': 'maths',
            'category': 'Algebra',
            'name': 'Linear Equations',
            'slug': 'linear-equations',
            'emoji': '📈',
            'class_range': '6,7,8,9,10,11,12',
            'description': 'Linear equations solver',
            'is_active': True,
            'parameter_id': None,
            'param_name': None,
            'param_label': None,
            'unit': None,
            'min_value': None,
            'max_value': None,
            'default_value': None,
            'step_size': None,
        },
    ]


@pytest.fixture
def sample_runs():
    return [
        {
            'id': '123e4567-e89b-12d3-a456-426614174000',
            'session_id': 'session-123',
            'simulation_slug': 'projectile-motion',
            'input_params': {'angle': 45, 'initial_velocity': 10},
            'result_payload': {'trajectory': [], 'max_height': 5.0},
            'is_saved': True,
            'created_at': '2024-01-01T00:00:00Z',
        },
        {
            'id': '223e4567-e89b-12d3-a456-426614174001',
            'session_id': 'session-123',
            'simulation_slug': 'waves-shm',
            'input_params': {'amplitude': 1, 'frequency': 2},
            'result_payload': {'points': [], 'period': 0.5},
            'is_saved': False,
            'created_at': '2024-01-01T01:00:00Z',
        },
    ]
