import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ.setdefault('APP_NAME', 'EduViz Backend')
os.environ.setdefault('APP_ENV', 'production')
os.environ.setdefault('APP_PORT', '8000')
os.environ.setdefault('DEBUG', 'false')

if 'DATABASE_URL' not in os.environ:
    db_url = os.getenv('POSTGRES_URL', '')
    if db_url:
        os.environ['DATABASE_URL'] = db_url

if 'REDIS_URL' not in os.environ:
    redis_url = os.getenv('REDIS_URL', '')
    if redis_url:
        os.environ['REDIS_URL'] = redis_url

if 'REDIS_TTL' not in os.environ:
    os.environ['REDIS_TTL'] = '3600'

if 'ALLOWED_ORIGINS' not in os.environ:
    os.environ.setdefault('ALLOWED_ORIGINS', 'https://eduviz-a3234.web.app')

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Request
from fastapi.responses import JSONResponse

app = FastAPI(title='EduViz Backend', debug=False)

frontend_url = os.getenv('FRONTEND_URL', 'https://eduviz-a3234.web.app')
app.add_middleware(
    CORSMiddleware,
    allow_origins=[frontend_url, 'http://localhost:3000', 'http://localhost:5173'],
    allow_origin_regex=r'^https?://(localhost|127\.0\.0\.1)(:\d+)?$',
    allow_credentials=False,
    allow_methods=['*'],
    allow_headers=['*'],
)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={'detail': str(exc), 'type': type(exc).__name__}
    )

@app.get('/health')
def health():
    return {'status': 'ok', 'app': 'EduViz Backend'}

@app.get('/')
def root():
    return {'message': 'EduViz Backend API', 'docs': '/docs'}

def try_include_routers():
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

try_include_routers()

def handler(request, context=None):
    return app(request.scope, request.receive, request._send)
