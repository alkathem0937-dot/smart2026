# الخطوات التالية - إعداد Groq و OpenRouter

## ✅ ما تم إنجازه

تم إنشاء جميع الملفات المطلوبة بنجاح:
- ✅ RAG Engine محسّن مع API جديد
- ✅ Django Services (RAG, LLM, AIAssistant)
- ✅ Flutter Screens (AI Assistant, Case Analysis)
- ✅ Data Loading Script

---

## 📋 الخطوات التالية (بالترتيب)

### 1️⃣ الحصول على API Keys (5-10 دقائق)

#### أ) Groq Cloud API Key:
1. اذهب إلى [Groq Cloud Console](https://console.groq.com/)
2. سجّل الدخول أو أنشئ حساب جديد
3. اذهب إلى "API Keys" في القائمة الجانبية
4. أنشئ API Key جديد
5. **ملاحظة:** Groq مجاني ولا يحتاج بطاقة ائتمان ويدعم اليمن ✅

#### ب) OpenRouter API Key:
1. اذهب إلى [OpenRouter](https://openrouter.ai/)
2. سجّل الدخول أو أنشئ حساب جديد
3. اذهب إلى "Keys" في القائمة الجانبية
4. أنشئ API Key جديد
5. **ملاحظة:** OpenRouter لديه خطة مجانية ويدعم نماذج Qwen ✅

---

### 2️⃣ نشر RAG Engine على Hugging Face Spaces (15-20 دقيقة)

1. اذهب إلى [Hugging Face Spaces](https://huggingface.co/spaces)
2. انقر "Create new Space"
3. اختر:
   - **SDK:** Docker
   - **Name:** smartjudi-rag-engine (أو أي اسم تفضله)
   - **Visibility:** Public (أو Private حسب احتياجك)
4. ارفع الملفات من `rag_engine/`:
   - `Dockerfile`
   - `requirements.txt`
   - `main.py`
5. في Settings → Variables (اختياري):
   ```
   EMBEDDING_MODEL_NAME=sentence-transformers/multilingual-e5-large
   CHROMA_DB_DIR=./chroma_db
   ```
6. انتظر حتى يكتمل البناء (10-15 دقيقة)
7. اختبر: `curl https://your-username-smartjudi-rag-engine.hf.space/health`

**✅ النتيجة:** رابط Space مثل `https://your-username-smartjudi-rag-engine.hf.space`

---

### 3️⃣ تحديث متغيرات البيئة في Render (5 دقائق)

في Render Dashboard → Django Service → Environment:

```
RAG_API_URL=https://your-username-smartjudi-rag-engine.hf.space
GROQ_API_KEY=your_groq_api_key_here
OPENROUTER_API_KEY=your_openrouter_api_key_here
GROQ_MODEL_NAME=llama-3.3-70b-versatile
OPENROUTER_MODEL_NAME=qwen/qwen-2.5-7b-instruct
```

**ملاحظة:** يمكنك استخدام نموذج مختلف من OpenRouter مثل:
- `qwen/qwen-2.5-7b-instruct` (موصى به)
- `qwen/qwen-2.5-14b-instruct` (أقوى)
- `qwen/qwen-2.5-32b-instruct` (الأقوى)

---

### 4️⃣ تثبيت التبعيات في Django (محلياً)

```bash
cd smartju
pip install httpx python-dotenv
```

أو إذا كان لديك `requirements.txt`:
```bash
pip install -r requirements.txt
```

---

### 5️⃣ تحميل المستندات القانونية إلى RAG (10-15 دقيقة)

1. أنشئ مجلد `legal_documents` في جذر المشروع:
   ```bash
   mkdir legal_documents
   ```

2. ضع ملفات PDF, DOCX, TXT القانونية اليمنية في المجلد

3. ثبت التبعيات المطلوبة:
   ```bash
   pip install python-dotenv requests pypdf python-docx langchain
   ```

4. شغّل السكربت:
   ```bash
   cd scripts
   python load_legal_data.py
   ```

   أو حدد مجلد مخصص:
   ```bash
   export LEGAL_DATA_DIR=/path/to/your/legal/documents
   python load_legal_data.py
   ```

---

### 6️⃣ تحديث Flutter App (2 دقيقة)

تم تحديث `main.dart` بالفعل! فقط تأكد من:

1. تشغيل `flutter pub get`:
   ```bash
   flutter pub get
   ```

2. التحقق من أن `lib/config/api_config.dart` يحتوي على:
   ```dart
   static const String baseUrl = 'https://smartjudi-nls1.onrender.com';
   ```

---

### 7️⃣ اختبار النظام

#### أ) اختبار RAG Engine:
```bash
curl https://your-rag-space.hf.space/health
```

#### ب) اختبار Django API:
```bash
curl -X POST https://smartjudi-nls1.onrender.com/api/ai/chat/ \
  -H "Content-Type: application/json" \
  -d '{
    "user_query": "ما هي شروط عقد البيع في القانون اليمني؟",
    "conversation_history": []
  }'
```

#### ج) اختبار Flutter App:
1. شغّل التطبيق
2. اذهب إلى شاشة "المساعد الذكي"
3. أرسل استفسار قانوني
4. تحقق من الاستجابة

---

## 🔧 استكشاف الأخطاء

### مشكلة: RAG API لا يعمل
- ✅ تحقق من أن Space تم نشره بنجاح
- ✅ تحقق من `RAG_API_URL` في Render
- ✅ اختبر `/health` endpoint

### مشكلة: Groq لا يعمل
- ✅ تحقق من `GROQ_API_KEY` في Render
- ✅ تحقق من أن النموذج متاح: `llama-3.3-70b-versatile`
- ✅ راجع Logs في Render

### مشكلة: OpenRouter لا يعمل
- ✅ تحقق من `OPENROUTER_API_KEY` في Render
- ✅ تحقق من اسم النموذج في `OPENROUTER_MODEL_NAME`
- ✅ راجع Logs في Render

### مشكلة: Flutter لا يتصل بالـ API
- ✅ تحقق من `baseUrl` في `api_config.dart`
- ✅ تحقق من أن Render Service يعمل
- ✅ راجع Console Logs في Flutter

---

## 📝 ملاحظات مهمة

1. **Rate Limits:** كن حذراً من حدود الاستخدام في Groq و OpenRouter
2. **ChromaDB Persistence:** البيانات محفوظة في Hugging Face Space
3. **Security:** لا تضع API Keys في الكود مباشرة، استخدم Environment Variables دائماً
4. **Model Names:** يمكنك تغيير أسماء النماذج في Environment Variables

---

## 🎉 جاهز للاستخدام!

بعد إكمال جميع الخطوات، سيكون لديك:
- ✅ RAG Engine يعمل على Hugging Face
- ✅ Django Backend مع Groq و OpenRouter
- ✅ Flutter App مع واجهات محسّنة
- ✅ مستندات قانونية مفهرسة في RAG

**حظاً موفقاً! 🚀**
