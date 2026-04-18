# Recreate Python venv "my_smart" when pyvenv.cfg points to another PC (e.g. C:\Users\USER\...)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host "Removing old venv folder my_smart..." -ForegroundColor Yellow
Remove-Item -Recurse -Force "$root\my_smart" -ErrorAction SilentlyContinue

Write-Host "Creating new venv with: python -m venv my_smart" -ForegroundColor Green
python -m venv my_smart

& "$root\my_smart\Scripts\Activate.ps1"
python -m pip install --upgrade pip
pip install -r "$root\requirements.txt"

Write-Host "Done. Run Django:" -ForegroundColor Green
Write-Host "  my_smart\Scripts\Activate.ps1" -ForegroundColor Cyan
Write-Host "  Set-Location smartju; python manage.py runserver 0.0.0.0:8000" -ForegroundColor Cyan
