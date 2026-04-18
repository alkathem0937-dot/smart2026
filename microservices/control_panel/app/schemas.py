from pydantic import BaseModel, Field


class TenantCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=200)


class TenantResponse(BaseModel):
    id: str
    name: str
    is_active: bool


class TenantCreateResponse(TenantResponse):
    api_key: str


class BackupRecordResponse(BaseModel):
    id: str
    tenant_id: str
    filename: str
    timestamp_utc: str
    size_bytes: int
    sha256_hex: str
    uploaded_at: str
    restore_requested: bool


class BackupRestoreRequest(BaseModel):
    tenant_id: str
    backup_id: str
