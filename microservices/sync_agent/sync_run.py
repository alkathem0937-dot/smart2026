import os
import subprocess
from pathlib import Path
import sys

from dotenv import load_dotenv


_ENV_PATH = Path(__file__).resolve().parent / '.env'
load_dotenv(_ENV_PATH, override=False)


def main():
    # 1) Create encrypted backup
    proc = subprocess.run([sys.executable, 'backup_and_encrypt.py'], capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit(proc.stderr)

    enc_path = proc.stdout.strip().splitlines()[-1].strip()
    if not enc_path:
        raise SystemExit('No encrypted output file path returned')

    # 2) Upload to control panel (if configured)
    control_base = os.environ.get('CONTROL_PANEL_BASE_URL', '').strip()
    if not control_base:
        print(enc_path)
        return

    env = os.environ.copy()
    env['ENC_BACKUP_FILE'] = enc_path

    proc2 = subprocess.run([sys.executable, 'upload_to_control_panel.py'], env=env)
    if proc2.returncode != 0:
        raise SystemExit(proc2.returncode)


if __name__ == '__main__':
    main()
