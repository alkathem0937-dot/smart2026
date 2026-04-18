import os
from pathlib import Path

import httpx
from dotenv import load_dotenv


_ENV_PATH = Path(__file__).resolve().parent / '.env'
load_dotenv(_ENV_PATH, override=False)


def main():
    control_base = os.environ.get('CONTROL_PANEL_BASE_URL', '').rstrip('/')
    if not control_base:
        raise SystemExit('CONTROL_PANEL_BASE_URL is required (e.g. https://control.your-domain.com)')

    tenant_id = os.environ.get('TENANT_ID', '')
    tenant_api_key = os.environ.get('TENANT_API_KEY', '')
    if not tenant_id or not tenant_api_key:
        raise SystemExit('TENANT_ID and TENANT_API_KEY are required')

    enc_file_path = os.environ.get('ENC_BACKUP_FILE')
    if not enc_file_path:
        raise SystemExit('ENC_BACKUP_FILE is required (path to .enc.json)')

    p = Path(enc_file_path)
    if not p.exists():
        raise SystemExit(f'File not found: {p}')

    url = f"{control_base}/backups/upload"
    params = {'tenant_id': tenant_id}
    headers = {'X-Tenant-Api-Key': tenant_api_key}

    with p.open('rb') as f:
        files = {'file': (p.name, f, 'application/json')}
        resp = httpx.post(url, params=params, headers=headers, files=files, timeout=60.0)

    if resp.status_code >= 400:
        raise SystemExit(f'Upload failed: {resp.status_code} {resp.text}')

    print(resp.json())


if __name__ == '__main__':
    main()
