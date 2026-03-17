from __future__ import annotations

from uuid import UUID

from fastapi import HTTPException, status

def parse_uuid(value: str, field_name: str = 'value') -> UUID:
    try:
        return UUID(value)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f'{field_name} must be a valid UUID') from exc
