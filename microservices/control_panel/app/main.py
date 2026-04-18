import hashlib
from datetime import datetime

from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Header, Query
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from .config import ADMIN_API_KEY, AUTO_CREATE_TABLES, PUBLIC_BASE_URL
from .db import engine, get_db
from .models import Tenant, BackupRecord
from .schemas import (
    TenantCreateRequest, TenantCreateResponse, TenantResponse,
    BackupRecordResponse, BackupRestoreRequest,
)
from .security import generate_api_key, hash_api_key, verify_api_key
from .storage import ensure_storage_dirs, save_backup_file


app = FastAPI(title='SmartJudi Control Panel', version='1.0.0')


@app.on_event('startup')
def _startup():
    ensure_storage_dirs()
    if AUTO_CREATE_TABLES:
        from .db import Base
        Base.metadata.create_all(bind=engine)


@app.get('/health/')
def health():
    return {'status': 'ok', 'service': 'control-panel'}


def require_admin(x_admin_api_key: str = Header(default='')):
    if not ADMIN_API_KEY:
        raise HTTPException(status_code=500, detail='ADMIN_API_KEY not configured')
    if x_admin_api_key != ADMIN_API_KEY:
        raise HTTPException(status_code=403, detail='forbidden')


def require_tenant(tenant_id: str, x_tenant_api_key: str, db: Session) -> Tenant:
    tenant = db.get(Tenant, tenant_id)
    if not tenant or not tenant.is_active:
        raise HTTPException(status_code=404, detail='tenant not found')
    if not verify_api_key(x_tenant_api_key, tenant.api_key_hash):
        raise HTTPException(status_code=403, detail='invalid tenant api key')
    return tenant


# ─────────────────────────────────────────────────────────────
# Tenants
# ─────────────────────────────────────────────────────────────
@app.post('/tenants/', response_model=TenantCreateResponse)
def create_tenant(payload: TenantCreateRequest, db: Session = Depends(get_db), x_admin_api_key: str = Header(default='')):
    require_admin(x_admin_api_key)

    tenant_id = hashlib.sha256((payload.name + str(datetime.utcnow())).encode('utf-8')).hexdigest()[:16]
    api_key = generate_api_key()

    tenant = Tenant(
        id=tenant_id,
        name=payload.name,
        api_key_hash=hash_api_key(api_key),
        is_active=True,
    )
    db.add(tenant)
    db.commit()

    return TenantCreateResponse(
        id=tenant.id,
        name=tenant.name,
        is_active=tenant.is_active,
        api_key=api_key,
    )


@app.get('/tenants/', response_model=list[TenantResponse])
def list_tenants(db: Session = Depends(get_db), x_admin_api_key: str = Header(default='')):
    require_admin(x_admin_api_key)
    tenants = db.query(Tenant).order_by(Tenant.created_at.desc()).all()
    return [TenantResponse(id=t.id, name=t.name, is_active=t.is_active) for t in tenants]


# ─────────────────────────────────────────────────────────────
# Backups
# ─────────────────────────────────────────────────────────────
@app.post('/backups/upload', response_model=BackupRecordResponse)
def upload_backup(
    tenant_id: str = Query(...),
    file: UploadFile = File(...),
    x_tenant_api_key: str = Header(default=''),
    db: Session = Depends(get_db),
):
    require_tenant(tenant_id, x_tenant_api_key, db)

    content = file.file.read()
    if not content:
        raise HTTPException(status_code=400, detail='empty file')

    sha256_hex = hashlib.sha256(content).hexdigest()

    # Attempt to parse metadata (optional)
    timestamp_utc = ''
    size_bytes = len(content)
    try:
        import json
        obj = json.loads(content.decode('utf-8'))
        meta = obj.get('meta', {})
        timestamp_utc = meta.get('timestamp', '')
        size_bytes = int(meta.get('size_bytes', size_bytes))
    except Exception:
        # Not a JSON envelope; still accept as encrypted blob
        timestamp_utc = datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')

    backup_id = hashlib.sha256((tenant_id + sha256_hex + str(datetime.utcnow())).encode('utf-8')).hexdigest()[:24]

    storage_path = save_backup_file(tenant_id=tenant_id, backup_id=backup_id, filename=file.filename, content=content)

    record = BackupRecord(
        id=backup_id,
        tenant_id=tenant_id,
        filename=file.filename,
        storage_path=str(storage_path),
        timestamp_utc=timestamp_utc,
        size_bytes=size_bytes,
        sha256_hex=sha256_hex,
    )
    db.add(record)
    db.commit()

    return BackupRecordResponse(
        id=record.id,
        tenant_id=record.tenant_id,
        filename=record.filename,
        timestamp_utc=record.timestamp_utc,
        size_bytes=record.size_bytes,
        sha256_hex=record.sha256_hex,
        uploaded_at=record.uploaded_at.isoformat(),
        restore_requested=record.restore_requested,
    )


@app.get('/backups/list', response_model=list[BackupRecordResponse])
def list_backups(
    tenant_id: str = Query(...),
    x_tenant_api_key: str = Header(default=''),
    db: Session = Depends(get_db),
):
    require_tenant(tenant_id, x_tenant_api_key, db)

    records = (
        db.query(BackupRecord)
        .filter(BackupRecord.tenant_id == tenant_id)
        .order_by(BackupRecord.uploaded_at.desc())
        .all()
    )

    return [
        BackupRecordResponse(
            id=r.id,
            tenant_id=r.tenant_id,
            filename=r.filename,
            timestamp_utc=r.timestamp_utc,
            size_bytes=r.size_bytes,
            sha256_hex=r.sha256_hex,
            uploaded_at=r.uploaded_at.isoformat(),
            restore_requested=r.restore_requested,
        )
        for r in records
    ]


@app.post('/backups/restore')
def request_restore(
    payload: BackupRestoreRequest,
    x_tenant_api_key: str = Header(default=''),
    db: Session = Depends(get_db),
):
    require_tenant(payload.tenant_id, x_tenant_api_key, db)

    record = db.get(BackupRecord, payload.backup_id)
    if not record or record.tenant_id != payload.tenant_id:
        raise HTTPException(status_code=404, detail='backup not found')

    record.restore_requested = True
    record.restore_requested_at = datetime.utcnow()
    db.commit()

    download_url = f"{PUBLIC_BASE_URL}/backups/{record.id}/download?tenant_id={payload.tenant_id}"
    return {
        'success': True,
        'backup_id': record.id,
        'download_url': download_url,
    }


@app.get('/backups/{backup_id}/download')
def download_backup(
    backup_id: str,
    tenant_id: str = Query(...),
    x_tenant_api_key: str = Header(default=''),
    db: Session = Depends(get_db),
):
    require_tenant(tenant_id, x_tenant_api_key, db)

    record = db.get(BackupRecord, backup_id)
    if not record or record.tenant_id != tenant_id:
        raise HTTPException(status_code=404, detail='backup not found')

    return FileResponse(
        path=record.storage_path,
        filename=f"{tenant_id}_{backup_id}.enc.json",
        media_type='application/json',
    )
