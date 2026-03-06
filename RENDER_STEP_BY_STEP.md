# 📝 خطوات إكمال إعداد Render - خطوة بخطوة

## 🎯 الهدف
إكمال إعداد SmartJudi2 على Render مع تفعيل AI Assistant

---

## ✅ الخطوة 1: فتح Render Dashboard

1. اذهب إلى: https://dashboard.render.com/
2. سجل دخول بحسابك
3. اختر المشروع: **smartjudi** (Web Service)

---

## ✅ الخطوة 2: إضافة Environment Variables

### 2.1 فتح صفحة Environment Variables

1. في صفحة **Web Service** → **smartjudi**
2. انقر على تبويب **Environment** (في القائمة الجانبية)
3. انقر **Add Environment Variable**

### 2.2 إضافة المتغيرات التالية (واحد تلو الآخر):

#### أ. DJANGO_SETTINGS_MODULE
```
Key: DJANGO_SETTINGS_MODULE
Value: smartju.settings.production
```

#### ب. SECRET_KEY
```
Key: SECRET_KEY
Value: zqbnx@=a!8_ed&guaox$s-!4-c$0f*&5(*#mnmi)ixqae!iv^p
```

#### ج. ALLOWED_HOSTS
```
Key: ALLOWED_HOSTS
Value: smartjudi-nls1.onrender.com,*.onrender.com
```

#### د. GROQ_API_KEY
```
Key: GROQ_API_KEY
Value: your_groq_api_key_here
```

#### ه. GROQ_MODEL_NAME
```
Key: GROQ_MODEL_NAME
Value: qwen2.5-7b-instruct
```

**بعد إضافة كل متغير:**
- انقر **Save Changes**
- كرر العملية لكل متغير

---

## ✅ الخطوة 3: ربط PostgreSQL Database

### 3.1 فتح صفحة Environment

1. في صفحة **Web Service** → **smartjudi**
2. انقر على تبويب **Environment**

### 3.2 ربط Database

1. ابحث عن قسم **Databases** أو **Linked Databases**
2. انقر **Link Database** أو **Add Database**
3. اختر Database: **smartjudi** (من القائمة المنسدلة)
4. انقر **Link** أو **Save**

**النتيجة:**
- سيتم إضافة `DATABASE_URL` تلقائياً في Environment Variables
- لا حاجة لإضافتها يدوياً

---

## ✅ الخطوة 4: إعادة تشغيل الخدمة

بعد إضافة Environment Variables وربط Database:

1. في صفحة **Web Service** → **smartjudi**
2. انقر **Manual Deploy** → **Deploy latest commit**
3. أو انتظر حتى يتم إعادة التشغيل تلقائياً

**راقب Logs:**
- انتظر حتى يكتمل Build
- تأكد من عدم وجود أخطاء

---

## ✅ الخطوة 5: تشغيل Migrations

### 5.1 فتح Shell

1. في صفحة **Web Service** → **smartjudi**
2. انقر على تبويب **Shell** (في القائمة الجانبية)
3. أو انقر **Open Shell** في الأعلى

### 5.2 تشغيل Migrations

في Shell، شغّل:

```bash
cd smartju
python manage.py migrate
```

**النتيجة المتوقعة:**
```
Operations to perform:
  Apply all migrations: ...
Running migrations:
  ...
```

### 5.3 إنشاء Superuser

```bash
python manage.py createsuperuser
```

**أدخل البيانات:**
- Username: (أدخل اسم المستخدم)
- Email: (أدخل البريد الإلكتروني - اختياري)
- Password: (أدخل كلمة المرور)
- Password (again): (أعد إدخال كلمة المرور)

---

## ✅ الخطوة 6: اختبار الخدمة

### 6.1 اختبار Health Check

افتح في المتصفح أو استخدم curl:
```
https://smartjudi-nls1.onrender.com/health/
```

**النتيجة المتوقعة:** `{"status": "ok"}`

### 6.2 اختبار Home Page

```
https://smartjudi-nls1.onrender.com/
```

**النتيجة المتوقعة:** JSON response مع معلومات API

### 6.3 اختبار Admin Panel

```
https://smartjudi-nls1.onrender.com/admin/
```

**سجل دخول** باستخدام بيانات Superuser التي أنشأتها

### 6.4 اختبار AI Assistant (اختياري)

إذا كان لديك Access Token:

```bash
curl -X POST https://smartjudi-nls1.onrender.com/api/ai/chat/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"message": "ما هو القانون اليمني؟"}'
```

---

## ✅ الخطوة 7: التحقق من Logs

1. في صفحة **Web Service** → **smartjudi**
2. انقر على تبويب **Logs**
3. تأكد من:
   - ✅ Build نجح بدون أخطاء
   - ✅ Server بدأ بنجاح
   - ✅ Database متصل
   - ✅ لا توجد أخطاء في AI Assistant

---

## 🎉 تم الإكمال!

بعد إكمال جميع الخطوات:

- ✅ **الخدمة تعمل** على: `https://smartjudi-nls1.onrender.com`
- ✅ **AI Assistant مفعّل** ويعمل مع Groq
- ✅ **Database متصل** وجاهز
- ✅ **Admin Panel متاح** لإدارة البيانات

---

## ⚠️ استكشاف الأخطاء

### مشكلة: "Environment Variable not found"
**الحل:** تأكد من إضافة المتغير في صفحة Environment

### مشكلة: "Database connection failed"
**الحل:** 
- تأكد من ربط Database
- تحقق من `DATABASE_URL` في Environment Variables

### مشكلة: "AI Assistant not working"
**الحل:**
- تحقق من `GROQ_API_KEY` في Environment Variables
- راجع Logs لمعرفة الخطأ الدقيق

### مشكلة: "Migrations failed"
**الحل:**
- تأكد من ربط Database أولاً
- تحقق من `DATABASE_URL` في Environment Variables

---

## 📞 ملاحظات إضافية

1. **SECRET_KEY:** يمكنك استخدام القيمة المذكورة أعلاه أو إنشاء واحدة جديدة
2. **GROQ_API_KEY:** تأكد من أن المفتاح صحيح من https://console.groq.com/
3. **ALLOWED_HOSTS:** إذا غيرت اسم الخدمة، حدث هذا المتغير
4. **DATABASE_URL:** لا تضيفها يدوياً، يتم إضافتها تلقائياً عند ربط Database
