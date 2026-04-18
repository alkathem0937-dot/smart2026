# دليل إعداد المساعد الذكي - SmartJudi2 AI Assistant Setup Guide

## ✅ ما تم إنجازه

تم إنشاء جميع الملفات المطلوبة للمساعد الذكي:

### Django Backend
- ✅ تطبيق `ai_assistant` كامل مع services, views, serializers, urls
- ✅ تحديث `settings.py` و `urls.py`
- ✅ إضافة `requests` إلى `requirements.txt`

### Flutter Frontend
- ✅ `AIApiService` للتواصل مع API
- ✅ `AIChatProvider` لإدارة حالة الدردشة
- ✅ تحديث `smart_assistant_screen.dart` و `ai_case_analysis_screen.dart`
- ✅ تحديث `main.dart` و `api_config.dart`

### RAG Engine
- ✅ ملفات Hugging Face Space (`rag_engine/`)

### Scripts
- ✅ `load_legal_data.py` لرفع المستندات
- ✅ `Modelfile` لـ Ollama

---

## 📋 الخطوات التالية (Next Steps)

### 1️⃣ إعداد Ollama على الجهاز المحلي

#### أ. تثبيت Ollama
```bash
# Windows: قم بتحميل المثبت من https://ollama.ai/download
# أو استخدم Chocolatey:
choco install ollama

# Linux/Mac: اتبع التعليمات من الموقع الرسمي
```

#### ب. تحميل نموذج Qwen
```bash
ollama pull qwen:7b-chat
# أو للحصول على نموذج أكبر (إذا كان لديك ذاكرة كافية):
ollama pull qwen:14b-chat
```

#### ج. إنشاء نموذج مخصص للقانون اليمني
```bash
# انتقل إلى مجلد scripts
cd scripts

# إنشاء النموذج المخصص
ollama create smartjudi-qwen -f Modelfile

# اختبار النموذج
ollama run smartjudi-qwen "ما هي شروط عقد البيع في القانون اليمني؟"
```

#### د. تكوين Ollama للوصول عبر الشبكة

**Windows (Command Prompt):**
```cmd
setx OLLAMA_HOST "0.0.0.0:11434"
```
ثم أعد تشغيل Ollama أو أعد تشغيل الكمبيوتر.

**Linux/macOS:**
```bash
# أضف إلى ~/.bashrc أو ~/.zshrc
export OLLAMA_HOST="0.0.0.0:11434"
source ~/.bashrc  # أو source ~/.zshrc
```

#### هـ. تعريض Ollama للإنترنت (لوصول Django من Render)

**الخيار 1: ngrok (أسهل للاختبار)**
```bash
# تثبيت ngrok من https://ngrok.com/download
# الحصول على auth token من الموقع

ngrok authtoken YOUR_NGROK_TOKEN
ngrok http 11434

# سيتم إعطاؤك رابط مثل: https://xxxx-xxxx-xxxx.ngrok-free.app
# استخدم هذا الرابط كـ OLLAMA_API_URL
```

**الخيار 2: Cloudflare Tunnel (للاستخدام الدائم)**
```bash
# تثبيت cloudflared
# إنشاء tunnel
cloudflared tunnel create smartjudi-ollama

# إعداد config.yml في ~/.cloudflared/config.yml
# تشغيل tunnel
cloudflared tunnel run smartjudi-ollama
```

---

### 2️⃣ نشر RAG Engine على Hugging Face Spaces

#### أ. إنشاء Space جديد
1. اذهب إلى https://huggingface.co/spaces
2. انقر على "Create new Space"
3. اختر:
   - **SDK**: Docker
   - **Name**: smartjudi-rag-engine (أو أي اسم تريده)
   - **Visibility**: Public أو Private

#### ب. رفع الملفات
قم برفع جميع الملفات من مجلد `rag_engine/`:
- `Dockerfile`
- `requirements.txt`
- `main.py`
- `.env` (أنشئه يدوياً في Space)

**ملاحظة:** في Hugging Face Spaces، يمكنك إضافة متغيرات البيئة من Settings → Variables and secrets

#### ج. إعداد متغيرات البيئة في Space
في Settings → Variables and secrets:
```
EMBEDDING_MODEL_NAME=sentence-transformers/multilingual-e5-large
CHROMA_DB_DIR=./chroma_db
```

#### د. التحقق من التشغيل
بعد النشر، انتظر حتى يكتمل البناء (قد يستغرق 10-15 دقيقة في المرة الأولى).

ثم اختبر:
```bash
curl https://your-space-name.hf.space/health
```

يجب أن تحصل على:
```json
{"status":"ok","message":"RAG engine is healthy and ChromaDB is accessible."}
```

**احفظ رابط Space هذا** - ستحتاجه كـ `RAG_API_URL`

---

### 3️⃣ تحديث متغيرات البيئة في Django (Render)

