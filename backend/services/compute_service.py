from __future__ import annotations

import hashlib
import json
import math
from collections import defaultdict
from datetime import datetime
from typing import Any
import uuid

import numpy as np
from fastapi import HTTPException, status
from pydantic import BaseModel

from backend.cache import cache_get, cache_set
from backend.database import fetch_simulation_by_slug, fetch_runs, fetch_run_stats, insert_run, mark_run_saved
from backend.schemas.compute import CircuitRequest, ProjectileRequest, WaveRequest, WaveSuperpositionRequest
from backend.schemas.response import (
    BranchCurrent,
    CircuitResponse,
    NodeVoltage,
    Point3D,
    ProjectileResponse,
    SaveRunResponse,
    WaveResponse,
    WaveSeries,
    WaveSuperpositionResponse,
)

TTL_SECONDS = {'projectile-motion': 600, 'waves-shm': 300, 'electric-circuits': 900}


def parse_uuid(value: str, field_name: str = 'value') -> uuid.UUID:
    try:
        return uuid.UUID(value)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f'{field_name} must be a valid UUID') from exc


def _build_cache_key(prefix: str, payload: dict) -> str:
    normalized = json.dumps(payload, sort_keys=True, separators=(',', ':'))
    return f'{prefix}:{hashlib.sha256(normalized.encode()).hexdigest()}'


def _ensure_simulation(slug: str):
    simulation = fetch_simulation_by_slug(slug)
    if simulation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Simulation not found')
    return simulation


def compute_projectile(session_id: str, payload: ProjectileRequest) -> ProjectileResponse:
    slug = 'projectile-motion'
    _ensure_simulation(slug)
    body = payload.model_dump()
    cache_key = _build_cache_key(slug, body)
    cached = cache_get(cache_key)
    if cached:
        run_id = insert_run(session_id, slug, body, cached)
        return ProjectileResponse(run_id=run_id, cache_hit=True, **cached)

    angle_rad = math.radians(payload.angle)
    vx = payload.initial_velocity * math.cos(angle_rad)
    vy = payload.initial_velocity * math.sin(angle_rad)
    discriminant = vy * vy + 2 * payload.gravity * payload.initial_height
    tof = (vy + math.sqrt(discriminant)) / payload.gravity if payload.gravity else 0.0
    max_height = payload.initial_height + (vy * vy) / (2 * payload.gravity) if payload.gravity else payload.initial_height

    points: list[Point3D] = []
    t = 0.0
    while True:
        x = vx * t
        y = payload.initial_height + vy * t - 0.5 * payload.gravity * t * t
        if y < 0 and t > 0:
            break
        points.append(Point3D(x=round(x, 4), y=round(max(y, 0.0), 4), t=round(t, 4)))
        t += 0.05

    horizontal_range = points[-1].x if points else 0.0
    if not points or points[-1].y != 0.0:
        points.append(Point3D(x=round(vx * tof, 4), y=0.0, t=round(tof, 4)))
        horizontal_range = points[-1].x

    result = {
        'trajectory': [point.model_dump() for point in points],
        'max_height': round(max_height, 4),
        'range': round(horizontal_range, 4),
        'time_of_flight': round(tof, 4),
    }
    cache_set(cache_key, result, TTL_SECONDS[slug])
    run_id = insert_run(session_id, slug, body, result)
    return ProjectileResponse(run_id=run_id, cache_hit=False, **result)


def _wave_points(amplitude: float, frequency: float, phase: float, wave_type: str):
    period = 1 / frequency
    angular = 2 * math.pi * frequency
    step = max(period / 100, 0.01)
    points = []
    x = 0.0
    while x <= period * 2 + 1e-9:
        angle = angular * x + phase
        y = amplitude * (math.sin(angle) if wave_type == 'sine' else math.cos(angle))
        points.append(Point3D(x=round(x, 4), y=round(y, 4)))
        x += step
    return points, round(period, 4), round(angular, 4)


def compute_wave(session_id: str, payload: WaveRequest) -> WaveResponse:
    slug = 'waves-shm'
    _ensure_simulation(slug)
    body = payload.model_dump()
    cache_key = _build_cache_key(f'{slug}:single', body)
    cached = cache_get(cache_key)
    if cached:
        run_id = insert_run(session_id, slug, body, cached)
        return WaveResponse(run_id=run_id, cache_hit=True, **cached)
    points, period, angular = _wave_points(payload.amplitude, payload.frequency, payload.phase, payload.wave_type)
    result = {'points': [p.model_dump() for p in points], 'period': period, 'angular_frequency': angular}
    cache_set(cache_key, result, TTL_SECONDS[slug])
    run_id = insert_run(session_id, slug, body, result)
    return WaveResponse(run_id=run_id, cache_hit=False, **result)


def compute_wave_superposition(session_id: str, payload: WaveSuperpositionRequest) -> WaveSuperpositionResponse:
    slug = 'waves-shm'
    _ensure_simulation(slug)
    body = payload.model_dump()
    cache_key = _build_cache_key(f'{slug}:superposition', body)
    cached = cache_get(cache_key)
    if cached:
        run_id = insert_run(session_id, slug, body, cached)
        return WaveSuperpositionResponse(run_id=run_id, cache_hit=True, **cached)
    series = []
    totals = defaultdict(float)
    x_axis = None
    for index, wave in enumerate(payload.waves, start=1):
        points, period, angular = _wave_points(wave.amplitude, wave.frequency, wave.phase, wave.wave_type)
        if x_axis is None:
            x_axis = [p.x for p in points]
        for point in points:
            totals[point.x] += point.y
        series.append(WaveSeries(label=wave.label or f'Wave {index}', wave_type=wave.wave_type, points=points, period=period, angular_frequency=angular))
    combined = [Point3D(x=x, y=round(totals[x], 4)) for x in (x_axis or [])]
    result = {'waves': [wave.model_dump() for wave in series], 'combined_points': [point.model_dump() for point in combined]}
    cache_set(cache_key, result, TTL_SECONDS[slug])
    run_id = insert_run(session_id, slug, body, result)
    return WaveSuperpositionResponse(run_id=run_id, cache_hit=False, **result)


