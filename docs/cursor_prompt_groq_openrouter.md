```markdown
# Cursor AI Prompt: SmartJudi2 Project Modification for RAG and Advanced LLM Integration

This prompt provides detailed instructions for Cursor AI to modify the existing SmartJudi2 project, integrating a Retrieval-Augmented Generation (RAG) engine hosted on Hugging Face Spaces, utilizing Groq Cloud as the primary Large Language Model (LLM) provider, and OpenRouter as a fallback LLM. The modifications will cover the Django backend, Flutter frontend, and include a data loading script.

## Project Structure Overview

The SmartJudi2 project on GitHub (`https://github.com/tfyemen-afk/smartjudi2`) consists of:
-   **Django Backend**: Located in the `smartju` directory. The backend is deployed on Render at `https://smartjudi-nls1.onrender.com`.
-   **Flutter Frontend**: Located in the `lib` directory. Already contains `lib/config/api_config.dart` and `lib/services/ai_api_service.dart`.
-   **RAG Engine**: Located in the `rag_engine` directory (already exists in the project). Contains a FastAPI application with ChromaDB integration.

## Recent Project Updates (Already Implemented - DO NOT Duplicate)

The following features have already been added to the project. Cursor AI must review these existing files and build upon them, not replace them:
1. `rag_engine/main.py`: Already supports PDF file uploads with OCR processing using `pytesseract` and `pdf2image` for extracting text from scanned legal documents.
2. `smartju/ai_assistant/services_groq.py`: Already exists and handles Groq Cloud API integration.
3. `smartju/ai_assistant/views.py`: Already supports switching between Groq (primary) and fallback LLM.
4. `lib/config/api_config.dart`: Already configured with production URL `https://smartjudi-nls1.onrender.com`.
5. `lib/services/ai_api_service.dart`: Already exists for AI chat API communication.

## Architectural Goals

1.  **Hugging Face Spaces**: Host the RAG engine (multilingual-e5-large embedding model + ChromaDB + FastAPI) - already has a `rag_engine` directory, enhance it.
2.  **Groq Cloud**: Primary LLM provider (llama-3.3-70b-versatile) - `services_groq.py` already exists, enhance it.
3.  **OpenRouter**: Fallback LLM provider (supporting Qwen models like `qwen/qwen3-4b:free`).
4.  **Django on Render**: Backend at `https://smartjudi-nls1.onrender.com`, with enhanced AI integrations.
5.  **Flutter**: Frontend with existing `ai_api_service.dart`, needs UI enhancements.

## Part 1: Enhance the Existing RAG Engine (rag_engine directory)

Cursor AI, the `rag_engine` directory already exists in the project. DO NOT create it from scratch. Instead, review the existing `rag_engine/main.py` and enhance it with the following improvements. The existing code already supports PDF uploads with OCR (pytesseract + pdf2image). Build upon this foundation.

### 1.1 Dockerfile

Create a `Dockerfile` in the root of the Hugging Face Space project. This Dockerfile will set up the environment for the FastAPI application.

```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.11-slim-buster

# Set the working directory in the container
WORKDIR /app

# Install system dependencies
# تثبيت التبعيات اللازمة للنظام
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container at /app
# نسخ ملف المتطلبات إلى مجلد التطبيق
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
# تثبيت الحزم المطلوبة من ملف requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container at /app
# نسخ باقي كود التطبيق إلى مجلد التطبيق
COPY . .

# Expose the port that the FastAPI application will run on
# تحديد المنفذ الذي سيعمل عليه تطبيق FastAPI
EXPOSE 8000

# Define the command to run the FastAPI application using Uvicorn
# تعريف الأمر لتشغيل تطبيق FastAPI باستخدام Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 1.2 main.py (FastAPI Application)

Create a `main.py` file. This file will contain the FastAPI application, integrating the embedding model and ChromaDB for RAG functionalities.

```python
# main.py

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
import logging
import os

from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_core.documents import Document

# Configure logging
# إعداد نظام التسجيل (logging)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI(
    title="SmartJudi2 RAG Engine",
    description="FastAPI service for Retrieval-Augmented Generation using ChromaDB and HuggingFace Embeddings.",
    version="1.0.0",
)

# Global variables for embedding model and vector store
# متغيرات عامة لنموذج التضمين ومخزن المتجهات
embeddings = None
vectorstore = None

# Configuration for embedding model and ChromaDB
# إعدادات نموذج التضمين و ChromaDB
EMBEDDING_MODEL_NAME = "sentence-transformers/multilingual-e5-large"
CHROMA_DB_PATH = os.getenv("CHROMA_DB_PATH", "./chroma_db") # Persistent storage

class DocumentSchema(BaseModel):
    page_content: str = Field(..., description="The textual content of the document.")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Arbitrary metadata associated with the document.")

class SearchQuery(BaseModel):
    query_text: str = Field(..., description="The query string to search for.")
    k: int = Field(default=4, ge=1, le=10, description="The number of relevant documents to retrieve.")

class DeleteQuery(BaseModel):
    ids: Optional[List[str]] = Field(None, description="List of document IDs to delete.")
    metadata_filter: Optional[Dict[str, Any]] = Field(None, description="Metadata to filter documents for deletion.")

