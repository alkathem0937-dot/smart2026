# ✅ خطوات إعداد Render Static Site (تلقائي من GitHub)

## 🎉 تم إعداد Git!

تمت إضافة `build/web` إلى Git بنجاح.

---

## 📋 الخطوات التالية

### 1️⃣ Commit و Push إلى GitHub

```bash
git add .gitignore build/web AUTO_DEPLOY_FLUTTER_WEB.md RENDER_STATIC_SITE_SETUP.md
git commit -m "Add Flutter Web build for Render deployment"
git push origin main
```

**أو في PowerShell:**
```powershell
git add .gitignore build/web AUTO_DEPLOY_FLUTTER_WEB.md RENDER_STATIC_SITE_SETUP.md
git commit -m "Add Flutter Web build for Render deployment"
git push origin main
```

---

### 2️⃣ إعداد Render Static Site

#### في صفحة "New Static Site" على Render:

**املأ الحقول التالية:**

| الحقل | القيمة |
|-------|--------|
| **Name** | `smartjudi-web` |
| **Branch** | `main` |
| **Root Directory** | `build/web` ⚠️ **مهم!** |
| **Build Command** | فارغ (اتركه فارغاً) |
| **Publish Directory** | `/` |

**الشرح:**
- **Root Directory:** `build/web` - هذا يخبر Render أن الملفات الجاهزة موجودة في هذا المجلد
- **Build Command:** فارغ - لأننا بنينا محلياً ودفعنا الملفات
- **Publish Directory:** `/` - لأن الملفات الجاهزة موجودة في `build/web`

---

### 3️⃣ بعد النشر

Render سيسحب الملفات من `build/web` تلقائياً من GitHub!

---

## 🔄 تحديث التطبيق لاحقاً

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

## ✅ Checklist

- [x] تحديث `.gitignore` لإضافة استثناء `build/web`
- [x] إضافة `build/web` إلى Git
- [ ] Commit و Push إلى GitHub
- [ ] إنشاء Static Site على Render
- [ ] إعداد Root Directory: `build/web`
- [ ] إعداد Publish Directory: `/`
- [ ] اختبار URL بعد النشر

---

## 🎉 النتيجة

بعد الإعداد:
- ✅ Render يسحب من GitHub تلقائياً
- ✅ كل push جديد يعيد النشر
- ✅ لا حاجة للرفع اليدوي

---

**جاهز! ادفع إلى GitHub ثم أعد Render.** 🚀
