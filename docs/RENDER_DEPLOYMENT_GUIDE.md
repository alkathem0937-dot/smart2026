# 🚀 دليل رفع SmartJudi2 على Render - حساب جديد

## 📋 فهم الإعداد الحالي

بناءً على فحص الملفات، المشروع كان مرفوع كالتالي:

### الإعدادات المكتشفة:
- **نوع الخدمة:** Web Service (Django)
- **قاعدة البيانات:** PostgreSQL (اسم: `smartjudi`)
- **Python Version:** 3.11.0
- **Build Command:** `./build.sh`
- **Start Command:** `cd smartju && gunicorn smartju.wsgi:application`
- **Settings:** `smartju.settings.production`
- **Static Files:** WhiteNoise
- **Domain:** `smartjudi.onrender.com` (يمكن تغييره)

---

## 🎯 خطوات الرفع على Render (حساب جديد)

### المرحلة 1: إعداد حساب Render الجديد

#### 1.1 إنشاء حساب جديد
1. اذهب إلى: https://render.com/
2. انقر **Sign Up**
3. سجّل بحساب GitHub أو Email
4. أكمل التحقق من البريد الإلكتروني

#### 1.2 ربط GitHub (موصى به)
1. في Render Dashboard، اذهب إلى **Account Settings**
2. **Connect GitHub** (إذا لم يكن مربوطاً)
3. امنح Render صلاحيات الوصول إلى المستودع

---

### المرحلة 2: إنشاء قاعدة البيانات PostgreSQL

#### 2.1 إنشاء Database جديد
1. في Render Dashboard، انقر **New +**
2. اختر **PostgreSQL**
3. املأ التفاصيل:
   - **Name:** `smartjudi` (أو أي اسم تريده)
   - **Database:** `smartjudi`
   - **User:** `smartjudi_user` (أو أي اسم)
   - **Region:** اختر الأقرب (مثلاً: Frankfurt, Germany)
   - **Plan:** Free (للبداية) أو Paid (للإنتاج)
4. انقر **Create Database**

#### 2.2 حفظ معلومات الاتصال
بعد الإنشاء، Render سيعطيك:
- **Internal Database URL** (للخدمات في نفس Render)
- **External Database URL** (للوصول من خارج Render)

**احفظ هذه المعلومات!**

---

### المرحلة 3: رفع المشروع كـ Web Service

#### 3.1 إنشاء Web Service جديد
1. في Render Dashboard، انقر **New +**
2. اختر **Web Service**
3. اختر المستودع:
   - **Connect repository** (إذا لم يكن مربوطاً)
   - أو اختر المستودع من القائمة

#### 3.2 إعدادات الخدمة

**Basic Settings:**
- **Name:** `smartjudi` (أو أي اسم)
- **Region:** نفس منطقة قاعدة البيانات
- **Branch:** `main` (أو `master`)
- **Root Directory:** اتركه فارغاً (المشروع في الجذر)

**Build & Deploy:**
- **Environment:** `Python 3`
- **Build Command:** `./build.sh`
- **Start Command:** `cd smartju && gunicorn smartju.wsgi:application --bind 0.0.0.0:$PORT`

**⚠️ مهم:** Render يستخدم متغير `$PORT` تلقائياً

#### 3.3 Environment Variables

أضف المتغيرات التالية:

**متغيرات Django الأساسية:**
```
DJANGO_SETTINGS_MODULE=smartju.settings.production
SECRET_KEY=your-secret-key-here-generate-random
ALLOWED_HOSTS=smartjudi.onrender.com,your-custom-domain.com
```

**قاعدة البيانات:**
```
DATABASE_URL=postgresql://user:password@host:port/dbname
```
(سيتم ملؤها تلقائياً إذا ربطت Database من Render)

**متغيرات AI Assistant:**
```
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL_NAME=qwen2.5-7b-instruct
RAG_API_URL=https://your-rag-space.hf.space
```

**متغيرات أخرى (اختياري):**
```
PYTHON_VERSION=3.11.0
CORS_ALLOWED_ORIGINS=https://your-flutter-app.com
```

#### 3.4 إنشاء Secret Key

لإنشاء SECRET_KEY آمن:
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

أو استخدم:
```bash
python -c "import secrets; print(secrets.token_urlsafe(50))"
```

---

### المرحلة 4: ربط قاعدة البيانات

#### 4.1 ربط Database بالخدمة
1. في صفحة Web Service، اذهب إلى **Environment**
2. انقر **Add Database**
3. اختر قاعدة البيانات التي أنشأتها (`smartjudi`)
4. Render سيضيف `DATABASE_URL` تلقائياً

