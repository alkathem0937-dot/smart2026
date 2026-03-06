@echo off
REM سكربت إعداد Ollama للمساعد الذكي
REM Setup script for Ollama AI Assistant

echo ========================================
echo إعداد Ollama للمساعد الذكي
echo Setting up Ollama for SmartJudi AI Assistant
echo ========================================
echo.

REM Step 1: تحميل نموذج Qwen
echo [1/3] تحميل نموذج Qwen 7B...
echo [1/3] Downloading Qwen 7B model...
ollama pull qwen:7b-chat
if %errorlevel% neq 0 (
    echo خطأ في تحميل النموذج
    echo Error downloading model
    pause
    exit /b 1
)
echo.
echo ✅ تم تحميل النموذج بنجاح
echo ✅ Model downloaded successfully
echo.

REM Step 2: إنشاء النموذج المخصص
echo [2/3] إنشاء النموذج المخصص للقانون اليمني...
echo [2/3] Creating custom model for Yemeni law...
cd /d %~dp0
ollama create smartjudi-qwen -f Modelfile
if %errorlevel% neq 0 (
    echo خطأ في إنشاء النموذج المخصص
    echo Error creating custom model
    pause
    exit /b 1
)
echo.
echo ✅ تم إنشاء النموذج المخصص بنجاح
echo ✅ Custom model created successfully
echo.

REM Step 3: تكوين الوصول عبر الشبكة
echo [3/3] تكوين الوصول عبر الشبكة...
echo [3/3] Configuring network access...
setx OLLAMA_HOST "0.0.0.0:11434"
if %errorlevel% neq 0 (
    echo تحذير: فشل في تعيين متغير البيئة
    echo Warning: Failed to set environment variable
) else (
    echo ✅ تم تكوين الوصول عبر الشبكة
    echo ✅ Network access configured
    echo.
    echo ⚠️  مهم: يجب إعادة تشغيل Ollama أو الكمبيوتر لتطبيق التغييرات
    echo ⚠️  Important: Restart Ollama or your computer to apply changes
)
echo.

echo ========================================
echo ✅ اكتمل الإعداد!
echo ✅ Setup complete!
echo ========================================
echo.
echo الخطوات التالية:
echo Next steps:
echo 1. أعد تشغيل Ollama (أو الكمبيوتر)
echo    Restart Ollama (or your computer)
echo 2. شغّل ngrok: ngrok http 11434
echo    Run ngrok: ngrok http 11434
echo 3. احفظ رابط ngrok لاستخدامه في Render
echo    Save the ngrok URL for use in Render
echo.
pause
