import os
import sys

print("Starting vercel_app.py")

current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)
print(f"Current dir: {current_dir}")
print(f"Parent dir: {parent_dir}")
print(f"sys.path: {sys.path[:3]}")

try:
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware
    print("FastAPI imported successfully")
except Exception as e:
    print(f"Error importing FastAPI: {e}")

app = FastAPI(title='Test App')

@app.get('/health')
def health():
    return {'status': 'ok'}

@app.get('/')
def root():
    return {'message': 'Hello from Vercel'}

def handler(request, context=None):
    return app(request.scope, request.receive, request._send)
