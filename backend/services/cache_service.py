from __future__ import annotations

import hashlib
import json

def build_cache_key(prefix: str, payload: dict) -> str:
    normalized = json.dumps(payload, sort_keys=True, separators=(',', ':'))
    return f'{prefix}:{hashlib.sha256(normalized.encode()).hexdigest()}'
