# SmartJudi Sync Agent (Local)

## هدفه
- يعمل على سيرفر المكتب (LAN)
- يأخذ نسخة احتياطية من PostgreSQL المحلي (`pg_dump`)
- يشفّرها **قبل الإرسال** (Client-side encryption)
- (لاحقاً) يرفعها إلى Control Panel في السحابة مع ميتاداتا فقط

## التشغيل (مرحلة 1: Backup + Encrypt فقط)

### 1) متطلبات
- PostgreSQL tools (وجود `pg_dump` على PATH) أو ضبط `PG_DUMP_PATH`
- Python + packages:

```bash
python -m pip install -r requirements.txt
```

### 2) متغيرات البيئة

> يفضّل إنشاء ملف `.env` داخل نفس مجلد `sync_agent` (انسخ من `.env.example`) لأن هذا يسهل تشغيله عبر Task Scheduler بدون إعدادات إضافية.

- `TENANT_ID` مثال: `office-1`
- `LOCAL_DATABASE_URL` مثال:
  - `postgresql://user:pass@127.0.0.1:5432/smartjudi`
- `BACKUP_PASSPHRASE` كلمة مرور قوية للتشفير
- `PG_DUMP_PATH` (اختياري) مسار pg_dump الكامل
- `BACKUP_OUTPUT_DIR` (اختياري) مجلد الإخراج

### 3) تشغيل

```bash
python backup_and_encrypt.py
```

الناتج:
- ملف `.dump` (نسخة pg_dump)
- ملف `.enc.json` (محتوى مشفّر + ميتاداتا)

> ملاحظة: في الإنتاج سنحذف ملف dump الخام بعد نجاح التشفير/الرفع.
