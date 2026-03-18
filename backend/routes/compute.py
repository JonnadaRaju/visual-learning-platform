from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import BaseModel

from services.compute_service import (
    compute_circuit,
    compute_projectile,
    compute_wave,
    compute_wave_superposition,
    get_run_stats,
    get_runs,
    parse_uuid,
    save_run,
)
from schemas.compute import CircuitRequest, ProjectileRequest, SaveRunRequest, WaveRequest, WaveSuperpositionRequest
from schemas.response import CircuitResponse, ProjectileResponse, RunListResponse, RunStatsResponse, RunSummary, SaveRunResponse, WaveResponse, WaveSuperpositionResponse

router = APIRouter(tags=['compute'])

def require_session_id(session_id: Optional[str] = Header(default=None, alias='X-Session-ID')) -> str:
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
    return save_run(session_id, payload.run_id)


@router.get('/runs', response_model=RunListResponse)
def runs(session_id: str = Depends(require_session_id)):
    items = get_runs(session_id)
    return RunListResponse(runs=[RunSummary(**item) for item in items])


@router.get('/runs/stats', response_model=RunStatsResponse)
def run_stats(session_id: str = Depends(require_session_id)):
    stats = get_run_stats(session_id)
    return RunStatsResponse(**stats)