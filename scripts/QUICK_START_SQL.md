# 🚀 دليل سريع: تحميل البيانات من SQL

## الخطوة 1: إعداد البيئة

```bash
# تأكد من وجود ملف .env في المجلد الرئيسي
# أضف هذا السطر:
RAG_API_URL=https://smartgudi-smartjudi-rag.hf.space
```

## الخطوة 2: تثبيت المتطلبات (اختياري)

```bash
pip install langchain langchain-text-splitters langchain-core
```

**ملاحظة**: السكربت يعمل بدون langchain أيضاً (يستخدم طريقة بسيطة للتقسيم).

## الخطوة 3: تشغيل السكربت

```bash
cd scripts
python load_legal_data_from_sql.py
```

السكربت سيبحث تلقائياً عن `yemen_legal_dataset.sql` في المجلد الرئيسي.

## النتيجة المتوقعة

```
INFO - Starting legal data loading process from SQL file: ...
INFO - Found table: legal_articles with columns: [...]
INFO - Found 4907 rows to parse
INFO - Successfully parsed 4907 legal articles from SQL file.
INFO - Chunking documents...
INFO - Chunked 4907 documents into X chunks.
INFO - Indexing batch 1/XX (50 documents)...
INFO - Successfully indexed batch 1: {...}
...
INFO - ✅ Legal data indexing completed successfully!
```

## استكشاف الأخطاء

### خطأ: "RAG_API_URL environment variable not set"
**الحل**: أنشئ ملف `.env` في `smartjudi2/` وأضف `RAG_API_URL`.

### خطأ: "Failed to index batch"
**الحل**: 
1. تحقق من أن RAG Engine يعمل:
   ```bash
   curl https://smartgudi-smartjudi-rag.hf.space/health
   ```
2. انتظر حتى ينتهي تحميل النموذج (قد يستغرق 2-5 دقائق بعد أول تشغيل)

## بعد التحميل

اختبر RAG Engine:
```bash
curl -X POST https://smartgudi-smartjudi-rag.hf.space/search \
  -H "Content-Type: application/json" \
  -d '{"query": "ما هي شروط عقد البيع؟", "k": 3}'
```
