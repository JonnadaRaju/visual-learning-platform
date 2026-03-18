from pathlib import Path
import sys

ROOT_DIR = Path(__file__).resolve().parents[2]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from backend.database import initialize_database, replace_simulation_parameters, upsert_simulation


def seed() -> None:
    initialize_database()

    simulations = [

        # ── Physics ───────────────────────────────────────────────────────────
        {
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': 'Projectile Motion',
            'slug': 'projectile-motion',
            'emoji': '🏏',
            'class_range': '9,10,11,12',
            'description': 'Launch a projectile and inspect trajectory, height, range, and flight time.',
            'parameters': [
                ('angle',            'Angle',            'deg',   0.0,   90.0,  45.0, 1.0),
                ('initial_velocity', 'Initial Velocity', 'm/s',   0.0,  100.0,  40.0, 1.0),
                ('gravity',          'Gravity',          'm/s^2', 1.0,   20.0,   9.8, 0.1),
                ('initial_height',   'Initial Height',   'm',     0.0,  100.0,   0.0, 1.0),
            ],
        },
        {
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': 'Waves / SHM',
            'slug': 'waves-shm',
            'emoji': '🌊',
            'class_range': '9,10,11,12',
            'description': 'Explore single waves and superposition of multiple waves.',
            'parameters': [
                ('amplitude', 'Amplitude', 'units', 1.0, 100.0, 20.0, 1.0),
                ('frequency', 'Frequency', 'Hz',    0.5,  20.0,  2.0, 0.1),
                ('phase',     'Phase',     'rad',   0.0,   6.28,  0.0, 0.1),
            ],
        },
        {
            'subject_id': 'physics',
            'category': 'Electricity',
            'name': 'Electric Circuits',
            'slug': 'electric-circuits',
            'emoji': '⚡',
            'class_range': '9,10,11,12',
            'description': 'Build resistor-battery circuits and solve node voltages and currents.',
            'parameters': [],
        },
        {
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': 'Gravitation & Orbits',
            'slug': 'gravitation-orbits',
            'emoji': '🪐',
            'class_range': '9,10,11,12',
            'description': 'Simulate planetary orbits using gravitational force and Kepler\'s laws.',
            'parameters': [
                ('mass',   'Planet Mass',   'units', 1.0,  12.0, 5.0, 0.5),
                ('radius', 'Orbit Radius',  'px',   50.0, 130.0, 90.0, 1.0),
            ],
        },
        {
            'subject_id': 'physics',
            'category': 'Mechanics',
            'name': "Newton's Laws",
            'slug': 'newtons-laws',
            'emoji': '⚖️',
            'class_range': '9,10,11,12',
            'description': 'Apply forces to objects and observe acceleration, friction, and motion.',
            'parameters': [
                ('mass',     'Mass',                  'kg', 0.5, 10.0,  3.0, 0.5),
                ('force',    'Applied Force',          'N', 0.0, 50.0, 10.0, 1.0),
                ('friction', 'Friction Coefficient',   '',  0.0,  0.9,  0.3, 0.1),
            ],
        },
        {
            'subject_id': 'physics',
            'category': 'Fluids',
            'name': 'Fluid Pressure',
            'slug': 'fluid-pressure',
            'emoji': '💧',
            'class_range': '9,10,11,12',
            'description': 'Explore buoyancy and Archimedes\' principle with density and fluid depth.',
            'parameters': [
                ('object_density', 'Object Density', 'g/cm³', 0.1, 2.0, 0.6, 0.1),
                ('fluid_density',  'Fluid Density',  'g/cm³', 0.5, 2.5, 1.0, 0.1),
                ('object_size',    'Object Size',    'px',   20.0, 70.0, 40.0, 1.0),
            ],
        },

        # ── Maths ─────────────────────────────────────────────────────────────
        {
            'subject_id': 'maths',
            'category': 'Algebra',
            'name': 'Linear Equations',
            'slug': 'linear-equations',
            'emoji': '📈',
            'class_range': '6,7,8,9,10,11,12',
            'description': 'Plot y = mx + c and find the intersection of two straight lines.',
            'parameters': [
                ('m1', 'Slope of Line 1',     '', -5.0, 5.0, 2.0, 0.5),
                ('c1', 'Intercept of Line 1', '', -8.0, 8.0, 1.0, 0.5),
                ('m2', 'Slope of Line 2',     '', -5.0, 5.0, -1.0, 0.5),
                ('c2', 'Intercept of Line 2', '', -8.0, 8.0, 4.0, 0.5),
            ],
        },
        {
            'subject_id': 'maths',
            'category': 'Geometry',
            'name': 'Geometry',
            'slug': 'geometry',
            'emoji': '📐',
            'class_range': '6,7,8,9,10,11,12',
            'description': 'Explore area, perimeter, and Pythagoras theorem with triangles, circles, and rectangles.',
            'parameters': [
                ('base',   'Base',   'units', 1.0, 10.0, 6.0, 0.5),
                ('height', 'Height', 'units', 1.0,  8.0, 4.0, 0.5),
            ],
        },

        # ── Chemistry ─────────────────────────────────────────────────────────
        {
            'subject_id': 'chemistry',
            'category': 'Atomic Theory',
            'name': 'Atomic Structure',
            'slug': 'atomic-structure',
            'emoji': '⚛️',
            'class_range': '6,7,8,9,10,11,12',
            'description': 'Visualise the Bohr model for elements H to Ar with electron shells.',
            'parameters': [
                ('atomic_number', 'Atomic Number', '', 1.0, 18.0, 6.0, 1.0),
            ],
        },
        {
            'subject_id': 'chemistry',
            'category': 'Chemical Reactions',
            'name': 'Acids & Bases',
            'slug': 'acids-bases',
            'emoji': '🧪',
            'class_range': '7,8,9,10,11,12',
            'description': 'Explore the pH scale, H⁺ concentration, and acid-base neutralisation.',
            'parameters': [
                ('ph', 'pH Value', '', 0.0, 14.0, 7.0, 0.1),
            ],
        },
    ]

    for item in simulations:
        simulation_id = upsert_simulation(item)
        replace_simulation_parameters(simulation_id, item['parameters'])

    print(f'Seed complete — {len(simulations)} simulations loaded.')


if __name__ == '__main__':
    seed()