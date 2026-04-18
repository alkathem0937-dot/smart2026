# ⚡ دليل سريع - رفع SmartJudi2 على Render

## 🎯 الخطوات السريعة (5 دقائق)

### 1️⃣ إنشاء حساب Render
- اذهب إلى: https://render.com/
- Sign Up بحساب GitHub أو Email

### 2️⃣ إنشاء PostgreSQL Database
```
New + → PostgreSQL
Name: smartjudi
Database: smartjudi
Plan: Free (للبداية)
```

### 3️⃣ إنشاء Web Service
```
New + → Web Service
Repository: اختر مستودع GitHub
```

**الإعدادات:**
- **Name:** `smartjudi`
- **Environment:** `Python 3`
- **Build Command:** `./build.sh`
- **Start Command:** `cd smartju && gunicorn smartju.wsgi:application --bind 0.0.0.0:$PORT`

### 4️⃣ Environment Variables

**أضف هذه المتغيرات:**

```bash
# Django Settings
DJANGO_SETTINGS_MODULE=smartju.settings.production
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=smartjudi.onrender.com

# Database (سيتم إضافتها تلقائياً عند ربط Database)
DATABASE_URL=postgresql://...

# AI Assistant
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL_NAME=qwen2.5-7b-instruct
RAG_API_URL=https://your-rag-space.hf.space
```

**لإنشاء SECRET_KEY:**
```bash
python scripts/generate_secret_key.py
```

### 5️⃣ ربط Database
- في صفحة Web Service → **Environment**
- **Add Database** → اختر `smartjudi`
- سيتم إضافة `DATABASE_URL` تلقائياً

### 6️⃣ النشر
- Render سيبدأ النشر تلقائياً
- انتظر 5-10 دقائق
- راقب Logs

### 7️⃣ تشغيل Migrations
- في صفحة الخدمة → **Shell**
```bash
cd smartju
python manage.py migrate
python manage.py createsuperuser
```

---

## ✅ التحقق من النشر

```bash
# اختبار Health
curl https://smartjudi.onrender.com/

# اختبار API
curl https://smartjudi.onrender.com/api/token/ \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password"}'
```

---

## 📋 قائمة التحقق

- [ ] حساب Render تم إنشاؤه
- [ ] Database تم إنشاؤه
- [ ] Web Service تم إنشاؤه
- [ ] Environment Variables تم إضافتها
- [ ] Database تم ربطه
- [ ] النشر اكتمل
- [ ] Migrations تم تشغيلها
- [ ] Superuser تم إنشاؤه

---

## 🔗 روابط مفيدة

- **Render Dashboard:** https://dashboard.render.com/
- **الدليل الكامل:** راجع `RENDER_DEPLOYMENT_GUIDE.md`

---

**جاهز! 🚀**
