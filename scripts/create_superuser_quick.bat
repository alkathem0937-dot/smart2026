@echo off
REM Quick script to create superuser on Render database
REM This uses the External Database URL from RENDER_DATABASE_SETUP.md

echo ============================================================
echo Creating Superuser on Render Database
echo ============================================================
echo.

REM Set External Database URL (from Render Dashboard)
set DATABASE_URL=postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a.singapore-postgres.render.com/smartjudi_dpck

REM Set Django settings
set DJANGO_SETTINGS_MODULE=smartju.settings.production

echo Using External Database URL...
echo.

REM Change to smartju directory
cd /d "%~dp0..\smartju"

REM Run the script
python ..\scripts\create_superuser_render.py

pause
