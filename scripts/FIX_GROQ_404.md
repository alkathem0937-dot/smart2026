# 🔧 إصلاح خطأ 404 من Groq API

## المشكلة

الخطأ 404 من Groq API يعني أن النموذج غير موجود أو غير متاح.

## الحل

### 1. تحديث GROQ_MODEL_NAME في Render

اذهب إلى Render Dashboard → Environment Variables

**غيّر:**
```
GROQ_MODEL_NAME=qwen2.5-7b-instruct
```

**إلى أحد النماذج المتاحة:**
```
GROQ_MODEL_NAME=llama-3.1-8b-instruct
```

أو:
```
GROQ_MODEL_NAME=llama-3.1-70b-instruct
```

أو:
```
GROQ_MODEL_NAME=mixtral-8x7b-32768
```

### 2. النماذج المتاحة في Groq

- ✅ `llama-3.1-8b-instruct` (موصى به - سريع ومجاني)
- ✅ `llama-3.1-70b-instruct` (أفضل جودة)
- ✅ `mixtral-8x7b-32768` (جيد للسياق الطويل)
- ✅ `gemma-7b-it` (بديل جيد)

### 3. بعد التحديث

1. احفظ التغييرات في Render
2. انتظر إعادة النشر (2-5 دقائق)
3. تحقق من Logs - يجب أن تختفي أخطاء 404
4. اختبر من Flutter App

---

## ملاحظات

- `qwen2.5-7b-instruct` قد لا يكون متاحاً في Groq API
- استخدم `llama-3.1-8b-instruct` كبديل موثوق
- جميع النماذج المذكورة أعلاه مجانية في Groq
