from __future__ import annotations

from fastapi import APIRouter, Depends, Header, HTTPException, status

from backend.schemas.compute import CircuitRequest, ProjectileRequest, SaveRunRequest, WaveRequest, WaveSuperpositionRequest
from backend.schemas.response import CircuitResponse, ProjectileResponse, SaveRunResponse, WaveResponse, WaveSuperpositionResponse
from backend.services.compute_service import compute_circuit, compute_projectile, compute_wave, compute_wave_superposition, save_run
from backend.services.validation_service import parse_uuid

router = APIRouter(tags=['compute'])

def require_session_id(session_id: str | None = Header(default=None, alias='X-Session-ID')) -> str:
    if not session_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='X-Session-ID header is required')
    parse_uuid(session_id, 'X-Session-ID')
    return session_id

@router.post('/simulations/projectile', response_model=ProjectileResponse)
def projectile(payload: ProjectileRequest, session_id: str = Depends(require_session_id)):
    return compute_projectile(session_id, payload)

@router.post('/simulations/waves', response_model=WaveResponse)
def waves(payload: WaveRequest, session_id: str = Depends(require_session_id)):
    return compute_wave(session_id, payload)

@router.post('/simulations/waves/superposition', response_model=WaveSuperpositionResponse)
def wave_superposition(payload: WaveSuperpositionRequest, session_id: str = Depends(require_session_id)):
    return compute_wave_superposition(session_id, payload)

@router.post('/simulations/circuits', response_model=CircuitResponse)
def circuits(payload: CircuitRequest, session_id: str = Depends(require_session_id)):
    return compute_circuit(session_id, payload)

@router.post('/runs/save', response_model=SaveRunResponse)
def save(payload: SaveRunRequest, session_id: str = Depends(require_session_id)):
    return SaveRunResponse(**save_run(session_id, payload.run_id))