@app.on_event("startup")
async def startup_event():
    """
    Initialize the embedding model and ChromaDB on application startup.
    تهيئة نموذج التضمين و ChromaDB عند بدء تشغيل التطبيق.
    """
    global embeddings, vectorstore
    try:
        logger.info("Initializing HuggingFaceEmbeddings...")
        embeddings = HuggingFaceEmbeddings(model_name=EMBEDDING_MODEL_NAME)
        logger.info("HuggingFaceEmbeddings initialized successfully.")

        logger.info(f"Initializing ChromaDB at {CHROMA_DB_PATH}...")
        # Initialize ChromaDB with persistent storage
        # تهيئة ChromaDB مع التخزين الدائم
        vectorstore = Chroma(persist_directory=CHROMA_DB_PATH, embedding_function=embeddings)
        vectorstore.persist()
        logger.info("ChromaDB initialized and persisted successfully.")
    except Exception as e:
        logger.error(f"Failed to initialize RAG components: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to initialize RAG components: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    """
    Persist ChromaDB on application shutdown.
    حفظ ChromaDB عند إغلاق التطبيق.
    """
    global vectorstore
    if vectorstore:
        try:
            vectorstore.persist()
            logger.info("ChromaDB persisted successfully on shutdown.")
        except Exception as e:
            logger.error(f"Failed to persist ChromaDB on shutdown: {e}")

@app.get("/health", summary="Health Check", response_model=Dict[str, str])
async def health_check():
    """
    Checks the health of the RAG engine.
    يتحقق من حالة عمل محرك RAG.
    """
    logger.info("Health check requested.")
    if embeddings is None or vectorstore is None:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="RAG components not initialized.")
    return {"status": "ok"}

@app.post("/add_documents", summary="Add Documents to ChromaDB", response_model=Dict[str, str])
async def add_documents(documents: List[DocumentSchema]):
    """
    Adds a list of documents to the ChromaDB vector store.
    يضيف قائمة من المستندات إلى مخزن المتجهات ChromaDB.
    """
    if not vectorstore:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Vector store not initialized.")
    try:
        langchain_documents = [Document(page_content=doc.page_content, metadata=doc.metadata) for doc in documents]
        logger.info(f"Adding {len(langchain_documents)} documents to ChromaDB.")
        vectorstore.add_documents(langchain_documents)
        vectorstore.persist()
        logger.info(f"Successfully added {len(langchain_documents)} documents.")
        return {"message": f"Successfully added {len(langchain_documents)} documents."}
    except Exception as e:
        logger.error(f"Error adding documents: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to add documents: {e}")

@app.post("/search", summary="Search for Relevant Documents", response_model=List[DocumentSchema])
async def search_documents(query: SearchQuery):
    """
    Searches the ChromaDB vector store for documents relevant to the given query.
    يبحث في مخزن المتجهات ChromaDB عن المستندات ذات الصلة بالاستعلام المحدد.
    """
    if not vectorstore:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Vector store not initialized.")
    try:
        logger.info(f"Searching ChromaDB for query: '{query.query_text}' with k={query.k}")
        results = vectorstore.similarity_search(query.query_text, k=query.k)
        logger.info(f"Found {len(results)} relevant documents.")
        return [DocumentSchema(page_content=doc.page_content, metadata=doc.metadata) for doc in results]
    except Exception as e:
        logger.error(f"Error searching documents: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to search documents: {e}")

@app.post("/delete_documents", summary="Delete Documents from ChromaDB", response_model=Dict[str, str])
async def delete_documents(delete_query: DeleteQuery):
    """
    Deletes documents from the ChromaDB vector store based on IDs or metadata filter.
    يحذف المستندات من مخزن المتجهات ChromaDB بناءً على المعرفات أو فلتر البيانات الوصفية.
    """
    if not vectorstore:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Vector store not initialized.")
    
    if not delete_query.ids and not delete_query.metadata_filter:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Either 'ids' or 'metadata_filter' must be provided.")

    try:
        if delete_query.ids:
            logger.info(f"Deleting documents with IDs: {delete_query.ids}")
            vectorstore.delete(ids=delete_query.ids)
            vectorstore.persist()
            logger.info(f"Successfully deleted documents with IDs: {delete_query.ids}")
            return {"message": f"Successfully deleted documents with IDs: {delete_query.ids}"}
        elif delete_query.metadata_filter:
            logger.info(f"Deleting documents with metadata filter: {delete_query.metadata_filter}")
            # ChromaDB's delete method doesn't directly support metadata filtering for deletion in all versions
            # A workaround might be to retrieve documents first and then delete by ID, or ensure ChromaDB version supports it.
            # For simplicity, this example assumes direct metadata filtering is supported or IDs are preferred.
            # If direct metadata filtering is not supported, this part would need adjustment.
            # For now, we'll simulate it or rely on a ChromaDB version that supports it.
            # For a robust solution, one might need to query for documents matching the filter and then delete by their IDs.
            
            # As a direct approach, if ChromaDB.delete() supports where clause for metadata:
            vectorstore.delete(where=delete_query.metadata_filter)
            vectorstore.persist()
            logger.info(f"Successfully deleted documents with metadata filter: {delete_query.metadata_filter}")
            return {"message": f"Successfully deleted documents with metadata filter: {delete_query.metadata_filter}"}
    except Exception as e:
        logger.error(f"Error deleting documents: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to delete documents: {e}")

```

### 1.3 requirements.txt

Create a `requirements.txt` file in the root of the Hugging Face Space project.

```
# requirements.txt
fastapi==0.110.0
uvicorn==0.29.0
langchain==0.1.13
langchain-community==0.0.29
chromadb==0.4.24
sentence-transformers==2.2.2
pydantic==2.6.4
python-dotenv==1.0.1
```

## Part 2: Modify Django Project (smartju)

Cursor AI, please apply the following modifications to the `smartju` Django project.

### 2.1 Create `ai_assistant` App

First, create a new Django app named `ai_assistant` within the `smartju` project directory.

```bash
# Navigate to the smartju directory if not already there
# cd smartju
python manage.py startapp ai_assistant
```

### 2.2 RAGService (`ai_assistant/services/rag_service.py`)

Create a new directory `services` inside `ai_assistant`, and then create `rag_service.py` within it. This service will handle communication with the Hugging Face RAG API.

```python
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

```

### 2.3 LLMService (`ai_assistant/services/llm_service.py`)

Create `llm_service.py` in the `ai_assistant/services` directory. This service will manage interactions with Groq and OpenRouter LLMs, including fallback logic.

```python
# smartju/ai_assistant/services/llm_service.py

import os
import httpx
import logging
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

class LLMService:
    """
    Service to interact with Groq and OpenRouter LLMs, with fallback mechanism.
    خدمة للتفاعل مع نماذج اللغة الكبيرة (LLMs) من Groq و OpenRouter، مع آلية احتياطية.
    """
    def __init__(self):
        self.groq_api_key = os.getenv("GROQ_API_KEY")
        self.openrouter_api_key = os.getenv("OPENROUTER_API_KEY")

        if not self.groq_api_key:
            logger.warning("GROQ_API_KEY environment variable not set. Groq will be unavailable.")
        if not self.openrouter_api_key:
            logger.warning("OPENROUTER_API_KEY environment variable not set. OpenRouter will be unavailable.")

        self.groq_client = httpx.Client(base_url="https://api.groq.com/openai/v1", headers={"Authorization": f"Bearer {self.groq_api_key}"}, timeout=60.0) if self.groq_api_key else None
        self.openrouter_client = httpx.Client(base_url="https://openrouter.ai/api/v1", headers={"Authorization": f"Bearer {self.openrouter_api_key}", "HTTP-Referer": "https://smartjudi2.com", "X-Title": "SmartJudi2"}, timeout=60.0) if self.openrouter_api_key else None

        self.system_prompt = """
أنت مساعد قانوني خبير في القانون اليمني. مهمتك هي تقديم استشارات قانونية دقيقة وموثوقة بناءً على القوانين والتشريعات اليمنية. يجب أن تكون إجاباتك واضحة، موجزة، ومستندة إلى النصوص القانونية المتاحة. تجنب التكهنات أو تقديم آراء شخصية. عند الإشارة إلى مواد قانونية، اذكر رقم المادة والقانون الذي تنتمي إليه. حافظ على نبرة احترافية ومحايدة.

Think step-by-step. First, identify the key legal concepts in the user's query. Second, analyze the provided context for relevant information. Third, formulate an answer based on Yemeni law, citing specific articles if applicable. Finally, present your answer clearly and concisely.

Few-shot Examples:
User: ما هي شروط عقد البيع في القانون اليمني؟
AI: شروط عقد البيع في القانون اليمني، وفقاً لقانون البيع رقم (24) لسنة 2002، هي كالتالي:
1.  الرضا: يجب أن يكون هناك رضا متبادل بين البائع والمشتري.
2.  المحل: يجب أن يكون المبيع موجوداً أو ممكن الوجود، ومعيناً أو قابلاً للتعيين، ومشروعاً التعامل فيه.
3.  الثمن: يجب أن يكون الثمن معلوماً ومقدراً.
(المادة 12 من قانون البيع اليمني رقم 24 لسنة 2002).

User: هل يجوز للمرأة أن تطلب الطلاق في اليمن؟ وما هي الحالات؟
AI: نعم، يجوز للمرأة أن تطلب الطلاق (الخلع) في القانون اليمني، وذلك وفقاً لأحكام قانون الأحوال الشخصية رقم (20) لسنة 1992. من الحالات التي يجوز فيها للمرأة طلب الطلاق:
1.  إذا أضر الزوج بزوجته ضرراً لا يمكن معه دوام العشرة بالمعروف.
2.  إذا غاب الزوج عن زوجته مدة تزيد عن سنة دون عذر مقبول.
3.  إذا امتنع الزوج عن الإنفاق على زوجته.
(المواد 60-65 من قانون الأحوال الشخصية اليمني رقم 20 لسنة 1992).
"""

    def _call_llm(self, client: httpx.Client, model: str, messages: List[Dict], max_tokens: int = 1024, temperature: float = 0.7) -> str:
        """
        Helper method to call a specific LLM API.
        دالة مساعدة لاستدعاء واجهة برمجة تطبيقات نموذج اللغة الكبير (LLM) محددة.
        """
        try:
            payload = {
                "model": model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": temperature,
            }
            response = client.post("/chat/completions", json=payload)
            response.raise_for_status()
            return response.json()["choices"][0]["message"]["content"]
        except httpx.RequestError as e:
            logger.error(f"LLM API Request failed for model {model}: {e}")
            raise ConnectionError(f"Could not connect to LLM API ({model}): {e}")
        except httpx.HTTPStatusError as e:
            logger.error(f"LLM API returned HTTP error {e.response.status_code} for model {model}: {e.response.text}")
            raise ValueError(f"LLM API error ({model}): {e.response.text}")
        except Exception as e:
            logger.error(f"An unexpected error occurred during LLM API call to model {model}: {e}")
            raise RuntimeError(f"Unexpected error with LLM API ({model}): {e}")

    def generate_response(self, user_query: str, rag_context: str, conversation_history: List[Dict], temperature: float = 0.7) -> str:
        """
        Generates a response using Groq as primary and OpenRouter as fallback.
        يولد استجابة باستخدام Groq كنموذج أساسي و OpenRouter كنموذج احتياطي.
        """
        messages = [{"role": "system", "content": self.system_prompt}]
        messages.extend(conversation_history)

        # Integrate RAG context into the user's current query
        # دمج سياق RAG في استعلام المستخدم الحالي
        prompt_template = f"""
Context: {rag_context}
User Query: {user_query}
Based on the provided context and your knowledge of Yemeni law, please answer the user's query.
"""
        messages.append({"role": "user", "content": prompt_template})

        # Try Groq first
        # محاولة Groq أولاً
        if self.groq_client:
            try:
                logger.info("Attempting to generate response with Groq...")
                response = self._call_llm(self.groq_client, "llama3-8b-8192", messages, temperature=temperature) # Using llama3-8b-8192 as llama-3.3-70b-versatile might not be directly available via API name
                logger.info("Response generated successfully with Groq.")
                return response
            except Exception as e:
                logger.warning(f"Groq failed, attempting fallback to OpenRouter: {e}")

        # Fallback to OpenRouter
        # الانتقال إلى OpenRouter كخيار احتياطي
        if self.openrouter_client:
            try:
                logger.info("Attempting to generate response with OpenRouter...")
                # Using a common Qwen model name, adjust if a specific one is preferred
                response = self._call_llm(self.openrouter_client, "qwen/qwen-110b-chat", messages, temperature=temperature)
                logger.info("Response generated successfully with OpenRouter.")
                return response
            except Exception as e:
                logger.error(f"OpenRouter also failed: {e}")
                raise RuntimeError("Both Groq and OpenRouter LLMs failed to generate a response.")
        
        raise RuntimeError("No LLM client available or both failed to generate a response.")

```

### 2.4 AIAssistantService (`ai_assistant/services/ai_assistant_service.py`)

Create `ai_assistant_service.py` in the `ai_assistant/services` directory. This service orchestrates the RAG and LLM interactions.

```python
# smartju/ai_assistant/services/ai_assistant_service.py

import logging
from typing import List, Dict, Any

from .rag_service import RAGService
from .llm_service import LLMService

logger = logging.getLogger(__name__)

class AIAssistantService:
    """
    Orchestrates RAG and LLM services to provide AI assistant functionality.
    تنسيق خدمات RAG و LLM لتوفير وظائف المساعد الذكي.
    """
    def __init__(self):
        self.rag_service = RAGService()
        self.llm_service = LLMService()

    def get_ai_response(self, user_query: str, conversation_history: List[Dict]) -> str:
        """
        Retrieves relevant documents using RAG and generates an AI response.
        يسترجع المستندات ذات الصلة باستخدام RAG ويولد استجابة من الذكاء الاصطناعي.
        """
        logger.info(f"Received user query: {user_query}")

        # 1. Retrieve relevant documents from RAG
        # 1. استرجاع المستندات ذات الصلة من RAG
        retrieved_docs = self.rag_service.search_documents(user_query, k=5)
        rag_context = "\n\n".join([doc["page_content"] for doc in retrieved_docs])
        
        if not rag_context:
            logger.warning("No relevant documents found for the query. Proceeding with LLM only.")
            rag_context = "No specific legal context found."

        logger.debug(f"RAG Context: {rag_context[:200]}...") # Log first 200 chars of context

        # 2. Generate response using LLM with RAG context and conversation history
        # 2. توليد استجابة باستخدام LLM مع سياق RAG وتاريخ المحادثة
        try:
            ai_response = self.llm_service.generate_response(
                user_query=user_query,
                rag_context=rag_context,
                conversation_history=conversation_history
            )
            logger.info("AI response generated successfully.")
            return ai_response
        except Exception as e:
            logger.error(f"Failed to generate AI response: {e}")
            return "عذرًا، حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى لاحقًا." # Arabic error message

```

### 2.5 Views (`ai_assistant/views.py`)

Modify `ai_assistant/views.py` to include an API endpoint for the AI assistant.

```python
# smartju/ai_assistant/views.py

import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .services.ai_assistant_service import AIAssistantService
from .serializers import ChatRequestSerializer, ChatResponseSerializer

logger = logging.getLogger(__name__)

class AIAssistantChatView(APIView):
    """
    API endpoint for interacting with the AI legal assistant.
    نقطة نهاية API للتفاعل مع المساعد القانوني الذكي.
    """
    def post(self, request, *args, **kwargs):
        serializer = ChatRequestSerializer(data=request.data)
        if serializer.is_valid():
            user_query = serializer.validated_data.get("user_query")
            conversation_history = serializer.validated_data.get("conversation_history", [])

            try:
                ai_assistant_service = AIAssistantService()
                ai_response_content = ai_assistant_service.get_ai_response(user_query, conversation_history)
                
                response_data = {
                    "ai_response": ai_response_content,
                    "conversation_history": conversation_history + [
                        {"role": "user", "content": user_query},
                        {"role": "assistant", "content": ai_response_content}
                    ]
                }
                return Response(ChatResponseSerializer(response_data).data, status=status.HTTP_200_OK)
            except Exception as e:
                logger.error(f"Error in AIAssistantChatView: {e}", exc_info=True)
                return Response(
                    {"error": "An internal server error occurred.", "details": str(e)},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

```

### 2.6 URLs (`ai_assistant/urls.py` and `smartju/urls.py`)

Create `ai_assistant/urls.py`:

```python
# smartju/ai_assistant/urls.py

from django.urls import path
from .views import AIAssistantChatView

urlpatterns = [
    path('chat/', AIAssistantChatView.as_view(), name='ai_assistant_chat'),
]
```

Modify `smartju/urls.py` to include the new app's URLs:

```python
# smartju/smartju/urls.py

from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/ai-assistant/', include('ai_assistant.urls')), # Add this line
    # ... other paths
]
```

### 2.7 Serializers (`ai_assistant/serializers.py`)

Create `ai_assistant/serializers.py` for request and response data validation and formatting.

```python
# smartju/ai_assistant/serializers.py

from rest_framework import serializers

class ChatRequestSerializer(serializers.Serializer):
    """
    Serializer for incoming chat requests.
    مُسلسل لطلبات الدردشة الواردة.
    """
    user_query = serializers.CharField(max_length=1000)
    conversation_history = serializers.ListField(child=serializers.DictField(), required=False, default=[])

class ChatResponseSerializer(serializers.Serializer):
    """
    Serializer for outgoing chat responses.
    مُسلسل لاستجابات الدردشة الصادرة.
    """
    ai_response = serializers.CharField()
    conversation_history = serializers.ListField(child=serializers.DictField())

```

### 2.8 .env Settings

Ensure your `.env` file (or environment variables on Render) includes these settings. Cursor AI, please instruct the user to add these to their `.env` file.

```dotenv
# .env
RAG_API_URL=YOUR_HUGGING_FACE_SPACE_URL # e.g., https://your-username-your-space-name.hf.space
GROQ_API_KEY=YOUR_GROQ_API_KEY
OPENROUTER_API_KEY=YOUR_OPENROUTER_API_KEY
```

### 2.9 settings.py Modifications

Modify `smartju/smartju/settings.py`:

1.  Add `ai_assistant` to `INSTALLED_APPS`.
2.  Configure `python-dotenv` to load environment variables.

```python
# smartju/smartju/settings.py

import os
from pathlib import Path
from dotenv import load_dotenv # Import load_dotenv

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env file
# تحميل متغيرات البيئة من ملف .env
load_dotenv(os.path.join(BASE_DIR, '.env'))

# ... existing settings ...

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'ai_assistant', # Add the new app here
    # ... other apps
]

# ... other settings ...

# Example of how to access environment variables
# مثال على كيفية الوصول إلى متغيرات البيئة
RAG_API_URL = os.getenv("RAG_API_URL")
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

# Ensure these are available for services
# التأكد من توفر هذه المتغيرات للخدمات
if not RAG_API_URL:
    raise ImproperlyConfigured("RAG_API_URL not found in environment variables.")
if not GROQ_API_KEY:
    # This is a warning, as Groq might be optional if OpenRouter is sufficient for testing
    print("Warning: GROQ_API_KEY not found in environment variables. Groq LLM will be unavailable.")
if not OPENROUTER_API_KEY:
    # This is a warning, as OpenRouter might be optional if Groq is sufficient for testing
    print("Warning: OPENROUTER_API_KEY not found in environment variables. OpenRouter LLM will be unavailable.")

```

### 2.10 Install Django Dependencies

Cursor AI, please instruct the user to install the new Python dependencies for the Django project.

```bash
# Navigate to the smartju directory
# cd smartju
pip install python-dotenv djangorestframework httpx
```

## Part 3: Modify Flutter Application

Cursor AI, please apply the following modifications to the `lib` Flutter project.

### 3.1 AI API Service (`lib/services/ai_api_service.dart`)

Create a new file `ai_api_service.dart` in `lib/services`.

```dart
// lib/services/ai_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For @required

class AIApiService {
  // Replace with your Django backend URL
  // استبدل بعنوان URL الخاص بالواجهة الخلفية لـ Django
  final String _baseUrl = "https://your-django-render-app.onrender.com/api/ai-assistant"; 

  Future<Map<String, dynamic>> chat({
    @required String userQuery,
    List<Map<String, dynamic>> conversationHistory = const [],
  }) async {
    final url = Uri.parse('$_baseUrl/chat/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_query': userQuery,
          'conversation_history': conversationHistory,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Log the error response for debugging
        // تسجيل استجابة الخطأ لأغراض التصحيح
        debugPrint('Error response from Django: ${response.body}');
        throw Exception('Failed to load AI response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in AIApiService.chat: $e');
      throw Exception('Failed to connect to AI service: $e');
    }
  }
}
```

### 3.2 Provider/State Management (`lib/providers/chat_provider.dart`)

Create a new file `chat_provider.dart` in `lib/providers`.

```dart
// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../services/ai_api_service.dart';

class ChatProvider with ChangeNotifier {
  final AIApiService _apiService = AIApiService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider() {
    // Initial system message or welcome message
    // رسالة ترحيب أو رسالة نظام أولية
    _messages.add({'role': 'assistant', 'content': 'مرحباً بك في مساعدك القانوني الذكي. كيف يمكنني مساعدتك اليوم؟'});
  }

  Future<void> sendMessage(String userQuery) async {
    _messages.add({'role': 'user', 'content': userQuery});
    _isLoading = true;
    notifyListeners();

    try {
      // Prepare conversation history for the API call
      // إعداد سجل المحادثة لاستدعاء API
      List<Map<String, dynamic>> historyForApi = _messages.where((msg) => msg['role'] != 'system').toList();
      
      final response = await _apiService.chat(
        userQuery: userQuery,
        conversationHistory: historyForApi,
      );

      _messages.add({'role': 'assistant', 'content': response['ai_response']});
      // Update conversation history from the response (if the backend sends an updated one)
      // تحديث سجل المحادثة من الاستجابة (إذا كان الواجهة الخلفية ترسل سجل محدث)
      // _messages = response['conversation_history'].cast<Map<String, dynamic>>();

    } catch (e) {
      _messages.add({'role': 'assistant', 'content': 'عذرًا، حدث خطأ: $e'});
      debugPrint('Error sending message: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 3.3 AI Assistant Chat Interface (`lib/screens/ai_assistant_screen.dart`)

Create a new file `ai_assistant_screen.dart` in `lib/screens`.

```dart
// lib/screens/ai_assistant_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(_textController.text.trim());
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد القانوني الذكي'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                _scrollToBottom(); // Scroll to bottom when messages update
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isUser = message['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blueAccent[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Text(
                          message['content'],
                          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (Provider.of<ChatProvider>(context).isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'اكتب استفسارك القانوني...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                  backgroundColor: Colors.blueGrey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3.4 Case Analysis Screen (`lib/screens/case_analysis_screen.dart`)

Create a new file `case_analysis_screen.dart` in `lib/screens`. This screen will allow users to input case details for AI analysis.

```dart
// lib/screens/case_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart'; // Reusing chat provider for simplicity, or create a dedicated one

class CaseAnalysisScreen extends StatefulWidget {
  const CaseAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<CaseAnalysisScreen> createState() => _CaseAnalysisScreenState();
}

class _CaseAnalysisScreenState extends State<CaseAnalysisScreen> {
  final TextEditingController _caseDetailsController = TextEditingController();
  String _analysisResult = '';
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _caseDetailsController.dispose();
    super.dispose();
  }

  Future<void> _analyzeCase() async {
    if (_caseDetailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال تفاصيل القضية للتحليل.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = '';
    });

    try {
      // For simplicity, we'll reuse the chat API for analysis.
      // In a real scenario, you might have a dedicated API endpoint for case analysis.
      // لتبسيط الأمر، سنعيد استخدام واجهة برمجة تطبيقات الدردشة للتحليل.
      // في سيناريو حقيقي، قد يكون لديك نقطة نهاية API مخصصة لتحليل الحالات.
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final userQuery = "حلل القضية التالية بناءً على القانون اليمني:\n\n" + _caseDetailsController.text.trim();
      
      // Temporarily add user query to chat history for LLM context, then remove if not a chat screen
      // إضافة استعلام المستخدم مؤقتًا إلى سجل الدردشة لسياق LLM، ثم إزالته إذا لم تكن شاشة دردشة
      // This part might need refinement if a dedicated analysis API is implemented.
      await chatProvider.sendMessage(userQuery);
      
      // Assuming the last message in chatProvider.messages is the analysis result
      // بافتراض أن الرسالة الأخيرة في chatProvider.messages هي نتيجة التحليل
      setState(() {
        _analysisResult = chatProvider.messages.last['content'];
      });

    } catch (e) {
      setState(() {
        _analysisResult = 'حدث خطأ أثناء تحليل القضية: $e';
      });
      debugPrint('Error analyzing case: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل القضايا بالذكاء الاصطناعي'),
        backgroundColor: Colors.teal[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أدخل تفاصيل القضية هنا:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _caseDetailsController,
                      decoration: InputDecoration(
                        hintText: 'وصف القضية، الوقائع، الأطراف، المطالبات...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeCase,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.analytics_outlined),
                      label: Text(_isAnalyzing ? 'جاري التحليل...' : 'تحليل القضية'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'نتائج التحليل:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15.0),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: Colors.blueGrey[200]!),
                      ),
                      width: double.infinity,
                      child: _analysisResult.isEmpty && !_isAnalyzing
                          ? Text(
                              'سيظهر تحليل الذكاء الاصطناعي هنا بعد إدخال تفاصيل القضية.',
                              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                            )
                          : SelectableText(
                              _analysisResult,
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3.5 Update `main.dart`

Modify `lib/main.dart` to integrate the new screens and provider.

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/chat_provider.dart';
import './screens/ai_assistant_screen.dart';
import './screens/case_analysis_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // Add other providers here if needed
      ],
      child: MaterialApp(
        title: 'SmartJudi2 AI',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MainScreen(), // Use a main screen to navigate
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartJudi2 AI Features'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AIAssistantScreen()),
                );
              },
              icon: const Icon(Icons.chat, size: 28),
              label: const Text('المساعد القانوني', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(250, 60),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CaseAnalysisScreen()),
                );
              },
              icon: const Icon(Icons.gavel, size: 28),
              label: const Text('تحليل القضايا', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(250, 60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3.6 Install Flutter Dependencies

Cursor AI, please instruct the user to add the following dependencies to their `pubspec.yaml` file and run `flutter pub get`.

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1 # Add this
  provider: ^6.0.5 # Add this
  # ... other dependencies
```

## Part 4: Legal Data Loading Script

Cursor AI, create a Python script `load_legal_data.py` in a new `scripts` directory at the root of the `smartjudi2` project (outside `smartju` and `lib`). This script will handle loading, chunking, and indexing legal documents into the Hugging Face RAG engine.

```python
# smartjudi2/scripts/load_legal_data.py

import os
import requests
import logging
from dotenv import load_dotenv
from typing import List, Dict, Any

# For PDF and DOCX parsing
from pypdf import PdfReader # Use pypdf instead of PyPDF2 for modern Python
from docx import Document as DocxDocument

# For text splitting
from langchain.text_splitter import RecursiveCharacterTextSplitter

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()
RAG_API_URL = os.getenv("RAG_API_URL")

if not RAG_API_URL:
    logger.error("RAG_API_URL environment variable not set. Exiting.")
    exit(1)

# Initialize HTTP client for RAG API
rag_api_client = requests.Session()

def extract_text_from_pdf(pdf_path: str) -> str:
    """
    Extracts text from a PDF file.
    يستخرج النص من ملف PDF.
    """
    text = ""
    try:
        reader = PdfReader(pdf_path)
        for page in reader.pages:
            text += page.extract_text() + "\n"
        return text
    except Exception as e:
        logger.error(f"Error extracting text from PDF {pdf_path}: {e}")
        return ""

def extract_text_from_docx(docx_path: str) -> str:
    """
    Extracts text from a DOCX file.
    يستخرج النص من ملف DOCX.
    """
    text = ""
    try:
        doc = DocxDocument(docx_path)
        for paragraph in doc.paragraphs:
            text += paragraph.text + "\n"
        return text
    except Exception as e:
        logger.error(f"Error extracting text from DOCX {docx_path}: {e}")
        return ""

def load_documents_from_directory(directory_path: str) -> List[Dict[str, Any]]:
    """
    Loads and extracts text from PDF, DOCX, and TXT files in a given directory.
    يقوم بتحميل واستخراج النصوص من ملفات PDF و DOCX و TXT في دليل معين.
    """
    documents = []
    for root, _, files in os.walk(directory_path):
        for file_name in files:
            file_path = os.path.join(root, file_name)
            content = ""
            if file_name.endswith(".pdf"):
                content = extract_text_from_pdf(file_path)
            elif file_name.endswith(".docx"):
                content = extract_text_from_docx(file_path)
            elif file_name.endswith(".txt"):
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
            
            if content:
                documents.append({
                    "page_content": content,
                    "metadata": {"source": file_path, "file_name": file_name}
                })
                logger.info(f"Loaded document: {file_name}")
    return documents

def chunk_documents(documents: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Chunks documents into smaller pieces with overlap using RecursiveCharacterTextSplitter.
    يقسم المستندات إلى أجزاء أصغر مع تداخل باستخدام RecursiveCharacterTextSplitter.
    """
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len,
        add_start_index=True,
    )
    chunked_docs = []
    for doc in documents:
        chunks = text_splitter.create_documents([doc["page_content"]], metadatas=[doc["metadata"]])
        for chunk in chunks:
            chunked_docs.append({
                "page_content": chunk.page_content,
                "metadata": chunk.metadata
            })
    logger.info(f"Chunked {len(documents)} documents into {len(chunked_docs)} chunks.")
    return chunked_docs

