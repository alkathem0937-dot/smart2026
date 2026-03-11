# إعدادات Hugging Face Spaces للـ Health Check

## المشكلة
Hugging Face Spaces يعتبر Space غير صحي بعد 30 دقيقة رغم أن التطبيق يعمل بشكل صحيح.

## الحلول المطبقة

### 1. Health Check Endpoints المتاحة
- `/` - Root endpoint (JSON response)
- `/health` - Health check endpoint (JSON response)
- `/healthz` - Ultra-simple health check (plain text "OK")

### 2. إعدادات Hugging Face Spaces المطلوبة

#### الطريقة 1: استخدام Root Endpoint
1. اذهب إلى: https://huggingface.co/spaces/smartgudi/smartjudi_rag/settings
2. في قسم **Health Check**:
   - **Health Check Path**: `/`
   - **Health Check Timeout**: `60` (ثواني)
   - **Expected Status Code**: `200`

#### الطريقة 2: استخدام Healthz Endpoint (الأبسط)
1. اذهب إلى: https://huggingface.co/spaces/smartgudi/smartjudi_rag/settings
2. في قسم **Health Check**:
   - **Health Check Path**: `/healthz`
   - **Health Check Timeout**: `60` (ثواني)
   - **Expected Status Code**: `200`

#### الطريقة 3: استخدام Health Endpoint
1. اذهب إلى: https://huggingface.co/spaces/smartgudi/smartjudi_rag/settings
2. في قسم **Health Check**:
   - **Health Check Path**: `/health`
   - **Health Check Timeout**: `60` (ثواني)
   - **Expected Status Code**: `200`

## التحقق من الحل

بعد تحديث الإعدادات:

1. **انتظر حتى ينتهي البناء** (2-5 دقائق)
2. **اختبر Health Check:**
   ```bash
   # Root endpoint
   curl https://smartgudi-smartjudi-rag.hf.space/
   
   # Healthz endpoint (الأبسط)
   curl https://smartgudi-smartjudi-rag.hf.space/healthz
   
   # Health endpoint
   curl https://smartgudi-smartjudi-rag.hf.space/health
   ```

3. **تحقق من حالة Space:**
   - يجب أن يظهر "Running" بدلاً من "Building" أو "Error"
   - يجب أن تكون السجلات خالية من أخطاء health check

## ملاحظات

- **النموذج**: `intfloat/multilingual-e5-base` (أصغر وأسرع)
- **وقت التحميل**: ~11 ثانية (أسرع بكثير من large)
- **Health Check**: يعمل فوراً بعد startup (لا ينتظر تحميل النموذج)

## إذا استمرت المشكلة

1. **تحقق من السجلات:**
   - ابحث عن أخطاء في تحميل النموذج
   - تحقق من أن ChromaDB يتم تهيئته بنجاح

2. **جرب endpoint مختلف:**
   - `/healthz` (الأبسط - plain text)
   - `/` (JSON response)
   - `/health` (JSON response مع معلومات إضافية)

3. **زيادة Timeout:**
   - جرب 120 ثانية بدلاً من 60
