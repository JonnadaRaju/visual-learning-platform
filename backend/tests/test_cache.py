import json
from unittest.mock import MagicMock, patch


def test_cache_get_hit():
    test_data = {'key': 'value', 'number': 42}
    
    with patch('cache.redis_client') as mock_redis:
        mock_redis.get.return_value = json.dumps(test_data)
        
        from cache import cache_get
        result = cache_get('test_key')
        
        assert result == test_data
        mock_redis.get.assert_called_once_with('test_key')


def test_cache_get_miss():
    with patch('cache.redis_client') as mock_redis:
        mock_redis.get.return_value = None
        
        from cache import cache_get
        result = cache_get('nonexistent_key')
        
        assert result is None


def test_cache_get_invalid_json():
    with patch('cache.redis_client') as mock_redis:
        mock_redis.get.return_value = 'invalid json'
        
        from cache import cache_get
        result = cache_get('bad_key')
        
        assert result is None


def test_cache_set():
    test_data = {'key': 'value'}
    
    with patch('cache.redis_client') as mock_redis:
        from cache import cache_set
        cache_set('test_key', test_data, 300)
        
        mock_redis.setex.assert_called_once()
        call_args = mock_redis.setex.call_args
        assert call_args[0][0] == 'test_key'
        assert call_args[0][1] == 300
        assert json.loads(call_args[0][2]) == test_data


def test_verify_cache_connection():
    with patch('cache.redis_client') as mock_redis:
        mock_redis.ping.return_value = True
        
        from cache import verify_cache_connection
        verify_cache_connection()
        
        mock_redis.ping.assert_called_once()


def test_verify_cache_connection_failure():
    from redis.exceptions import RedisError
    
    with patch('cache.redis_client') as mock_redis:
        mock_redis.ping.side_effect = RedisError('Connection refused')
        
        from cache import verify_cache_connection
        try:
            verify_cache_connection()
            assert False, 'Should have raised exception'
        except RuntimeError as e:
            assert 'Failed to connect to Redis' in str(e)
