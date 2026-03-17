from __future__ import annotations

from fastapi import APIRouter, Depends

from backend.database import fetch_run_stats, fetch_runs
from backend.routes.compute import require_session_id
from backend.schemas.response import RunListResponse, RunStatsResponse, RunSummary

router = APIRouter(prefix='/runs', tags=['runs'])

@router.get('', response_model=RunListResponse)
def runs(session_id: str = Depends(require_session_id)):
    items = fetch_runs(session_id)
    return RunListResponse(runs=[RunSummary(id=i.id, simulation_slug=i.simulation_slug, input_params=i.input_params, result_payload=i.result_payload, is_saved=i.is_saved, created_at=i.created_at) for i in items])

@router.get('/stats', response_model=RunStatsResponse)
def run_stats(session_id: str = Depends(require_session_id)):
    return RunStatsResponse(**fetch_run_stats(session_id))
