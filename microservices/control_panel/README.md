# SmartJudi Control Panel (Cloud) — FastAPI

## الهدف
- إدارة Tenants (مكاتب/شركات)
- استقبال النسخ الاحتياطية **المشفرة فقط** (Client-side encrypted)
- تخزين Metadata فقط (حجم/تاريخ/sha256/آخر مزامنة)
- توفير Download/Restore بدون الاطلاع على البيانات

## Endpoints

### Tenants
- `POST /tenants/` (Admin) → إنشاء Tenant + يعيد API Key
- `GET /tenants/` (Admin)

### Backups
- `POST /backups/upload?tenant_id=...` (Tenant) — Multipart file
  - Header: `X-Tenant-Api-Key: ...`
- `GET /backups/list?tenant_id=...` (Tenant)
  - Header: `X-Tenant-Api-Key: ...`
- `POST /backups/restore` (Tenant)
  - Body: `{ "tenant_id": "...", "backup_id": "..." }`
  - Header: `X-Tenant-Api-Key: ...`
- `GET /backups/{backup_id}/download?tenant_id=...` (Tenant)
  - Header: `X-Tenant-Api-Key: ...`

## التشغيل

### 1) تثبيت الحزم
```bash
python -m pip install -r requirements.txt
```

### 2) متغيرات البيئة
- `CONTROL_PANEL_DATABASE_URL`
  - مثال: `postgresql://user:pass@127.0.0.1:5432/smartjudi_control`
- `CONTROL_PANEL_STORAGE_DIR` (اختياري)
- `CONTROL_PANEL_ADMIN_API_KEY`
- `CONTROL_PANEL_PUBLIC_BASE_URL`

### 3) تشغيل السيرفر
```bash
python -m uvicorn app.main:app --host 0.0.0.0 --port 8100
```

## ملاحظات أمنية
- السيرفر لا يعرف كلمة التشفير ولا يمكنه فك البيانات
- API Keys الخاصة بالـ Tenants تُخزن على السيرفر بشكل hash فقط
- يفضّل وضع الخدمة خلف HTTPS + Rate limit + WAF
