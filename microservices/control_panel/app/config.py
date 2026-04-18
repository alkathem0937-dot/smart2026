import os
from pathlib import Path


def get_env(name: str, default: str = '') -> str:
    v = os.environ.get(name)
    return v if v is not None else default


DATABASE_URL = get_env('CONTROL_PANEL_DATABASE_URL', get_env('DATABASE_URL', ''))
if not DATABASE_URL:
    # Dev fallback
    DATABASE_URL = 'postgresql://smartjudi:smartjudi_secret@127.0.0.1:5432/smartjudi_control'

STORAGE_DIR = Path(get_env('CONTROL_PANEL_STORAGE_DIR', str(Path(__file__).resolve().parent.parent / 'storage')))

# Admin key for tenant management endpoints
ADMIN_API_KEY = get_env('CONTROL_PANEL_ADMIN_API_KEY', '')

# If true, create tables on startup (dev bootstrap)
AUTO_CREATE_TABLES = get_env('CONTROL_PANEL_AUTO_CREATE_TABLES', '1') != '0'

PUBLIC_BASE_URL = get_env('CONTROL_PANEL_PUBLIC_BASE_URL', 'http://127.0.0.1:8100').rstrip('/')
