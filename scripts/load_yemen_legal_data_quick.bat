@echo off
REM سكربت سريع لرفع البيانات القانونية إلى Render
REM Quick script to load legal data to Render

echo ========================================
echo رفع البيانات القانونية اليمنية إلى Render
echo Loading Yemen Legal Data to Render
echo ========================================
echo.

REM تعيين DATABASE_URL (استخدم External URL للاتصال من خارج Render)
REM Set DATABASE_URL (use External URL for connection from outside Render)
set DATABASE_URL=postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a.singapore-postgres.render.com/smartjudi_dpck

REM الانتقال إلى مجلد المشروع
REM Navigate to project directory
cd /d "%~dp0\.."

REM تشغيل السكربت
REM Run the script
python scripts\load_yemen_legal_data_to_render.py

pause
