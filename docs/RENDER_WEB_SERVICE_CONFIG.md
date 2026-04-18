# ⚙️ إعدادات Web Service على Render

## 📋 ملء الحقول في صفحة "New Web Service"

### ✅ الحقول الصحيحة:

#### 1. **Language:**
```
Python 3
```
✅ صحيح - اتركه كما هو

---

#### 2. **Branch:**
```
main
```
✅ صحيح - أو `master` حسب مستودعك

---

#### 3. **Region:**
```
Singapore (Southeast Asia)
```
✅ صحيح - نفس منطقة قاعدة البيانات

---

#### 4. **Root Directory:**
```
(فارغ - اتركه فارغاً)
```
✅ صحيح - المشروع في الجذر

---

#### 5. **Build Command:**
```
./build.sh
```
⚠️ **يجب تغييره من:** `$ pip install -r requirements.txt`  
✅ **إلى:** `./build.sh`

**السبب:** `build.sh` يحتوي على:
- تثبيت الحزم
- جمع static files
- تشغيل migrations

---

#### 6. **Start Command:**
```
cd smartju && gunicorn smartju.wsgi:application --bind 0.0.0.0:$PORT
```
⚠️ **يجب تغييره من:** `$ gunicorn app:app`  
✅ **إلى:** `cd smartju && gunicorn smartju.wsgi:application --bind 0.0.0.0:$PORT`

**السبب:**
- المشروع في مجلد `smartju`
- WSGI module هو `smartju.wsgi:application`
- `$PORT` مطلوب لـ Render

---

## 📝 ملخص التغييرات المطلوبة:

| الحقل | القيمة الحالية | القيمة الصحيحة |
|-------|----------------|-----------------|
| Build Command | `$ pip install -r requirements.txt` | `./build.sh` |
| Start Command | `$ gunicorn app:app` | `cd smartju && gunicorn smartju.wsgi:application --bind 0.0.0.0:$PORT` |

---

## 🎯 الخطوات:

1. **Build Command:** احذف `$ pip install -r requirements.txt` وأدخل `./build.sh`
2. **Start Command:** احذف `$ gunicorn app:app` وأدخل `cd smartju && gunicorn smartju.wsgi:application --bind 0.0.0.0:$PORT`
3. انقر **Create Web Service** أو **Continue**

---

## ⚠️ ملاحظات مهمة:

- **$PORT:** Render يضيف هذا المتغير تلقائياً - لا تحذفه
- **build.sh:** يجب أن يكون قابل للتنفيذ (chmod +x build.sh)
- **gunicorn:** موجود في `requirements.txt`

---

## ✅ بعد إنشاء الخدمة:

1. أضف Environment Variables (راجع `RENDER_DEPLOYMENT_GUIDE.md`)
2. اربط قاعدة البيانات (Add Database)
3. Render سيبدأ النشر تلقائياً

---

**جاهز! قم بتحديث Build Command و Start Command ثم أنشئ الخدمة.** 🚀
