# 🔄 تحديث GROQ_MODEL_NAME في Render

## المشكلة الحالية

Render يعرض خطأ:
```
The model llama-3.1-8b-instruct does not exist or you do not have access to it.
```

## الحل: تحديث النموذج

### الخطوات:

1. **اذهب إلى Render Dashboard:**
   - https://dashboard.render.com/
   - اختر خدمة: **smartjudi** (Web Service)
   - اذهب إلى **Environment** (في القائمة الجانبية)

2. **ابحث عن `GROQ_MODEL_NAME`**

3. **غيّر القيمة من:**
   ```
   llama-3.1-8b-instruct
   ```
   
   **إلى:**
   ```
   llama-3.3-70b-versatile
   ```
   
   ⭐ **موصى به - تم اختباره ويعمل بشكل ممتاز**

4. **احفظ التغييرات**

5. **انتظر إعادة النشر** (2-5 دقائق)

---

## نماذج بديلة (إذا لم يعمل `llama-3-8b-8192`):

### الخيار 1: Llama 3.3 70B Versatile (موصى به - تم اختباره) ⭐
```
GROQ_MODEL_NAME=llama-3.3-70b-versatile
```

### الخيار 2: Llama 3 8B (سريع)
```
GROQ_MODEL_NAME=llama-3-8b-8192
```

### الخيار 3: Mixtral (للسياق الطويل)
```
GROQ_MODEL_NAME=mixtral-8x7b-32768
```

### الخيار 4: Gemma 2
```
GROQ_MODEL_NAME=gemma2-9b-it
```

---

## التحقق من النشر

بعد إعادة النشر:

1. اذهب إلى **Logs** في Render
2. ابحث عن:
   - ✅ `GroqService initialized with model: llama-3.3-70b-versatile`
   - ✅ لا يجب أن ترى أخطاء 404
   - ✅ يجب أن ترى استجابات ناجحة من Groq API

---

## ملاحظات

- الكود محدث تلقائياً لاستخدام `llama-3-8b-8192` كافتراضي
- إذا لم تقم بتعيين `GROQ_MODEL_NAME` في Render، سيستخدم النموذج الافتراضي الجديد
- جميع النماذج المذكورة مجانية في Groq
