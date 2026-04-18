# دليل البدء السريع - Flutter + Django

## خطوات سريعة للتشغيل

### 1. إعداد Django Backend

```bash
# الانتقال لمجلد Django
cd smartju

# تثبيت الحزم (إذا لم تكن مثبتة)
pip install -r ../requirements.txt

# تشغيل السيرفر
python manage.py runserver
```

✅ Django يعمل الآن على `http://localhost:8000`

### 2. إعداد Flutter App

```bash
# العودة للمجلد الرئيسي
cd ..

# تثبيت حزم Flutter
flutter pub get

# تشغيل التطبيق
flutter run
```

### 3. إعداد الاتصال (مهم!)

افتح `lib/config/api_config.dart` وعدّل `baseUrl`:

- **Android Emulator**: `http://10.0.2.2:8000` ✅ (الافتراضي)
- **iOS Simulator**: `http://localhost:8000`
- **جهاز فعلي**: `http://YOUR_IP:8000` (مثال: `http://192.168.1.100:8000`)

### 4. اختبار تسجيل الدخول

استخدم أي مستخدم موجود في Django:
- Username: `admin`
- Password: (كلمة المرور التي قمت بإنشائها)

أو أنشئ مستخدم جديد من Django Admin.

## ملاحظات مهمة

1. **CORS**: تم إعداد CORS تلقائياً في Django للسماح بالاتصال من Flutter
2. **Tokens**: يتم حفظ JWT tokens تلقائياً محلياً
3. **Auto-refresh**: التطبيق يقوم بتحديث tokens تلقائياً عند انتهاء الصلاحية

## استكشاف الأخطاء

### خطأ الاتصال
```
Connection timeout / Network error
```
**الحل**: 
- تأكد من أن Django يعمل
- تحقق من `baseUrl` في `api_config.dart`
- للجهاز الفعلي: تأكد من IP الصحيح

### خطأ المصادقة
```
Unauthorized: Invalid credentials
```
**الحل**:
- تحقق من username/password
- تأكد من وجود UserProfile في Django
- جرب حذف التطبيق وإعادة تثبيته

### خطأ CORS
```
CORS policy: No 'Access-Control-Allow-Origin'
```
**الحل**:
- تأكد من تثبيت `django-cors-headers`
- تحقق من إعدادات CORS في `settings/base.py`

## الملفات المهمة

- `lib/config/api_config.dart` - إعدادات API
- `lib/services/api_service.dart` - خدمة الاتصال
- `lib/providers/auth_provider.dart` - إدارة المصادقة
- `smartju/smartju/settings/base.py` - إعدادات Django (CORS)

## الخطوات التالية

بعد التأكد من أن كل شيء يعمل:
1. جرب إنشاء دعوى جديدة
2. جرب تعديل دعوى
3. استكشف الواجهات المختلفة

للتفاصيل الكاملة، راجع `README_FLUTTER.md`

