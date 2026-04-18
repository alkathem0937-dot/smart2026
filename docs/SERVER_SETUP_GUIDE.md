# دليل تشغيل سيرفر SmartJudi وربطه بقاعدة البيانات

---

## الفهرس
1. [المتطلبات الأساسية](#1-المتطلبات-الأساسية)
2. [الوضع الأول: تشغيل سريع بـ SQLite (بدون PostgreSQL)](#2-الوضع-الأول-تشغيل-سريع-بـ-sqlite)
3. [الوضع الثاني: ربط بقاعدة بيانات PostgreSQL محلية](#3-الوضع-الثاني-ربط-بقاعدة-بيانات-postgresql-محلية)
4. [الوضع الثالث: Docker Microservices (كامل)](#4-الوضع-الثالث-docker-microservices)
5. [تشغيل Local Gateway (البوابة المحلية)](#5-تشغيل-local-gateway)
6. [تشغيل خدمة المواريث (Inheritance Service)](#6-تشغيل-خدمة-المواريث)
7. [ربط تطبيق Flutter بالسيرفر](#7-ربط-تطبيق-flutter-بالسيرفر)
8. [الأوامر المفيدة](#8-الأوامر-المفيدة)
9. [حل المشاكل الشائعة](#9-حل-المشاكل-الشائعة)

---

## 1. المتطلبات الأساسية

| الأداة | الحد الأدنى | ملاحظات |
|--------|-------------|---------|
| Python | 3.10+ | `python --version` |
| pip | أحدث إصدار | `pip --version` |
| PostgreSQL | 16 (اختياري) | فقط إذا أردت PostgreSQL بدلاً من SQLite |
| Docker | 24+ (اختياري) | فقط للوضع Microservices |
| Git | أي إصدار | `git --version` |

---

## 2. الوضع الأول: تشغيل سريع بـ SQLite

> هذا أبسط وضع — لا تحتاج PostgreSQL. قاعدة البيانات ملف `db.sqlite3` بجانب `manage.py`.

### الخطوة 1: إنشاء بيئة افتراضية وتثبيت المكتبات

```powershell
# من المجلد الرئيسي للمشروع
cd d:\programapp\smartjudi2-2

# إنشاء بيئة افتراضية
python -m venv venv

# تفعيل البيئة (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# تثبيت المكتبات
pip install -r requirements.txt
```

### الخطوة 2: إعداد قاعدة البيانات

```powershell
cd smartju

# إنشاء جداول قاعدة البيانات
python manage.py migrate

# إنشاء مستخدم admin
python manage.py createsuperuser
# أدخل: اسم المستخدم، البريد، كلمة المرور
```

### الخطوة 3: تشغيل السيرفر

```powershell
python manage.py runserver 0.0.0.0:8000
```

### التحقق من التشغيل

| الرابط | الوصف |
|--------|-------|
| `http://127.0.0.1:8000/health/` | فحص صحة السيرفر |
| `http://127.0.0.1:8000/admin/` | لوحة التحكم (Jazzmin) |
| `http://127.0.0.1:8000/swagger/` | توثيق API التفاعلي |
| `http://127.0.0.1:8000/api/token/` | الحصول على JWT Token |

---

## 3. الوضع الثاني: ربط بقاعدة بيانات PostgreSQL محلية

### الخطوة 1: تثبيت وتشغيل PostgreSQL

1. حمّل PostgreSQL 16 من [postgresql.org](https://www.postgresql.org/download/windows/)
2. ثبّته واحتفظ بكلمة مرور المستخدم `postgres`

### الخطوة 2: إنشاء قاعدة البيانات

```powershell
# افتح psql أو pgAdmin وشغّل:
psql -U postgres
```

```sql
CREATE DATABASE smartjudi;
CREATE USER jood WITH PASSWORD '123456';
GRANT ALL PRIVILEGES ON DATABASE smartjudi TO jood;
ALTER USER jood CREATEDB;
\q
```

### الخطوة 3: إعداد متغيرات البيئة

أنشئ ملف `.env` في مجلد `smartju/`:

```env
# الطريقة الأولى: متغيرات منفصلة
USE_LOCAL_POSTGRES=1
DB_NAME=smartjudi
DB_USER=jood
DB_PASSWORD=123456
DB_HOST=localhost
DB_PORT=5432
```

**أو** استخدم `DATABASE_URL` (طريقة بديلة):

```env
# الطريقة الثانية: رابط واحد
DATABASE_URL=postgres://jood:123456@localhost:5432/smartjudi
```

### الخطوة 4: تطبيق Migrations وتشغيل السيرفر

```powershell
cd smartju
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

### (اختياري) تحميل بيانات أولية

```powershell
# تحميل بيانات المحافظات والمحاكم
python manage.py loaddata ../governorates_courts_final.json

# أو تحميل نسخة احتياطية كاملة
python manage.py loaddata ../data.json
```

---

## 4. الوضع الثالث: Docker Microservices

> هذا الوضع يشغّل كل الخدمات كـ microservices مع قواعد بيانات منفصلة.

### الخطوة 1: إنشاء ملف `.env`

```powershell
cd d:\programapp\smartjudi2-2\microservices
copy .env.example .env
```

عدّل `.env`:

```env
DB_PASSWORD=smartjudi_secret
JWT_SECRET_KEY=django-insecure-4cyci@v!&=khm4+b)(^n@&k0((=5o5=o^r8w&)#4h=wdl)cjx=
INTERNAL_API_KEY=my-internal-key-2025
GROQ_API_KEY=your-groq-api-key-here
EMBEDDING_MODEL_NAME=intfloat/multilingual-e5-small
```

> **مهم:** قيمة `JWT_SECRET_KEY` يجب أن تكون **نفس** `SECRET_KEY` في Django حتى تعمل التوكنات بين الخدمات.

### الخطوة 2: تشغيل كل الخدمات

```powershell
cd d:\programapp\smartjudi2-2\microservices

# بناء وتشغيل
docker compose up --build -d

# مراقبة السجلات
docker compose logs -f
```

### الخطوة 3: تطبيق Migrations لكل خدمة

```powershell
docker compose exec auth    python manage.py migrate
docker compose exec cases   python manage.py migrate
docker compose exec hearings python manage.py migrate
docker compose exec documents python manage.py migrate
docker compose exec legal   python manage.py migrate
docker compose exec notifications python manage.py migrate
docker compose exec search  python manage.py migrate
```

### البنية التحتية

| الخدمة | المنفذ الداخلي | قاعدة البيانات | الوصف |
|--------|---------------|----------------|-------|
| gateway (Nginx) | 80 | — | البوابة الرئيسية |
| auth | 8000 | smartjudi_auth | المصادقة والمستخدمين |
| cases | 8000 | smartjudi_cases | الدعاوى والأطراف |
| hearings | 8000 | smartjudi_hearings | الجلسات |
| documents | 8000 | smartjudi_documents | المرفقات |
| legal | 8000 | smartjudi_legal | القوانين والمحاكم |
| notifications | 8000 | smartjudi_notifications | الإشعارات |
| search | 8000 | smartjudi_search | البحث |
| ai | 8000 | ChromaDB | المساعد الذكي |
| redis | 6379 | — | التخزين المؤقت والأحداث |

### الوصول

- **البوابة:** `http://localhost/api/...` (المنفذ 80)
- **فحص الصحة:** `http://localhost/health/`

---

## 5. تشغيل Local Gateway (البوابة المحلية)

> البوابة المحلية (`local_gateway`) هي بروكسي FastAPI يوزّع الطلبات بين السيرفر المحلي (Monolith) وخدمات السحابة وخدمة المواريث.

### متى تستخدمها؟
- عندما تريد تشغيل **الباك إند (Django) محلياً** مع إضافة خدمة المواريث
- عندما تريد توجيه بعض الطلبات للسحابة (Legal/AI) والباقي محلياً

### خطوات التشغيل

```powershell
cd d:\programapp\smartjudi2-2\microservices\local_gateway

# تثبيت المتطلبات
pip install -r requirements.txt

# تشغيل البوابة (المنفذ 9000)
uvicorn main:app --host 0.0.0.0 --port 9000 --reload
```

### متغيرات البيئة (اختيارية)

```env
# السيرفر المحلي (Django monolith) — الافتراضي http://127.0.0.1:8000
LOCAL_BASE=http://127.0.0.1:8000

# خدمة المواريث المحلية — الافتراضي http://127.0.0.1:8001
INHERITANCE_LOCAL_BASE=http://127.0.0.1:8001

# خدمات السحابة (اتركها فارغة إذا لم تستخدم السحابة)
LEGAL_CLOUD_BASE=
AI_CLOUD_BASE=
```

### كيف يعمل التوجيه

| المسار | الوجهة |
|--------|--------|
| `/api/inheritance/*` | خدمة المواريث (`localhost:8001`) |
| `/api/ai/*` | السحابة (إذا تم تعيين `AI_CLOUD_BASE`) |
| `/api/legal-categories/*`, `/api/laws/*`, إلخ | السحابة (إذا تم تعيين `LEGAL_CLOUD_BASE`) |
| **كل شيء آخر** | Django Monolith (`localhost:8000`) |

### ترتيب التشغيل الصحيح

```
1. شغّل Django:   python manage.py runserver 0.0.0.0:8000   (من smartju/)
2. شغّل المواريث: uvicorn main:app --port 8001              (من services/inheritance/)
3. شغّل البوابة:  uvicorn main:app --port 9000              (من local_gateway/)
```

**Flutter يتصل بـ `http://<IP>:9000`** بدلاً من 8000 مباشرة.

---

## 6. تشغيل خدمة المواريث (Inheritance Service)

> خدمة حساب المواريث — FastAPI مستقلة بدون قاعدة بيانات.

```powershell
cd d:\programapp\smartjudi2-2\microservices\services\inheritance

pip install -r requirements.txt

# تشغيل الخدمة
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

### الاختبار

```powershell
# فحص الصحة
curl http://localhost:8001/health/

# طلب حساب ميراث
curl -X POST http://localhost:8001/api/inheritance/calculate/ `
  -H "Content-Type: application/json" `
  -d '{\"estate_value\": 1000000, \"debts\": 0, \"bequests\": 0, \"heirs\": [{\"type\": \"son\", \"count\": 2}, {\"type\": \"daughter\", \"count\": 1}]}'
```

### متغيرات البيئة (اختيارية)

```env
# تفعيل التحقق من JWT (افتراضياً معطّل)
INHERITANCE_AUTH_REQUIRED=0

# مفتاح JWT (نفس SECRET_KEY في Django)
SECRET_KEY=django-insecure-4cyci@v!&=khm4+b)(^n@&k0((=5o5=o^r8w&)#4h=wdl)cjx=
```

---

## 7. ربط تطبيق Flutter بالسيرفر

### إعدادات API في Flutter

عدّل ملف `lib/config/api_config.dart`:

```dart
// للتطوير المحلي (نفس الجهاز)
static const String baseUrl = 'http://127.0.0.1:9000';

// للاتصال من جهاز Android Emulator
static const String baseUrl = 'http://10.0.2.2:9000';

// للاتصال من هاتف حقيقي على نفس الشبكة
static const String baseUrl = 'http://192.168.x.x:9000';
```

> **نصيحة:** إذا لم تستخدم البوابة المحلية، استبدل `9000` بـ `8000` (Django مباشرة).

### سيناريوهات الاتصال

| السيناريو | عنوان Flutter |
|-----------|--------------|
| بدون بوابة (Django مباشرة) | `http://<IP>:8000` |
| مع بوابة محلية | `http://<IP>:9000` |
| Docker Microservices | `http://<IP>:80` أو `http://<IP>` |

---

## 8. الأوامر المفيدة

### Django

```powershell
# تشغيل السيرفر (يقبل اتصالات من أي IP)
python manage.py runserver 0.0.0.0:8000

# إنشاء migrations بعد تعديل Models
python manage.py makemigrations
python manage.py migrate

# إنشاء مستخدم إداري
python manage.py createsuperuser

# فتح Django Shell
python manage.py shell

# جمع الملفات الثابتة (للنشر)
python manage.py collectstatic --noinput
```

### Docker

```powershell
# تشغيل كل الخدمات
docker compose up --build -d

# إيقاف كل الخدمات
docker compose down

# إيقاف مع حذف قواعد البيانات (تحذير: يحذف كل البيانات!)
docker compose down -v

# مراقبة سجلات خدمة معينة
docker compose logs -f cases

# دخول shell لخدمة
docker compose exec cases python manage.py shell
```

### الحصول على JWT Token (اختبار API)

```powershell
# الحصول على token
curl -X POST http://localhost:8000/api/token/ `
  -H "Content-Type: application/json" `
  -d '{\"username\": \"admin\", \"password\": \"yourpassword\"}'

# استخدام token في طلب
curl http://localhost:8000/api/lawsuits/ `
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

---

## 9. حل المشاكل الشائعة

### ❌ `ModuleNotFoundError: No module named 'django'`
```powershell
# تأكد من تفعيل البيئة الافتراضية
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### ❌ `FATAL: password authentication failed` (PostgreSQL)
```powershell
# تأكد من إعدادات قاعدة البيانات
$env:USE_LOCAL_POSTGRES="1"
$env:DB_NAME="smartjudi"
$env:DB_USER="jood"
$env:DB_PASSWORD="123456"
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
```

### ❌ `Connection refused` من Flutter
1. تأكد أن السيرفر يعمل على `0.0.0.0` وليس `127.0.0.1` فقط
2. تأكد من عنوان IP الصحيح (`ipconfig` في PowerShell)
3. تأكد أن جدار الحماية (Firewall) يسمح بالمنفذ

### ❌ `OperationalError: no such table`
```powershell
cd smartju
python manage.py migrate
```

### ❌ خدمة Docker لا تبدأ
```powershell
docker compose logs <service-name>
# مثال: docker compose logs cases
```

---

## ملخص سريع — أسرع طريقة للبدء

```powershell
# 1. تفعيل البيئة
cd d:\programapp\smartjudi2-2
.\venv\Scripts\Activate.ps1     # أو: python -m venv venv أولاً

# 2. تثبيت المكتبات
pip install -r requirements.txt

# 3. إعداد قاعدة البيانات (SQLite تلقائياً)
cd smartju
python manage.py migrate
python manage.py createsuperuser

# 4. تشغيل السيرفر
python manage.py runserver 0.0.0.0:8000

# ✅ السيرفر جاهز على http://localhost:8000
# ✅ لوحة التحكم: http://localhost:8000/admin/
# ✅ API Docs: http://localhost:8000/swagger/
```
