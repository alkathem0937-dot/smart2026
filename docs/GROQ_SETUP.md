# 🚀 إعداد Groq Cloud API كبديل لـ Ollama

## ✅ المميزات

- **مجاني:** Groq يوفر API مجاني مع حدود معقولة
- **سريع:** معالجة سريعة جداً (أسرع من Ollama محلياً في معظم الحالات)
- **لا يحتاج تثبيت محلي:** يعمل من السحابة
- **متاح من اليمن:** لا توجد قيود جغرافية
- **يدعم Qwen 2.5:** متوفر نموذج Qwen 2.5-7B-Instruct

---

## 📋 الخطوات

### 1️⃣ الحصول على API Key من Groq

1. اذهب إلى: https://console.groq.com/
2. سجّل حساب جديد (Sign Up) - مجاني
3. بعد تسجيل الدخول، اذهب إلى: **API Keys**
4. انقر **Create API Key**
5. **احفظ المفتاح** - لن تتمكن من رؤيته مرة أخرى!

### 2️⃣ تحديث Django Environment Variables

في Render Dashboard → Django Service → Environment Variables:

```
# استخدم Groq بدلاً من Ollama
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL_NAME=qwen2.5-7b-instruct

# أو استخدم HuggingFace (بديل مجاني أيضاً)
# HUGGINGFACE_API_KEY=your_hf_api_key_here
# HF_MODEL_NAME=Qwen/Qwen2.5-7B-Instruct

# RAG Engine (يبقى كما هو)
RAG_API_URL=https://your-space.hf.space
```

### 3️⃣ تحديث Django Services

**الخيار 1: استخدام Groq (موصى به)**

في `smartju/ai_assistant/views.py`، استبدل:

```python
from .services import AIAssistantService

# بـ
from .services_groq import AIAssistantServiceGroq as AIAssistantService
```

**الخيار 2: استخدام HuggingFace (مجاني تماماً)**

```python
from .services_groq import AIAssistantServiceGroq

# في __init__:
self.ai_assistant_service = AIAssistantServiceGroq(use_groq=False)
```

### 4️⃣ إعادة نشر Django

بعد تحديث Environment Variables، سيتم إعادة نشر Django تلقائياً.

---

## 🔄 البدائل المتاحة

### Groq Cloud (موصى به)
- **المميزات:** سريع جداً، مجاني، يدعم Qwen
- **الحدود:** 30 requests/minute (مجاني)
- **النماذج المتاحة:**
  - `qwen2.5-7b-instruct` ✅
  - `llama-3.1-8b-instruct`
  - `mixtral-8x7b-32768`

### HuggingFace Inference API
- **المميزات:** مجاني تماماً، لا يحتاج API key للاستخدام الأساسي
- **الحدود:** قد يكون أبطأ قليلاً
- **النماذج:** جميع نماذج HuggingFace متاحة

### Together AI
- **المميزات:** مجاني محدود
- **الحدود:** $25 مجاني شهرياً

---

## 🧪 الاختبار

بعد الإعداد، اختبر:

```bash
curl -X POST "https://your-django.onrender.com/api/ai/chat/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"query": "ما هي شروط عقد البيع؟", "conversation_history": []}'
```

---

## 📝 ملاحظات مهمة

1. **Groq مجاني لكن بحدود:** 30 طلب/دقيقة في الخطة المجانية
2. **API Key آمن:** لا تشارك API key مع أحد
3. **الخصوصية:** البيانات تُرسل إلى Groq (مختلف عن Ollama المحلي)
4. **التكلفة:** الخطة المجانية كافية للاستخدام الأساسي

---

## ✅ المزايا مقارنة بـ Ollama المحلي

| الميزة | Ollama المحلي | Groq Cloud |
|--------|---------------|------------|
| التكلفة | مجاني | مجاني |
| السرعة | يعتمد على الجهاز | سريع جداً |
| الخصوصية | 100% محلي | بيانات في السحابة |
| الإعداد | معقد (DNS، ngrok) | سهل (API key فقط) |
| الاعتمادية | يعتمد على اتصالك | موثوق |

---

## 🎯 التوصية

**استخدم Groq Cloud إذا:**
- ✅ تواجه مشاكل في الاتصال (DNS، ngrok)
- ✅ تريد حل سريع وسهل
- ✅ لا تمانع إرسال البيانات إلى السحابة
- ✅ تريد أداء أسرع

**استخدم Ollama المحلي إذا:**
- ✅ تريد خصوصية كاملة
- ✅ لا تريد الاعتماد على خدمات خارجية
- ✅ لديك اتصال إنترنت مستقر

---

**جاهز للبدء! 🚀**