#### أ. في Render Dashboard
1. اذهب إلى خدمة Django الخاصة بك
2. Settings → Environment Variables
3. أضف المتغيرات التالية:

```
RAG_API_URL=https://your-space-name.hf.space
OLLAMA_API_URL=https://your-ngrok-url.ngrok-free.app
OLLAMA_MODEL_NAME=smartjudi-qwen
```

#### ب. إعادة نشر Django
بعد إضافة المتغيرات، سيتم إعادة نشر الخدمة تلقائياً.

---

### 4️⃣ رفع المستندات القانونية إلى RAG Engine

#### أ. إعداد البيئة المحلية
```bash
# إنشاء virtual environment (اختياري)
python -m venv venv
source venv/bin/activate  # Linux/Mac
# أو
venv\Scripts\activate  # Windows

# تثبيت المتطلبات
pip install requests python-dotenv
```

#### ب. رفع المستندات
```bash
# مثال: رفع ملفات PDF
python scripts/load_legal_data.py \
  --rag_api_url "https://your-space-name.hf.space" \
  --upload "./data/law1.pdf" "./data/law2.txt" "./data/law3.pdf"

# أو رفع جميع ملفات PDF من مجلد
python scripts/load_legal_data.py \
  --rag_api_url "https://your-space-name.hf.space" \
  --upload ./data/*.pdf
```

#### ج. التحقق من الرفع
```bash
# اختبار البحث
curl -X POST "https://your-space-name.hf.space/search" \
  -H "Content-Type: application/json" \
  -d '{"query": "عقد البيع", "k": 3}'
```

---

### 5️⃣ تحديث Flutter App

#### أ. التحقق من إعدادات API
افتح `lib/config/api_config.dart` وتأكد من:
```dart
static const String baseUrl = 'https://smartjudi.onrender.com'; // أو URL الخاص بك
```

#### ب. ربط AIChatProvider بـ AuthProvider
يجب تحديث `AIChatProvider` لاستخدام token من `AuthProvider`. دعني أتحقق من ذلك:

---

### 6️⃣ اختبار النظام

#### أ. اختبار Django API
```bash
# اختبار health check
curl https://your-django-url.onrender.com/api/ai/chat/ \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"query": "ما هي شروط عقد البيع؟", "conversation_history": []}'
```

#### ب. اختبار Flutter App
1. شغّل التطبيق
2. سجّل الدخول
3. اذهب إلى "المساعد الذكي" من القائمة
4. اكتب سؤال قانوني واختبر الاستجابة

---

## 🔍 استكشاف الأخطاء (Troubleshooting)

### مشكلة: "RAG_API_URL environment variable not set"
**الحل:** تأكد من إضافة `RAG_API_URL` في Render Environment Variables

### مشكلة: "Ollama service timed out"
**الحل:** 
- تأكد من تشغيل Ollama محلياً
- تأكد من أن `OLLAMA_HOST=0.0.0.0:11434`
- تأكد من أن ngrok/Cloudflare Tunnel يعمل
- اختبر Ollama مباشرة: `curl http://localhost:11434/api/tags`

### مشكلة: "Failed to load embedding model"
**الحل:**
- تأكد من أن Hugging Face Space لديه ذاكرة كافية (CPU: 2+ cores, RAM: 8GB+)
- قد يستغرق تحميل النموذج وقتاً في المرة الأولى

### مشكلة: Flutter لا يتصل بـ API
**الحل:**
- تأكد من `baseUrl` في `api_config.dart`
- تأكد من أن المستخدم مسجل دخول (JWT token موجود)
- تحقق من logs في Render

---

## 📝 ملاحظات مهمة

1. **الأمان:** في الإنتاج، استخدم Cloudflare Tunnel بدلاً من ngrok
2. **الأداء:** نموذج Qwen 7B يحتاج ~8GB RAM. إذا كان لديك GPU، استخدمه
3. **التكلفة:** Hugging Face Spaces مجاني للاستخدام الأساسي، لكن قد تحتاج خطة مدفوعة للاستخدام المكثف
4. **البيانات:** تأكد من أن المستندات القانونية المرفوعة لا تحتوي على معلومات حساسة

---

## 🎯 الخطوات التالية الموصى بها

1. ✅ إعداد Ollama محلياً
2. ✅ نشر RAG Engine على Hugging Face
3. ✅ تحديث متغيرات البيئة في Render
4. ✅ رفع المستندات القانونية
5. ✅ اختبار النظام بالكامل
6. 🔄 تحسين System Prompt بناءً على النتائج
7. 🔄 إضافة المزيد من المستندات القانونية
8. 🔄 مراقبة الأداء والتحسين

---

## 📞 الدعم

إذا واجهت أي مشاكل، تحقق من:
- Logs في Render Dashboard
- Logs في Hugging Face Space
- Console logs في Flutter app
- Ollama logs في الجهاز المحلي

---

**تاريخ الإنشاء:** $(date)
**الإصدار:** 1.0.0
