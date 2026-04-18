# 🚀 دليل البدء السريع - المساعد الذكي

## ✅ ما تم إنجازه

تم إنشاء جميع الملفات المطلوبة للمساعد الذكي بنجاح! 🎉

---

## 📋 الخطوات التالية (بالترتيب)

### 1️⃣ إعداد Ollama (5-10 دقائق)

**الطريقة السريعة (Windows):**
```batch
# شغّل السكربت التلقائي
cd scripts
setup_ollama.bat
```

**أو يدوياً:**
```bash
# 1. تحميل النموذج
ollama pull qwen:7b-chat

# 2. إنشاء النموذج المخصص
cd scripts
ollama create smartjudi-qwen -f Modelfile

# 3. تكوين الوصول عبر الشبكة (Windows)
setx OLLAMA_HOST "0.0.0.0:11434"
# ثم أعد تشغيل Ollama

# 4. اختبار (اختياري)
test_ollama.bat

# 5. تعريض Ollama للإنترنت (ngrok)
ngrok authtoken YOUR_TOKEN
ngrok http 11434
# احفظ الرابط: https://xxxx.ngrok-free.app
```

**✅ النتيجة:** رابط ngrok مثل `https://xxxx.ngrok-free.app`

---

### 2️⃣ نشر RAG Engine على Hugging Face (15-20 دقيقة)

1. اذهب إلى https://huggingface.co/spaces
2. انقر "Create new Space"
3. اختر:
   - **SDK:** Docker
   - **Name:** smartjudi-rag-engine
4. ارفع الملفات من `rag_engine/`:
   - `Dockerfile`
   - `requirements.txt`
   - `main.py`
5. في Settings → Variables:
   ```
   EMBEDDING_MODEL_NAME=sentence-transformers/multilingual-e5-large
   CHROMA_DB_DIR=./chroma_db
   ```
6. انتظر حتى يكتمل البناء (10-15 دقيقة)
7. اختبر: `curl https://your-space.hf.space/health`

**✅ النتيجة:** رابط Space مثل `https://your-space.hf.space`

---

### 3️⃣ تحديث Render Environment Variables (2 دقيقة)

في Render Dashboard → Django Service → Environment:

```
RAG_API_URL=https://your-space.hf.space
OLLAMA_API_URL=https://xxxx.ngrok-free.app
OLLAMA_MODEL_NAME=smartjudi-qwen
```

**✅ النتيجة:** Django سيتم إعادة نشره تلقائياً

---

### 4️⃣ رفع المستندات القانونية (اختياري - حسب الحاجة)

```bash
# تثبيت المتطلبات
pip install requests python-dotenv

# رفع المستندات
python scripts/load_legal_data.py \
  --rag_api_url "https://your-space.hf.space" \
  --upload "./data/law1.pdf" "./data/law2.txt"
```

**✅ النتيجة:** المستندات متاحة للبحث في RAG

---

### 5️⃣ اختبار النظام

#### اختبار Django API:
```bash
curl -X POST "https://your-django.onrender.com/api/ai/chat/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"query": "ما هي شروط عقد البيع؟", "conversation_history": []}'
```

#### اختبار Flutter:
1. شغّل التطبيق
2. سجّل الدخول
3. اذهب إلى "المساعد الذكي"
4. اكتب سؤال قانوني

---

## 🔧 استكشاف الأخطاء السريع

| المشكلة | الحل |
|---------|------|
| `RAG_API_URL not set` | أضف المتغير في Render Environment |
| `Ollama timed out` | تأكد من تشغيل ngrok وOllama |
| `Failed to load embedding model` | انتظر 10-15 دقيقة للبناء الأول |
| Flutter لا يتصل | تحقق من `baseUrl` في `api_config.dart` |

---

## 📝 ملاحظات مهمة

1. **ngrok مجاني لكن محدود:** للاستخدام الدائم، استخدم Cloudflare Tunnel
2. **Hugging Face Spaces:** قد يحتاج خطة مدفوعة للاستخدام المكثف
3. **Ollama:** يحتاج ~8GB RAM للنموذج 7B
4. **الأمان:** لا ترفع مستندات حساسة على Hugging Face

---

## 🎯 الترتيب الموصى به

```
1. Ollama (محلي) → 2. RAG Engine (Hugging Face) → 
3. Environment Variables (Render) → 4. رفع المستندات → 
5. الاختبار
```

---

## 📞 للمساعدة

- راجع `SETUP_AI_ASSISTANT.md` للتفاصيل الكاملة
- تحقق من Logs في Render و Hugging Face
- راجع Console في Flutter

**جاهز للبدء! 🚀**
