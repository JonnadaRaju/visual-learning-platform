from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
import uuid

@dataclass(slots=True)
class SimulationRun:
    id: uuid.UUID
    session_id: str
    simulation_slug: str
    input_params: dict
    result_payload: dict
    is_saved: bool
    created_at: datetime
