#!/usr/bin/env python3
"""
Test script for RAG Engine endpoints
سكربت اختبار لـ RAG Engine endpoints
"""

import requests
import json
import time
from typing import Dict, Any

# Base URL for Hugging Face Space
BASE_URL = "https://smartgudi-smartjudi-rag.hf.space"

def test_root_endpoint():
    """Test root endpoint (/)"""
    print("\n" + "="*60)
    print("🔍 Testing Root Endpoint (/)")
    print("="*60)
    
    try:
        response = requests.get(f"{BASE_URL}/", timeout=10)
        print(f"✅ Status Code: {response.status_code}")
        print(f"✅ Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_health_endpoint():
    """Test health endpoint (/health)"""
    print("\n" + "="*60)
    print("🔍 Testing Health Endpoint (/health)")
    print("="*60)
    
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=10)
        print(f"✅ Status Code: {response.status_code}")
        data = response.json()
        print(f"✅ Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
        
        # Check model status
        if data.get("model_loaded"):
            print("✅ Model is loaded and ready!")
        elif data.get("model_loading"):
            print("⏳ Model is still loading...")
        else:
            print("⚠️  Model not loaded yet")
        
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_healthz_endpoint():
    """Test healthz endpoint (/healthz)"""
    print("\n" + "="*60)
    print("🔍 Testing Healthz Endpoint (/healthz)")
    print("="*60)
    
    try:
        response = requests.get(f"{BASE_URL}/healthz", timeout=10)
        print(f"✅ Status Code: {response.status_code}")
        print(f"✅ Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def wait_for_model(max_wait=120, check_interval=5):
    """Wait for model to load"""
    print("\n" + "="*60)
    print("⏳ Waiting for model to load...")
    print("="*60)
    
    start_time = time.time()
    
    while time.time() - start_time < max_wait:
        try:
            response = requests.get(f"{BASE_URL}/health", timeout=10)
            data = response.json()
            
            if data.get("model_loaded") and not data.get("model_loading"):
                elapsed = time.time() - start_time
                print(f"✅ Model loaded successfully! (took {elapsed:.1f} seconds)")
                return True
            elif data.get("model_loading"):
                elapsed = time.time() - start_time
                print(f"⏳ Still loading... ({elapsed:.1f}s)")
            else:
                print("⏳ Initializing...")
        except Exception as e:
            print(f"⚠️  Error checking status: {e}")
        
        time.sleep(check_interval)
    
    print(f"❌ Timeout: Model did not load within {max_wait} seconds")
    return False

def test_search_endpoint():
    """Test search endpoint (/search)"""
    print("\n" + "="*60)
    print("🔍 Testing Search Endpoint (/search)")
    print("="*60)
    
    # First check if model is loaded
    try:
        health_response = requests.get(f"{BASE_URL}/health", timeout=10)
        health_data = health_response.json()
        
        if not health_data.get("model_loaded"):
            print("⚠️  Model not loaded yet. Skipping search test.")
            return False
    except Exception as e:
        print(f"⚠️  Could not check model status: {e}")
        return False
    
    # Test search query
    query = {
        "query_text": "قانون",
        "k": 3
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/search",
            json=query,
            timeout=30
        )
        
        print(f"✅ Status Code: {response.status_code}")
        
        if response.status_code == 200:
            results = response.json()
            print(f"✅ Found {len(results)} results")
            
            for i, result in enumerate(results[:2], 1):  # Show first 2 results
                print(f"\n📄 Result {i}:")
                print(f"   Score: {result.get('score', 'N/A'):.4f}")
                print(f"   Content: {result.get('content', '')[:100]}...")
                print(f"   Metadata: {result.get('metadata', {})}")
            
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_add_documents_endpoint():
    """Test add documents endpoint (/add_documents)"""
    print("\n" + "="*60)
    print("🔍 Testing Add Documents Endpoint (/add_documents)")
    print("="*60)
    
    # First check if model is loaded
    try:
        health_response = requests.get(f"{BASE_URL}/health", timeout=10)
        health_data = health_response.json()
        
        if not health_data.get("model_loaded"):
            print("⚠️  Model not loaded yet. Skipping add documents test.")
            return False
    except Exception as e:
        print(f"⚠️  Could not check model status: {e}")
        return False
    
    # Create a test document
    test_content = """
    هذا نص تجريبي للاختبار.
    This is a test document for testing the RAG engine.
    المادة الأولى: القانون الأساسي للدولة.
    Article 1: The basic law of the state.
    """
    
    try:
        files = {
            'files': ('test.txt', test_content.encode('utf-8'), 'text/plain')
        }
        
        response = requests.post(
            f"{BASE_URL}/add_documents",
            files=files,
            timeout=60
        )
        
        print(f"✅ Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
            print(f"✅ Successfully added {data.get('documents_added', 0)} documents")
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def run_all_tests():
    """Run all tests"""
    print("\n" + "="*60)
    print("🚀 Starting RAG Engine Tests")
    print("="*60)
    print(f"📍 Base URL: {BASE_URL}")
    
    results = {}
    
    # Test 1: Root endpoint
    results["root"] = test_root_endpoint()
    
    # Test 2: Health endpoint
    results["health"] = test_health_endpoint()
    
    # Test 3: Healthz endpoint
    results["healthz"] = test_healthz_endpoint()
    
    # Test 4: Wait for model
    model_ready = wait_for_model(max_wait=120, check_interval=5)
    results["model_loading"] = model_ready
    
    if model_ready:
        # Test 5: Search endpoint
        results["search"] = test_search_endpoint()
        
        # Test 6: Add documents endpoint
        results["add_documents"] = test_add_documents_endpoint()
    else:
        print("\n⚠️  Skipping search and add documents tests (model not ready)")
        results["search"] = False
        results["add_documents"] = False
    
    # Summary
    print("\n" + "="*60)
    print("📊 Test Results Summary")
    print("="*60)
    
    for test_name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}: {test_name}")
    
    total = len(results)
    passed = sum(1 for v in results.values() if v)
    
    print(f"\n📈 Total: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed!")
    else:
        print("⚠️  Some tests failed")
    
    return passed == total

if __name__ == "__main__":
    try:
        success = run_all_tests()
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
        exit(1)
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        exit(1)
