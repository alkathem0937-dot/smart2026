from pathlib import Path

from .config import STORAGE_DIR


def ensure_storage_dirs():
    STORAGE_DIR.mkdir(parents=True, exist_ok=True)


def tenant_dir(tenant_id: str) -> Path:
    d = STORAGE_DIR / 'backups' / tenant_id
    d.mkdir(parents=True, exist_ok=True)
    return d


def save_backup_file(tenant_id: str, backup_id: str, filename: str, content: bytes) -> Path:
    # Store as {backup_id}.enc.json (preserve original filename in DB)
    d = tenant_dir(tenant_id)
    path = d / f'{backup_id}.enc.json'
    path.write_bytes(content)
    return path
