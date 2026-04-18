# 🚀 بناء سريع لتطبيق iOS

## ⚠️ ملاحظة مهمة
**بناء تطبيق iOS يتطلب macOS و Xcode.**  
لا يمكن بناء iOS على Windows مباشرة.

---

## 📋 الخطوات السريعة (على macOS)

### 1. التحقق من الإعداد:
```bash
flutter doctor
```

### 2. تنظيف وبناء:
```bash
# تنظيف
flutter clean
flutter pub get

# تثبيت Pods
cd ios
pod install
cd ..

# بناء Release
flutter build ios --release

# أو بناء IPA للتوزيع
flutter build ipa --release
```

### 3. فتح في Xcode:
```bash
cd ios
open Runner.xcworkspace
```

---

## 🔧 الإعدادات المهمة

### ✅ تم إعدادها بالفعل:
- ✅ `Podfile` - تم إنشاؤه
- ✅ `Info.plist` - تم إضافة NSAppTransportSecurity
- ✅ `ApiConfig.baseUrl` - مضبوط على Render URL

### ⚠️ يجب تعديلها قبل النشر:
- ⚠️ **Bundle Identifier**: `com.example.smartjudiflutter` → غيره
- ⚠️ **App Name**: `Smartjudiflutter` → غيره في `Info.plist`

---

## 📱 الاختبار

### على Simulator:
```bash
flutter run -d ios
```

### على جهاز حقيقي:
1. وصّل iPhone/iPad بالـ Mac
2. في Xcode: اختر جهازك
3. اضغط **⌘ + R**

---

## 📚 للمزيد من التفاصيل
راجع: **[IOS_BUILD_GUIDE.md](IOS_BUILD_GUIDE.md)**

---

**ملاحظة:** إذا كنت على Windows، ستحتاج إلى:
- استخدام Mac (فيزيائي أو VM)
- أو استخدام خدمة CI/CD مثل Codemagic أو AppCircle
