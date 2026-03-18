import os
import sys

current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title='EduViz Backend')

ALLOWED_ORIGINS = os.environ.get('ALLOWED_ORIGINS', 'https://eduviz-a3234.web.app,http://localhost:3000,http://localhost:5173').split(',')
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_origin_regex=r'^https?://(localhost|127\.0\.0\.1)(:\d+)?$',
    allow_credentials=False,
    allow_methods=['*'],
    allow_headers=['*'],
)

try:
    from backend.routes.concepts import router as simulations_router
    app.include_router(simulations_router)
except Exception as e:
    print(f'Could not load concepts router: {e}')

try:
    from backend.routes.compute import router as compute_router
    app.include_router(compute_router)
except Exception as e:
    print(f'Could not load compute router: {e}')

try:
    from backend.database import initialize_database
    from backend.cache import verify_cache_connection
    initialize_database()
    verify_cache_connection()
except Exception as e:
    print(f'Could not initialize connections: {e}')

@app.get('/health')
def health():
    return {'status': 'ok', 'app': 'EduViz Backend'}

@app.get('/')
def root():
    return {'message': 'EduViz Backend API'}
