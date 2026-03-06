# 🗄️ إعداد قاعدة البيانات على Render

## 📋 معلومات قاعدة البيانات

تم إنشاء قاعدة البيانات بنجاح! ✅

### معلومات الاتصال:

- **Hostname:** `dpg-d6kv9v7tskes73e6erhg-a`
- **Port:** `5432`
- **Database:** `smartjudi_dpck`
- **Username:** `smartjudi_dpck_user`
- **Password:** `klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz`

---

## 🔗 Database URLs

### Internal Database URL
**للاستخدام من Render Services (موصى به):**
```
postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a/smartjudi_dpck
```

### External Database URL
**للاستخدام من خارج Render (للاختبار المحلي):**
```
postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a.singapore-postgres.render.com/smartjudi_dpck
```

---

## 📝 الخطوات التالية

### 1️⃣ إضافة DATABASE_URL إلى Web Service

#### الطريقة 1: ربط تلقائي (موصى به)
1. في صفحة **Web Service** على Render
2. اذهب إلى **Environment**
3. انقر **Add Database**
4. اختر قاعدة البيانات `smartjudi`
5. Render سيضيف `DATABASE_URL` تلقائياً (Internal URL)

#### الطريقة 2: إضافة يدوية
1. في صفحة **Web Service** → **Environment**
2. انقر **Add Environment Variable**
3. أضف:
   ```
   Key: DATABASE_URL
   Value: postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a/smartjudi_dpck
   ```

**⚠️ مهم:** استخدم **Internal URL** إذا كان Web Service على Render

---

### 2️⃣ اختبار الاتصال (محلياً)

يمكنك اختبار الاتصال من جهازك:

```bash
# تثبيت psycopg2
pip install psycopg2-binary

# تشغيل سكربت الاختبار
python scripts/test_database_connection.py
```

أو استخدام psql مباشرة:
```bash
psql "postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a.singapore-postgres.render.com/smartjudi_dpck?sslmode=require"
```

---

### 3️⃣ تشغيل Migrations

بعد ربط قاعدة البيانات:

#### من Render Shell:
1. في صفحة Web Service → **Shell**
2. شغّل:
```bash
cd smartju
python manage.py migrate
```

#### أو محلياً (باستخدام External URL):
```bash
# تعيين DATABASE_URL
set DATABASE_URL=postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a.singapore-postgres.render.com/smartjudi_dpck

# تشغيل migrations
cd smartju
python manage.py migrate
```

---

### 4️⃣ إنشاء Superuser

```bash
cd smartju
python manage.py createsuperuser
```

---

## 🔒 الأمان

**⚠️ مهم جداً:**
- **لا ترفع Database URL إلى GitHub**
- **لا تشارك Password مع أحد**
- **استخدم Environment Variables فقط**
- **احفظ هذه المعلومات في مكان آمن**

---

## 📊 معلومات إضافية

- **Region:** Singapore (singapore-postgres.render.com)
- **Status:** يجب أن يكون "Available"
- **Plan:** Free أو Paid (حسب ما اخترته)

---

## ✅ قائمة التحقق

- [ ] قاعدة البيانات تم إنشاؤها
- [ ] DATABASE_URL تم إضافتها إلى Web Service
- [ ] الاتصال تم اختباره (من Render Shell)
- [ ] Migrations تم تشغيلها
- [ ] Superuser تم إنشاؤه
- [ ] الجداول موجودة في قاعدة البيانات

---

## 🧪 اختبار سريع

بعد إضافة DATABASE_URL، اختبر من Render Shell:

```bash
cd smartju
python manage.py dbshell
```

يجب أن تفتح psql shell متصل بقاعدة البيانات.

---

**جاهز! الآن يمكنك رفع Web Service وربطه بقاعدة البيانات.** 🚀
