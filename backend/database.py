from typing import Dict, List, Optional, Tuple

import contextlib
import uuid
from dataclasses import dataclass, field

import psycopg2
from psycopg2.extras import Json, RealDictCursor

from config import get_settings

settings = get_settings()


@dataclass
class SimulationParameter:
    id: uuid.UUID
    simulation_id: uuid.UUID
    param_name: str
    param_label: str
    unit: str
    min_value: float
    max_value: float
    default_value: float
    step_size: float


@dataclass
class SimulationDefinition:
    id: uuid.UUID
    subject_id: str
    category: str
    name: str
    slug: str
    emoji: str
    class_range: str          
    description: str
    is_active: bool
    parameters: List[SimulationParameter] = field(default_factory=list)


def get_connection():
    try:
        return psycopg2.connect(settings.database_url, cursor_factory=RealDictCursor, sslmode='require')
    except psycopg2.Error as exc:
        raise RuntimeError(
            f'Failed to connect to PostgreSQL using DATABASE_URL: {exc}'
        ) from exc


@contextlib.contextmanager
def get_db_connection():
    connection = get_connection()
    try:
        yield connection
    finally:
        connection.close()


def verify_database_connection() -> None:
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1')
            cursor.fetchone()


def initialize_database() -> None:
    schema_sql = """
    CREATE EXTENSION IF NOT EXISTS pgcrypto;

    CREATE TABLE IF NOT EXISTS simulations (
        id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        subject_id  VARCHAR(50)  NOT NULL DEFAULT 'physics',
        category    VARCHAR(100) NOT NULL,
        name        VARCHAR(100) NOT NULL,
        slug        VARCHAR(100) NOT NULL UNIQUE,
        emoji       VARCHAR(10)  NOT NULL DEFAULT '',
        class_range VARCHAR(50)  NOT NULL DEFAULT '9,10,11,12',
        description TEXT         NOT NULL,
        is_active   BOOLEAN      NOT NULL DEFAULT TRUE
    );

    -- Add new columns to existing table if upgrading
    ALTER TABLE simulations
        ADD COLUMN IF NOT EXISTS subject_id  VARCHAR(50)  NOT NULL DEFAULT 'physics',
        ADD COLUMN IF NOT EXISTS emoji       VARCHAR(10)  NOT NULL DEFAULT '',
        ADD COLUMN IF NOT EXISTS class_range VARCHAR(50)  NOT NULL DEFAULT '9,10,11,12';

    CREATE TABLE IF NOT EXISTS simulation_parameters (
        id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        simulation_id UUID NOT NULL REFERENCES simulations(id) ON DELETE CASCADE,
        param_name    VARCHAR(100)       NOT NULL,
        param_label   VARCHAR(100)       NOT NULL,
        unit          VARCHAR(50)        NOT NULL,
        min_value     DOUBLE PRECISION   NOT NULL,
        max_value     DOUBLE PRECISION   NOT NULL,
        default_value DOUBLE PRECISION   NOT NULL,
        step_size     DOUBLE PRECISION   NOT NULL
    );

    CREATE TABLE IF NOT EXISTS simulation_runs (
        id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        session_id      VARCHAR(100) NOT NULL,
        simulation_slug VARCHAR(100) NOT NULL,
        input_params    JSONB        NOT NULL,
        result_payload  JSONB        NOT NULL,
        is_saved        BOOLEAN      NOT NULL DEFAULT FALSE,
        created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
    );

    CREATE UNIQUE INDEX IF NOT EXISTS idx_simulation_parameters_unique
        ON simulation_parameters(simulation_id, param_name);

    CREATE INDEX IF NOT EXISTS idx_simulation_runs_session_id
        ON simulation_runs(session_id);
    """
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(schema_sql)
        connection.commit()


def fetch_simulations() -> List[SimulationDefinition]:
    query = """
        SELECT s.id, s.subject_id, s.category, s.name, s.slug,
               s.emoji, s.class_range, s.description, s.is_active,
               p.id AS parameter_id, p.param_name, p.param_label,
               p.unit, p.min_value, p.max_value, p.default_value, p.step_size
        FROM simulations s
        LEFT JOIN simulation_parameters p ON p.simulation_id = s.id
        WHERE s.is_active = TRUE
        ORDER BY s.subject_id, s.category, s.name, p.param_name
    """
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query)
            rows = cursor.fetchall()
    return _rows_to_simulations(rows)


def fetch_simulation_by_slug(slug: str) -> Optional[SimulationDefinition]:
    query = """
        SELECT s.id, s.subject_id, s.category, s.name, s.slug,
               s.emoji, s.class_range, s.description, s.is_active,
               p.id AS parameter_id, p.param_name, p.param_label,
               p.unit, p.min_value, p.max_value, p.default_value, p.step_size
        FROM simulations s
        LEFT JOIN simulation_parameters p ON p.simulation_id = s.id
        WHERE s.slug = %s AND s.is_active = TRUE
        ORDER BY p.param_name
    """
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (slug,))
            rows = cursor.fetchall()
    simulations = _rows_to_simulations(rows)
    return simulations[0] if simulations else None


