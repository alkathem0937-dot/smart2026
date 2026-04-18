# 🍎 بناء تطبيق iOS - SmartJudi

## ⚠️ ملاحظة مهمة

**بناء تطبيق iOS يتطلب macOS و Xcode.**  
لا يمكن بناء iOS على Windows مباشرة.

---

## ✅ ما تم إعداده

تم إعداد جميع الملفات المطلوبة لبناء iOS:

1. ✅ **Podfile** - لإدارة CocoaPods dependencies
2. ✅ **Info.plist** - تم إضافة NSAppTransportSecurity للاتصال بالـ API
3. ✅ **دليل البناء الكامل** - `BUILD_IOS_FOR_TESTING.md`
4. ✅ **Checklist** - `ios_build_checklist.md`
5. ✅ **سكريبتات البناء** - `build_ios.sh` و `build_ios.ps1`

---

## 🚀 الخطوات التالية

### إذا كان لديك Mac:

1. **افتح المشروع:**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **ثبت Dependencies:**
   ```bash
   flutter pub get
   cd ios
   pod install
   cd ..
   ```

3. **ابني التطبيق:**
   ```bash
   flutter build ios --release
   ```

4. **للاختبار على جهاز:**
   - وصّل iPhone/iPad
   - في Xcode: اختر جهازك واضغط **⌘ + R**

### إذا لم يكن لديك Mac:

**الخيارات المتاحة:**

1. **استخدام Mac VM** (بطيء لكن يعمل)
2. **استخدام خدمة CI/CD:**
   - [Codemagic](https://codemagic.io) - مجاني للبدء
   - [AppCircle](https://appcircle.io) - مجاني للبدء
   - [GitHub Actions](https://github.com/features/actions) - مع macOS runner

3. **طلب المساعدة من شخص لديه Mac:**
   - أرسل له المشروع
   - اطلب منه اتباع `BUILD_IOS_FOR_TESTING.md`

---

## 📋 الملفات المهمة

| الملف | الوصف |
|-------|-------|
| `BUILD_IOS_FOR_TESTING.md` | دليل شامل خطوة بخطوة |
| `ios_build_checklist.md` | Checklist للتحقق من كل شيء |
| `ios/Podfile` | ملف CocoaPods |
| `ios/Runner/Info.plist` | إعدادات iOS |
| `build_ios.sh` | سكريبت بناء (macOS/Linux) |

---

## ✅ التأكد من التوافق

تم التحقق من:
- ✅ جميع Dependencies متوافقة مع iOS
- ✅ WebView يعمل على iOS و Android
- ✅ API Configuration مضبوط
- ✅ لا يوجد كود خاص بـ Android فقط

---

## 📱 بعد البناء

بعد بناء التطبيق:
1. اختبر جميع الميزات
2. تأكد من أن التصميم مطابق لـ Android
3. أنشئ IPA للتوزيع:
   ```bash
   flutter build ipa --release
   ```
4. أرسل ملف `.ipa` للشخص الذي سيجرب التطبيق

---

## 🆘 المساعدة

إذا واجهت مشاكل:
1. راجع `BUILD_IOS_FOR_TESTING.md`
2. راجع `ios_build_checklist.md`
3. تحقق من `flutter doctor -v`

---

**تم إعداد كل شيء! الآن كل ما تحتاجه هو Mac لبناء التطبيق.** 🎉
