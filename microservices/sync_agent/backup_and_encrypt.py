import os
import json
import base64
import hashlib
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from dotenv import load_dotenv


_ENV_PATH = Path(__file__).resolve().parent / '.env'
load_dotenv(_ENV_PATH, override=False)


def _derive_key(passphrase: str, salt: bytes) -> bytes:
    """Derive a 32-byte key from passphrase using PBKDF2-like hashing (simple, deterministic)."""
    # Note: For production you can switch to PBKDF2HMAC; keeping minimal deps.
    data = passphrase.encode('utf-8') + salt
    return hashlib.sha256(data).digest()


def encrypt_bytes(plaintext: bytes, passphrase: str) -> dict:
    salt = os.urandom(16)
    nonce = os.urandom(12)
    key = _derive_key(passphrase, salt)
    aesgcm = AESGCM(key)
    ciphertext = aesgcm.encrypt(nonce, plaintext, None)
    return {
        'v': 1,
        'alg': 'AESGCM',
        'salt_b64': base64.b64encode(salt).decode('ascii'),
        'nonce_b64': base64.b64encode(nonce).decode('ascii'),
        'ciphertext_b64': base64.b64encode(ciphertext).decode('ascii'),
    }


def run_pg_dump(pg_dump_path: str, db_url: str, out_file: Path) -> None:
    out_file.parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        pg_dump_path,
        db_url,
        '--format=custom',
        '--no-owner',
        '--no-privileges',
    ]

    with out_file.open('wb') as f:
        proc = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE)

    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.decode('utf-8', errors='ignore'))


def main():
    tenant_id = os.environ.get('TENANT_ID', 'tenant-local')
    db_url = os.environ.get('LOCAL_DATABASE_URL')
    if not db_url:
        raise SystemExit('LOCAL_DATABASE_URL is required')

    pg_dump_path = os.environ.get('PG_DUMP_PATH', 'pg_dump')
    passphrase = os.environ.get('BACKUP_PASSPHRASE')
    if not passphrase:
        raise SystemExit('BACKUP_PASSPHRASE is required')

    out_dir = Path(os.environ.get('BACKUP_OUTPUT_DIR', './backups'))
    ts = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')

    dump_path = out_dir / tenant_id / f'{tenant_id}_{ts}.dump'
    enc_path = out_dir / tenant_id / f'{tenant_id}_{ts}.enc.json'

    run_pg_dump(pg_dump_path=pg_dump_path, db_url=db_url, out_file=dump_path)

    dump_bytes = dump_path.read_bytes()
    payload = encrypt_bytes(dump_bytes, passphrase=passphrase)

    meta = {
        'tenant_id': tenant_id,
        'timestamp': ts,
        'size_bytes': len(dump_bytes),
        'format': 'pg_dump_custom',
    }

    enc_path.parent.mkdir(parents=True, exist_ok=True)
    enc_path.write_text(json.dumps({'meta': meta, 'data': payload}, ensure_ascii=False))

    print(str(enc_path))


if __name__ == '__main__':
    main()
