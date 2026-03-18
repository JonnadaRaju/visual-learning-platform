import uuid
from unittest.mock import MagicMock, patch


def test_rows_to_simulations():
    from database import _rows_to_simulations
    
    rows = [
        {
            'id': uuid.uuid4(),
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': 'Projectile Motion',
            'slug': 'projectile-motion',
            'emoji': '🏏',
            'class_range': '9,10,11,12',
            'description': 'Test description',
            'is_active': True,
            'parameter_id': None,
            'param_name': None,
            'param_label': None,
            'unit': None,
            'min_value': None,
            'max_value': None,
            'default_value': None,
            'step_size': None,
        }
    ]
    
    simulations = _rows_to_simulations(rows)
    
    assert len(simulations) == 1
    assert simulations[0].slug == 'projectile-motion'
    assert simulations[0].subject_id == 'physics'
    assert simulations[0].class_range == '9,10,11,12'
    assert simulations[0].emoji == '🏏'


def test_rows_to_simulations_with_parameters():
    from database import _rows_to_simulations
    
    sim_id = uuid.uuid4()
    param_id = uuid.uuid4()
    
    rows = [
        {
            'id': sim_id,
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': 'Projectile Motion',
            'slug': 'projectile-motion',
            'emoji': '🏏',
            'class_range': '9,10,11,12',
            'description': 'Test description',
            'is_active': True,
            'parameter_id': param_id,
            'param_name': 'angle',
            'param_label': 'Angle',
            'unit': 'degrees',
            'min_value': 0.0,
            'max_value': 90.0,
            'default_value': 45.0,
            'step_size': 1.0,
        }
    ]
    
    simulations = _rows_to_simulations(rows)
    
    assert len(simulations) == 1
    assert len(simulations[0].parameters) == 1
    assert simulations[0].parameters[0].param_name == 'angle'
    assert simulations[0].parameters[0].min_value == 0.0


def test_rows_to_simulations_multiple_rows_same_simulation():
    from database import _rows_to_simulations
    
    sim_id = uuid.uuid4()
    param_id_1 = uuid.uuid4()
    param_id_2 = uuid.uuid4()
    
    rows = [
        {
            'id': sim_id,
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': 'Projectile Motion',
            'slug': 'projectile-motion',
            'emoji': '🏏',
            'class_range': '9,10,11,12',
            'description': 'Test description',
            'is_active': True,
            'parameter_id': param_id_1,
            'param_name': 'angle',
            'param_label': 'Angle',
            'unit': 'degrees',
            'min_value': 0.0,
            'max_value': 90.0,
            'default_value': 45.0,
            'step_size': 1.0,
        },
        {
            'id': sim_id,
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': 'Projectile Motion',
            'slug': 'projectile-motion',
            'emoji': '🏏',
            'class_range': '9,10,11,12',
            'description': 'Test description',
            'is_active': True,
            'parameter_id': param_id_2,
            'param_name': 'velocity',
            'param_label': 'Initial Velocity',
            'unit': 'm/s',
            'min_value': 1.0,
            'max_value': 100.0,
            'default_value': 10.0,
            'step_size': 1.0,
        },
    ]
    
    simulations = _rows_to_simulations(rows)
    
    assert len(simulations) == 1
    assert len(simulations[0].parameters) == 2


def test_simulation_definition_class_range():
    from database import SimulationDefinition
    
    sim = SimulationDefinition(
        id=uuid.uuid4(),
        subject_id='physics',
        category='Mechanics',
        name='Test',
        slug='test',
        emoji='🏏',
        class_range='9,10,11,12',
        description='Test',
        is_active=True,
    )
    
    assert '9' in sim.class_range
    assert '12' in sim.class_range
