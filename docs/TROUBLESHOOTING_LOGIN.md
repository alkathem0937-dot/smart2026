# استكشاف أخطاء تسجيل الدخول

## المشكلة: تسجيل الدخول يعود إلى شاشة تسجيل الدخول

إذا قمت بتسجيل الدخول بنجاح ولكن التطبيق يعود إلى شاشة تسجيل الدخول، فالمشكلة على الأرجح في:

### 1. ملف المستخدم (UserProfile) غير موجود في Django

**السبب:**
- تسجيل الدخول نجح (حصلنا على JWT tokens)
- لكن جلب معلومات المستخدم (`/api/profiles/me/`) فشل
- لأن `UserProfile` غير موجود للمستخدم

**الحل:**

#### الطريقة 1: إنشاء UserProfile من Django Admin

1. افتح Django Admin: `http://127.0.0.1:8000/admin/`
2. اذهب إلى **Accounts > User profiles**
3. اضغط **Add User profile**
4. اختر المستخدم
5. اختر الدور (role)
6. احفظ

#### الطريقة 2: إنشاء UserProfile تلقائياً

Django يجب أن ينشئ `UserProfile` تلقائياً عند إنشاء مستخدم جديد (من خلال signal في `accounts/models.py`).

إذا لم يحدث ذلك، يمكنك:

```python
# في Django shell
python manage.py shell

from django.contrib.auth.models import User
from accounts.models import UserProfile

# إنشاء UserProfile لمستخدم موجود
user = User.objects.get(username='admin')
profile, created = UserProfile.objects.get_or_create(
    user=user,
    defaults={'role': UserProfile.ROLE_ADMIN}
)
```

#### الطريقة 3: استخدام Management Command

```bash
cd smartju
python manage.py shell
```

ثم:

```python
from django.contrib.auth.models import User
from accounts.models import UserProfile

# إنشاء profiles لجميع المستخدمين الذين لا يملكون profile
users_without_profile = User.objects.filter(profile__isnull=True)
for user in users_without_profile:
    UserProfile.objects.create(
        user=user,
        role=UserProfile.ROLE_CITIZEN  # أو أي دور مناسب
    )
```

### 2. التحقق من أن Django يعمل بشكل صحيح

تأكد من:
- Django يعمل على `http://127.0.0.1:8000`
- CORS مفعل
- يمكنك الوصول إلى `/api/profiles/me/` من المتصفح (بعد تسجيل الدخول)

### 3. التحقق من الـ Response من Django

افتح Django terminal وتحقق من الـ logs عند محاولة تسجيل الدخول.

أو جرب في المتصفح:
1. سجل دخول من `/api/token/` للحصول على token
2. استخدم token في header:
   ```
   Authorization: Bearer YOUR_TOKEN_HERE
   ```
3. افتح `/api/profiles/me/` وتحقق من الـ response

### 4. رسائل الخطأ المحسّنة

الآن التطبيق يعرض رسائل خطأ أوضح:
- إذا كان ملف المستخدم غير موجود: "ملف المستخدم غير موجود..."
- إذا كان غير مصرح: "غير مصرح..."
- أي خطأ آخر: سيظهر تفاصيل الخطأ

## خطوات التشخيص

1. **تحقق من رسالة الخطأ** في SnackBar الأحمر
2. **تحقق من Django logs** لمعرفة الخطأ الدقيق
3. **تحقق من وجود UserProfile** في Django Admin
4. **جرب تسجيل الدخول مرة أخرى** بعد إنشاء UserProfile

## ملاحظات

- تأكد من أن المستخدم لديه `UserProfile` في Django
- تأكد من أن `role` في UserProfile صحيح
- تأكد من أن JWT token صالح

