# 🍎 دليل بناء تطبيق iOS للاختبار - SmartJudi

## 📋 المتطلبات الأساسية

**يجب أن يكون لديك:**
- ✅ **Mac** (macOS 12.0 أو أحدث)
- ✅ **Xcode** (14.0 أو أحدث) - من App Store
- ✅ **Flutter SDK** (3.8.1 أو أحدث)
- ✅ **CocoaPods** - سيتم تثبيته تلقائياً
- ✅ **حساب Apple Developer** (مجاني للاختبار على جهازك)

---

## 🚀 خطوات البناء السريعة

### 1️⃣ التحقق من الإعداد:
```bash
# تأكد من تثبيت Flutter
flutter doctor

# يجب أن ترى:
# ✓ Flutter (Channel stable, 3.8.1)
# ✓ Xcode - develop for iOS and macOS
# ✓ CocoaPods version 1.x.x
```

### 2️⃣ فتح المشروع:
```bash
# انتقل إلى مجلد المشروع
cd /path/to/smartjudi2

# افتح المشروع في Xcode
cd ios
open Runner.xcworkspace
```

### 3️⃣ تثبيت Dependencies:
```bash
# في Terminal (من مجلد المشروع الرئيسي)
flutter clean
flutter pub get

# تثبيت CocoaPods
cd ios
pod install
cd ..
```

### 4️⃣ إعداد Signing في Xcode:

1. في Xcode، اختر **Runner** من Project Navigator (أقصى اليسار)
2. اختر **Runner** تحت **TARGETS**
3. اذهب إلى تبويب **Signing & Capabilities**
4. ✅ فعّل **Automatically manage signing**
5. اختر **Team** الخاص بك (Apple Developer Account)
6. Xcode سيولد **Bundle Identifier** تلقائياً

> **ملاحظة:** إذا لم يكن لديك Team، اضغط **Add Account** وأدخل Apple ID

### 5️⃣ بناء التطبيق:

#### للاختبار على Simulator:
```bash
# اختر Simulator من Xcode (أعلى الشاشة)
# ثم اضغط ⌘ + R (أو Run من القائمة)
```

أو من Terminal:
```bash
flutter run -d ios
```

#### للاختبار على جهاز حقيقي:

1. **ربط iPhone/iPad:**
   - وصّل الجهاز بالـ Mac عبر USB
   - ثق بالجهاز عند ظهور رسالة "Trust This Computer"

2. **في Xcode:**
   - اختر جهازك من القائمة المنسدلة (أعلى الشاشة)
   - اضغط **⌘ + R** للتشغيل

3. **على الجهاز:**
   - اذهب إلى **Settings > General > VPN & Device Management**
   - اضغط **Trust** على شهادة المطور

### 6️⃣ إنشاء IPA للتوزيع:

#### الطريقة 1: من Xcode (موصى بها)
1. في Xcode: **Product > Archive**
2. انتظر حتى يكتمل البناء
3. في نافذة **Organizer**:
   - اختر **Distribute App**
   - اختر **Ad Hoc** (للتوزيع المباشر)
   - اختر **Development** (للاختبار فقط)
   - اتبع الخطوات

#### الطريقة 2: من Terminal
```bash
flutter build ipa --release
```

الملف سيكون في: `build/ios/ipa/smartjudiflutter.ipa`

---

## 📱 تثبيت على جهاز iPhone/iPad

### الطريقة 1: عبر Xcode (أسهل)
1. وصّل الجهاز بالـ Mac
2. في Xcode: اختر جهازك واضغط **⌘ + R**

### الطريقة 2: عبر IPA File
1. أرسل ملف `.ipa` للشخص
2. على iPhone/iPad:
   - افتح **Settings > General > VPN & Device Management**
   - اضغط **Trust** على شهادة المطور
   - افتح ملف `.ipa` (يمكن استخدام **AltStore** أو **3uTools**)

### الطريقة 3: عبر TestFlight (للتوزيع الواسع)
1. ارفع التطبيق إلى **App Store Connect**
2. أضف المختبرين في **TestFlight**
3. أرسل دعوة للمختبرين

---

## 🔧 حل المشاكل الشائعة

### ❌ خطأ: "No Podfile found"
```bash
cd ios
pod init
pod install
```

### ❌ خطأ: "CocoaPods not installed"
```bash
sudo gem install cocoapods
pod setup
```

### ❌ خطأ: "Signing for Runner requires a development team"
- افتح **Runner.xcworkspace** في Xcode
- اذهب إلى **Signing & Capabilities**
- اختر **Team** الخاص بك

### ❌ خطأ: "Unable to boot the iOS Simulator"
```bash
killall Simulator
open -a Simulator
```

### ❌ خطأ: "Command PhaseScriptExecution failed"
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### ❌ خطأ: "No devices found"
- تأكد من ربط الجهاز بالـ Mac
- تأكد من تفعيل **Developer Mode** على iOS 16+
- اذهب إلى **Settings > Privacy & Security > Developer Mode**

---

## ✅ Checklist قبل الإرسال

- [ ] ✅ التطبيق يعمل على Simulator
- [ ] ✅ التطبيق يعمل على جهاز حقيقي
- [ ] ✅ جميع الشاشات تعمل (Login, Home, AI Assistant, إلخ)
- [ ] ✅ الاتصال بالـ API يعمل (`https://smartjudi-nls1.onrender.com`)
- [ ] ✅ المساعد الذكي يعمل
- [ ] ✅ رفع الملفات يعمل
- [ ] ✅ جميع الميزات تعمل مثل Android

---

## 📝 ملاحظات مهمة

### 1. Bundle Identifier:
- الحالي: `com.example.smartjudiflutter`
- **يمكن تركه للاختبار**، لكن يجب تغييره قبل النشر على App Store

### 2. App Name:
- الحالي: `Smartjudiflutter`
- يمكن تغييره في `ios/Runner/Info.plist` → `CFBundleDisplayName`

### 3. API Configuration:
- ✅ مضبوط على: `https://smartjudi-nls1.onrender.com`
- ✅ NSAppTransportSecurity مضبوط في `Info.plist`

### 4. Version:
- موجود في `pubspec.yaml`: `version: 1.0.0+1`

---

## 🎯 سكريبتات سريعة

### بناء كامل:
```bash
#!/bin/bash
flutter clean && \
flutter pub get && \
cd ios && \
pod install && \
cd .. && \
flutter build ios --release
```

### اختبار سريع:
```bash
flutter run -d ios
```

### بناء IPA:
```bash
flutter build ipa --release
```

---

## 📞 الدعم

إذا واجهت مشاكل:
1. تحقق من `flutter doctor -v`
2. راجع [Flutter iOS Documentation](https://docs.flutter.dev/deployment/ios)
3. راجع [Xcode Documentation](https://developer.apple.com/documentation/xcode)

---

## 🎉 بعد البناء

بعد بناء التطبيق بنجاح:
1. ✅ اختبر جميع الميزات
2. ✅ تأكد من أن التصميم مطابق لـ Android
3. ✅ تأكد من أن جميع الوظائف تعمل
4. ✅ أرسل ملف `.ipa` أو استخدم TestFlight

---

**تم إعداد هذا الدليل بتاريخ:** 2026-03-13  
**آخر تحديث:** 2026-03-13
