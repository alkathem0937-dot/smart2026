# 🚀 نشر Flutter Web على Render

## 📋 الوضع الحالي

- ✅ **Django Backend:** موجود على Render (`https://smartjudi-nls1.onrender.com/`)
- ⏳ **Flutter Web:** يحتاج إلى النشر على Render

---

## 🎯 الحل: نشر Flutter Web كـ Static Site على Render

Render يدعم نشر Static Sites (مثل Flutter Web) مجاناً!

---

## 📝 الخطوات

### 1️⃣ بناء Flutter Web محلياً

```bash
# تأكد من أنك في مجلد المشروع
cd E:\smartjudi2

# نظف البناء السابق
flutter clean

# احصل على dependencies
flutter pub get

# ابني للويب
flutter build web --release
```

**النتيجة:** سيتم إنشاء مجلد `build/web` يحتوي على الملفات الجاهزة للنشر.

---

### 2️⃣ إنشاء Static Site على Render

#### في Render Dashboard:

1. **انقر "New +"**
2. **اختر "Static Site"**
3. **اربط GitHub Repository:**
   - اختر المستودع `smartjudi2`
   - أو ارفع الملفات يدوياً

#### الإعدادات:

**Basic Settings:**
- **Name:** `smartjudi-web` (أو أي اسم)
- **Branch:** `main` (أو `master`)
- **Root Directory:** `build/web` (مهم جداً!)

**Build Settings:**
- **Build Command:** `flutter build web --release`
- **Publish Directory:** `build/web`

**⚠️ مهم:** إذا كنت ترفع الملفات يدوياً، ارفع محتويات `build/web` فقط.

---

### 3️⃣ إعداد Environment Variables (اختياري)

إذا كنت تريد استخدام متغيرات بيئية:

- **API_URL:** `https://smartjudi-nls1.onrender.com`
- **ENVIRONMENT:** `production`

---

### 4️⃣ تحديث API Config في Flutter

تأكد من أن `lib/config/api_config.dart` يحتوي على:

```dart
static const String baseUrl = 'https://smartjudi-nls1.onrender.com';
```

✅ **هذا موجود بالفعل!**

---

### 5️⃣ إعداد CORS في Django

تأكد من أن Django يسمح بطلبات من Flutter Web domain.

في `smartju/smartju/settings/production.py`:

```python
CORS_ALLOWED_ORIGINS = [
    "https://smartjudi-web.onrender.com",  # Flutter Web URL
    "https://your-custom-domain.com",      # إذا كان لديك domain مخصص
]

# أو للسماح بجميع Render domains:
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^https://.*\.onrender\.com$",
]
```

---

## 🔄 الطريقة البديلة: استخدام Render.yaml

يمكنك إضافة Static Site في `render.yaml`:

```yaml
services:
  # Django Backend (موجود)
  - type: web
    name: smartjudi
    env: python
    buildCommand: "./build.sh"
    startCommand: "cd smartju && gunicorn smartju.wsgi:application --bind 0.0.0.0:$PORT"
    # ... باقي الإعدادات

  # Flutter Web (جديد)
  - type: web
    name: smartjudi-web
    env: static
    buildCommand: "flutter build web --release"
    staticPublishPath: build/web
```

**⚠️ ملاحظة:** Render قد لا يدعم Flutter build مباشرة. الأفضل هو:
1. بناء محلياً
2. رفع `build/web` كـ Static Site

---

## ✅ الطريقة الموصى بها (الأسهل)

### الخيار 1: رفع يدوي (سريع)

1. **ابني محلياً:**
   ```bash
   flutter build web --release
   ```

2. **في Render Dashboard:**
   - New + → Static Site
   - اختر "Upload files"
   - ارفع محتويات `build/web`
   - Publish Directory: `/` (الجذر)

3. **احصل على URL:**
   - Render سيعطيك URL مثل: `https://smartjudi-web.onrender.com`

---

### الخيار 2: من GitHub (أفضل للـ CI/CD)

1. **ابني محلياً:**
   ```bash
   flutter build web --release
   ```

2. **ادفع `build/web` إلى GitHub:**
   ```bash
   git add build/web
   git commit -m "Add Flutter Web build"
   git push
   ```

3. **في Render:**
   - New + → Static Site
   - اختر GitHub repository
   - Root Directory: `build/web`
   - Publish Directory: `build/web`

---

## 🔧 تحديث CORS في Django

بعد نشر Flutter Web، تأكد من تحديث CORS:

```python
# في smartju/smartju/settings/production.py

CORS_ALLOWED_ORIGINS = [
    "https://smartjudi-nls1.onrender.com",  # Backend نفسه
    "https://smartjudi-web.onrender.com",  # Flutter Web
]

# أو للسماح بجميع Render domains:
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^https://.*\.onrender\.com$",
]
```

---

## 📋 Checklist

- [ ] بناء Flutter Web محلياً (`flutter build web --release`)
- [ ] إنشاء Static Site على Render
- [ ] رفع ملفات `build/web`
- [ ] تحديث CORS في Django
- [ ] اختبار Flutter Web URL
- [ ] اختبار الاتصال مع Django API

---

## 🎉 النتيجة

بعد النشر:
- ✅ Flutter Web: `https://smartjudi-web.onrender.com`
- ✅ Django API: `https://smartjudi-nls1.onrender.com`
- ✅ كل شيء يعمل معاً!

---

## 🆘 إذا واجهت مشاكل

### مشكلة: "Build failed"
- تأكد من أن Flutter مثبت على الجهاز
- أو استخدم طريقة الرفع اليدوي

### مشكلة: "CORS error"
- تأكد من تحديث `CORS_ALLOWED_ORIGINS` في Django
- أعد تشغيل Django service

### مشكلة: "404 on routes"
- تأكد من أن `web/index.html` يحتوي على `<base href="/">`
- أو استخدم hash routing

---

**تم الإعداد:** 2026-03-13
