# سكربت لإصلاح DNS
# Script to fix DNS

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "إصلاح DNS للاتصال بـ Ollama" -ForegroundColor Cyan
Write-Host "Fixing DNS for Ollama connection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# التحقق من الاتصال
Write-Host "[1/3] التحقق من الاتصال بالإنترنت..." -ForegroundColor Yellow
Write-Host "[1/3] Checking internet connection..." -ForegroundColor Yellow

$testConnection = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
if (-not $testConnection) {
    Write-Host "❌ لا يوجد اتصال بالإنترنت" -ForegroundColor Red
    Write-Host "❌ No internet connection" -ForegroundColor Red
    Write-Host ""
    Write-Host "يرجى:" -ForegroundColor Yellow
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. التحقق من اتصال الإنترنت" -ForegroundColor White
    Write-Host "   Check internet connection" -ForegroundColor White
    Write-Host "2. إعادة تشغيل الموجه (Router)" -ForegroundColor White
    Write-Host "   Restart router" -ForegroundColor White
    Write-Host "3. التحقق من إعدادات الشبكة" -ForegroundColor White
    Write-Host "   Check network settings" -ForegroundColor White
    pause
    exit 1
}

Write-Host "✅ يوجد اتصال بالإنترنت" -ForegroundColor Green
Write-Host "✅ Internet connection available" -ForegroundColor Green
Write-Host ""

# الحصول على محولات الشبكة النشطة
Write-Host "[2/3] التحقق من إعدادات DNS..." -ForegroundColor Yellow
Write-Host "[2/3] Checking DNS settings..." -ForegroundColor Yellow

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
if ($adapters.Count -eq 0) {
    Write-Host "❌ لا توجد محولات شبكة نشطة" -ForegroundColor Red
    Write-Host "❌ No active network adapters" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "✅ تم العثور على محولات شبكة نشطة" -ForegroundColor Green
Write-Host "✅ Found active network adapters" -ForegroundColor Green
Write-Host ""

# عرض إعدادات DNS الحالية
foreach ($adapter in $adapters) {
    Write-Host "محول: $($adapter.Name)" -ForegroundColor Cyan
    Write-Host "Adapter: $($adapter.Name)" -ForegroundColor Cyan
    $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4
    Write-Host "  DNS الحالي: $($dns.ServerAddresses -join ', ')" -ForegroundColor Gray
    Write-Host "  Current DNS: $($dns.ServerAddresses -join ', ')" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[3/3] هل تريد تغيير DNS إلى Google DNS؟ (Y/N)" -ForegroundColor Yellow
Write-Host "[3/3] Do you want to change DNS to Google DNS? (Y/N)" -ForegroundColor Yellow
$response = Read-Host

if ($response -eq "Y" -or $response -eq "y") {
    foreach ($adapter in $adapters) {
        Write-Host "تغيير DNS لـ $($adapter.Name)..." -ForegroundColor Yellow
        Write-Host "Changing DNS for $($adapter.Name)..." -ForegroundColor Yellow
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "8.8.8.8", "8.8.4.4"
        Write-Host "✅ تم تغيير DNS إلى Google DNS (8.8.8.8, 8.8.4.4)" -ForegroundColor Green
        Write-Host "✅ Changed DNS to Google DNS (8.8.8.8, 8.8.4.4)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "⏳ انتظر 5 ثوانٍ لتطبيق التغييرات..." -ForegroundColor Yellow
    Write-Host "⏳ Wait 5 seconds for changes to apply..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # اختبار DNS
    Write-Host ""
    Write-Host "اختبار DNS..." -ForegroundColor Cyan
    Write-Host "Testing DNS..." -ForegroundColor Cyan
    $dnsTest = Resolve-DnsName -Name "registry.ollama.ai" -ErrorAction SilentlyContinue
    if ($dnsTest) {
        Write-Host "✅ DNS يعمل بشكل صحيح!" -ForegroundColor Green
        Write-Host "✅ DNS is working correctly!" -ForegroundColor Green
        Write-Host ""
        Write-Host "يمكنك الآن محاولة: ollama pull qwen:7b-chat" -ForegroundColor Cyan
        Write-Host "You can now try: ollama pull qwen:7b-chat" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  لا يزال هناك مشكلة في DNS" -ForegroundColor Yellow
        Write-Host "⚠️  DNS issue still exists" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "جرب:" -ForegroundColor Yellow
        Write-Host "Try:" -ForegroundColor Yellow
        Write-Host "1. إعادة تشغيل الكمبيوتر" -ForegroundColor White
        Write-Host "   Restart computer" -ForegroundColor White
        Write-Host "2. استخدام VPN" -ForegroundColor White
        Write-Host "   Use VPN" -ForegroundColor White
        Write-Host "3. الاتصال بشبكة أخرى" -ForegroundColor White
        Write-Host "   Connect to different network" -ForegroundColor White
    }
} else {
    Write-Host "تم الإلغاء" -ForegroundColor Gray
    Write-Host "Cancelled" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
pause
