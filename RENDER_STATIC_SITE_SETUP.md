# ⚙️ إعداد Static Site على Render - Flutter Web

## 📋 الحقول المطلوبة في صفحة "New Static Site"

### ✅ الحقول الصحيحة:

#### 1. **Name:**
```
smartjudi-web
```
✅ **صحيح** - اتركه كما هو

---

#### 2. **Branch:**
```
main
```
✅ **صحيح** - اتركه كما هو

---

#### 3. **Root Directory:**
```
build/web
```
⚠️ **يجب تغييره** - اكتب `build/web`

**السبب:** هذا هو المجلد الذي يحتوي على ملفات Flutter Web المبنية.

---

#### 4. **Build Command:**
```
flutter build web --release
```
⚠️ **يجب تغييره** من `$ pip install -r requirements.txt` إلى `flutter build web --release`

**⚠️ تحذير:** Render قد لا يدعم بناء Flutter مباشرة (لأنه يحتاج Flutter SDK).

**الحل الأفضل:** ارفع الملفات يدوياً (انظر الخيار البديل أدناه)

---

#### 5. **Publish Directory:**
```
build/web
```
⚠️ **يجب ملؤه** - اكتب `build/web`

**أو:**
```
/
```
إذا كنت ترفع الملفات يدوياً (الخيار الأفضل)

---

## 🎯 الخيار الأفضل: رفع يدوي

بما أن Render قد لا يدعم بناء Flutter مباشرة، الأفضل هو:

### الطريقة 1: رفع يدوي (موصى به) ⭐

1. **في صفحة "New Static Site":**
   - **Root Directory:** اتركه فارغاً
   - **Build Command:** اتركه فارغاً أو احذفه
   - **Publish Directory:** `/` (الجذر)

2. **بعد إنشاء Static Site:**
   - اذهب إلى Static Site
   - انقر على **"Manual Deploy"** أو **"Upload files"**
   - ارفع **جميع محتويات** مجلد `E:\smartjudi2\build\web`

---

### الطريقة 2: من GitHub (إذا كان `build/web` في Git)

1. **تأكد من أن `build/web` موجود في GitHub:**
   ```bash
   git add build/web
   git commit -m "Add Flutter Web build"
   git push
   ```

2. **في Render:**
   - **Root Directory:** `build/web`
   - **Build Command:** اتركه فارغاً
   - **Publish Directory:** `/` أو `build/web`

---

## 📝 ملخص الإعدادات الموصى بها

| الحقل | القيمة |
|-------|--------|
| **Name** | `smartjudi-web` |
| **Branch** | `main` |
| **Root Directory** | فارغ (للرفع اليدوي) أو `build/web` (من GitHub) |
| **Build Command** | فارغ (للرفع اليدوي) |
| **Publish Directory** | `/` |

---

## ✅ الخطوات السريعة

### للرفع اليدوي (الأسهل):

1. **Root Directory:** اتركه فارغاً
2. **Build Command:** احذف `$ pip install -r requirements.txt` واتركه فارغاً
3. **Publish Directory:** اكتب `/`
4. انقر **"Create Static Site"**
5. بعد الإنشاء، ارفع ملفات `build/web` يدوياً

---

## 🎉 بعد النشر

Render سيعطيك URL مثل:
```
https://smartjudi-web.onrender.com
```

---

**جاهز! املأ الحقول كما هو موضح أعلاه.** 🚀
