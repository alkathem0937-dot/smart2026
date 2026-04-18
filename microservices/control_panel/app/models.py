import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Integer, Boolean, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


class Tenant(Base):
    __tablename__ = 'tenants'

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)

    api_key_hash: Mapped[str] = mapped_column(String(128), nullable=False)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    backups = relationship('BackupRecord', back_populates='tenant', cascade='all, delete-orphan')


class BackupRecord(Base):
    __tablename__ = 'backup_records'

    id: Mapped[str] = mapped_column(String(64), primary_key=True)

    tenant_id: Mapped[str] = mapped_column(String(64), ForeignKey('tenants.id'), nullable=False, index=True)
    tenant = relationship('Tenant', back_populates='backups')

    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    storage_path: Mapped[str] = mapped_column(Text, nullable=False)

    timestamp_utc: Mapped[str] = mapped_column(String(32), nullable=False)
    size_bytes: Mapped[int] = mapped_column(Integer, nullable=False)
    sha256_hex: Mapped[str] = mapped_column(String(64), nullable=False)

    uploaded_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    restore_requested: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    restore_requested_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    notes: Mapped[str] = mapped_column(Text, default='', nullable=False)
