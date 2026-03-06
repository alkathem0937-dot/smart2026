# ⚡ مرجع سريع - Render Setup

## 🔗 الروابط المهمة

- **Render Dashboard:** https://dashboard.render.com/
- **Web Service:** https://dashboard.render.com/web/smartjudi-nls1
- **الخدمة المنشورة:** https://smartjudi-nls1.onrender.com
- **Groq Console:** https://console.groq.com/

---

## 📋 Environment Variables المطلوبة

### مطلوبة (Required):

```bash
DJANGO_SETTINGS_MODULE=smartju.settings.production
SECRET_KEY=6KAcQQIynrVcMXp76_MS76dvZLH6DRxUjWlWkSbqTXcihBfE31V8nf7-FFgKS5YYE6M
ALLOWED_HOSTS=smartjudi-nls1.onrender.com,*.onrender.com
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL_NAME=qwen2.5-7b-instruct
SUPERUSER_USERNAME=admin
SUPERUSER_EMAIL=admin@smartjudi.local
SUPERUSER_PASSWORD=admin123
```

### تلقائية (Auto-added):

```bash
DATABASE_URL=postgresql://...  # يتم إضافتها تلقائياً عند ربط Database
```

### اختيارية (Optional):

```bash
RAG_API_URL=https://your-rag-space.hf.space
CORS_ALLOWED_ORIGINS=https://your-app.com
```

---

## 🚀 الأوامر السريعة

### في Render Shell:

```bash
cd smartju
python manage.py migrate
python manage.py createsuperuser
python manage.py collectstatic --noinput
```

### اختبار API:

```bash
# Health Check
curl https://smartjudi-nls1.onrender.com/health/

# Home Page
curl https://smartjudi-nls1.onrender.com/

# Admin Panel
https://smartjudi-nls1.onrender.com/admin/
```

---

## ✅ Checklist

- [ ] إضافة Environment Variables (8 متغيرات)
- [ ] ربط PostgreSQL Database
- [ ] إعادة تشغيل الخدمة
- [ ] التحقق من Logs (Migrations + Superuser)
- [ ] اختبار Health Check
- [ ] اختبار Admin Panel (admin/admin123)
- [ ] مراجعة Logs للتأكد من عدم وجود أخطاء

---

## 📚 الملفات المرجعية

- **دليل شامل:** `RENDER_COMPLETE_SETUP.md`
- **خطوة بخطوة:** `RENDER_STEP_BY_STEP.md`
- **Environment Variables:** `RENDER_ENV_VARIABLES.txt`
