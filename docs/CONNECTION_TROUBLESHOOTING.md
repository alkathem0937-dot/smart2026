# استكشاف مشاكل الاتصال

## المشكلة: TimeoutException

إذا رأيت هذا الخطأ:
```
❌ [API] Exception in _makeRequest: TimeoutException after 0:00:30.000000
```

هذا يعني أن التطبيق لا يستطيع الاتصال بـ Django.

## الحلول:

### 1. تحقق من أن Django يعمل

```bash
cd smartju
python manage.py runserver
```

يجب أن ترى:
```
Starting development server at http://127.0.0.1:8000/
```

### 2. تحقق من `baseUrl` في `lib/config/api_config.dart`

#### للـ Android Emulator:
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

#### للـ iOS Simulator:
```dart
static const String baseUrl = 'http://localhost:8000';
```

#### للجهاز الفعلي:
```dart
// استبدل YOUR_IP بـ IP جهازك
static const String baseUrl = 'http://192.168.1.100:8000';
```

**كيفية معرفة IP جهازك:**
- Windows: `ipconfig` في CMD
- Mac/Linux: `ifconfig` في Terminal
- ابحث عن IPv4 Address (مثال: 192.168.1.100)

### 3. اختبر الاتصال من Emulator

#### من Android Emulator:
```bash
adb shell
ping 10.0.2.2
```

#### أو من المتصفح في Emulator:
افتح المتصفح في Emulator واذهب إلى:
```
http://10.0.2.2:8000
```

### 4. تحقق من Firewall

- تأكد من أن Windows Firewall لا يحجب المنفذ 8000
- أو أضف exception لـ Python

### 5. تحقق من CORS

تأكد من أن CORS مفعل في Django:
```python
# في smartju/smartju/settings/base.py
CORS_ALLOW_ALL_ORIGINS = DEBUG  # يجب أن يكون True في development
```

### 6. اختبر API مباشرة

افتح في المتصفح:
```
http://127.0.0.1:8000/api/token/
```

يجب أن ترى صفحة API أو JSON response.

### 7. تحقق من Network في Emulator

- تأكد من أن Emulator متصل بالإنترنت
- جرب إعادة تشغيل Emulator
- جرب إعادة تشغيل Android Studio

## خطوات التشخيص السريع:

1. ✅ Django يعمل على `http://127.0.0.1:8000`
2. ✅ `baseUrl` في `api_config.dart` صحيح
3. ✅ Emulator يمكنه الوصول إلى `10.0.2.2:8000`
4. ✅ CORS مفعل في Django
5. ✅ Firewall لا يحجب الاتصال

## اختبار سريع:

```bash
# Terminal 1: شغّل Django
cd smartju
python manage.py runserver

# Terminal 2: اختبر الاتصال
curl http://127.0.0.1:8000/api/token/ -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your_password"}'
```

إذا عمل curl، المشكلة في Flutter configuration.
إذا لم يعمل curl، المشكلة في Django.

