#!/usr/bin/env python3
"""
Test search after adding documents
اختبار البحث بعد إضافة المستندات
"""

import requests
import json

BASE_URL = "https://smartgudi-smartjudi-rag.hf.space"

def test_full_workflow():
    """Test complete workflow: add document then search"""
    print("\n" + "="*60)
    print("🔄 Testing Complete Workflow")
    print("="*60)
    
    # Step 1: Add a test document
    print("\n📄 Step 1: Adding test document...")
    
    test_content = """
    المادة الأولى: القانون الأساسي للجمهورية اليمنية.
    المادة الثانية: الإسلام دين الدولة، واللغة العربية لغتها الرسمية.
    المادة الثالثة: الشريعة الإسلامية المصدر الرئيسي للتشريع.
    """
    
    try:
        files = {
            'files': ('test_law.txt', test_content.encode('utf-8'), 'text/plain')
        }
        
        response = requests.post(
            f"{BASE_URL}/add_documents",
            files=files,
            timeout=60
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Document added: {data.get('documents_added', 0)} chunks")
        else:
            print(f"❌ Failed to add document: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error adding document: {e}")
        return False
    
    # Step 2: Wait a moment for indexing
    print("\n⏳ Waiting for indexing...")
    import time
    time.sleep(2)
    
    # Step 3: Search for the document
    print("\n🔍 Step 2: Searching for 'قانون'...")
    
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
        
        if response.status_code == 200:
            results = response.json()
            print(f"✅ Found {len(results)} results")
            
            for i, result in enumerate(results, 1):
                print(f"\n📄 Result {i}:")
                print(f"   Score: {result.get('score', 'N/A'):.4f}")
                content = result.get('content', '')
                print(f"   Content: {content[:150]}...")
                print(f"   Metadata: {result.get('metadata', {})}")
            
            if len(results) > 0:
                print("\n🎉 Search is working correctly!")
                return True
            else:
                print("\n⚠️  No results found (might need more time for indexing)")
                return False
        else:
            print(f"❌ Search failed: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error searching: {e}")
        return False

if __name__ == "__main__":
    success = test_full_workflow()
    exit(0 if success else 1)
