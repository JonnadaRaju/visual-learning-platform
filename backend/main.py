import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import initialize_database, verify_database_connection
from cache import verify_cache_connection
from routes.concepts import router as simulations_router
from routes.compute import router as compute_router
from routes.ai import router as ai_router

app = FastAPI(title='EduViz Backend')

# ── CORS ──────────────────────────────────────────────────────────────────────
ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get(
        'ALLOWED_ORIGINS',
        'https://eduviz-a3234.web.app,http://localhost:3000',
    ).split(',')
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_origin_regex=r'^https?://(localhost|127\.0\.0\.1)(:\d+)?$',
    allow_credentials=False,
    allow_methods=['*'],
    allow_headers=['*'],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(simulations_router)
app.include_router(compute_router)
app.include_router(ai_router)

# ── Startup ───────────────────────────────────────────────────────────────────
initialize_database()
verify_database_connection()
verify_cache_connection()


# ── Routes ────────────────────────────────────────────────────────────────────
@app.get('/')
def root():
    return {'message': 'EduViz Backend API'}


@app.get('/health')
def health():
    try:
        verify_database_connection()
        verify_cache_connection()
        return {'status': 'ok', 'database': 'connected', 'cache': 'connected'}
    except Exception as e:
        return {'status': 'error', 'detail': str(e)}