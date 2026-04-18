import base64
import hashlib
import hmac
import secrets


def generate_api_key() -> str:
    # URL-safe random token
    return secrets.token_urlsafe(32)


def hash_api_key(api_key: str) -> str:
    # One-way hash for storage
    return hashlib.sha256(api_key.encode('utf-8')).hexdigest()


def verify_api_key(api_key: str, api_key_hash: str) -> bool:
    computed = hash_api_key(api_key)
    return hmac.compare_digest(computed, api_key_hash)
