#!/usr/bin/env python3
"""
Test search in legal documents
اختبار البحث في المستندات القانونية
"""

import requests
import json

BASE_URL = "https://smartgudi-smartjudi-rag.hf.space"

def test_legal_search():
    """Test searching in legal documents"""
    print("\n" + "="*60)
    print("🔍 Testing Legal Documents Search")
    print("="*60)
    
    # Test queries
    test_queries = [
        {
            "query": "ما هي شروط عقد البيع؟",
            "k": 5,
            "description": "بحث عن شروط عقد البيع"
        },
        {
            "query": "القانون المدني",
            "k": 3,
            "description": "بحث عن القانون المدني"
        },
        {
            "query": "حقوق المرأة",
            "k": 3,
            "description": "بحث عن حقوق المرأة"
        }
    ]
    
    for i, test in enumerate(test_queries, 1):
        print(f"\n📋 Test {i}: {test['description']}")
        print(f"   Query: {test['query']}")
        print("-" * 60)
        
        query = {
            "query_text": test["query"],
            "k": test["k"]
        }
        
        try:
            response = requests.post(
                f"{BASE_URL}/search",
                json=query,
                timeout=30
            )
            
            if response.status_code == 200:
                results = response.json()
                print(f"✅ Found {len(results)} results\n")
                
                for j, result in enumerate(results[:3], 1):  # Show top 3
                    print(f"   Result {j}:")
                    print(f"   Score: {result.get('score', 'N/A'):.4f}")
                    content = result.get('content', '')
                    # Show first 200 characters
                    preview = content[:200] + "..." if len(content) > 200 else content
                    print(f"   Content: {preview}")
                    print(f"   Metadata: {result.get('metadata', {})}")
                    print()
            else:
                print(f"❌ Error: {response.status_code}")
                print(f"   {response.text}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    
    print("\n" + "="*60)
    print("✅ Legal search tests completed!")
    print("="*60)

if __name__ == "__main__":
    test_legal_search()
