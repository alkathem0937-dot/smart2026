# سكريبت بناء تطبيق iOS - SmartJudi (PowerShell)
# Usage: .\build_ios.ps1 [debug|release|ipa]

param(
    [string]$BuildType = "release"
)

# الألوان للـ output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-ColorOutput Green "🚀 بدء بناء تطبيق iOS..."

# التحقق من Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-ColorOutput Red "❌ Flutter غير مثبت!"
    exit 1
}

Write-ColorOutput Green "📦 تنظيف المشروع..."
flutter clean

Write-ColorOutput Green "📥 جلب Dependencies..."
flutter pub get

Write-ColorOutput Green "🍎 تثبيت iOS Pods..."
Set-Location ios

if (Test-Path "Podfile") {
    # ملاحظة: CocoaPods يتطلب macOS، لذا هذا السكريبت للتحضير فقط
    Write-ColorOutput Yellow "⚠️  ملاحظة: CocoaPods يتطلب macOS"
    Write-ColorOutput Yellow "   قم بتشغيل 'pod install' يدوياً على macOS"
} else {
    Write-ColorOutput Red "❌ Podfile غير موجود!"
    Set-Location ..
    exit 1
}

Set-Location ..

# بناء التطبيق
switch ($BuildType) {
    "debug" {
        Write-ColorOutput Green "🔨 بناء Debug..."
        flutter build ios --debug
        Write-ColorOutput Green "✅ تم البناء بنجاح (Debug)"
    }
    "release" {
        Write-ColorOutput Green "🔨 بناء Release..."
        flutter build ios --release
        Write-ColorOutput Green "✅ تم البناء بنجاح (Release)"
    }
    "ipa" {
        Write-ColorOutput Green "🔨 بناء IPA للتوزيع..."
        flutter build ipa --release
        Write-ColorOutput Green "✅ تم بناء IPA بنجاح"
        Write-ColorOutput Yellow "📍 موقع الملف: build\ios\ipa\smartjudiflutter.ipa"
    }
    default {
        Write-ColorOutput Red "❌ نوع بناء غير صحيح: $BuildType"
        Write-ColorOutput Yellow "الاستخدام: .\build_ios.ps1 [debug|release|ipa]"
        exit 1
    }
}

Write-ColorOutput Green "🎉 اكتمل البناء بنجاح!"
Write-ColorOutput Yellow "⚠️  ملاحظة: بناء iOS يتطلب macOS و Xcode"
