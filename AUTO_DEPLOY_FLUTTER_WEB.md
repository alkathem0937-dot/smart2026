# 🚀 نشر Flutter Web تلقائياً على Render (من GitHub)

## 🎯 الهدف

نشر Flutter Web تلقائياً من GitHub بدون رفع يدوي.

---

## ⚠️ المشكلة

Render **لا يدعم بناء Flutter مباشرة** لأنه يحتاج Flutter SDK.

**الحل:** نبني محلياً، ندفع `build/web` إلى GitHub، ثم Render يسحب الملفات تلقائياً.

---

## 📋 الخطوات

### 1️⃣ إضافة `build/web` إلى Git

**تحقق من `.gitignore`:**
```bash
# تأكد من أن build/web غير موجود في .gitignore
```

إذا كان `build/web` في `.gitignore`، احذفه أو أضف استثناء:
```
# في .gitignore
build/
!build/web/
```

---

### 2️⃣ دفع `build/web` إلى GitHub

```bash
# أضف build/web
git add build/web

# Commit
git commit -m "Add Flutter Web build for Render deployment"

# Push
git push origin main
```

---

### 3️⃣ إعداد Render Static Site

#### في صفحة "New Static Site":

**الحقول:**

| الحقل | القيمة |
|-------|--------|
| **Name** | `smartjudi-web` |
| **Branch** | `main` |
| **Root Directory** | `build/web` ⚠️ |
| **Build Command** | فارغ (اتركه فارغاً) |
| **Publish Directory** | `/` أو `build/web` |

**الشرح:**
- **Root Directory:** `build/web` - هذا يخبر Render أن الملفات الجاهزة موجودة في هذا المجلد
- **Build Command:** فارغ - لأننا بنينا محلياً
- **Publish Directory:** `/` - لأن الملفات الجاهزة موجودة في `build/web`

---

### 4️⃣ بعد النشر

Render سيسحب الملفات من `build/web` تلقائياً!

---

## 🔄 تحديث التطبيق (عند التغييرات)

عندما تحدث التطبيق:

1. **ابني محلياً:**
   ```bash
   flutter build web --release
   ```

2. **ادفع إلى GitHub:**
   ```bash
   git add build/web
   git commit -m "Update Flutter Web build"
   git push origin main
   ```

3. **Render سيعيد النشر تلقائياً!** ✅

---

## 📝 ملاحظات

- ✅ **تلقائي:** كل push جديد يعيد النشر تلقائياً
- ✅ **لا رفع يدوي:** كل شيء من GitHub
- ⚠️ **يجب البناء محلياً:** لأن Render لا يدعم Flutter SDK

---

## 🎉 النتيجة

بعد الإعداد:
- ✅ Render يسحب من GitHub تلقائياً
- ✅ كل push جديد يعيد النشر
- ✅ لا حاجة للرفع اليدوي

---

**جاهز! اتبع الخطوات أعلاه.** 🚀