class _UnionFind:
    def __init__(self):
        self.parent: dict[str, str] = {}

    def find(self, item: str) -> str:
        self.parent.setdefault(item, item)
        if self.parent[item] != item:
            self.parent[item] = self.find(self.parent[item])
        return self.parent[item]

    def union(self, a: str, b: str) -> None:
        root_a = self.find(a)
        root_b = self.find(b)
        if root_a != root_b:
            self.parent[root_b] = root_a


def compute_circuit(session_id: str, payload: CircuitRequest) -> CircuitResponse:
    slug = 'electric-circuits'
    _ensure_simulation(slug)
    body = payload.model_dump()
    cache_key = _build_cache_key(slug, body)
    cached = cache_get(cache_key)
    if cached:
        run_id = insert_run(session_id, slug, body, cached)
        return CircuitResponse(run_id=run_id, cache_hit=True, **cached)

    union_find = _UnionFind()
    for component in payload.components:
        union_find.find(component.node_a)
        union_find.find(component.node_b)
        if component.type == 'wire':
            union_find.union(component.node_a, component.node_b)

    reduced: list[dict[str, Any]] = []
    node_labels = set()
    for component in payload.components:
        node_a = union_find.find(component.node_a)
        node_b = union_find.find(component.node_b)
        if node_a == node_b:
            continue
        if component.type != 'wire':
            reduced.append({'id': component.id, 'type': component.type, 'value': component.value, 'node_a': node_a, 'node_b': node_b})
            node_labels.update([node_a, node_b])

    batteries = [item for item in reduced if item['type'] == 'battery']
    resistors = [item for item in reduced if item['type'] == 'resistor']
    if not batteries or not resistors:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail='Circuit requires at least one battery and one resistor')

    ground = batteries[0]['node_b']
    node_order = [node for node in sorted(node_labels) if node != ground]
    node_index = {node: index for index, node in enumerate(node_order)}
    source_index = {component['id']: index for index, component in enumerate(batteries)}
    size = len(node_order) + len(batteries)
    matrix = np.zeros((size, size), dtype=float)
    vector = np.zeros(size, dtype=float)

    for resistor in resistors:
        conductance = 1.0 / resistor['value'] if resistor['value'] else 0.0
        node_a = resistor['node_a']
        node_b = resistor['node_b']
        if node_a != ground:
            matrix[node_index[node_a], node_index[node_a]] += conductance
        if node_b != ground:
            matrix[node_index[node_b], node_index[node_b]] += conductance
        if node_a != ground and node_b != ground:
            index_a = node_index[node_a]
            index_b = node_index[node_b]
            matrix[index_a, index_b] -= conductance
            matrix[index_b, index_a] -= conductance

    for battery in batteries:
        row = len(node_order) + source_index[battery['id']]
        node_a = battery['node_a']
        node_b = battery['node_b']
        if node_a != ground:
            index_a = node_index[node_a]
            matrix[index_a, row] += 1
            matrix[row, index_a] += 1
        if node_b != ground:
            index_b = node_index[node_b]
            matrix[index_b, row] -= 1
            matrix[row, index_b] -= 1
        vector[row] = battery['value']

    try:
        solution = np.linalg.solve(matrix, vector)
    except np.linalg.LinAlgError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail='Circuit could not be solved') from exc

    voltages = {ground: 0.0}
    for node, index in node_index.items():
        voltages[node] = float(solution[index])

    branch_currents = []
    total_power = 0.0
    total_source_current = 0.0
    for resistor in resistors:
        current = (voltages.get(resistor['node_a'], 0.0) - voltages.get(resistor['node_b'], 0.0)) / resistor['value']
        branch_currents.append(BranchCurrent(component_id=resistor['id'], current=round(current, 6)))
        total_power += (current ** 2) * resistor['value']
    for battery in batteries:
        current = float(solution[len(node_order) + source_index[battery['id']]])
        branch_currents.append(BranchCurrent(component_id=battery['id'], current=round(current, 6)))
        total_source_current += abs(current)

    total_voltage = sum(battery['value'] for battery in batteries)
    total_resistance = round(total_voltage / total_source_current, 6) if total_source_current else None
    result = {
        'node_voltages': [NodeVoltage(node=node, voltage=round(voltage, 6)).model_dump() for node, voltage in sorted(voltages.items())],
        'branch_currents': [current.model_dump() for current in branch_currents],
        'total_resistance': total_resistance,
        'total_power': round(total_power, 6),
    }
    cache_set(cache_key, result, TTL_SECONDS[slug])
    run_id = insert_run(session_id, slug, body, result)
    return CircuitResponse(run_id=run_id, cache_hit=False, **result)


def save_run(session_id: str, run_id: uuid.UUID) -> SaveRunResponse:
    if not mark_run_saved(session_id, run_id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Run not found')
    return SaveRunResponse(run_id=run_id, is_saved=True)


def get_runs(session_id: str):
    return fetch_runs(session_id)


def get_run_stats(session_id: str):
    return fetch_run_stats(session_id)