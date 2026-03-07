# 🧪 دليل اختبار AI Assistant

## 📋 المتطلبات

### 1. Groq API Key

للحصول على Groq API Key:

1. اذهب إلى: https://console.groq.com/
2. سجّل حساب جديد (مجاني)
3. بعد تسجيل الدخول، اذهب إلى: **API Keys**
4. انقر **Create API Key**
5. **احفظ المفتاح** - لن تتمكن من رؤيته مرة أخرى!

### 2. إضافة API Key محلياً

#### الطريقة 1: استخدام ملف `.env`

1. انسخ `.env.example` إلى `.env`:
   ```bash
   copy .env.example .env
   ```

2. افتح `.env` وأضف API Key:
   ```
   GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   GROQ_MODEL_NAME=qwen2.5-7b-instruct
   ```

#### الطريقة 2: استخدام Environment Variables

في PowerShell:
```powershell
$env:GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$env:GROQ_MODEL_NAME="qwen2.5-7b-instruct"
```

في CMD:
```cmd
set GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
set GROQ_MODEL_NAME=qwen2.5-7b-instruct
```

---

## 🧪 تشغيل الاختبار

### الطريقة السريعة:

```bash
scripts\test_ai_assistant_quick.bat
```

### الطريقة اليدوية:

```bash
python scripts\test_ai_assistant.py
```

---

## 📊 ما يختبره السكربت

### ✅ اختبار 1: Groq API مباشرة
- يختبر الاتصال بـ Groq API مباشرة
- يرسل سؤال قانوني ويحصل على استجابة

### ✅ اختبار 2: Render Health Check
- يتحقق من أن Render Service يعمل
- يختبر endpoint `/health/`

### ✅ اختبار 3: AI Assistant على Render
- يحصل على JWT token من Render
- يرسل طلب إلى `/api/ai/chat/`
- يتحقق من الاستجابة

### ✅ اختبار 4: AI Assistant محلياً
- يختبر AI Assistant باستخدام Django محلياً
- يتطلب Django running و GROQ_API_KEY

---

## 🔧 استكشاف الأخطاء

### ❌ "GROQ_API_KEY غير موجود"

**الحل:**
1. تأكد من إضافة GROQ_API_KEY إلى `.env` أو environment variables
2. تحقق من أن المفتاح صحيح (يبدأ بـ `gsk_`)

### ❌ "Render Service غير متاح"

**الحل:**
1. تحقق من أن Render Service يعمل:
   - اذهب إلى Render Dashboard
   - تحقق من حالة الخدمة (يجب أن تكون "Live")
2. تحقق من الاتصال بالإنترنت
3. قد تكون الخدمة متوقفة (Free Plan يتوقف بعد 15 دقيقة من عدم الاستخدام)

### ❌ "RAG_API_URL environment variable not set"

**الحل:**
- هذا ليس خطأ! RAG اختياري
- AI Assistant يعمل بدون RAG (لكن بدون سياق من المستندات)
- إذا أردت استخدام RAG، أضف `RAG_API_URL` إلى `.env`

---

## ✅ بعد نجاح الاختبار

### 1. إضافة GROQ_API_KEY إلى Render

1. اذهب إلى Render Dashboard
2. اختر خدمة Django
3. اذهب إلى **Environment** → **Add Environment Variable**
4. أضف:
   ```
   Key: GROQ_API_KEY
   Value: gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
5. أضف أيضاً:
   ```
   Key: GROQ_MODEL_NAME
   Value: qwen2.5-7b-instruct
   ```
6. احفظ - Render سيبدأ إعادة النشر تلقائياً

### 2. التحقق من Render Logs

بعد إعادة النشر (2-5 دقائق):
1. اذهب إلى **Logs** في Render
2. ابحث عن رسالة: `Using Groq Cloud API for AI Assistant`
3. إذا ظهرت هذه الرسالة، فالإعداد صحيح! ✅

### 3. اختبار من Flutter App

1. افتح Flutter App
2. سجّل الدخول
3. اذهب إلى "المساعد الذكي"
4. اكتب سؤال قانوني واختبر الاستجابة

---

## 📝 ملاحظات

- **الأمان:** لا ترفع `.env` إلى GitHub
- **المفتاح:** احفظ GROQ_API_KEY في مكان آمن
- **الحدود:** Groq Free Plan له حدود معقولة (30 requests/minute)
- **RAG:** RAG اختياري - AI Assistant يعمل بدون RAG لكن بجودة أقل

---

## 🎯 الخطوات التالية

بعد نجاح الاختبار:

1. ✅ إضافة GROQ_API_KEY إلى Render
2. ✅ اختبار من Flutter App
3. ✅ إعداد RAG Engine (اختياري)
4. ✅ اختبار شامل للنظام
