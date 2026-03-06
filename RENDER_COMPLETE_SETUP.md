# 🚀 دليل إكمال إعداد Render - SmartJudi2

## ✅ الوضع الحالي

- ✅ **الخدمة منشورة على Render:** `https://smartjudi-nls1.onrender.com`
- ✅ **ai_assistant مفعّل** في الكود
- ✅ **المتطلبات محدثة** في `requirements.txt`
- ⏳ **مطلوب:** إضافة Environment Variables وربط Database

---

## 📋 الخطوات المطلوبة

### 1️⃣ إضافة Environment Variables في Render

اذهب إلى: **Render Dashboard** → **smartjudi** (Web Service) → **Environment** → **Add Environment Variable**

#### أ. Django الأساسية (مطلوبة):

```bash
DJANGO_SETTINGS_MODULE=smartju.settings.production
SECRET_KEY=zqbnx@=a!8_ed&guaox$s-!4-c$0f*&5(*#mnmi)ixqae!iv^p
ALLOWED_HOSTS=smartjudi-nls1.onrender.com,*.onrender.com
```

**ملاحظة:** `SECRET_KEY` أعلاه هو مثال. يمكنك استخدام نفس القيمة أو إنشاء واحدة جديدة.

#### ب. AI Assistant - Groq (مطلوبة للـ AI):

```bash
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL_NAME=qwen2.5-7b-instruct
```

**ملاحظة:** 
- استبدل `GROQ_API_KEY` بمفتاحك الحقيقي من: https://console.groq.com/
- إذا لم يكن لديك مفتاح Groq، يمكنك استخدام HuggingFace API بدلاً منه

#### ج. RAG Engine (اختياري - إذا كان لديك RAG على HuggingFace):

```bash
RAG_API_URL=https://your-rag-space.hf.space
```

**ملاحظة:** إذا لم يكن لديك RAG Engine، سيستخدم AI Assistant Groq فقط بدون RAG.

#### د. Superuser (لإنشاء Admin تلقائياً - بدون Shell):

```bash
SUPERUSER_USERNAME=admin
SUPERUSER_EMAIL=admin@smartjudi.local
SUPERUSER_PASSWORD=admin123
```

**ملاحظة:** 
- هذه المتغيرات تستخدم لإنشاء Superuser تلقائياً في `build.sh`
- إذا لم تضيفها، سيتم استخدام القيم الافتراضية
- Superuser يتم إنشاؤه فقط إذا لم يكن موجوداً

#### ه. CORS (اختياري - إذا كان لديك Flutter App):

```bash
CORS_ALLOWED_ORIGINS=https://your-flutter-app.com,https://another-domain.com
```

**ملاحظة:** إذا لم تحدد هذا، سيتم السماح لجميع المصادر (CORS_ALLOW_ALL_ORIGINS = True).

---

### 2️⃣ ربط PostgreSQL Database

1. في صفحة **Web Service** → **Environment**
2. انقر **Add Database** (أو **Link Database**)
3. اختر Database: `smartjudi` (الذي أنشأته مسبقاً)
4. سيتم إضافة `DATABASE_URL` تلقائياً

**التحقق:**
- بعد الربط، تأكد من ظهور `DATABASE_URL` في قائمة Environment Variables
- يجب أن يكون بالشكل: `postgresql://user:password@host:port/dbname`

---

### 3️⃣ تشغيل Migrations وإنشاء Superuser

**ملاحظة:** في الخطة المجانية، Shell غير متوفر. لذلك:

✅ **Migrations تعمل تلقائياً** في `build.sh`
✅ **Superuser يتم إنشاؤه تلقائياً** في `build.sh` باستخدام Environment Variables

**ما يحدث تلقائياً:**
- عند كل Build، يتم تشغيل `python manage.py migrate`
- يتم تشغيل `python manage.py create_superuser_auto --no-input`
- Superuser يتم إنشاؤه فقط إذا لم يكن موجوداً

