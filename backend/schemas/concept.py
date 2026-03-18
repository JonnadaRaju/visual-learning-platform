from typing import List

import uuid
from pydantic import BaseModel

class SimulationParameterResponse(BaseModel):
    id: uuid.UUID
    param_name: str
    param_label: str
    unit: str
    min_value: float
    max_value: float
    default_value: float
    step_size: float

class SimulationListItem(BaseModel):
    id: uuid.UUID
    category: str
    name: str
    slug: str
    description: str
    parameters: List[SimulationParameterResponse]

class SimulationListResponse(BaseModel):
    simulations: List[SimulationListItem]

class SimulationDetailResponse(SimulationListItem):
    pass
