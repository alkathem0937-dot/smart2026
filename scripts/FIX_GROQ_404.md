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
GROQ_MODEL_NAME=llama-3-8b-8192
```

أو:
```
GROQ_MODEL_NAME=llama-3-70b-8192
```

أو:
```
GROQ_MODEL_NAME=mixtral-8x7b-32768
```

أو:
```
GROQ_MODEL_NAME=gemma2-9b-it
```

### 2. النماذج المتاحة في Groq

- ✅ `llama-3-8b-8192` (موصى به - سريع ومجاني) ⭐
- ✅ `llama-3-70b-8192` (أفضل جودة)
- ✅ `mixtral-8x7b-32768` (جيد للسياق الطويل)
- ✅ `gemma2-9b-it` (بديل جيد)

### 3. بعد التحديث

1. احفظ التغييرات في Render
2. انتظر إعادة النشر (2-5 دقائق)
3. تحقق من Logs - يجب أن تختفي أخطاء 404
4. اختبر من Flutter App

---

## ملاحظات

- ⚠️ `qwen2.5-7b-instruct` و `llama-3.1-8b-instruct` غير متاحين في Groq API
- ✅ استخدم `llama-3-8b-8192` كبديل موثوق (الافتراضي الجديد)
- جميع النماذج المذكورة أعلاه مجانية في Groq
- إذا استمرت المشكلة، جرب `mixtral-8x7b-32768` أو `gemma2-9b-it`