def insert_run(
    session_id: str,
    simulation_slug: str,
    input_params: Dict,
    result_payload: Dict,
) -> uuid.UUID:
    query = """
        INSERT INTO simulation_runs
            (session_id, simulation_slug, input_params, result_payload)
        VALUES (%s, %s, %s, %s)
        RETURNING id
    """
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                query,
                (session_id, simulation_slug, Json(input_params), Json(result_payload)),
            )
            run_id = cursor.fetchone()['id']
        connection.commit()
    return run_id


def mark_run_saved(session_id: str, run_id: uuid.UUID) -> bool:
    query = """
        UPDATE simulation_runs
        SET is_saved = TRUE
        WHERE id = %s AND session_id = %s
        RETURNING is_saved
    """
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (str(run_id), session_id))
            row = cursor.fetchone()
        connection.commit()
    return bool(row and row['is_saved'])


def fetch_runs(session_id: str) -> List[Dict]:
    query = """
        SELECT id, session_id, simulation_slug, input_params,
               result_payload, is_saved, created_at
        FROM simulation_runs
        WHERE session_id = %s
        ORDER BY created_at DESC
    """
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (session_id,))
            rows = cursor.fetchall()
    return [
        {
            'id':               r['id'],
            'session_id':       r['session_id'],
            'simulation_slug':  r['simulation_slug'],
            'input_params':     r['input_params'],
            'result_payload':   r['result_payload'],
            'is_saved':         r['is_saved'],
            'created_at':       r['created_at'],
        }
        for r in rows
    ]


def fetch_run_stats(session_id: str) -> Dict:
    query = """
        SELECT
            COUNT(*)                                        AS total_runs,
            COUNT(*) FILTER (WHERE is_saved = TRUE)        AS saved_runs,
            COUNT(DISTINCT simulation_slug)                 AS simulations_explored,
            MAX(created_at)                                 AS last_active
        FROM simulation_runs
        WHERE session_id = %s
    """
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (session_id,))
            row = cursor.fetchone()
    return {
        'total_runs':            row['total_runs'] or 0,
        'saved_runs':            row['saved_runs'] or 0,
        'simulations_explored':  row['simulations_explored'] or 0,
        'last_active':           row['last_active'],
    }


def upsert_simulation(item: Dict) -> uuid.UUID:
    query = """
        INSERT INTO simulations
            (subject_id, category, name, slug, emoji, class_range, description, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, %s, TRUE)
        ON CONFLICT (slug) DO UPDATE SET
            subject_id  = EXCLUDED.subject_id,
            category    = EXCLUDED.category,
            name        = EXCLUDED.name,
            emoji       = EXCLUDED.emoji,
            class_range = EXCLUDED.class_range,
            description = EXCLUDED.description,
            is_active   = TRUE
        RETURNING id
    """
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (
                item.get('subject_id', 'physics'),
                item['category'],
                item['name'],
                item['slug'],
                item.get('emoji', ''),
                item.get('class_range', '9,10,11,12'),
                item['description'],
            ))
            simulation_id = cursor.fetchone()['id']
        connection.commit()
    return simulation_id


def replace_simulation_parameters(
    simulation_id: uuid.UUID, parameters: List[Tuple]
) -> None:
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                'DELETE FROM simulation_parameters WHERE simulation_id = %s',
                (str(simulation_id),),
            )
            for item in parameters:
                cursor.execute(
                    """INSERT INTO simulation_parameters
                        (simulation_id, param_name, param_label, unit,
                         min_value, max_value, default_value, step_size)
                       VALUES (%s,%s,%s,%s,%s,%s,%s,%s)""",
                    (str(simulation_id), *item),
                )
        connection.commit()


def _rows_to_simulations(rows: List[Dict]) -> List[SimulationDefinition]:
    simulations: Dict[uuid.UUID, SimulationDefinition] = {}
    for row in rows:
        sim_id = row['id']
        sim = simulations.get(sim_id)
        if sim is None:
            sim = SimulationDefinition(
                id=row['id'],
                subject_id=row.get('subject_id', 'physics'),
                category=row['category'],
                name=row['name'],
                slug=row['slug'],
                emoji=row.get('emoji', ''),
                class_range=row.get('class_range', '9,10,11,12'),
                description=row['description'],
                is_active=row['is_active'],
                parameters=[],
            )
            simulations[sim_id] = sim
        if row.get('parameter_id'):
            sim.parameters.append(SimulationParameter(
                id=row['parameter_id'],
                simulation_id=sim_id,
                param_name=row['param_name'],
                param_label=row['param_label'],
                unit=row['unit'],
                min_value=float(row['min_value']),
                max_value=float(row['max_value']),
                default_value=float(row['default_value']),
                step_size=float(row['step_size']),
            ))
    return list(simulations.values())