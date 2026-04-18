# ⚡ نشر Flutter Web على Render - دليل سريع

## 🎯 الهدف

نشر Flutter Web على Render كـ Static Site بدلاً من استخدام سيرفر محلي.

---

## ✅ الخطوات السريعة (5 دقائق)

### 1️⃣ بناء Flutter Web

**على Windows:**
```powershell
.\build_flutter_web.ps1
```

**على Linux/Mac:**
```bash
chmod +x build_flutter_web.sh
./build_flutter_web.sh
```

**أو يدوياً:**
```bash
flutter clean
flutter pub get
flutter build web --release
```

**النتيجة:** ملفات جاهزة في `build/web/`

---

### 2️⃣ إنشاء Static Site على Render

1. **اذهب إلى Render Dashboard:**
   - https://dashboard.render.com/

2. **انقر "New +" → "Static Site"**

3. **اختر طريقة الرفع:**

   **الخيار A: رفع يدوي (الأسرع)**
   - اختر **"Upload files"**
   - ارفع **جميع محتويات** مجلد `build/web`
   - **Publish Directory:** `/` (الجذر)

   **الخيار B: من GitHub (أفضل للـ CI/CD)**
   - اختر **GitHub repository**
   - **Root Directory:** `build/web`
   - **Publish Directory:** `build/web`
   - ⚠️ **مهم:** يجب أن تدفع `build/web` إلى GitHub أولاً

---

### 3️⃣ إعداد CORS في Django

**في Render Dashboard → Django Service → Environment:**

أضف متغير بيئي جديد:

```
CORS_ALLOWED_ORIGINS=https://smartjudi-web.onrender.com,https://smartjudi-nls1.onrender.com
```

**أو اتركه فارغاً** للسماح بجميع Render domains (تم إعداده بالفعل).

---

### 4️⃣ احصل على URL

بعد النشر، Render سيعطيك URL مثل:
```
https://smartjudi-web.onrender.com
```

---

## ✅ التحقق من النشر

1. **افتح Flutter Web URL:**
   ```
   https://smartjudi-web.onrender.com
   ```

2. **يجب أن ترى:**
   - ✅ صفحة تسجيل الدخول
   - ✅ التصميم يعمل بشكل صحيح
   - ✅ الاتصال مع Django API يعمل

3. **اختبر تسجيل الدخول:**
   - جرب تسجيل الدخول
   - تأكد من أن API calls تعمل

---

## 🔧 تحديث API Config (إذا لزم الأمر)

تأكد من أن `lib/config/api_config.dart` يحتوي على:

```dart
static const String baseUrl = 'https://smartjudi-nls1.onrender.com';
```

✅ **هذا موجود بالفعل!**

---

## 📋 Checklist

- [ ] بناء Flutter Web (`flutter build web --release`)
- [ ] إنشاء Static Site على Render
- [ ] رفع ملفات `build/web`
- [ ] تحديث CORS في Django (اختياري)
- [ ] اختبار Flutter Web URL
- [ ] اختبار تسجيل الدخول

---

## 🎉 النتيجة

بعد النشر:
- ✅ **Flutter Web:** `https://smartjudi-web.onrender.com`
- ✅ **Django API:** `https://smartjudi-nls1.onrender.com`
- ✅ **كل شيء يعمل معاً!**

---

## 🆘 حل المشاكل

### مشكلة: "Build failed"
- تأكد من أن Flutter مثبت
- جرب `flutter doctor` للتحقق

### مشكلة: "CORS error"
- تأكد من تحديث `CORS_ALLOWED_ORIGINS` في Django
- أعد تشغيل Django service

### مشكلة: "404 on routes"
- تأكد من أن `web/index.html` يحتوي على `<base href="/">`
- أو استخدم hash routing

---

## 📝 ملاحظات

- ✅ Render Static Sites **مجانية** للبدء
- ✅ يمكنك ربط domain مخصص لاحقاً
- ✅ يمكنك إضافة SSL تلقائياً

---

**تم الإعداد:** 2026-03-13
