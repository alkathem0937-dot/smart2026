# test_groq_api.py
# سكربت لاختبار Groq API مباشرة
# Script to test Groq API directly

import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()

# API Key
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "your_groq_api_key_here")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
MODEL_NAME = "qwen2.5-7b-instruct"

def test_groq_api():
    """اختبار Groq API"""
    print("=" * 50)
    print("اختبار Groq API")
    print("Testing Groq API")
    print("=" * 50)
    print()
    
    # رسائل الاختبار
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
        print("📤 إرسال الطلب...")
        print("📤 Sending request...")
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
        print("-" * 50)
        
        if 'choices' in result and len(result['choices']) > 0:
            assistant_message = result['choices'][0]['message']['content']
            print(assistant_message)
        else:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        
        print()
        print("=" * 50)
        print("✅ الاختبار نجح!")
        print("✅ Test successful!")
        print("=" * 50)
        
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

if __name__ == "__main__":
    # تثبيت المتطلبات إذا لزم الأمر:
    # pip install requests python-dotenv
    
    success = test_groq_api()
    
    if success:
        print()
        print("🎉 يمكنك الآن إضافة API key إلى Render!")
        print("🎉 You can now add API key to Render!")
    else:
        print()
        print("⚠️  تحقق من API key وإعدادات الاتصال")
        print("⚠️  Check API key and connection settings")
