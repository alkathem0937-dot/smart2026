#!/bin/bash
# Script to build Flutter Web for deployment on Render

echo "🚀 Building Flutter Web for Render..."

# Clean previous build
echo "📦 Cleaning previous build..."
flutter clean

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building Flutter Web (release mode)..."
flutter build web --release

# Check if build was successful
if [ -d "build/web" ]; then
    echo "✅ Build successful! Files are in build/web/"
    echo "📁 Ready to deploy to Render Static Site"
    echo ""
    echo "Next steps:"
    echo "1. Go to Render Dashboard"
    echo "2. Create new Static Site"
    echo "3. Upload contents of build/web/"
    echo "4. Set Publish Directory to: /"
else
    echo "❌ Build failed! Check the errors above."
    exit 1
fi
