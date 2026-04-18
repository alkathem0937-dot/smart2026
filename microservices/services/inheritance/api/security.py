from __future__ import annotations

import os
from pathlib import Path
from typing import Optional

import jwt
from fastapi import Header, HTTPException


def _read_key_env_or_file(env_name: str, file_env_name: str) -> str:
    value = os.environ.get(env_name, '').strip()
    if value:
        return value

    file_path = os.environ.get(file_env_name, '').strip()
    if not file_path:
        return ''

    p = Path(file_path)
    try:
        return p.read_text(encoding='utf-8')
    except FileNotFoundError:
        return ''


def _get_jwt_config():
    public_key = _read_key_env_or_file('JWT_PUBLIC_KEY', 'JWT_PUBLIC_KEY_FILE')
    secret = os.environ.get('JWT_SECRET', os.environ.get('SECRET_KEY', '')).strip()
    if public_key:
        return 'RS256', public_key
    if secret:
        return 'HS256', secret
    return '', ''


def require_auth(authorization: Optional[str] = Header(default=None)) -> None:
    if os.environ.get('INHERITANCE_AUTH_REQUIRED', '0') == '0':
        return

    if not authorization or not authorization.lower().startswith('bearer '):
        raise HTTPException(status_code=401, detail='Missing Bearer token')

    token = authorization.split(' ', 1)[1].strip()
    alg, key = _get_jwt_config()
    if not alg or not key:
        raise HTTPException(status_code=500, detail='JWT verification not configured')

    try:
        jwt.decode(token, key, algorithms=[alg], options={'verify_aud': False})
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail='Token expired')
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail='Invalid token')
