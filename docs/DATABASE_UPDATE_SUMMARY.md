# ملخص تحديث قاعدة البيانات

## نظرة عامة

تم تحديث قاعدة البيانات لتطابق الهيكل الكامل الموجود في `dbsmart.sql`.

## الجداول الجديدة المضافة

### 1. المحاكم (Courts App)

#### Governorate (المحافظات)
- `name`: اسم المحافظة (unique)
- `created_at`, `updated_at`

#### District (الأحياء/المناطق)
- `governorate`: FK إلى Governorate
- `name`: اسم الحي/المنطقة
- `created_at`, `updated_at`

#### CourtType (أنواع المحاكم)
- `name`: نوع المحكمة
- `judicial_level`: المستوى القضائي (ابتدائي، استئناف، تمييز، دستوري)
- `created_at`, `updated_at`

#### CourtSpecialization (تخصصات المحاكم)
- `name`: اسم التخصص
- `description`: الوصف
- `created_at`, `updated_at`

#### Court (المحاكم)
- `name`: اسم المحكمة
- `court_type`: FK إلى CourtType
- `governorate`: FK إلى Governorate
- `district`: FK إلى District
- `address`: العنوان
- `location_url`: رابط الموقع
- `latitude`, `longitude`: الإحداثيات
- `specializations`: ManyToMany مع CourtSpecialization
- `is_active`: نشط
- `created_at`, `updated_at`

### 2. المدفوعات (Payments App)

#### PaymentOrder (أوامر الدفع)
- `lawsuit`: FK إلى Lawsuit
- `amount`: المبلغ
- `order_date`: تاريخ الأمر
- `order_number`: رقم الأمر (unique)
- `description`: الوصف
- `status`: حالة الدفع (قيد الانتظار، مدفوع، مدفوع جزئياً، ملغي)
- `paid_amount`: المبلغ المدفوع
- `payment_date`: تاريخ الدفع
- `created_at`, `updated_at`

### 3. القوانين (Laws App)

#### LegalCategory (الفئات القانونية)
- `name`: اسم الفئة (unique)
- `description`: الوصف
- `created_at`, `updated_at`

#### Law (القوانين)
- `category`: FK إلى LegalCategory
- `name`: اسم القانون
- `issue_year`: سنة الإصدار
- `description`: الوصف
- `created_at`, `updated_at`

#### LawChapter (فصول القوانين)
- `law`: FK إلى Law
- `title`: عنوان الفصل
- `chapter_number`: رقم الفصل
- `order`: الترتيب
- `created_at`, `updated_at`

#### LawSection (أقسام القوانين)
- `chapter`: FK إلى LawChapter
- `title`: عنوان القسم
- `section_number`: رقم القسم
- `order`: الترتيب
- `created_at`, `updated_at`

#### LawArticle (مواد القوانين)
- `section`: FK إلى LawSection
- `article_number`: رقم المادة
- `article_text`: نص المادة
- `order`: الترتيب
- `created_at`, `updated_at`
- Unique constraint: `(section, article_number)`

#### CaseLegalReference (المراجع القانونية)
- `lawsuit`: FK إلى Lawsuit
- `article`: FK إلى LawArticle
- `confidence_score`: نقاط الثقة
- `is_ai`: من AI
- `notes`: ملاحظات
- `created_at`, `updated_at`

### 4. السجلات (Logs App)

#### UserSession (جلسات المستخدمين)
- `user`: FK إلى User
- `device_type`: نوع الجهاز
- `browser`: المتصفح
- `ip_address`: عنوان IP
- `country`: الدولة
- `governorate`: المحافظة
- `city`: المدينة
- `login_time`: وقت تسجيل الدخول
- `logout_time`: وقت تسجيل الخروج
- `is_active`: نشط

#### SearchLog (سجل البحث)
- `user`: FK إلى User (nullable)
- `search_query`: استعلام البحث
- `search_date`: تاريخ البحث
- `results_count`: عدد النتائج

#### AIChatLog (سجل محادثات AI)
- `user`: FK إلى User (nullable)
- `question`: السؤال
- `answer`: الإجابة
- `model_version`: إصدار النموذج
- `created_at`: تاريخ الإنشاء

## التحديثات على الجداول الموجودة

### Lawsuit Model
- ✅ إضافة `court_fk`: ForeignKey إلى Court
- ✅ إضافة `filing_date`: تاريخ رفع الدعوى
- ✅ إضافة `description`: الوصف
- ✅ إضافة `legal_basis`: الأساس القانوني
- ✅ تحديث `court`: أصبح nullable للتوافق مع البيانات القديمة
- ✅ تحديث `facts`, `reasons`, `requests`: أصبحت nullable

### UserProfile
- ✅ موجود بالفعل (يتوافق مع Users table)

### AuditLog
- ✅ موجود بالفعل (يتوافق مع UserActivityLogs)

## الجداول الموجودة (لا تحتاج تغيير)

- ✅ `Plaintiff` - موجود
- ✅ `Defendant` - موجود
- ✅ `Attachment` - موجود (يتوافق مع Lawsuit_Attachments)
- ✅ `Response` - موجود (يتوافق مع Lawsuit_Response)
- ✅ `Appeal` - موجود
- ✅ `Hearing` - موجود (إضافي - غير موجود في SQL)
- ✅ `Judgment` - موجود (إضافي - غير موجود في SQL)

## الخطوات التالية

1. **إنشاء Migrations:**
   ```bash
   cd smartju
   python manage.py makemigrations
   ```

2. **تطبيق Migrations:**
   ```bash
   python manage.py migrate
   ```

3. **إنشاء Serializers و Viewsets** للـ apps الجديدة

4. **تحديث URLs** لإضافة endpoints الجديدة

5. **تحديث Flutter App** لدعم النماذج الجديدة

## ملاحظات مهمة

- تم الحفاظ على التوافق مع البيانات القديمة (legacy fields)
- جميع الحقول الجديدة nullable أو لها default values
- تم إضافة indexes للأداء
- تم إضافة admin interfaces لجميع النماذج الجديدة

