@echo off
REM سكربت لتثبيت النموذج من ملف محلي (إذا كان التحميل فشل)
REM Script to install model from local file (if download failed)

echo ========================================
echo تثبيت نموذج Qwen من ملف محلي
echo Installing Qwen model from local file
echo ========================================
echo.

REM التحقق من وجود الملف
if not exist "..\data" (
    echo ❌ الملف غير موجود في مجلد data
    echo ❌ File not found in data folder
    pause
    exit /b 1
)

echo ℹ️  ملاحظة: Ollama يحتاج إلى بنية كاملة للنموذج
echo ℹ️  Note: Ollama needs complete model structure
echo.
echo الحل الأفضل هو:
echo Best solution:
echo 1. استخدم ollama pull (سيستخدم الملف الموجود تلقائياً)
echo    Use ollama pull (will use existing file automatically)
echo 2. أو انتظر حتى يكتمل التحميل
echo    Or wait for download to complete
echo.

REM محاولة التحميل - Ollama سيكتشف الملف الموجود
echo [1/2] محاولة التحميل (Ollama سيكتشف الملف الموجود)...
echo [1/2] Attempting download (Ollama will detect existing file)...
ollama pull qwen:7b-chat
if %errorlevel% neq 0 (
    echo.
    echo ⚠️  إذا فشل التحميل، جرب:
    echo ⚠️  If download failed, try:
    echo    1. تأكد من أن Ollama يعمل
    echo       Make sure Ollama is running
    echo    2. تحقق من اتصال الإنترنت
    echo       Check internet connection
    echo    3. انتظر حتى يكتمل التحميل (قد يستغرق وقتاً)
    echo       Wait for download to complete (may take time)
    echo.
    pause
    exit /b 1
)

echo.
echo ✅ تم تثبيت النموذج بنجاح
echo ✅ Model installed successfully
echo.

REM إنشاء النموذج المخصص
echo [2/2] إنشاء النموذج المخصص...
echo [2/2] Creating custom model...
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
