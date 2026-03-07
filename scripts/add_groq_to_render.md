# 🔐 إضافة Groq API Key إلى Render - خطوات سريعة

## ✅ API Key المتوفر
```
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL_NAME=llama-3.1-8b-instruct
```

---

## 📋 الخطوات (5 دقائق)

### 1️⃣ افتح Render Dashboard
- اذهب إلى: https://dashboard.render.com/
- سجّل الدخول

### 2️⃣ اختر خدمة Django
- ابحث عن: **smartjudi** (Web Service)
- انقر عليها

### 3️⃣ اذهب إلى Environment Variables
- من القائمة الجانبية، انقر **Environment**
- أو: **Settings** → **Environment Variables**

### 4️⃣ أضف المتغيرات التالية

#### المتغير الأول: GROQ_API_KEY
1. انقر **Add Environment Variable**
2. **Key:** `GROQ_API_KEY`
3. **Value:** `your_groq_api_key_here` (استبدل بمفتاحك الحقيقي من https://console.groq.com/)
4. انقر **Save Changes**

#### المتغير الثاني: GROQ_MODEL_NAME
1. انقر **Add Environment Variable** مرة أخرى
2. **Key:** `GROQ_MODEL_NAME`
3. **Value:** `llama-3.1-8b-instruct` (أو `llama-3.1-70b-instruct` أو `mixtral-8x7b-32768`)
4. انقر **Save Changes**

### 5️⃣ انتظر إعادة النشر
- Render سيبدأ إعادة نشر الخدمة تلقائياً
- قد يستغرق 2-5 دقائق

---

## ✅ التحقق من الإعداد

### بعد إعادة النشر:

1. اذهب إلى **Logs** في Render
2. ابحث عن رسالة:
   ```
   Using Groq Cloud API for AI Assistant
   ```
3. إذا ظهرت هذه الرسالة، فالإعداد صحيح! ✅

---

## 🧪 اختبار

بعد إعادة النشر، اختبر من Flutter App:

1. افتح Flutter App
2. سجّل الدخول (admin / admin123)
3. اذهب إلى "المساعد الذكي"
4. اكتب سؤال قانوني:
   - "ما هي شروط عقد البيع في القانون اليمني؟"
   - "ما هي حقوق المستأجر في القانون اليمني؟"
5. تحقق من الاستجابة

---

## 🔒 ملاحظات الأمان

- ✅ **لا ترفع API Key إلى GitHub**
- ✅ **API Key موجود فقط في Render Environment Variables**
- ✅ **لا تشارك المفتاح مع أحد**

---

## ❌ إذا لم يعمل

### تحقق من:
1. ✅ GROQ_API_KEY موجود في Environment Variables
2. ✅ GROQ_MODEL_NAME موجود في Environment Variables
3. ✅ الخدمة تم إعادة نشرها (Status: Live)
4. ✅ Logs تظهر "Using Groq Cloud API for AI Assistant"

### إذا استمرت المشكلة:
- تحقق من Logs في Render للبحث عن أخطاء
- تأكد من أن API Key صحيح (يبدأ بـ `gsk_`)
