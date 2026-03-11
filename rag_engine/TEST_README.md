# دليل اختبار RAG Engine

## الاختبارات المتاحة

### 1. اختبار جميع Endpoints (`test_endpoints.py`)

```bash
python test_endpoints.py
```

**يختبر:**
- ✅ Root endpoint (`/`)
- ✅ Health endpoint (`/health`)
- ✅ Healthz endpoint (`/healthz`)
- ✅ Model loading status
- ✅ Search endpoint (`/search`)
- ✅ Add documents endpoint (`/add_documents`)

### 2. اختبار Workflow الكامل (`test_search_after_add.py`)

```bash
python test_search_after_add.py
```

**يختبر:**
- ✅ إضافة مستند
- ✅ البحث بعد الإضافة
- ✅ التحقق من النتائج

---

## استخدام الاختبارات

### المتطلبات

```bash
pip install requests
```

### تشغيل الاختبارات

```bash
# اختبار جميع endpoints
python test_endpoints.py

# اختبار workflow كامل
python test_search_after_add.py
```

---

## النتائج المتوقعة

### عند نجاح جميع الاختبارات:

```
📈 Total: 6/6 tests passed
🎉 All tests passed!
```

### عند فشل بعض الاختبارات:

```
⚠️  Some tests failed
```

---

## ملاحظات

- **Model Loading**: قد يستغرق 10-30 ثانية في المرة الأولى
- **Search**: يعيد 0 نتائج إذا لم تكن هناك مستندات
- **Add Documents**: يجب أن يكون النموذج محمل قبل الإضافة

---

## استكشاف الأخطاء

### إذا فشل Health Check:
- تحقق من أن Space يعمل (Running)
- تحقق من السجلات في Hugging Face Spaces

### إذا فشل Search:
- تأكد من إضافة مستندات أولاً
- انتظر قليلاً بعد الإضافة للفهرسة

### إذا فشل Add Documents:
- تحقق من أن النموذج محمل (`model_loaded: true`)
- تحقق من صيغة الملف (يجب أن يكون .txt أو .pdf)
