# 🔧 إصلاح خطأ "لم يتم تزويد بيانات الدخول"

## ❌ المشكلة

الخطأ: `"detail":"لم يتم تزويد بيانات الدخول."`

**السبب**: `GROQ_API_KEY` غير موجود في ملف `.env`

---

## ✅ الحل

### الطريقة 1: إضافة GROQ_API_KEY (موصى به)

1. **الحصول على API Key من Groq:**
   - اذهب إلى: https://console.groq.com/
   - سجل دخول أو أنشئ حساب
   - اذهب إلى API Keys
   - أنشئ API Key جديد

2. **إضافة إلى ملف `.env`:**
   ```env
   GROQ_API_KEY=gsk_your_actual_api_key_here
   ```

3. **إعادة تشغيل Django:**
   ```bash
   python manage.py runserver
   ```

---

### الطريقة 2: استخدام HuggingFace (بديل مجاني)

إذا لم يكن لديك Groq API Key، يمكن استخدام HuggingFace:

1. **الحصول على HuggingFace API Key:**
   - اذهب إلى: https://huggingface.co/settings/tokens
   - أنشئ token جديد

2. **إضافة إلى ملف `.env`:**
   ```env
   HUGGINGFACE_API_KEY=hf_your_actual_api_key_here
   ```

3. **تعديل الكود لاستخدام HuggingFace كافتراضي:**
   - الكود سيستخدم HuggingFace تلقائياً إذا لم يكن Groq متاحاً

---

### الطريقة 3: استخدام Render Environment Variables

إذا كان التطبيق على Render:

1. اذهب إلى Render Dashboard
2. اختر خدمة Django
3. Settings → Environment Variables
4. أضف:
   ```
   GROQ_API_KEY=gsk_your_actual_api_key_here
   ```
5. إعادة نشر الخدمة

---

## 📋 ملف `.env` الكامل المطلوب

```env
# RAG Engine
RAG_API_URL=https://smartgudi-smartjudi-rag.hf.space

# AI Service (اختر واحد على الأقل)
GROQ_API_KEY=gsk_your_actual_api_key_here
# أو
HUGGINGFACE_API_KEY=hf_your_actual_api_key_here

# Optional
GROQ_MODEL_NAME=llama-3.3-70b-versatile
```

---

## ✅ التحقق من الإصلاح

بعد إضافة API Key:

1. **إعادة تشغيل Django**
2. **اختبار من التطبيق:**
   - أرسل سؤال مثل "ماهي عقوبة السرقة"
   - يجب أن تحصل على إجابة بدلاً من خطأ

---

## 🔍 استكشاف الأخطاء

### إذا استمر الخطأ:

1. **تحقق من API Key:**
   ```bash
   # في Python shell
   import os
   from dotenv import load_dotenv
   load_dotenv()
   print(os.getenv("GROQ_API_KEY"))
   ```

2. **تحقق من السجلات:**
   - ابحث عن "GROQ_API_KEY" في logs
   - تحقق من رسائل الخطأ

3. **اختبار API Key مباشرة:**
   ```python
   import requests
   headers = {"Authorization": f"Bearer {os.getenv('GROQ_API_KEY')}"}
   response = requests.post(
       "https://api.groq.com/openai/v1/chat/completions",
       headers=headers,
       json={"model": "llama-3.3-70b-versatile", "messages": [{"role": "user", "content": "test"}]}
   )
   print(response.status_code)
   ```

---

## 🎯 الخلاصة

**المشكلة**: `GROQ_API_KEY` غير موجود  
**الحل**: أضف `GROQ_API_KEY` إلى `.env` أو استخدم HuggingFace
