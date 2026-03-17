from __future__ import annotations

from dataclasses import dataclass, field
import uuid

@dataclass(slots=True)
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

@dataclass(slots=True)
class SimulationDefinition:
    id: uuid.UUID
    category: str
    name: str
    slug: str
    description: str
    is_active: bool
    parameters: list[SimulationParameter] = field(default_factory=list)
