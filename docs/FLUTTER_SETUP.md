# دليل إعداد وتشغيل تطبيق Flutter

## المتطلبات

1. Flutter SDK (الإصدار 3.8.1 أو أحدث)
2. Dart SDK
3. Android Studio / VS Code مع Flutter extension
4. Django backend يعمل على `http://localhost:8000`

## خطوات الإعداد

### 1. تثبيت الحزم المطلوبة

```bash
flutter pub get
```

### 2. إعداد الاتصال مع Django

افتح ملف `lib/config/api_config.dart` وعدّل `baseUrl` حسب بيئتك:

- **Android Emulator**: `http://10.0.2.2:8000` (الافتراضي)
- **iOS Simulator**: `http://localhost:8000`
- **جهاز فعلي**: `http://YOUR_COMPUTER_IP:8000` (مثال: `http://192.168.1.100:8000`)

### 3. إعداد CORS في Django

تم إعداد CORS تلقائياً في `smartju/smartju/settings/base.py`. تأكد من تثبيت الحزمة:

```bash
cd smartju
pip install django-cors-headers
```

### 4. تشغيل Django Backend

```bash
cd smartju
python manage.py runserver
```

### 5. تشغيل تطبيق Flutter

```bash
flutter run
```

## البنية

```
lib/
├── config/
│   └── api_config.dart          # إعدادات API
├── models/
│   ├── user_model.dart          # نموذج المستخدم
│   └── lawsuit_model.dart       # نموذج الدعوى
├── services/
│   └── api_service.dart         # خدمة الاتصال مع Django
├── providers/
│   ├── auth_provider.dart       # إدارة حالة المصادقة
│   └── lawsuit_provider.dart    # إدارة حالة الدعاوى
├── screens/
│   ├── login_screen.dart        # شاشة تسجيل الدخول
│   ├── home_screen.dart         # الشاشة الرئيسية
│   ├── lawsuits_list_screen.dart # قائمة الدعاوى
│   └── lawsuit_detail_screen.dart # تفاصيل/إضافة دعوى
└── main.dart                    # نقطة البداية
```

## الميزات الحالية

✅ تسجيل الدخول باستخدام JWT
✅ عرض قائمة الدعاوى
✅ إضافة دعوى جديدة (للمحامين والمديرين)
✅ تعديل دعوى (للمحامين والمديرين)
✅ حذف دعوى (للمحامين والمديرين)
✅ Pagination تلقائي
✅ Pull to refresh
✅ إدارة الحالة باستخدام Provider

## الأدوار المدعومة

- **judge** (قاضي): يمكنه عرض الدعاوى وإدارة الجلسات والأحكام
- **lawyer** (محامي): يمكنه إنشاء وتعديل الدعاوى
- **citizen** (مواطن): يمكنه فقط عرض دعاويه
- **admin** (مدير): صلاحيات كاملة
- **notary** (كاتب عدل)

## الخطوات التالية

- [ ] إضافة شاشات إدارة الأطراف (المدعون/المدعى عليهم)
- [ ] إضافة شاشات الجلسات
- [ ] إضافة شاشات الأحكام
- [ ] إضافة رفع المرفقات
- [ ] إضافة البحث والفلترة المتقدمة
- [ ] إضافة الإشعارات
- [ ] تحسين التصميم والـ UI/UX

## استكشاف الأخطاء

### مشكلة الاتصال مع Django

1. تأكد من أن Django يعمل على المنفذ الصحيح
2. تحقق من إعدادات CORS في Django
3. تأكد من أن `baseUrl` في `api_config.dart` صحيح
4. للجهاز الفعلي، تأكد من أن الكمبيوتر والجهاز على نفس الشبكة

### مشكلة المصادقة

1. تأكد من أن JWT tokens يتم حفظها بشكل صحيح
2. تحقق من انتهاء صلاحية Token
3. جرب تسجيل الخروج والدخول مرة أخرى

## ملاحظات

- التطبيق يستخدم Material Design 3
- جميع النصوص بالعربية مع دعم RTL
- يتم حفظ Tokens محلياً باستخدام SharedPreferences
- التطبيق يدعم Auto-refresh للـ tokens

