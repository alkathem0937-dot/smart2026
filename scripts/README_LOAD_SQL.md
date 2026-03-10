# دليل تحميل البيانات القانونية من SQL

## نظرة عامة
هذا السكربت يستخرج البيانات القانونية من ملف `yemen_legal_dataset.sql` ويحملها إلى RAG Engine المستضاف على Hugging Face Spaces.

## المتطلبات

### 1. تثبيت المكتبات المطلوبة
```bash
pip install requests python-dotenv langchain langchain-text-splitters langchain-core
```

أو إذا كنت تستخدم `requirements.txt`:
```bash
pip install -r requirements.txt
```

### 2. إعداد متغيرات البيئة
أنشئ ملف `.env` في مجلد المشروع الرئيسي (`smartjudi2/`) وأضف:

```env
RAG_API_URL=https://smartgudi-smartjudi-rag.hf.space
```

**ملاحظة**: إذا كان RAG Engine على Hugging Face Spaces، تأكد من أن الرابط صحيح.

## الاستخدام

### الطريقة 1: استخدام المسار الافتراضي
ضع ملف `yemen_legal_dataset.sql` في المجلد الرئيسي للمشروع (`smartjudi2/`)، ثم:

```bash
cd scripts
python load_legal_data_from_sql.py
```

### الطريقة 2: تحديد مسار مخصص
```bash
cd scripts
LEGAL_SQL_FILE=../path/to/your/file.sql python load_legal_data_from_sql.py
```

أو في Windows PowerShell:
```powershell
$env:LEGAL_SQL_FILE="E:\smartjudi2\yemen_legal_dataset.sql"
python load_legal_data_from_sql.py
```

## ما يفعله السكربت

1. **تحليل ملف SQL**: يستخرج جميع المواد القانونية من عبارات `INSERT INTO`
2. **تقسيم المستندات**: يقسم المواد الطويلة إلى أجزاء أصغر (chunks) مع تداخل 200 حرف
3. **الفهرسة**: يحمل جميع الأجزاء إلى RAG Engine عبر API

## هيكل البيانات المتوقع

السكربت يتوقع ملف SQL بهذا الشكل:
```sql
INSERT INTO legal_articles (source_title, book_title, section_title, chapter_title, branch_title, article_number, article_text)
VALUES
('قانون الاجراءات الجزائية','الكتاب الأول','','الباب الأول','','1','نص المادة...'),
...
```

## المخرجات

- **عدد المواد المستخرجة**: يظهر في السجلات
- **عدد الأجزاء (chunks)**: بعد التقسيم
- **حالة الفهرسة**: نجاح/فشل كل دفعة (batch)

## استكشاف الأخطاء

### خطأ: "RAG_API_URL environment variable not set"
**الحل**: تأكد من وجود ملف `.env` مع `RAG_API_URL` صحيح.

### خطأ: "No documents found in SQL file"
**الحل**: تحقق من أن ملف SQL يحتوي على عبارات `INSERT INTO` بصيغة صحيحة.

### خطأ: "Failed to index batch"
**الحل**: 
- تحقق من أن RAG Engine يعمل (اختبر `/health`)
- تحقق من الاتصال بالإنترنت
- تحقق من أن RAG Engine جاهز (انتهى تحميل النموذج)

## ملاحظات

- السكربت يقسم البيانات إلى دفعات (batches) من 50 مستند لكل دفعة
- إذا فشلت إحدى الدفعات، يتوقف السكربت ويعرض الخطأ
- يمكنك إعادة تشغيل السكربت - RAG Engine يدعم إضافة مستندات جديدة دون حذف القديمة

## الخطوات التالية

بعد تحميل البيانات:
1. اختبر RAG Engine عبر API:
   ```bash
   curl -X POST https://smartgudi-smartjudi-rag.hf.space/search \
     -H "Content-Type: application/json" \
     -d '{"query": "ما هي شروط عقد البيع؟", "k": 3}'
   ```

2. اختبر Django API:
   ```bash
   curl -X POST https://smartjudi-nls1.onrender.com/api/ai/chat/ \
     -H "Content-Type: application/json" \
     -d '{"user_query": "ما هي شروط عقد البيع في القانون اليمني؟", "conversation_history": []}'
   ```

3. اختبر Flutter App:
   - شغّل التطبيق
   - اذهب إلى "المساعد الذكي"
   - اسأل سؤال قانوني
