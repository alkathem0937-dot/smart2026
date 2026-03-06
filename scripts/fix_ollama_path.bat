@echo off
REM سكربت لإصلاح مسار Ollama
REM Script to fix Ollama PATH

echo ========================================
echo إصلاح مسار Ollama
echo Fixing Ollama PATH
echo ========================================
echo.

REM إضافة Ollama إلى PATH للجلسة الحالية
set "OLLAMA_PATH=%LOCALAPPDATA%\Programs\Ollama"

if not exist "%OLLAMA_PATH%\ollama.exe" (
    echo ❌ Ollama غير مثبت في: %OLLAMA_PATH%
    echo ❌ Ollama not installed at: %OLLAMA_PATH%
    echo.
    echo يرجى تثبيت Ollama من: https://ollama.ai/download
    echo Please install Ollama from: https://ollama.ai/download
    pause
    exit /b 1
)

echo ✅ تم العثور على Ollama
echo ✅ Found Ollama
echo.

REM إضافة إلى PATH للجلسة الحالية
set "PATH=%PATH%;%OLLAMA_PATH%"

REM اختبار
echo اختبار Ollama...
echo Testing Ollama...
"%OLLAMA_PATH%\ollama.exe" --version
if %errorlevel% neq 0 (
    echo ❌ خطأ في تشغيل Ollama
    echo ❌ Error running Ollama
    pause
    exit /b 1
)

echo.
echo ✅ Ollama يعمل بشكل صحيح!
echo ✅ Ollama is working correctly!
echo.
echo ========================================
echo ✅ اكتمل!
echo ✅ Complete!
echo ========================================
echo.
echo يمكنك الآن استخدام: ollama pull qwen:7b-chat
echo You can now use: ollama pull qwen:7b-chat
echo.
echo ⚠️  ملاحظة: هذا التغيير مؤقت للجلسة الحالية فقط
echo ⚠️  Note: This change is temporary for current session only
echo    لإضافة دائم: شغّل fix_ollama_path.ps1
echo    For permanent: run fix_ollama_path.ps1
echo.
pause