**للتحقق:**
- راجع **Logs** بعد النشر
- ابحث عن: `✅ Superuser created successfully!`

---

### 4️⃣ اختبار الخدمة

#### أ. Health Check:
```bash
curl https://smartjudi-nls1.onrender.com/health/
```
**النتيجة المتوقعة:** `{"status": "ok"}`

#### ب. Home Page:
```bash
curl https://smartjudi-nls1.onrender.com/
```
**النتيجة المتوقعة:** JSON response مع معلومات API

#### ج. AI Assistant Endpoint:
```bash
curl -X POST https://smartjudi-nls1.onrender.com/api/ai/chat/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"message": "ما هو القانون اليمني؟"}'
```

#### د. Admin Panel:
افتح في المتصفح:
```
https://smartjudi-nls1.onrender.com/admin/
```
سجل دخول باستخدام بيانات Superuser التي أنشأتها.

---

## 🔍 التحقق من Logs

في Render Dashboard → **Logs**، تأكد من:

1. ✅ **Build نجح** بدون أخطاء
2. ✅ **Server بدأ** بنجاح
3. ✅ **Database متصل** (لا توجد أخطاء connection)
4. ✅ **AI Assistant جاهز** (إذا كان `GROQ_API_KEY` مضاف)

---

## ⚠️ استكشاف الأخطاء

### مشكلة: "ModuleNotFoundError"
**الحل:** تأكد من أن `requirements.txt` يحتوي على جميع المتطلبات

### مشكلة: "Database connection failed"
**الحل:** 
- تأكد من ربط Database في Environment
- تحقق من `DATABASE_URL` في Environment Variables

### مشكلة: "AI Assistant not working"
**الحل:**
- تأكد من إضافة `GROQ_API_KEY`
- تحقق من Logs لمعرفة الخطأ الدقيق

### مشكلة: "CORS error"
**الحل:**
- أضف `CORS_ALLOWED_ORIGINS` مع URL الخاص بتطبيق Flutter

---

## 📝 ملخص Environment Variables الكاملة

```bash
# Django
DJANGO_SETTINGS_MODULE=smartju.settings.production
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=smartjudi-nls1.onrender.com,*.onrender.com

# Database (يتم إضافتها تلقائياً عند الربط)
DATABASE_URL=postgresql://...

# AI Assistant - Groq
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL_NAME=qwen2.5-7b-instruct

# Superuser (لإنشاء Admin تلقائياً - بدون Shell)
SUPERUSER_USERNAME=admin
SUPERUSER_EMAIL=admin@smartjudi.local
SUPERUSER_PASSWORD=admin123

# RAG Engine (اختياري)
RAG_API_URL=https://your-rag-space.hf.space

# CORS (اختياري)
CORS_ALLOWED_ORIGINS=https://your-app.com
```

---

## ✅ Checklist النهائي

- [ ] إضافة Environment Variables (Django, Groq)
- [ ] ربط PostgreSQL Database
- [ ] تشغيل Migrations
- [ ] إنشاء Superuser
- [ ] اختبار Health Check
- [ ] اختبار Home Page
- [ ] اختبار AI Assistant Endpoint
- [ ] اختبار Admin Panel
- [ ] مراجعة Logs للتأكد من عدم وجود أخطاء

---

## 🎉 بعد الإكمال

بعد إكمال جميع الخطوات:

1. **الخدمة جاهزة للاستخدام** على: `https://smartjudi-nls1.onrender.com`
2. **AI Assistant يعمل** مع Groq API
3. **Database متصل** وجاهز
4. **Admin Panel متاح** لإدارة البيانات

---

## 📞 الدعم

إذا واجهت أي مشاكل:
1. راجع **Logs** في Render Dashboard
2. تحقق من **Environment Variables**
3. تأكد من أن جميع **المتطلبات مثبتة** في `requirements.txt`
