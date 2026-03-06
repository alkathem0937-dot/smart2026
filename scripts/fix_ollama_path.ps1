# سكربت PowerShell لإصلاح مسار Ollama
# PowerShell script to fix Ollama PATH

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "إصلاح مسار Ollama" -ForegroundColor Cyan
Write-Host "Fixing Ollama PATH" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ollamaPath = "$env:LOCALAPPDATA\Programs\Ollama"
$ollamaExe = "$ollamaPath\ollama.exe"

# التحقق من وجود Ollama
if (-not (Test-Path $ollamaExe)) {
    Write-Host "❌ Ollama غير مثبت في: $ollamaPath" -ForegroundColor Red
    Write-Host "❌ Ollama not installed at: $ollamaPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "يرجى تثبيت Ollama من: https://ollama.ai/download" -ForegroundColor Yellow
    Write-Host "Please install Ollama from: https://ollama.ai/download" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "✅ تم العثور على Ollama في: $ollamaPath" -ForegroundColor Green
Write-Host "✅ Found Ollama at: $ollamaPath" -ForegroundColor Green
Write-Host ""

# إضافة إلى PATH للجلسة الحالية
$env:PATH += ";$ollamaPath"
Write-Host "✅ تم إضافة Ollama إلى PATH للجلسة الحالية" -ForegroundColor Green
Write-Host "✅ Added Ollama to PATH for current session" -ForegroundColor Green
Write-Host ""

# إضافة إلى PATH بشكل دائم (اختياري)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$ollamaPath*") {
    Write-Host "هل تريد إضافة Ollama إلى PATH بشكل دائم؟ (Y/N)" -ForegroundColor Yellow
    Write-Host "Do you want to add Ollama to PATH permanently? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    
    if ($response -eq "Y" -or $response -eq "y") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$ollamaPath", "User")
        Write-Host "✅ تم إضافة Ollama إلى PATH بشكل دائم" -ForegroundColor Green
        Write-Host "✅ Added Ollama to PATH permanently" -ForegroundColor Green
        Write-Host "⚠️  ملاحظة: يجب إعادة فتح PowerShell لتطبيق التغييرات" -ForegroundColor Yellow
        Write-Host "⚠️  Note: You need to reopen PowerShell to apply changes" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "اختبار Ollama..." -ForegroundColor Cyan
Write-Host "Testing Ollama..." -ForegroundColor Cyan
$version = ollama --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Ollama يعمل بشكل صحيح!" -ForegroundColor Green
    Write-Host "✅ Ollama is working correctly!" -ForegroundColor Green
    Write-Host "   Version: $version" -ForegroundColor Gray
} else {
    Write-Host "❌ خطأ في تشغيل Ollama" -ForegroundColor Red
    Write-Host "❌ Error running Ollama" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ اكتمل!" -ForegroundColor Green
Write-Host "✅ Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "يمكنك الآن استخدام: ollama pull qwen:7b-chat" -ForegroundColor Cyan
Write-Host "You can now use: ollama pull qwen:7b-chat" -ForegroundColor Cyan
Write-Host ""
pause