def index_documents_to_rag(chunked_documents: List[Dict[str, Any]]) -> bool:
    """
    Indexes chunked documents into the Hugging Face RAG API.
    يفهرس المستندات المقسمة إلى واجهة برمجة تطبيقات RAG المستضافة على Hugging Face.
    """
    if not RAG_API_URL:
        logger.error("RAG_API_URL is not set. Cannot index documents.")
        return False

    add_docs_url = f"{RAG_API_URL}/add_documents"
    try:
        response = rag_api_client.post(add_docs_url, json=chunked_documents, timeout=120)
        response.raise_for_status()
        logger.info(f"Successfully indexed {len(chunked_documents)} chunks to RAG engine: {response.json()}")
        return True
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to index documents to RAG engine: {e}")
        if hasattr(e, 'response') and e.response is not None:
            logger.error(f"RAG API Error Response: {e.response.text}")
        return False

def main(data_directory: str):
    """
    Main function to load, chunk, and index legal data.
    الدالة الرئيسية لتحميل وتقسيم وفهرسة البيانات القانونية.
    """
    logger.info(f"Starting legal data loading process from: {data_directory}")
    
    # 1. Load documents
    # 1. تحميل المستندات
    raw_documents = load_documents_from_directory(data_directory)
    if not raw_documents:
        logger.warning("No documents found to process. Exiting.")
        return

    # 2. Chunk documents
    # 2. تقسيم المستندات
    chunked_documents = chunk_documents(raw_documents)

    # 3. Index documents to RAG engine
    # 3. فهرسة المستندات إلى محرك RAG
    if index_documents_to_rag(chunked_documents):
        logger.info("Legal data indexing completed successfully.")
    else:
        logger.error("Legal data indexing failed.")

