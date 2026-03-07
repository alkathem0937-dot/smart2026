@echo off
REM Quick script to test AI Assistant
REM سكربت سريع لاختبار AI Assistant

echo ========================================
echo اختبار AI Assistant
echo Testing AI Assistant
echo ========================================
echo.

REM Navigate to project directory
cd /d "%~dp0\.."

REM Run the test script
python scripts\test_ai_assistant.py

pause
