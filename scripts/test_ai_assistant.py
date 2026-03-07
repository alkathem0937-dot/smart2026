# test_ai_assistant.py
# سكربت شامل لاختبار AI Assistant
# Comprehensive script to test AI Assistant

import os
import sys
import requests
import json

# محاولة تحميل dotenv (اختياري)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # dotenv غير متاح، سنستخدم environment variables فقط

# إضافة مسار Django إلى Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'smartju'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'smartju.settings.base')

# إعدادات
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
MODEL_NAME = os.getenv("GROQ_MODEL_NAME", "qwen2.5-7b-instruct")
RENDER_URL = "https://smartjudi-nls1.onrender.com"

def test_groq_api_direct():
    """اختبار Groq API مباشرة"""
    print("=" * 60)
    print("🧪 اختبار 1: Groq API مباشرة")
    print("🧪 Test 1: Direct Groq API")
    print("=" * 60)
    print()
    
    if not GROQ_API_KEY or GROQ_API_KEY == "your_groq_api_key_here":
        print("⚠️  GROQ_API_KEY غير موجود أو غير صحيح")
        print("⚠️  GROQ_API_KEY not found or invalid")
        print("   يرجى إضافة GROQ_API_KEY إلى .env أو environment variables")
        print("   Please add GROQ_API_KEY to .env or environment variables")
        return False
    
    messages = [
        {
            "role": "system",
            "content": "أنت مساعد قانوني متخصص في القانون اليمني."
        },
        {
            "role": "user",
            "content": "ما هي شروط عقد البيع في القانون اليمني؟"
        }
    ]
    
    payload = {
        "model": MODEL_NAME,
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": 1000,
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {GROQ_API_KEY}'
    }
    
    try:
        print("📤 إرسال الطلب إلى Groq...")
        print("📤 Sending request to Groq...")
        print()
        
        response = requests.post(
            GROQ_API_URL,
            headers=headers,
            json=payload,
            timeout=30
        )
        
        response.raise_for_status()
        result = response.json()
        
        print("✅ نجح الطلب!")
        print("✅ Request successful!")
        print()
        print("📝 الاستجابة:")
        print("📝 Response:")
        print("-" * 60)
        
        if 'choices' in result and len(result['choices']) > 0:
            assistant_message = result['choices'][0]['message']['content']
            print(assistant_message)
        else:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        
        print()
        print("=" * 60)
        print("✅ اختبار Groq API نجح!")
        print("✅ Groq API test successful!")
        print("=" * 60)
        print()
        
        return True
        
    except requests.exceptions.RequestException as e:
        print("❌ خطأ في الطلب:")
        print("❌ Request error:")
        print(f"   {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"   Status: {e.response.status_code}")
            print(f"   Response: {e.response.text}")
        return False
    except Exception as e:
        print("❌ خطأ غير متوقع:")
        print("❌ Unexpected error:")
        print(f"   {e}")
        return False


def test_render_health():
    """اختبار Render Health Check"""
    print("=" * 60)
    print("🧪 اختبار 2: Render Health Check")
    print("🧪 Test 2: Render Health Check")
    print("=" * 60)
    print()
    
    try:
        print(f"📤 التحقق من {RENDER_URL}/health/...")
        print(f"📤 Checking {RENDER_URL}/health/...")
        print()
        
        response = requests.get(
            f"{RENDER_URL}/health/",
            timeout=10
        )
        
        if response.status_code == 200:
            print("✅ Render Service يعمل!")
            print("✅ Render Service is running!")
            print(f"   Response: {response.text}")
            print()
            return True
        else:
            print(f"⚠️  Render Service متاح لكن Health Check فشل")
            print(f"⚠️  Render Service available but Health Check failed")
            print(f"   Status: {response.status_code}")
            print(f"   Response: {response.text}")
            print()
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Render Service غير متاح (Timeout)")
        print("❌ Render Service unavailable (Timeout)")
        print("   قد تكون الخدمة متوقفة أو هناك مشكلة في الاتصال")
        print("   Service may be stopped or there's a connection issue")
        print()
        return False
    except requests.exceptions.RequestException as e:
        print("❌ خطأ في الاتصال بـ Render:")
        print("❌ Error connecting to Render:")
        print(f"   {e}")
        print()
        return False


def test_ai_assistant_render():
    """اختبار AI Assistant على Render"""
    print("=" * 60)
    print("🧪 اختبار 3: AI Assistant على Render")
    print("🧪 Test 3: AI Assistant on Render")
    print("=" * 60)
    print()
    
    # أولاً نحتاج JWT token - سنستخدم username/password
    print("📝 ملاحظة: هذا الاختبار يحتاج JWT token")
    print("📝 Note: This test requires JWT token")
    print("   يمكنك الحصول على token من Flutter App أو من:")
    print("   You can get token from Flutter App or from:")
    print(f"   POST {RENDER_URL}/api/token/")
    print()
    
    # محاولة الحصول على token
    try:
        login_data = {
            "username": "admin",
            "password": "admin123"
        }
        
        print("📤 محاولة تسجيل الدخول...")
        print("📤 Attempting login...")
        print()
        
        login_response = requests.post(
            f"{RENDER_URL}/api/token/",
            json=login_data,
            timeout=30
        )
        
        if login_response.status_code == 200:
            token_data = login_response.json()
            access_token = token_data.get('access')
            
            if access_token:
                print("✅ تم الحصول على JWT token!")
                print("✅ JWT token obtained!")
                print()
                
                # اختبار AI Assistant
                chat_data = {
                    "query": "ما هي شروط عقد البيع في القانون اليمني؟",
                    "conversation_history": []
                }
                
                headers = {
                    'Content-Type': 'application/json',
                    'Authorization': f'Bearer {access_token}'
                }
                
                print("📤 إرسال طلب إلى AI Assistant...")
                print("📤 Sending request to AI Assistant...")
                print()
                
                chat_response = requests.post(
                    f"{RENDER_URL}/api/ai/chat/",
                    json=chat_data,
                    headers=headers,
                    timeout=60
                )
                
                if chat_response.status_code == 200:
                    result = chat_response.json()
                    print("✅ نجح طلب AI Assistant!")
                    print("✅ AI Assistant request successful!")
                    print()
                    print("📝 الاستجابة:")
                    print("📝 Response:")
                    print("-" * 60)
                    print(json.dumps(result, indent=2, ensure_ascii=False))
                    print()
                    print("=" * 60)
                    print("✅ اختبار AI Assistant على Render نجح!")
                    print("✅ AI Assistant test on Render successful!")
                    print("=" * 60)
                    print()
                    return True
                else:
                    print(f"❌ فشل طلب AI Assistant")
                    print(f"❌ AI Assistant request failed")
                    print(f"   Status: {chat_response.status_code}")
                    print(f"   Response: {chat_response.text}")
                    print()
                    return False
            else:
                print("⚠️  لم يتم العثور على access token في الاستجابة")
                print("⚠️  Access token not found in response")
                print()
                return False
        else:
            print(f"❌ فشل تسجيل الدخول")
            print(f"❌ Login failed")
            print(f"   Status: {login_response.status_code}")
            print(f"   Response: {login_response.text}")
            print()
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Render Service غير متاح (Timeout)")
        print("❌ Render Service unavailable (Timeout)")
        print()
        return False
    except requests.exceptions.RequestException as e:
        print("❌ خطأ في الاتصال:")
        print("❌ Connection error:")
        print(f"   {e}")
        print()
        return False


def test_ai_assistant_local():
    """اختبار AI Assistant محلياً (يتطلب Django running)"""
    print("=" * 60)
    print("🧪 اختبار 4: AI Assistant محلياً")
    print("🧪 Test 4: AI Assistant locally")
    print("=" * 60)
    print()
    
    try:
        import django
        django.setup()
        
        from ai_assistant.services_groq import AIAssistantServiceGroq
        
        print("📤 تهيئة AIAssistantServiceGroq...")
        print("📤 Initializing AIAssistantServiceGroq...")
        print()
        
        service = AIAssistantServiceGroq(use_groq=True)
        
        print("✅ تم تهيئة الخدمة!")
        print("✅ Service initialized!")
        print()
        
        print("📤 إرسال استفسار...")
        print("📤 Sending query...")
        print()
        
        result = service.get_ai_response(
            "ما هي شروط عقد البيع في القانون اليمني؟",
            conversation_history=[]
        )
        
        print("✅ نجح الطلب!")
        print("✅ Request successful!")
        print()
        print("📝 الاستجابة:")
        print("📝 Response:")
        print("-" * 60)
        print(result.get('response', 'No response'))
        print()
        print("=" * 60)
        print("✅ اختبار AI Assistant محلياً نجح!")
        print("✅ Local AI Assistant test successful!")
        print("=" * 60)
        print()
        
        return True
        
    except ImportError as e:
        print("⚠️  لا يمكن استيراد Django")
        print("⚠️  Cannot import Django")
        print(f"   {e}")
        print("   تأكد من تشغيل Django محلياً")
        print("   Make sure Django is running locally")
        print()
        return False
    except ValueError as e:
        print("❌ خطأ في تهيئة الخدمة:")
        print("❌ Service initialization error:")
        print(f"   {e}")
        print("   تأكد من إضافة GROQ_API_KEY")
        print("   Make sure to add GROQ_API_KEY")
        print()
        return False
    except Exception as e:
        print("❌ خطأ غير متوقع:")
        print("❌ Unexpected error:")
        print(f"   {e}")
        print()
        return False


def main():
    """تشغيل جميع الاختبارات"""
    print()
    print("=" * 60)
    print("🚀 اختبار شامل لـ AI Assistant")
    print("🚀 Comprehensive AI Assistant Testing")
    print("=" * 60)
    print()
    
    results = {}
    
    # اختبار 1: Groq API مباشرة
    results['groq_direct'] = test_groq_api_direct()
    
    # اختبار 2: Render Health Check
    results['render_health'] = test_render_health()
    
    # اختبار 3: AI Assistant على Render (إذا كان Health Check نجح)
    if results['render_health']:
        results['ai_render'] = test_ai_assistant_render()
    else:
        print("⏭️  تخطي اختبار AI Assistant على Render (Health Check فشل)")
        print("⏭️  Skipping AI Assistant test on Render (Health Check failed)")
        print()
        results['ai_render'] = None
    
    # اختبار 4: AI Assistant محلياً
    results['ai_local'] = test_ai_assistant_local()
    
    # ملخص النتائج
    print()
    print("=" * 60)
    print("📊 ملخص النتائج")
    print("📊 Results Summary")
    print("=" * 60)
    print()
    print(f"✅ Groq API مباشرة: {'نجح' if results['groq_direct'] else 'فشل'}")
    print(f"✅ Direct Groq API: {'Success' if results['groq_direct'] else 'Failed'}")
    print()
    print(f"✅ Render Health Check: {'نجح' if results['render_health'] else 'فشل'}")
    print(f"✅ Render Health Check: {'Success' if results['render_health'] else 'Failed'}")
    print()
    if results['ai_render'] is not None:
        print(f"✅ AI Assistant على Render: {'نجح' if results['ai_render'] else 'فشل'}")
        print(f"✅ AI Assistant on Render: {'Success' if results['ai_render'] else 'Failed'}")
    else:
        print("⏭️  AI Assistant على Render: تم التخطي")
        print("⏭️  AI Assistant on Render: Skipped")
    print()
    print(f"✅ AI Assistant محلياً: {'نجح' if results['ai_local'] else 'فشل'}")
    print(f"✅ Local AI Assistant: {'Success' if results['ai_local'] else 'Failed'}")
    print()
    print("=" * 60)
    print()
    
    # توصيات
    if not results['groq_direct']:
        print("⚠️  توصية: أضف GROQ_API_KEY إلى .env أو environment variables")
        print("⚠️  Recommendation: Add GROQ_API_KEY to .env or environment variables")
        print()
    
    if not results['render_health']:
        print("⚠️  توصية: تحقق من أن Render Service يعمل")
        print("⚠️  Recommendation: Check that Render Service is running")
        print()
    
    if results['groq_direct'] and results['render_health']:
        print("🎉 يمكنك الآن استخدام AI Assistant!")
        print("🎉 You can now use AI Assistant!")
        print()
        print("📝 الخطوة التالية:")
        print("📝 Next steps:")
        print("   1. تأكد من إضافة GROQ_API_KEY إلى Render Environment Variables")
        print("   1. Make sure to add GROQ_API_KEY to Render Environment Variables")
        print("   2. اختبر من Flutter App")
        print("   2. Test from Flutter App")
        print()


if __name__ == "__main__":
    main()
