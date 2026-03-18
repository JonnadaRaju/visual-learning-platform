from typing import Dict

import json
import logging

from redis import Redis
from redis.exceptions import RedisError

from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()
redis_client = Redis.from_url(settings.redis_url, decode_responses=True)

def verify_cache_connection() -> None:
    try:
        redis_client.ping()
    except RedisError as exc:
        raise RuntimeError(f'Failed to connect to Redis at {settings.redis_url}: {exc}') from exc
    logger.info('Redis connection verified')

def cache_get(key: str):
    try:
        value = redis_client.get(key)
        return json.loads(value) if value else None
    except (RedisError, json.JSONDecodeError) as exc:
        logger.warning('Redis get failed for key %s: %s', key, exc)
        return None

def cache_set(key: str, value: Dict, ttl_seconds: int) -> None:
    try:
        redis_client.setex(key, ttl_seconds, json.dumps(value))
    except RedisError as exc:
        logger.warning('Redis set failed for key %s: %s', key, exc)
