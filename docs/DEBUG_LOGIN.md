# دليل Debugging لتسجيل الدخول

## خطوات التشخيص

بعد إضافة logging شامل، اتبع هذه الخطوات:

### 1. شغّل التطبيق وافتح Flutter Console/Debug Console

سترى رسائل مثل:
- `🚀 [Login] Starting login process...`
- `🔑 [Login] Calling authProvider.login...`
- `🔍 [API] Calling getCurrentUser...`
- `📦 [API] Response received: {...}`
- `✅ [Auth] User authenticated successfully`
- أو `❌ [Auth] Error getting user profile`

### 2. تحقق من الرسائل

#### إذا رأيت `❌ [API] Response is empty`:
- المشكلة: Django لا يعيد بيانات
- الحل: تحقق من أن UserProfile موجود

#### إذا رأيت `❌ [API] Failed to parse user data`:
- المشكلة: format البيانات غير متوقع
- الحل: تحقق من response structure

#### إذا رأيت `❌ [Auth] User profile is null after loading`:
- المشكلة: `getCurrentUser()` يعيد `null`
- الحل: تحقق من parsing logic

### 3. تحقق من Django Response مباشرة

افتح في المتصفح (بعد تسجيل الدخول):
```
http://127.0.0.1:8000/api/profiles/me/
```

أو استخدم curl:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://127.0.0.1:8000/api/profiles/me/
```

### 4. تحقق من UserProfile في Django

```bash
cd smartju
python manage.py shell
```

```python
from django.contrib.auth.models import User
from accounts.models import UserProfile

# تحقق من المستخدمين
users = User.objects.all()
for user in users:
    print(f"User: {user.username}, Has profile: {hasattr(user, 'profile')}")
    if hasattr(user, 'profile'):
        print(f"  Profile role: {user.profile.role}")
    else:
        print(f"  ❌ No profile!")

# إنشاء profile للمستخدمين الذين لا يملكون
for user in User.objects.filter(profile__isnull=True):
    UserProfile.objects.create(user=user, role='citizen')
    print(f"Created profile for {user.username}")
```

### 5. تحقق من CORS

تأكد من أن CORS يعمل:
- افتح Developer Tools في المتصفح
- تحقق من Network tab
- ابحث عن requests إلى `/api/profiles/me/`
- تحقق من headers

### 6. تحقق من JWT Token

```python
# في Django shell
from rest_framework_simplejwt.tokens import AccessToken

# decode token يدوياً
token_string = "YOUR_TOKEN_HERE"
token = AccessToken(token_string)
print(token.payload)
```

## الأخطاء الشائعة والحلول

### خطأ: "Profile not found"
**الحل**: شغّل `python manage.py create_user_profiles`

### خطأ: "Unauthorized"
**الحل**: تحقق من أن token صالح وأنه يتم إرساله في header

### خطأ: "Failed to parse user data"
**الحل**: تحقق من structure الـ response من Django

### خطأ: "Connection timeout"
**الحل**: تحقق من أن Django يعمل وأن `baseUrl` صحيح

