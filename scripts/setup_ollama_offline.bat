@echo off
REM سكربت لإعداد Ollama بدون اتصال بالإنترنت (استخدام ملف محلي)
REM Script to setup Ollama offline (using local file)

echo ========================================
echo إعداد Ollama من ملف محلي
echo Setting up Ollama from local file
echo ========================================
echo.

REM التحقق من وجود الملف
if not exist "..\data" (
    echo ❌ الملف غير موجود في مجلد data
    echo ❌ File not found in data folder
    echo.
    echo يرجى التأكد من وجود الملف في: E:\smartjudi2\data
    echo Please make sure file exists at: E:\smartjudi2\data
    pause
    exit /b 1
)

echo ℹ️  ملاحظة: الملف الموجود (4.5GB) قد يكون جزءاً من النموذج فقط
echo ℹ️  Note: The existing file (4.5GB) may be only part of the model
echo.

REM محاولة نسخ الملف إلى مجلد Ollama
set "OLLAMA_BLOBS=%USERPROFILE%\.ollama\models\blobs"
set "DATA_FILE=%~dp0..\data"

echo [1/3] إنشاء مجلد blobs إذا لم يكن موجوداً...
echo [1/3] Creating blobs folder if not exists...
if not exist "%OLLAMA_BLOBS%" mkdir "%OLLAMA_BLOBS%"

echo [2/3] نسخ الملف إلى مجلد Ollama...
echo [2/3] Copying file to Ollama folder...
copy "%DATA_FILE%" "%OLLAMA_BLOBS%\" /Y
if %errorlevel% neq 0 (
    echo ❌ فشل في نسخ الملف
    echo ❌ Failed to copy file
    pause
    exit /b 1
)

echo.
echo ✅ تم نسخ الملف
echo ✅ File copied
echo.

echo [3/3] محاولة تثبيت النموذج...
echo [3/3] Attempting to install model...
echo.
echo ⚠️  إذا فشل الأمر التالي، قد تحتاج إلى:
echo ⚠️  If the following command fails, you may need to:
echo    1. الاتصال بالإنترنت لتحميل باقي الملفات
echo       Connect to internet to download remaining files
echo    2. أو انتظر حتى يكتمل التحميل
echo       Or wait for download to complete
echo.

REM إضافة Ollama إلى PATH
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Ollama"

ollama pull qwen:7b-chat
if %errorlevel% neq 0 (
    echo.
    echo ⚠️  فشل التحميل. قد تحتاج إلى اتصال بالإنترنت
    echo ⚠️  Download failed. You may need internet connection
    echo.
    echo الحلول البديلة:
    echo Alternative solutions:
    echo 1. تحقق من اتصال الإنترنت
    echo    Check internet connection
    echo 2. جرب استخدام VPN أو DNS مختلف
    echo    Try using VPN or different DNS
    echo 3. انتظر حتى يكتمل التحميل من Ollama
    echo    Wait for Ollama download to complete
    pause
    exit /b 1
)

echo.
echo ✅ تم تثبيت النموذج بنجاح
echo ✅ Model installed successfully
echo.

REM إنشاء النموذج المخصص
echo [4/4] إنشاء النموذج المخصص...
echo [4/4] Creating custom model...
cd /d %~dp0
ollama create smartjudi-qwen -f Modelfile
if %errorlevel% neq 0 (
    echo ❌ خطأ في إنشاء النموذج المخصص
    echo ❌ Error creating custom model
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ اكتمل الإعداد!
echo ✅ Setup complete!
echo ========================================
echo.
echo يمكنك الآن اختبار النموذج:
echo You can now test the model:
echo   ollama run smartjudi-qwen "ما هي شروط عقد البيع؟"
echo.
pause
