from __future__ import annotations

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.cache import verify_cache_connection
from backend.config import get_settings
from backend.database import initialize_database, verify_database_connection
from backend.routes.compute import router as compute_router
from backend.routes.concepts import router as simulations_router

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s [%(name)s] %(message)s')
settings = get_settings()
logger = logging.getLogger(__name__)

app = FastAPI(title=settings.app_name, debug=settings.debug)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_origin_regex=r'^https?://(localhost|127\.0\.0\.1)(:\d+)?$',
    allow_credentials=False,
    allow_methods=['*'],
    allow_headers=['*'],
)
app.include_router(simulations_router)
app.include_router(compute_router)

@app.on_event('startup')
def startup() -> None:
    logger.info('Starting %s in %s', settings.app_name, settings.app_env)
    initialize_database()
    verify_database_connection()
    verify_cache_connection()

@app.get('/health')
def health():
    return {'status': 'ok', 'app': settings.app_name}
