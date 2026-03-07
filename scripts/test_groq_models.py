#!/usr/bin/env python
"""
سكربت لاختبار النماذج المتاحة في Groq API
"""
import os
import requests
import json

# نماذج محتملة للاختبار
MODELS_TO_TEST = [
    "llama-3.1-8b-instruct",
    "llama-3.1-70b-instruct",
    "llama-3-8b-8192",
    "llama-3-70b-8192",
    "mixtral-8x7b-32768",
    "gemma-7b-it",
    "gemma2-9b-it",
    "llama-3.2-3b-instruct",
    "llama-3.2-1b-instruct",
]

def test_model(model_name, api_key):
    """اختبار نموذج معين"""
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": model_name,
        "messages": [
            {"role": "user", "content": "Hello"}
        ],
        "max_tokens": 10
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        if response.status_code == 200:
            return True, "✅ متاح"
        else:
            error = response.json().get("error", {})
            return False, f"❌ {error.get('message', response.text)}"
    except Exception as e:
        return False, f"❌ خطأ: {str(e)}"

def main():
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        print("❌ GROQ_API_KEY غير موجود في Environment Variables")
        print("   قم بتعيينه: $env:GROQ_API_KEY='your_key'")
        return
    
    print("🔍 اختبار النماذج المتاحة في Groq API...\n")
    print(f"API Key: {api_key[:10]}...{api_key[-5:]}\n")
    print("-" * 60)
    
    available_models = []
    
    for model in MODELS_TO_TEST:
        print(f"اختبار: {model:<30}", end=" ")
        success, message = test_model(model, api_key)
        print(message)
        if success:
            available_models.append(model)
    
    print("-" * 60)
    print(f"\n✅ النماذج المتاحة ({len(available_models)}):")
    for model in available_models:
        print(f"   - {model}")
    
    if available_models:
        print(f"\n💡 موصى به: {available_models[0]}")
        print(f"\nقم بتعيين GROQ_MODEL_NAME في Render إلى:")
        print(f"   GROQ_MODEL_NAME={available_models[0]}")

if __name__ == "__main__":
    main()
