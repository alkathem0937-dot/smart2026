# سكربت لإصلاح مشكلة psycopg2
# Script to fix psycopg2 issue

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "إصلاح مشكلة psycopg2"
Write-Host "Fixing psycopg2 issue"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# الانتقال إلى مجلد المشروع
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# تفعيل البيئة الافتراضية
if (Test-Path "my_smart\Scripts\Activate.ps1") {
    Write-Host "تفعيل البيئة الافتراضية..." -ForegroundColor Yellow
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    .\my_smart\Scripts\Activate.ps1
}

Write-Host ""
Write-Host "إزالة psycopg2 القديم..." -ForegroundColor Yellow
Write-Host "Removing old psycopg2..." -ForegroundColor Yellow
pip uninstall psycopg2 psycopg2-binary -y

Write-Host ""
Write-Host "تثبيت psycopg2-binary..." -ForegroundColor Yellow
Write-Host "Installing psycopg2-binary..." -ForegroundColor Yellow
pip install psycopg2-binary

Write-Host ""
Write-Host "التحقق من التثبيت..." -ForegroundColor Yellow
Write-Host "Verifying installation..." -ForegroundColor Yellow
python -c "import psycopg2; print('✅ psycopg2-binary installed successfully!')"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "اكتمل الإصلاح!"
Write-Host "Fix completed!"
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

pause
