# 🚀 كيفية بناء iOS بدون Mac

## ⚠️ المشكلة

بناء iOS على Windows **مستحيل** لأن Apple تتطلب macOS و Xcode.

---

## ✅ الحل الأسهل: Codemagic (موصى به)

### الخطوات السريعة:

#### 1. سجّل في Codemagic:
- اذهب إلى: https://codemagic.io
- اضغط "Sign up with GitHub"
- سجّل بحساب GitHub

#### 2. أضف المشروع:
1. اضغط **"Add application"**
2. اختر **GitHub** كمصدر
3. اختر repository: `smartjudi2`
4. اضغط **"Finish"**

#### 3. إعداد iOS Build:
1. اختر **"iOS"** كـ platform
2. Codemagic سيكتشف الإعدادات تلقائياً
3. (اختياري) عدّل `codemagic.yaml` إذا لزم الأمر

#### 4. ابني التطبيق:
1. اضغط **"Start new build"**
2. اختر **"iOS"** workflow
3. اضغط **"Start build"**
4. انتظر 10-20 دقيقة

#### 5. حمّل IPA:
1. بعد اكتمال البناء
2. اضغط **"Download"** على ملف `.ipa`
3. أرسل الملف للشخص الذي سيجرب التطبيق

---

## 📋 إعدادات Codemagic

تم إنشاء ملف `codemagic.yaml` في المشروع.  
Codemagic سيستخدمه تلقائياً.

---

## 🔧 إعدادات إضافية (اختياري)

### إذا أردت تخصيص البناء:

1. افتح `codemagic.yaml`
2. عدّل الإعدادات حسب الحاجة
3. احفظ الملف
4. ادفع إلى GitHub

---

## 💡 نصائح

- ✅ **مجاني للبدء:** Codemagic يعطي 500 دقيقة مجانية شهرياً
- ✅ **سريع:** البناء يستغرق 10-20 دقيقة
- ✅ **سهل:** لا يحتاج إعداد معقد
- ✅ **آمن:** يستخدم macOS حقيقي

---

## 🆘 إذا واجهت مشاكل

### خطأ: "No signing certificate"
- في Codemagic: اذهب إلى **App settings > Code signing**
- أضف Apple Developer certificate

### خطأ: "Pod install failed"
- تأكد من أن `ios/Podfile` موجود
- تحقق من `flutter pub get` يعمل

---

## ✅ Checklist

- [ ] سجّلت في Codemagic
- [ ] أضفت المشروع
- [ ] بدأت البناء
- [ ] البناء اكتمل بنجاح
- [ ] حمّلت ملف `.ipa`

---

## 🎉 بعد البناء

1. ✅ اختبر ملف `.ipa` على iPhone
2. ✅ تأكد من أن جميع الميزات تعمل
3. ✅ أرسل الملف للشخص الذي سيجرب التطبيق

---

**هذا هو أسهل طريقة لبناء iOS بدون Mac!** 🚀
