import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def mock_app():
    with patch('main.verify_database_connection'):
        with patch('main.verify_cache_connection'):
            from main import app
            yield app


@pytest.fixture
def client(mock_app):
    return TestClient(mock_app)


def test_root_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    assert response.json() == {'message': 'EduViz Backend API'}


def test_list_simulations(client):
    mock_sim = MagicMock()
    mock_sim.id = uuid.uuid4()
    mock_sim.subject_id = 'physics'
    mock_sim.category = 'Mechanics'
    mock_sim.name = 'Projectile Motion'
    mock_sim.slug = 'projectile-motion'
    mock_sim.emoji = '🏏'
    mock_sim.class_range = '9,10,11,12'
    mock_sim.description = 'Test'
    mock_sim.is_active = True
    mock_sim.parameters = []

    with patch('routes.concepts.fetch_simulations', return_value=[mock_sim]):
        response = client.get('/simulations')
        
        assert response.status_code == 200
        data = response.json()
        assert 'simulations' in data
        assert len(data['simulations']) == 1


def test_get_simulation_not_found(client):
    with patch('routes.concepts.fetch_simulation_by_slug', return_value=None):
        response = client.get('/simulations/nonexistent')
        
        assert response.status_code == 404


def test_projectile_endpoint_no_session(client):
    response = client.post(
        '/simulations/projectile',
        json={'angle': 45, 'initial_velocity': 10},
    )
    
    assert response.status_code == 400


def test_get_runs_no_session(client):
    response = client.get('/runs')
    
    assert response.status_code == 400


def test_get_runs_stats_no_session(client):
    response = client.get('/runs/stats')
    
    assert response.status_code == 400
