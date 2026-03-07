# 🔄 إعادة نشر Render Service يدوياً

## المشكلة

Render لا يزال يستخدم الكود القديم الذي يحتوي على `qwen2.5-7b-instruct` رغم أن:
- ✅ `GROQ_MODEL_NAME` مضبوط على `llama-3.1-8b-instruct` في Environment Variables
- ✅ الكود محدث في Git

## الحل: إعادة نشر يدوي

### الطريقة 1: من Render Dashboard (موصى به)

1. اذهب إلى Render Dashboard: https://dashboard.render.com/
2. اختر خدمة: **smartjudi** (Web Service)
3. اذهب إلى **Settings** (في القائمة الجانبية)
4. ابحث عن قسم **Manual Deploy**
5. انقر **Clear build cache & deploy**
6. انتظر حتى يكتمل النشر (2-5 دقائق)

### الطريقة 2: من Git (بديل)

إذا لم تنجح الطريقة الأولى:

1. قم بعمل تغيير بسيط في أي ملف (مثلاً إضافة سطر فارغ)
2. Commit و Push:
   ```bash
   git commit --allow-empty -m "Trigger Render redeploy"
   git push origin main
   ```
3. Render سيعيد النشر تلقائياً

---

## التحقق من النشر

بعد إعادة النشر:

1. اذهب إلى **Logs** في Render
2. ابحث عن:
   - ✅ `Using Groq Cloud API for AI Assistant`
   - ✅ `Model: llama-3.1-8b-instruct` (في طلبات Groq)
   - ❌ لا يجب أن ترى `qwen2.5-7b-instruct` في الأخطاء

---

## ملاحظات

- إعادة النشر قد تستغرق 2-5 دقائق
- بعد النشر، اختبر من Flutter App
- إذا استمرت المشكلة، تحقق من أن `GROQ_MODEL_NAME` موجود في Environment Variables
