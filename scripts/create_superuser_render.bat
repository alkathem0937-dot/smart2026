@echo off
REM Script to create superuser on Render database from local machine
REM Usage: scripts\create_superuser_render.bat

echo ============================================================
echo Creating Superuser on Render Database
echo ============================================================
echo.

REM Check if DATABASE_URL is set
if "%DATABASE_URL%"=="" (
    echo ERROR: DATABASE_URL environment variable is not set!
    echo.
    echo To get DATABASE_URL from Render:
    echo 1. Go to Render Dashboard -^> Database -^> smartjudi
    echo 2. Copy the "External Database URL"
    echo 3. Set it as environment variable:
    echo.
    echo    set DATABASE_URL=postgresql://user:pass@host:port/dbname
    echo.
    pause
    exit /b 1
)

REM Change to smartju directory
cd /d "%~dp0..\smartju"

REM Run the script
python ..\scripts\create_superuser_render.py

pause
