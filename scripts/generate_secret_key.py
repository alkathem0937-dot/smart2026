#!/usr/bin/env python
# سكربت لإنشاء SECRET_KEY آمن لـ Django
# Script to generate secure SECRET_KEY for Django

import secrets

def generate_secret_key():
    """إنشاء SECRET_KEY آمن"""
    # طريقة 1: استخدام Django's get_random_secret_key
    try:
        from django.core.management.utils import get_random_secret_key
        secret_key = get_random_secret_key()
        print("✅ تم إنشاء SECRET_KEY باستخدام Django:")
        print("✅ Generated SECRET_KEY using Django:")
        print(secret_key)
        return secret_key
    except ImportError:
        # طريقة 2: استخدام secrets (مدمج في Python)
        secret_key = secrets.token_urlsafe(50)
        print("✅ تم إنشاء SECRET_KEY باستخدام secrets:")
        print("✅ Generated SECRET_KEY using secrets:")
        print(secret_key)
        return secret_key

if __name__ == "__main__":
    print("=" * 60)
    print("مولد SECRET_KEY لـ Django")
    print("Django SECRET_KEY Generator")
    print("=" * 60)
    print()
    
    key = generate_secret_key()
    
    print()
    print("=" * 60)
    print("📋 استخدم هذا المفتاح في Render Environment Variables:")
    print("📋 Use this key in Render Environment Variables:")
    print("   SECRET_KEY=" + key)
    print("=" * 60)
    print()
    print("⚠️  مهم: احفظ هذا المفتاح في مكان آمن!")
    print("⚠️  Important: Save this key in a safe place!")