#### 4.2 التحقق من الاتصال
بعد الربط، `DATABASE_URL` سيظهر في Environment Variables تلقائياً.

---

### المرحلة 5: النشر الأولي

#### 5.1 بدء النشر
1. بعد حفظ جميع الإعدادات، Render سيبدأ النشر تلقائياً
2. انتظر حتى يكتمل البناء (5-10 دقائق في المرة الأولى)

#### 5.2 مراقبة Logs
- اذهب إلى **Logs** في صفحة الخدمة
- راقب عملية البناء والنشر
- تحقق من عدم وجود أخطاء

#### 5.3 تشغيل Migrations
بعد النشر الأولي، قد تحتاج لتشغيل migrations يدوياً:

**من Render Shell:**
1. في صفحة الخدمة، اذهب إلى **Shell**
2. شغّل:
```bash
cd smartju
python manage.py migrate
python manage.py createsuperuser
```

---

### المرحلة 6: إعداد Static Files

#### 6.1 التحقق من WhiteNoise
المشروع يستخدم WhiteNoise (موجود في `requirements.txt` و `settings/production.py`)

#### 6.2 جمع Static Files
سيتم جمعها تلقائياً في `build.sh`:
```bash
python manage.py collectstatic --no-input
```

---

### المرحلة 7: اختبار الخدمة

#### 7.1 التحقق من Health
بعد النشر، اختبر:
```bash
curl https://smartjudi.onrender.com/
```

يجب أن تحصل على JSON response.

#### 7.2 اختبار API
```bash
curl https://smartjudi.onrender.com/api/token/ \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username": "your_username", "password": "your_password"}'
```

#### 7.3 اختبار AI Assistant
```bash
curl https://smartjudi.onrender.com/api/ai/chat/ \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"query": "مرحبا", "conversation_history": []}'
```

---

## 🔧 استكشاف الأخطاء

### مشكلة: Build Failed
**الحل:**
- تحقق من `build.sh` - يجب أن يكون قابل للتنفيذ
- تحقق من `requirements.txt` - جميع الحزم موجودة
- تحقق من Logs للتفاصيل

### مشكلة: Database Connection Failed
**الحل:**
- تحقق من `DATABASE_URL` في Environment Variables
- تأكد من ربط Database بالخدمة
- تحقق من أن Database يعمل (Status: Available)

### مشكلة: Static Files لا تظهر
**الحل:**
- تحقق من `STATIC_ROOT` في `settings/production.py`
- تأكد من `collectstatic` في `build.sh`
- تحقق من WhiteNoise في `MIDDLEWARE`

### مشكلة: 500 Internal Server Error
**الحل:**
- تحقق من Logs في Render
- تحقق من `SECRET_KEY` موجود
- تحقق من `ALLOWED_HOSTS` يحتوي على domain الخاص بك

---

## 📝 قائمة التحقق النهائية

- [ ] حساب Render جديد تم إنشاؤه
- [ ] قاعدة بيانات PostgreSQL تم إنشاؤها
- [ ] Web Service تم إنشاؤه وربطه بالمستودع
- [ ] Environment Variables تم إضافتها
- [ ] Database تم ربطه بالخدمة
- [ ] النشر الأولي اكتمل بنجاح
- [ ] Migrations تم تشغيلها
- [ ] Superuser تم إنشاؤه
- [ ] API يعمل بشكل صحيح
- [ ] AI Assistant يعمل (بعد إضافة Groq API key)

---

## 🎯 الخطوات السريعة (ملخص)

1. **إنشاء حساب Render** → Sign Up
2. **إنشاء PostgreSQL Database** → New PostgreSQL
3. **إنشاء Web Service** → New Web Service
4. **إعداد Environment Variables** → إضافة جميع المتغيرات
5. **ربط Database** → Add Database
6. **النشر** → Render سيبدأ تلقائياً
7. **تشغيل Migrations** → من Shell
8. **إنشاء Superuser** → من Shell
9. **الاختبار** → curl أو Postman

---

## 📞 ملاحظات مهمة

1. **الخطة المجانية:** محدودة (يغلق بعد 15 دقيقة من عدم الاستخدام)
2. **الخطة المدفوعة:** مستمرة، أفضل للإنتاج
3. **Custom Domain:** يمكن إضافة domain مخصص من Settings
4. **Auto-Deploy:** Render ينشر تلقائياً عند push إلى GitHub

---

## 🔗 روابط مفيدة

- Render Dashboard: https://dashboard.render.com/
- Render Docs: https://render.com/docs
- Django on Render: https://render.com/docs/deploy-django

---

**جاهز للرفع! 🚀**
