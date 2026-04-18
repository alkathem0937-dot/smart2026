# دليل بناء تطبيق iOS - SmartJudi

## 📋 المتطلبات الأساسية

### 1. الأجهزة والبرامج المطلوبة:
- **macOS** (macOS 12.0 أو أحدث)
- **Xcode** (14.0 أو أحدث) - يمكن تحميله من App Store
- **Flutter SDK** (3.8.1 أو أحدث)
- **CocoaPods** (لإدارة dependencies)

### 2. حساب Apple Developer:
- حساب Apple Developer مجاني للاختبار على جهازك
- حساب مدفوع ($99/سنة) للنشر على App Store

---

## 🔧 الإعداد الأولي

### 1. تثبيت Flutter:
```bash
# تحقق من تثبيت Flutter
flutter doctor

# تأكد من أن iOS toolchain مثبت
flutter doctor -v
```

### 2. تثبيت CocoaPods:
```bash
sudo gem install cocoapods
```

### 3. فتح المشروع في Xcode:
```bash
cd ios
open Runner.xcworkspace
```

---

## 🏗️ خطوات البناء

### الطريقة 1: البناء من Terminal (الأسرع)

#### 1. تنظيف المشروع:
```bash
cd ios
rm -rf Pods Podfile.lock
flutter clean
```

#### 2. تثبيت Dependencies:
```bash
flutter pub get
cd ios
pod install
cd ..
```

#### 3. بناء التطبيق:

**للتطوير (Development):**
```bash
flutter build ios --debug
```

**للإنتاج (Release):**
```bash
flutter build ios --release
```

**لإنشاء IPA (للتوزيع):**
```bash
flutter build ipa --release
```

### الطريقة 2: البناء من Xcode (للتوقيع والتوزيع)

#### 1. فتح المشروع:
```bash
cd ios
open Runner.xcworkspace
```

#### 2. إعداد Signing & Capabilities:
- اختر **Runner** من Project Navigator
- اذهب إلى **Signing & Capabilities**
- اختر **Team** الخاص بك (Apple Developer Account)
- Xcode سيولد **Bundle Identifier** تلقائياً

#### 3. اختيار الجهاز:
- اختر جهاز iOS من القائمة المنسدلة (أو Simulator للاختبار)

#### 4. البناء:
- اضغط **⌘ + B** للبناء
- أو **⌘ + R** للبناء والتشغيل

---

## 📱 الاختبار على جهاز حقيقي

### 1. ربط iPhone/iPad:
- وصّل الجهاز بالـ Mac عبر USB
- ثق بالجهاز عند ظهور رسالة "Trust This Computer"

### 2. في Xcode:
- اختر جهازك من القائمة المنسدلة
- اضغط **⌘ + R** للتشغيل

### 3. إعدادات الجهاز:
- اذهب إلى **Settings > General > VPN & Device Management**
- اضغط **Trust** على شهادة المطور

---

## 🚀 النشر على App Store

### 1. إعداد App Store Connect:
- سجّل الدخول إلى [App Store Connect](https://appstoreconnect.apple.com)
- أنشئ **App** جديد
- املأ معلومات التطبيق (اسم، وصف، لقطات شاشة، إلخ)

### 2. بناء Archive:
```bash
# في Xcode:
# Product > Archive
```

أو من Terminal:
```bash
flutter build ipa --release
```

### 3. رفع Archive:
- في Xcode: **Window > Organizer**
- اختر **Archive** الخاص بك
- اضغط **Distribute App**
- اختر **App Store Connect**
- اتبع الخطوات

### 4. إرسال للمراجعة:
- في App Store Connect: **TestFlight** أو **Submit for Review**

---

## 🔍 حل المشاكل الشائعة

### 1. خطأ "No Podfile found":
```bash
cd ios
pod init
pod install
```

### 2. خطأ "CocoaPods not installed":
```bash
sudo gem install cocoapods
pod setup
```

### 3. خطأ "Signing for Runner requires a development team":
- افتح **Runner.xcworkspace** في Xcode
- اذهب إلى **Signing & Capabilities**
- اختر **Team** الخاص بك

### 4. خطأ "Unable to boot the iOS Simulator":
```bash
# إعادة تشغيل Simulator
killall Simulator
open -a Simulator
```

### 5. خطأ "Command PhaseScriptExecution failed":
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### 6. مشاكل في الاتصال بالـ API:
- تأكد من إضافة **NSAppTransportSecurity** في `Info.plist` (تم بالفعل)
- تأكد من أن `ApiConfig.baseUrl` صحيح في `lib/config/api_config.dart`

---

## 📝 ملاحظات مهمة

### 1. Bundle Identifier:
- الحالي: `com.example.smartjudiflutter`
- **يجب تغييره** قبل النشر على App Store
- مثال: `com.yourcompany.smartjudi`

### 2. App Name:
- الحالي: `Smartjudiflutter`
- يمكن تغييره في `Info.plist` → `CFBundleDisplayName`

### 3. Version & Build Number:
- موجود في `pubspec.yaml`:
  ```yaml
  version: 1.0.0+1
  ```
- `1.0.0` = Version Name
- `1` = Build Number

### 4. Icons:
- الأيقونات موجودة في `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- تأكد من وجود جميع الأحجام المطلوبة

---

## 🎯 سكريبتات سريعة

### بناء سريع:
```bash
# في مجلد المشروع الرئيسي
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter build ios --release
```

### اختبار سريع:
```bash
flutter run -d ios
```

### فحص التبعيات:
```bash
flutter pub outdated
```

---

## 📞 الدعم

إذا واجهت مشاكل:
1. تحقق من `flutter doctor -v`
2. راجع [Flutter iOS Documentation](https://docs.flutter.dev/deployment/ios)
3. راجع [Xcode Documentation](https://developer.apple.com/documentation/xcode)

---

## ✅ Checklist قبل النشر

- [ ] تغيير Bundle Identifier
- [ ] تحديث App Name في Info.plist
- [ ] تحديث Version & Build Number
- [ ] اختبار على جهاز حقيقي
- [ ] اختبار جميع الميزات (Login, API calls, إلخ)
- [ ] إضافة Icons بجميع الأحجام
- [ ] إعداد App Store Connect
- [ ] إعداد Privacy Policy URL (مطلوب من Apple)
- [ ] اختبار على iOS Simulator و iPhone/iPad حقيقي

---

**تم إنشاء هذا الدليل بتاريخ:** 2026-03-13  
**آخر تحديث:** 2026-03-13