if __name__ == "__main__":
    # Example usage: specify the directory containing your legal documents
    # مثال على الاستخدام: حدد الدليل الذي يحتوي على مستنداتك القانونية
    # Make sure to create this directory and place your PDF, DOCX, TXT files inside.
    # تأكد من إنشاء هذا الدليل ووضع ملفات PDF و DOCX و TXT بداخله.
    LEGAL_DATA_DIR = os.getenv("LEGAL_DATA_DIR", "./legal_documents")
    if not os.path.exists(LEGAL_DATA_DIR):
        os.makedirs(LEGAL_DATA_DIR)
        logger.info(f"Created directory: {LEGAL_DATA_DIR}. Please place your legal documents here.")
    
    main(LEGAL_DATA_DIR)

```

### 4.2 Install Script Dependencies

Cursor AI, please instruct the user to install the following Python dependencies for the data loading script.

```bash
# Navigate to the smartjudi2/scripts directory
# cd smartjudi2/scripts
pip install python-dotenv requests pypdf python-docx langchain
```

## Part 5: Execution Order and Important Notes

Cursor AI, please present these instructions clearly to the user.

### 5.1 Execution Order

Follow these steps in order to set up the complete system:

1.  **Set up Hugging Face Space (RAG Engine)**:
    *   Create a new Hugging Face Space.
    *   Upload the `Dockerfile`, `main.py`, and `requirements.txt` files (from Part 1) to the root of your Hugging Face Space repository.
    *   Hugging Face will automatically build and deploy your FastAPI application.
    *   Once deployed, obtain the public URL of your Hugging Face Space. This will be your `RAG_API_URL`.

2.  **Deploy Django Changes to Render**:
    *   Apply all modifications from Part 2 to your local `smartju` Django project.
    *   Ensure you have installed the new Python dependencies (`python-dotenv djangorestframework httpx`).
    *   Update your `.env` file in the `smartju` project with `RAG_API_URL`, `GROQ_API_KEY`, and `OPENROUTER_API_KEY`.
    *   Deploy the updated Django project to Render. Make sure Render's environment variables are also configured with these keys.

3.  **Run Legal Data Loading Script**:
    *   Create a directory named `scripts` at the root of your `smartjudi2` project (e.g., `smartjudi2/scripts`).
    *   Place the `load_legal_data.py` script (from Part 4) into this `scripts` directory.
    *   Create a directory named `legal_documents` (or whatever you set `LEGAL_DATA_DIR` to) at the same level as `scripts` (e.g., `smartjudi2/legal_documents`).
    *   Place your Yemeni legal documents (PDF, DOCX, TXT) into the `legal_documents` directory.
    *   Ensure you have installed the script's Python dependencies (`python-dotenv requests pypdf python-docx langchain`).
    *   Run the script from your local machine:
        ```bash
        # Navigate to the smartjudi2/scripts directory
        # cd smartjudi2/scripts
        python load_legal_data.py
        ```
    *   This script will upload and index your legal documents into the Hugging Face RAG engine.

4.  **Update Flutter App**:
    *   Apply all modifications from Part 3 to your local `lib` Flutter project.
    *   Update your `pubspec.yaml` with the new dependencies (`http`, `provider`) and run `flutter pub get`.
    *   Update the `_baseUrl` in `lib/services/ai_api_service.dart` to point to your deployed Django backend URL on Render.
    *   Build and deploy your Flutter application.

### 5.2 How to Get API Keys

*   **Groq Cloud API Key**:
    1.  Go to [Groq Cloud](https://console.groq.com/).
    2.  Sign up or log in.
    3.  Navigate to the "API Keys" section.
    4.  Create a new API key. Groq offers free access without a credit card and supports Yemen.

*   **OpenRouter API Key**:
    1.  Go to [OpenRouter](https://openrouter.ai/).
    2.  Sign up or log in.
    3.  Go to your "API Keys" page (usually found in your account settings).
    4.  Generate a new API key. OpenRouter also offers free tiers and supports models like Qwen.

### 5.3 Testing Guidelines

*   **RAG Engine (Hugging Face Space)**:
    *   After deployment, test the `/health` endpoint directly via its URL (e.g., `https://your-space-url.hf.space/health`).
    *   Use `curl` or Postman to test `/add_documents` and `/search` endpoints to ensure documents are indexed and retrieved correctly.

