@echo off
REM سكربت اختبار Ollama
REM Test script for Ollama

echo ========================================
echo اختبار Ollama
echo Testing Ollama
echo ========================================
echo.

echo [1] اختبار النموذج الأساسي...
echo [1] Testing base model...
ollama run qwen:7b-chat "مرحبا"
echo.

echo [2] اختبار النموذج المخصص...
echo [2] Testing custom model...
ollama run smartjudi-qwen "ما هي شروط عقد البيع في القانون اليمني؟"
echo.

echo [3] التحقق من حالة Ollama...
echo [3] Checking Ollama status...
curl http://localhost:11434/api/tags
echo.

echo ========================================
echo ✅ اكتمل الاختبار
echo ✅ Test complete!
echo ========================================
pause
