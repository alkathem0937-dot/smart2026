#!/bin/bash
# سكربت للتحقق من جاهزية المشروع للرفع على Render
# Script to check project readiness for Render deployment

echo "========================================"
echo "فحص جاهزية المشروع للرفع على Render"
echo "Checking project readiness for Render"
echo "========================================"
echo ""

ERRORS=0
WARNINGS=0

# فحص build.sh
echo "[1/8] فحص build.sh..."
if [ -f "build.sh" ]; then
    if [ -x "build.sh" ]; then
        echo "✅ build.sh موجود وقابل للتنفيذ"
    else
        echo "⚠️  build.sh موجود لكن غير قابل للتنفيذ"
        echo "   قم بتشغيل: chmod +x build.sh"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "❌ build.sh غير موجود"
    ERRORS=$((ERRORS + 1))
fi

# فحص Procfile
echo ""
echo "[2/8] فحص Procfile..."
if [ -f "Procfile" ]; then
    echo "✅ Procfile موجود"
    cat Procfile
else
    echo "❌ Procfile غير موجود"
    ERRORS=$((ERRORS + 1))
fi

# فحص requirements.txt
echo ""
echo "[3/8] فحص requirements.txt..."
if [ -f "requirements.txt" ]; then
    echo "✅ requirements.txt موجود"
    echo "   عدد الحزم: $(wc -l < requirements.txt)"
else
    echo "❌ requirements.txt غير موجود"
    ERRORS=$((ERRORS + 1))
fi

# فحص render.yaml
echo ""
echo "[4/8] فحص render.yaml..."
if [ -f "render.yaml" ]; then
    echo "✅ render.yaml موجود"
else
    echo "⚠️  render.yaml غير موجود (اختياري)"
    WARNINGS=$((WARNINGS + 1))
fi

# فحص smartju/settings/production.py
echo ""
echo "[5/8] فحص settings/production.py..."
if [ -f "smartju/smartju/settings/production.py" ]; then
    echo "✅ production.py موجود"
else
    echo "❌ production.py غير موجود"
    ERRORS=$((ERRORS + 1))
fi

# فحص wsgi.py
echo ""
echo "[6/8] فحص wsgi.py..."
if [ -f "smartju/smartju/wsgi.py" ]; then
    echo "✅ wsgi.py موجود"
else
    echo "❌ wsgi.py غير موجود"
    ERRORS=$((ERRORS + 1))
fi

# فحص manage.py
echo ""
echo "[7/8] فحص manage.py..."
if [ -f "smartju/manage.py" ]; then
    echo "✅ manage.py موجود"
else
    echo "❌ manage.py غير موجود"
    ERRORS=$((ERRORS + 1))
fi

# فحص .gitignore
echo ""
echo "[8/8] فحص .gitignore..."
if [ -f ".gitignore" ]; then
    echo "✅ .gitignore موجود"
    if grep -q "*.pyc" .gitignore && grep -q "__pycache__" .gitignore; then
        echo "✅ .gitignore يحتوي على قواعد Python"
    else
        echo "⚠️  .gitignore قد يحتاج تحديث"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  .gitignore غير موجود (موصى به)"
    WARNINGS=$((WARNINGS + 1))
fi

# النتيجة النهائية
echo ""
echo "========================================"
if [ $ERRORS -eq 0 ]; then
    echo "✅ المشروع جاهز للرفع!"
    echo "✅ Project is ready for deployment!"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  لكن هناك $WARNINGS تحذير(ات)"
        echo "⚠️  But there are $WARNINGS warning(s)"
    fi
else
    echo "❌ هناك $ERRORS خطأ(أخطاء) يجب إصلاحها"
    echo "❌ There are $ERRORS error(s) to fix"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  و $WARNINGS تحذير(ات)"
        echo "⚠️  And $WARNINGS warning(s)"
    fi
fi
echo "========================================"

exit $ERRORS
