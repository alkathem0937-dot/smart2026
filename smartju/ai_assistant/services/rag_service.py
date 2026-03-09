# smartju/ai_assistant/services/rag_service.py

import os
import httpx
import logging
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

class RAGService:
    """
    Service to interact with the Hugging Face RAG API.
    خدمة للتفاعل مع واجهة برمجة تطبيقات RAG المستضافة على Hugging Face.
    """
    def __init__(self):
        self.rag_api_url = os.getenv("RAG_API_URL")
        if not self.rag_api_url:
            logger.error("RAG_API_URL environment variable not set.")
            raise ValueError("RAG_API_URL environment variable not set.")
        self.client = httpx.Client(base_url=self.rag_api_url, timeout=30.0)

    def _make_request(self, method: str, endpoint: str, json_data: Optional[Dict] = None) -> Any:
        """
        Helper method to make HTTP requests to the RAG API.
        دالة مساعدة لإجراء طلبات HTTP إلى واجهة برمجة تطبيقات RAG.
        """
        try:
            response = self.client.request(method, endpoint, json=json_data)
            response.raise_for_status()  # Raise an exception for HTTP errors (4xx or 5xx)
            return response.json()
        except httpx.RequestError as e:
            logger.error(f"RAG API Request failed for {endpoint}: {e}")
            raise ConnectionError(f"Could not connect to RAG API: {e}")
        except httpx.HTTPStatusError as e:
            logger.error(f"RAG API returned HTTP error {e.response.status_code} for {endpoint}: {e.response.text}")
            raise ValueError(f"RAG API error: {e.response.text}")
        except Exception as e:
            logger.error(f"An unexpected error occurred during RAG API call to {endpoint}: {e}")
            raise RuntimeError(f"Unexpected error with RAG API: {e}")

    def health_check(self) -> bool:
        """
        Checks the health of the RAG API.
        يتحقق من حالة عمل واجهة برمجة تطبيقات RAG.
        """
        try:
            response = self._make_request("GET", "/health")
            return response.get("status") == "ok"
        except Exception:
            return False

    def add_documents(self, documents: List[Dict]) -> bool:
        """
        Adds a list of documents to the RAG engine.
        يضيف قائمة من المستندات إلى محرك RAG.
        documents example: [{"page_content": "text", "metadata": {"source": "law_book"}}]
        """
        try:
            response = self._make_request("POST", "/add_documents", json=documents)
            logger.info(f"RAG API add_documents response: {response}")
            return "Successfully added" in response.get("message", "")
        except Exception as e:
            logger.error(f"Failed to add documents to RAG: {e}")
            return False

    def search_documents(self, query: str, k: int = 4) -> List[Dict]:
        """
        Searches for relevant documents in the RAG engine.
        يبحث عن المستندات ذات الصلة في محرك RAG.
        """
        try:
            response = self._make_request("POST", "/search", json={"query_text": query, "k": k})
            return response
        except Exception as e:
            logger.error(f"Failed to search documents in RAG: {e}")
            return []

    def delete_documents(self, ids: Optional[List[str]] = None, metadata_filter: Optional[Dict[str, Any]] = None) -> bool:
        """
        Deletes documents from the RAG engine based on IDs or metadata filter.
        يحذف المستندات من محرك RAG بناءً على المعرفات أو فلتر البيانات الوصفية.
        """
        payload = {}
        if ids:
            payload["ids"] = ids
        if metadata_filter:
            payload["metadata_filter"] = metadata_filter

        if not payload:
            logger.warning("No IDs or metadata filter provided for document deletion.")
            return False

        try:
            response = self._make_request("POST", "/delete_documents", json=payload)
            logger.info(f"RAG API delete_documents response: {response}")
            return "Successfully deleted" in response.get("message", "")
        except Exception as e:
            logger.error(f"Failed to delete documents from RAG: {e}")
            return False
