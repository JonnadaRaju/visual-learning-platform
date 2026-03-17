from __future__ import annotations

from typing import Literal
import uuid
from pydantic import BaseModel, Field, field_validator, model_validator

class ProjectileRequest(BaseModel):
    angle: float = Field(ge=0, le=90)
    initial_velocity: float = Field(ge=0, le=100)
    gravity: float = Field(ge=1, le=20)
    initial_height: float = Field(ge=0, le=100)

class WaveRequest(BaseModel):
    amplitude: float = Field(gt=0, le=100)
    frequency: float = Field(gt=0, le=20)
    phase: float = Field(ge=0, le=6.2832)
    wave_type: Literal['sine', 'cosine']

class WaveDefinitionInput(WaveRequest):
    label: str | None = None

class WaveSuperpositionRequest(BaseModel):
    waves: list[WaveDefinitionInput]
    @field_validator('waves')
    @classmethod
    def validate_waves(cls, value):
        if not 1 <= len(value) <= 3:
            raise ValueError('Provide between 1 and 3 waves for superposition')
        return value

class CircuitComponentInput(BaseModel):
    id: str
    type: Literal['resistor', 'battery', 'wire']
    value: float = Field(ge=0)
    node_a: str
    node_b: str
    @model_validator(mode='after')
    def validate_component(self):
        if self.node_a == self.node_b:
            raise ValueError('node_a and node_b must be different')
        if self.type == 'wire':
            self.value = 0
        return self

class CircuitRequest(BaseModel):
    components: list[CircuitComponentInput]
    @field_validator('components')
    @classmethod
    def validate_components(cls, value):
        if len(value) < 2:
            raise ValueError('Provide at least two components')
        return value

class SaveRunRequest(BaseModel):
    run_id: uuid.UUID
