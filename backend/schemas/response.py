from __future__ import annotations

from datetime import datetime
import uuid
from pydantic import BaseModel

class Point3D(BaseModel):
    x: float
    y: float
    t: float | None = None

class ProjectileResponse(BaseModel):
    run_id: uuid.UUID
    trajectory: list[Point3D]
    max_height: float
    range: float
    time_of_flight: float
    cache_hit: bool

class WaveResponse(BaseModel):
    run_id: uuid.UUID
    points: list[Point3D]
    period: float
    angular_frequency: float
    cache_hit: bool

class WaveSeries(BaseModel):
    label: str
    wave_type: str
    points: list[Point3D]
    period: float
    angular_frequency: float

class WaveSuperpositionResponse(BaseModel):
    run_id: uuid.UUID
    waves: list[WaveSeries]
    combined_points: list[Point3D]
    cache_hit: bool

class NodeVoltage(BaseModel):
    node: str
    voltage: float

class BranchCurrent(BaseModel):
    component_id: str
    current: float

class CircuitResponse(BaseModel):
    run_id: uuid.UUID
    node_voltages: list[NodeVoltage]
    branch_currents: list[BranchCurrent]
    total_resistance: float | None
    total_power: float
    cache_hit: bool

class RunSummary(BaseModel):
    id: uuid.UUID
    simulation_slug: str
    input_params: dict
    result_payload: dict
    is_saved: bool
    created_at: datetime

class RunListResponse(BaseModel):
    runs: list[RunSummary]

class RunStatsResponse(BaseModel):
    total_runs: int
    saved_runs: int
    simulations_explored: int
    last_active: datetime | None

class SaveRunResponse(BaseModel):
    run_id: uuid.UUID
    is_saved: bool
