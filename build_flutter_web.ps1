# PowerShell Script to build Flutter Web for deployment on Render

Write-Host "🚀 Building Flutter Web for Render..." -ForegroundColor Green

# Clean previous build
Write-Host "📦 Cleaning previous build..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📥 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build for web
Write-Host "🔨 Building Flutter Web (release mode)..." -ForegroundColor Yellow
flutter build web --release

# Check if build was successful
if (Test-Path "build\web") {
    Write-Host "✅ Build successful! Files are in build\web\" -ForegroundColor Green
    Write-Host "📁 Ready to deploy to Render Static Site" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Go to Render Dashboard"
    Write-Host "2. Create new Static Site"
    Write-Host "3. Upload contents of build\web\"
    Write-Host "4. Set Publish Directory to: /"
} else {
    Write-Host "❌ Build failed! Check the errors above." -ForegroundColor Red
    exit 1
}
