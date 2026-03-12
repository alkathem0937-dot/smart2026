#!/bin/bash

# سكريبت بناء تطبيق iOS - SmartJudi
# Usage: ./build_ios.sh [debug|release|ipa]

set -e  # إيقاف عند أي خطأ

# الألوان للـ output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# نوع البناء (افتراضي: release)
BUILD_TYPE=${1:-release}

echo -e "${GREEN}🚀 بدء بناء تطبيق iOS...${NC}"

# التحقق من Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter غير مثبت!${NC}"
    exit 1
fi

# التحقق من CocoaPods
if ! command -v pod &> /dev/null; then
    echo -e "${YELLOW}⚠️  CocoaPods غير مثبت. جاري التثبيت...${NC}"
    sudo gem install cocoapods
fi

echo -e "${GREEN}📦 تنظيف المشروع...${NC}"
flutter clean

echo -e "${GREEN}📥 جلب Dependencies...${NC}"
flutter pub get

echo -e "${GREEN}🍎 تثبيت iOS Pods...${NC}"
cd ios
if [ -f "Podfile" ]; then
    pod deintegrate 2>/dev/null || true
    pod install
else
    echo -e "${RED}❌ Podfile غير موجود!${NC}"
    exit 1
fi
cd ..

# بناء التطبيق
case $BUILD_TYPE in
    debug)
        echo -e "${GREEN}🔨 بناء Debug...${NC}"
        flutter build ios --debug
        echo -e "${GREEN}✅ تم البناء بنجاح (Debug)${NC}"
        ;;
    release)
        echo -e "${GREEN}🔨 بناء Release...${NC}"
        flutter build ios --release
        echo -e "${GREEN}✅ تم البناء بنجاح (Release)${NC}"
        ;;
    ipa)
        echo -e "${GREEN}🔨 بناء IPA للتوزيع...${NC}"
        flutter build ipa --release
        echo -e "${GREEN}✅ تم بناء IPA بنجاح${NC}"
        echo -e "${YELLOW}📍 موقع الملف: build/ios/ipa/smartjudiflutter.ipa${NC}"
        ;;
    *)
        echo -e "${RED}❌ نوع بناء غير صحيح: $BUILD_TYPE${NC}"
        echo -e "${YELLOW}الاستخدام: ./build_ios.sh [debug|release|ipa]${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}🎉 اكتمل البناء بنجاح!${NC}"