*   **Django Backend**:
    *   After deployment to Render, test the Django API endpoint (e.g., `https://your-django-app.onrender.com/api/ai-assistant/chat/`) using Postman or a similar tool.
    *   Verify that responses are generated, and the fallback mechanism works by temporarily invalidating the Groq API key to force OpenRouter usage.

*   **Flutter App**:
    *   Run the Flutter app on an emulator or physical device.
    *   Test the AI Assistant chat interface by sending various legal queries.
    *   Test the Case Analysis screen by inputting case details and checking the AI-generated analysis.

*   **Legal Data Loading Script**:
    *   Run the script with a small set of test documents first.
    *   Check the RAG engine's `/search` endpoint to confirm that the loaded documents are searchable.

### 5.4 Important Notes

*   **Environment Variables**: Ensure all `RAG_API_URL`, `GROQ_API_KEY`, and `OPENROUTER_API_KEY` are correctly set in your local `.env` files and on your Render deployment environment variables.
*   **LLM Rate Limits**: Be mindful of rate limits imposed by Groq and OpenRouter. For heavy usage, consider their paid tiers.
*   **ChromaDB Persistence**: The `main.py` for the Hugging Face Space is configured for persistent ChromaDB storage within the space's file system (`./chroma_db`). Ensure this directory is correctly handled by Hugging Face Spaces for persistence across restarts.
*   **Security**: Never hardcode API keys directly into your code. Always use environment variables.
*   **Model Names**: The LLM model names (`llama3-8b-8192` for Groq, `qwen/qwen-110b-chat` for OpenRouter) are examples. Verify the exact model names available through their respective APIs and adjust `llm_service.py` if necessary.
*   **Error Handling**: The provided code includes basic error handling. Enhance it further for production-grade robustness, including more specific exception types and user-friendly error messages.

```
