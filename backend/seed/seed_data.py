
from pathlib import Path
import sys

ROOT_DIR = Path(__file__).resolve().parents[2]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from backend.database import initialize_database, replace_simulation_parameters, upsert_simulation


def seed() -> None:
    initialize_database()
    simulations = [
        {'category': 'Physics', 'name': 'Projectile Motion', 'slug': 'projectile-motion', 'description': 'Launch a projectile and inspect trajectory, height, range, and flight time.', 'parameters': [('angle', 'Angle', 'deg', 0.0, 90.0, 45.0, 1.0), ('initial_velocity', 'Initial Velocity', 'm/s', 0.0, 100.0, 40.0, 1.0), ('gravity', 'Gravity', 'm/s^2', 1.0, 20.0, 9.8, 0.1), ('initial_height', 'Initial Height', 'm', 0.0, 100.0, 0.0, 1.0)]},
        {'category': 'Physics', 'name': 'Waves / SHM', 'slug': 'waves-shm', 'description': 'Explore single waves and superposition.', 'parameters': [('amplitude', 'Amplitude', 'units', 1.0, 100.0, 20.0, 1.0), ('frequency', 'Frequency', 'Hz', 0.5, 20.0, 2.0, 0.1), ('phase', 'Phase', 'rad', 0.0, 6.2832, 0.0, 0.1)]},
        {'category': 'Physics', 'name': 'Electric Circuits', 'slug': 'electric-circuits', 'description': 'Build resistor-battery circuits and solve node voltages and currents.', 'parameters': []},
    ]
    for item in simulations:
        simulation_id = upsert_simulation(item)
        replace_simulation_parameters(simulation_id, item['parameters'])
    print('Seed data loaded successfully.')

if __name__ == '__main__':
    seed()
