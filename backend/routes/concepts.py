from fastapi import APIRouter, HTTPException

from database import fetch_simulation_by_slug, fetch_simulations
from schemas.concept import SimulationDetailResponse, SimulationListItem, SimulationListResponse, SimulationParameterResponse

router = APIRouter(prefix='/simulations', tags=['simulations'])

def _param(p):
    return SimulationParameterResponse(
        id=p.id,
        param_name=p.param_name,
        param_label=p.param_label,
        unit=p.unit,
        min_value=p.min_value,
        max_value=p.max_value,
        default_value=p.default_value,
        step_size=p.step_size,
    )

@router.get('', response_model=SimulationListResponse)
def list_simulations():
    simulations = fetch_simulations()
    return SimulationListResponse(
        simulations=[
            SimulationListItem(
                id=s.id,
                category=s.category,
                name=s.name,
                slug=s.slug,
                description=s.description,
                parameters=[_param(p) for p in s.parameters],
                subject_id=getattr(s, 'subject_id', 'physics'),
                emoji=getattr(s, 'emoji', '⚛️'),
                class_range=getattr(s, 'class_range', [6, 7, 8, 9, 10, 11, 12]),
            )
            for s in simulations
        ]
    )

@router.get('/{slug}', response_model=SimulationDetailResponse)
def get_simulation(slug: str):
    simulation = fetch_simulation_by_slug(slug)
    if simulation is None:
        raise HTTPException(status_code=404, detail='Simulation not found')
    return SimulationDetailResponse(
        id=simulation.id,
        category=simulation.category,
        name=simulation.name,
        slug=simulation.slug,
        description=simulation.description,
        parameters=[_param(p) for p in simulation.parameters],
    )