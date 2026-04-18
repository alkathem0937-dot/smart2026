```markdown
# Cursor AI Prompt: SmartJudi2 Project Enhancement with RAG and Local LLM

This document outlines a comprehensive plan for enhancing the SmartJudi2 judicial platform by integrating a Retrieval-Augmented Generation (RAG) engine on Hugging Face Spaces and a local Large Language Model (LLM) powered by Ollama. The existing project structure on GitHub (https://github.com/tfyemen-afk/smartjudi2) has been reviewed, consisting of a Django backend (`smartju` directory) and a Flutter frontend (`lib` directory).

## Project Architecture Overview

**1. Hugging Face Spaces (RAG Engine):**
   - **Purpose:** Host the RAG engine for efficient retrieval of legal documents.
   - **Components:** `multilingual-e5-large` embedding model, ChromaDB vector store, FastAPI for API endpoints.

**2. Local Machine (Ollama LLM):**
   - **Purpose:** Run a powerful LLM (Qwen 2.5) locally for legal reasoning and response generation.
   - **Access:** Made accessible to the Django backend via Cloudflare Tunnel or ngrok.
   - **User's Local Machine Specs:** 32GB RAM, Core i7 CPU, NVIDIA GTX GPU, >1TB Storage.

**3. Django Backend (Render):**
   - **Purpose:** Integrate RAG and Ollama services, provide AI assistant APIs to Flutter.
   - **Hosting:** Remains on Render.

**4. Flutter Frontend:**
   - **Purpose:** Develop user interfaces for the AI assistant and case analysis.

## Detailed Modification Plan for Cursor AI

Cursor AI, please follow these steps meticulously to implement the described enhancements. Ensure all code is complete, runnable, and adheres to best practices. Use Arabic comments where appropriate within the code.

---

### Part 1: Create New Hugging Face Space Project (RAG Engine)

Create a new Hugging Face Space project. The project should have the following file structure and content:

**File: `Dockerfile`** (New file in the root of the Hugging Face Space project)

```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.10-slim-buster

# Set the working directory in the container
WORKDIR /app

# Install system dependencies for sentence-transformers and other libraries
# (تثبيت التبعيات اللازمة لـ sentence-transformers ومكتبات أخرى)
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
# (تثبيت الحزم المطلوبة من requirements.txt)
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 8000 for FastAPI
# (تعريض المنفذ 8000 لتطبيق FastAPI)
EXPOSE 8000

# Run main.py when the container launches
# (تشغيل main.py عند بدء تشغيل الحاوية)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**File: `requirements.txt`** (New file in the root of the Hugging Face Space project)

```
fastapi
uvicorn
langchain
langchain-community
chromadb
sentence-transformers
pytesseract
pdf2image
python-multipart
python-dotenv
loguru
```

**File: `main.py`** (New file in the root of the Hugging Face Space project)

```python
# main.py - FastAPI application for RAG engine

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from typing import List, Dict, Any
import os
import logging
from dotenv import load_dotenv
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.docstore.document import Document
from pdf2image import convert_from_path
import pytesseract
import tempfile

# Load environment variables
# (تحميل متغيرات البيئة)
load_dotenv()

# Configure logging
# (تكوين التسجيل)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI(title="SmartJudi2 RAG Engine", version="1.0.0")

# --- Configuration --- #

# Embedding model name
# (اسم نموذج التضمين)
EMBEDDING_MODEL_NAME = os.getenv("EMBEDDING_MODEL_NAME", "sentence-transformers/multilingual-e5-large")

# Directory for ChromaDB persistence
# (مسار تخزين قاعدة بيانات ChromaDB)
CHROMA_DB_DIR = os.getenv("CHROMA_DB_DIR", "./chroma_db")

# Initialize embedding model
# (تهيئة نموذج التضمين)
try:
    embeddings = HuggingFaceEmbeddings(model_name=EMBEDDING_MODEL_NAME)
    logger.info(f"Successfully loaded embedding model: {EMBEDDING_MODEL_NAME}")
except Exception as e:
    logger.error(f"Error loading embedding model: {e}")
    raise RuntimeError(f"Failed to load embedding model: {e}")

# Initialize ChromaDB client
# (تهيئة عميل ChromaDB)
def get_chroma_client():
    try:
        # Ensure the directory exists
        os.makedirs(CHROMA_DB_DIR, exist_ok=True)
        client = Chroma(persist_directory=CHROMA_DB_DIR, embedding_function=embeddings)
        logger.info(f"Successfully initialized ChromaDB at {CHROMA_DB_DIR}")
        return client
    except Exception as e:
        logger.error(f"Error initializing ChromaDB: {e}")
        raise RuntimeError(f"Failed to initialize ChromaDB: {e}")

vectorstore = get_chroma_client()

# Text splitter for document processing
# (مقسم النصوص لمعالجة المستندات)
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    length_function=len,
    add_start_index=True,
)

# --- Helper Functions ---

def extract_text_from_pdf(pdf_path: str) -> str:
    # (استخراج النص من ملف PDF)
    try:
        images = convert_from_path(pdf_path)
        text = ""
        for i, image in enumerate(images):
            text += pytesseract.image_to_string(image, lang='ara+eng') # Support Arabic and English
            logger.debug(f"Extracted text from page {i+1} of {pdf_path}")
        return text
    except Exception as e:
        logger.error(f"Error extracting text from PDF {pdf_path}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to extract text from PDF: {e}")

def process_document(file_content: bytes, file_name: str) -> List[Document]:
    # (معالجة المستند وتقسيمه إلى أجزاء)
    text = ""
    if file_name.endswith(".pdf"):
        with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_file:
            tmp_file.write(file_content)
            tmp_file_path = tmp_file.name
        try:
            text = extract_text_from_pdf(tmp_file_path)
        finally:
            os.unlink(tmp_file_path) # Clean up temp file
    elif file_name.endswith(".txt"):
        text = file_content.decode('utf-8')
    elif file_name.endswith(".docx") or file_name.endswith(".doc"):
        # For Word documents, you would typically use python-docx or similar.
        # For simplicity, this example assumes text or PDF. You'd need to add
        # a library like `python-docx` and implement its parsing here.
        # (لملفات الوورد، ستحتاج إلى مكتبة مثل python-docx)
        logger.warning(f"Word document processing not fully implemented for {file_name}. Treating as plain text.")
        text = file_content.decode('utf-8', errors='ignore')
    else:
        raise HTTPException(status_code=400, detail=f"Unsupported file type: {file_name}")

    if not text:
        raise HTTPException(status_code=400, detail="Could not extract text from document.")

    # Split text into chunks
    # (تقسيم النص إلى أجزاء)
    chunks = text_splitter.split_text(text)
    documents = [Document(page_content=chunk, metadata={"source": file_name}) for chunk in chunks]
    logger.info(f"Processed document {file_name} into {len(documents)} chunks.")
    return documents

# --- API Models ---

class DocumentAddRequest(BaseModel):
    documents: List[Dict[str, str]] # [{'content': 'text', 'source': 'filename'}]

class SearchRequest(BaseModel):
    query: str
    k: int = 4

class SearchResponse(BaseModel):
    results: List[Dict[str, Any]]

class HealthResponse(BaseModel):
    status: str
    message: str

# --- API Endpoints ---

@app.get("/health", response_model=HealthResponse)
async def health_check():
    # (نقطة نهاية للتحقق من صحة الخدمة)
    try:
        # Attempt to access the vectorstore to ensure it's responsive
        _ = vectorstore._collection.count()
        return HealthResponse(status="ok", message="RAG engine is healthy and ChromaDB is accessible.")
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail=f"RAG engine unhealthy: {e}")

@app.post("/add_documents")
async def add_documents(files: List[UploadFile] = File(...)):
    # (نقطة نهاية لإضافة مستندات جديدة)
    if not files:
        raise HTTPException(status_code=400, detail="No files provided.")

    all_documents = []
    for file in files:
        try:
            file_content = await file.read()
            docs = process_document(file_content, file.filename)
            all_documents.extend(docs)
        except HTTPException as e:
            logger.error(f"Error processing file {file.filename}: {e.detail}")
            raise e
        except Exception as e:
            logger.error(f"Unexpected error processing file {file.filename}: {e}")
            raise HTTPException(status_code=500, detail=f"Internal server error processing file {file.filename}")

    if not all_documents:
        raise HTTPException(status_code=400, detail="No valid documents could be processed.")

    try:
        vectorstore.add_documents(all_documents)
        logger.info(f"Added {len(all_documents)} document chunks to ChromaDB.")
        return {"status": "success", "message": f"Added {len(all_documents)} document chunks.", "filenames": [f.filename for f in files]}
    except Exception as e:
        logger.error(f"Error adding documents to ChromaDB: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to add documents to vector store: {e}")

@app.post("/search", response_model=SearchResponse)
async def search_documents(request: SearchRequest):
    # (نقطة نهاية للبحث عن المستندات ذات الصلة)
    try:
        results = vectorstore.similarity_search(request.query, k=request.k)
        formatted_results = []
        for doc in results:
            formatted_results.append({"page_content": doc.page_content, "metadata": doc.metadata})
        logger.info(f"Performed similarity search for query '{request.query}', found {len(formatted_results)} results.")
        return SearchResponse(results=formatted_results)
    except Exception as e:
        logger.error(f"Error during document search: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to search documents: {e}")

@app.delete("/delete_documents")
async def delete_documents(source: str = Form(...)):
    # (نقطة نهاية لحذف المستندات بناءً على المصدر)
    try:
        # ChromaDB's delete method requires an ID or where clause.
        # To delete by source, we first need to query for documents with that source.
        # This is a simplified approach; for large scale, consider storing IDs.
        # (لحذف المستندات حسب المصدر، نحتاج أولاً للبحث عنها)
        docs_to_delete = vectorstore.get(where={"source": source})
        if not docs_to_delete['ids']:
            return {"status": "info", "message": f"No documents found with source: {source}"}

        vectorstore.delete(ids=docs_to_delete['ids'])
        logger.info(f"Deleted {len(docs_to_delete['ids'])} document chunks with source: {source}")
        return {"status": "success", "message": f"Deleted documents with source: {source}"}
    except Exception as e:
        logger.error(f"Error deleting documents: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to delete documents: {e}")

```

**File: `.env`** (New file in the root of the Hugging Face Space project)

```
EMBEDDING_MODEL_NAME="sentence-transformers/multilingual-e5-large"
CHROMA_DB_DIR="./chroma_db"
```

---

### Part 2: Ollama Setup on Local Machine

This section details the setup for the user's local machine. Cursor AI should provide instructions for the user to follow.

**Instructions for User (Local Machine Setup):**

1.  **Install Ollama:**
    Follow the official installation guide for your operating system from the Ollama website: [https://ollama.ai/download](https://ollama.ai/download)
    (اتبع دليل التثبيت الرسمي لنظام التشغيل الخاص بك من موقع Ollama)

2.  **Download Qwen 2.5 Model:**
    Open your terminal or command prompt and run:
    ```bash
    ollama run qwen:7b-chat # Or qwen:14b-chat if you prefer a larger model and have enough resources
    ```
    (قم بتنزيل نموذج Qwen 2.5 باستخدام الأمر أعلاه. اختر 7B أو 14B حسب موارد جهازك)

3.  **Configure Ollama for Network Access:**
    By default, Ollama listens on `127.0.0.1:11434`. To make it accessible over the network, you need to set the `OLLAMA_HOST` environment variable.
    
    **Linux/macOS:**
    Add the following line to your `~/.bashrc`, `~/.zshrc`, or equivalent shell configuration file:
    ```bash
    export OLLAMA_HOST="0.0.0.0:11434"
    ```
    Then, apply the changes:
    ```bash
    source ~/.bashrc # Or source ~/.zshrc
    ```
    
    **Windows (Command Prompt):**
    ```cmd
    setx OLLAMA_HOST "0.0.0.0:11434"
    ```
    You might need to restart your system or Ollama service for changes to take effect.
    (لجعل Ollama متاحًا عبر الشبكة، قم بتعيين متغير البيئة OLLAMA_HOST إلى 0.0.0.0:11434)

4.  **Expose Ollama to the Internet (Cloudflare Tunnel or ngrok):**
    Since the Django backend is on Render, it needs to access your local Ollama instance. You can use Cloudflare Tunnel or ngrok for this.
    
    **Option A: Cloudflare Tunnel (Recommended for persistent access)**
    -   Install `cloudflared`: Follow instructions on [https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/)
    -   Authenticate `cloudflared`:
        ```bash
        cloudflared tunnel login
        ```
    -   Create a tunnel:
        ```bash
        cloudflared tunnel create smartjudi-ollama
        ```
    -   Create a `config.yml` file (e.g., in `~/.cloudflared/config.yml`):
        ```yaml
        tunnel: <YOUR_TUNNEL_UUID>
        credentials-file: /root/.cloudflared/<YOUR_TUNNEL_UUID>.json
        ingress:
          - hostname: ollama.yourdomain.com # Replace with your desired subdomain
            service: http://localhost:11434
          - service: http_status:404
        ```
    -   Run the tunnel:
        ```bash
        cloudflared tunnel run smartjudi-ollama
        ```
    -   **Note:** You will need a domain managed by Cloudflare for this. The `ollama.yourdomain.com` URL will be your `OLLAMA_API_URL`.
    (استخدم Cloudflare Tunnel لتعريض Ollama للإنترنت. ستحتاج إلى نطاق خاص بك)

    **Option B: ngrok (Easier for temporary testing)**
    -   Install ngrok: Follow instructions on [https://ngrok.com/download](https://ngrok.com/download)
    -   Authenticate ngrok:
        ```bash
        ngrok authtoken <YOUR_NGROK_AUTH_TOKEN>
        ```
    -   Run ngrok to expose Ollama:
        ```bash
        ngrok http 11434
        ```
    -   ngrok will provide a public URL (e.g., `https://xxxx-xxxx-xxxx-xxxx.ngrok-free.app`). This URL will be your `OLLAMA_API_URL`.
    (استخدم ngrok لتعريض Ollama للإنترنت بشكل مؤقت. ستحصل على رابط عام)

5.  **`docker-compose.yml` for Local Ollama (Optional, for more structured local setup):**
    If the user prefers to run Ollama within Docker, here's a `docker-compose.yml` example. This assumes Ollama is already installed and the model downloaded as per steps 1 & 2.
    
    **File: `docker-compose.yml`** (New file in a dedicated directory for local LLM setup)
    
    ```yaml
    version: '3.8'

    services:
      ollama:
        image: ollama/ollama:latest
        container_name: smartjudi-ollama
        ports:
          - "11434:11434"
        volumes:
          - ./ollama_models:/root/.ollama # Persist models
        environment:
          - OLLAMA_HOST=0.0.0.0:11434
        restart: always
        # If you have a GPU, uncomment the following lines:
        # (إذا كان لديك وحدة معالجة رسومات، قم بإلغاء التعليق عن الأسطر التالية)
        # deploy:
        #   resources:
        #     reservations:
        #       devices:
        #         - driver: nvidia
        #           count: all
        #           capabilities: [gpu]
    ```
    **Note:** If using this `docker-compose.yml`, ensure the `ollama_models` directory exists and your Qwen model is downloaded into it, or Ollama will download it on first run. Also, ensure Docker and Docker Compose are installed.
    (ملف docker-compose.yml لتشغيل Ollama محليًا داخل Docker، مع دعم GPU اختياري)

6.  **Custom Modelfile for Ollama with Yemeni Legal System Prompt:**
    Create a `Modelfile` to customize the Qwen model with a system prompt tailored for Yemeni law.
    
    **File: `Modelfile`** (New file in the same directory where you run `ollama create`)
    
    ```
    FROM qwen:7b-chat # Or qwen:14b-chat, matching your downloaded model
    SYSTEM "أنت مساعد قانوني متخصص في القانون اليمني. مهمتك هي تقديم استشارات قانونية دقيقة، تحليل القضايا بناءً على القوانين واللوائح اليمنية، وتقديم إجابات واضحة ومستندة إلى النصوص القانونية. يجب أن تكون إجاباتك محايدة، موضوعية، وتستند فقط إلى المعلومات القانونية المتاحة. عند الإجابة على استفسار، قم دائمًا بالإشارة إلى المواد القانونية أو المبادئ القضائية اليمنية ذات الصلة إن أمكن. تجنب إبداء آراء شخصية أو تقديم نصائح تتجاوز نطاق القانون. كن دقيقًا ومفصلاً في تحليلاتك. إذا كان السؤال يتطلب معلومات غير متوفرة، اطلب توضيحات إضافية أو أشر إلى أن المعلومات غير كافية لتقديم إجابة كاملة."
    ```
    
    Then, create the custom model:
    ```bash
    ollama create smartjudi-qwen -f ./Modelfile
    ```
    Now, when interacting with Ollama, you will use `smartjudi-qwen` instead of `qwen:7b-chat`.
    (ملف Modelfile مخصص لـ Ollama مع System Prompt متخصص بالقوانين اليمنية)

---

### Part 3: Modify Django Backend (`smartju`)

Navigate to the `smartju` directory of the Django project. All modifications will be relative to this directory.

**1. Create a New Django App `ai_assistant`:**

   Run the following command in the `smartju` directory:
   ```bash
   python manage.py startapp ai_assistant
   ```
   (إنشاء تطبيق Django جديد باسم ai_assistant)

   Add `ai_assistant` to `INSTALLED_APPS` in `smartju/settings.py`:
   ```python
   # smartju/settings.py

   INSTALLED_APPS = [
       # ... existing apps ...
       'rest_framework',
       'corsheaders',
       'drf_yasg',
       'django_filters',
       'accounts',
       'courts',
       'lawsuits',
       'parties',
       'attachments',
       'responses',
       'ai_assistant', # Add this line (إضافة هذا السطر)
   ]
   ```

**2. Update `.env` for API URLs:**

   Add the following variables to your Django project's `.env` file (or equivalent environment configuration for Render):
   ```
   RAG_API_URL="YOUR_HUGGINGFACE_SPACE_URL" # e.g., https://your-rag-space.hf.space
   OLLAMA_API_URL="YOUR_OLLAMA_TUNNEL_URL" # e.g., https://ollama.yourdomain.com or https://xxxx.ngrok-free.app
   ```
   (تحديث ملف .env بمسارات API لمحرك RAG و Ollama)

**3. Create `ai_assistant/services.py`:**

   This file will contain the service classes for interacting with the RAG engine and Ollama, and the main AI assistant logic.

   **File: `ai_assistant/services.py`** (New file)

   ```python
   # ai_assistant/services.py

   import os
   import requests
   import json
   import logging
   from typing import List, Dict, Any, Optional
   from django.conf import settings

   logger = logging.getLogger(__name__)

   class RAGService:
       # (خدمة للتواصل مع محرك RAG على Hugging Face Spaces)
       def __init__(self):
           self.rag_api_url = os.getenv("RAG_API_URL")
           if not self.rag_api_url:
               raise ValueError("RAG_API_URL environment variable not set.")
           self.search_endpoint = f"{self.rag_api_url}/search"
           self.add_documents_endpoint = f"{self.rag_api_url}/add_documents"
           self.delete_documents_endpoint = f"{self.rag_api_url}/delete_documents"
           self.health_endpoint = f"{self.rag_api_url}/health"

       def _make_request(self, method: str, url: str, **kwargs) -> Dict[str, Any]:
           # (دالة مساعدة لإجراء طلبات HTTP)
           try:
               response = requests.request(method, url, timeout=30, **kwargs)
               response.raise_for_status() # Raise HTTPError for bad responses (4xx or 5xx)
               return response.json()
           except requests.exceptions.Timeout:
               logger.error(f"Request to {url} timed out.")
               raise ConnectionError(f"RAG service at {url} timed out.")
           except requests.exceptions.RequestException as e:
               logger.error(f"Request to {url} failed: {e}")
               raise ConnectionError(f"RAG service at {url} failed: {e}")

       def health_check(self) -> Dict[str, Any]:
           # (التحقق من صحة خدمة RAG)
           logger.info(f"Checking RAG service health at {self.health_endpoint}")
           return self._make_request("GET", self.health_endpoint)

       def search(self, query: str, k: int = 4) -> List[Dict[str, Any]]:
           # (البحث عن المستندات ذات الصلة في محرك RAG)
           payload = {"query": query, "k": k}
           logger.info(f"Searching RAG for query: '{query}' with k={k}")
           response = self._make_request("POST", self.search_endpoint, json=payload)
           return response.get("results", [])

       def add_documents(self, files: List[tuple]) -> Dict[str, Any]:
           # files should be a list of (filename, file_content_bytes, content_type)
           # (إضافة مستندات جديدة إلى محرك RAG)
           multipart_files = []
           for filename, content, content_type in files:
               multipart_files.append(("files", (filename, content, content_type)))
           
           logger.info(f"Adding {len(files)} documents to RAG.")
           response = self._make_request("POST", self.add_documents_endpoint, files=multipart_files)
           return response

       def delete_documents(self, source: str) -> Dict[str, Any]:
           # (حذف المستندات من محرك RAG بناءً على المصدر)
           payload = {"source": source}
           logger.info(f"Deleting documents with source: {source} from RAG.")
           response = self._make_request("DELETE", self.delete_documents_endpoint, data=payload)
           return response

   class OllamaService:
       # (خدمة للتواصل مع Ollama LLM المحلي)
       def __init__(self):
           self.ollama_api_url = os.getenv("OLLAMA_API_URL")
           if not self.ollama_api_url:
               raise ValueError("OLLAMA_API_URL environment variable not set.")
           self.generate_endpoint = f"{self.ollama_api_url}/api/chat"
           self.model_name = os.getenv("OLLAMA_MODEL_NAME", "smartjudi-qwen") # Use custom model

       def _make_request(self, payload: Dict[str, Any]) -> Dict[str, Any]:
           # (دالة مساعدة لإجراء طلبات HTTP)
           try:
               headers = {'Content-Type': 'application/json'}
               response = requests.post(self.generate_endpoint, headers=headers, json=payload, timeout=120)
               response.raise_for_status()
               return response.json()
           except requests.exceptions.Timeout:
               logger.error(f"Request to Ollama timed out.")
               raise ConnectionError("Ollama service timed out.")
           except requests.exceptions.RequestException as e:
               logger.error(f"Request to Ollama failed: {e}")
               raise ConnectionError(f"Ollama service failed: {e}")

       def generate_response(self, messages: List[Dict[str, str]], stream: bool = False) -> Dict[str, Any]:
           # (توليد استجابة من Ollama LLM)
           payload = {
               "model": self.model_name,
               "messages": messages,
               "stream": stream,
               "options": {
                   "temperature": 0.7,
                   "top_k": 40,
                   "top_p": 0.9,
               }
           }
           logger.info(f"Generating response from Ollama model: {self.model_name}")
           return self._make_request(payload)

   class AIAssistantService:
       # (خدمة المساعد الذكي التي تجمع بين RAG و Ollama)
       def __init__(self):
           self.rag_service = RAGService()
           self.ollama_service = OllamaService()
           self.system_prompt = """
   أنت مساعد قانوني ذكي متخصص في القانون اليمني. مهمتك هي تحليل الاستفسارات القانونية، وتقديم إجابات دقيقة ومفصلة بناءً على النصوص القانونية اليمنية ذات الصلة. يجب أن تكون إجاباتك محايدة، موضوعية، ومستندة إلى الحقائق القانونية فقط. عند الإجابة، قم دائمًا بالإشارة إلى المواد القانونية أو المبادئ القضائية اليمنية التي استندت إليها. إذا تم توفير سياق من مستندات قانونية، استخدم هذا السياق بشكل أساسي لصياغة إجابتك. في حالة عدم كفاية المعلومات، اطلب توضيحات إضافية. حافظ على نبرة احترافية وقانونية.
   """
           # (النظام الأساسي للمساعد الذكي مع التركيز على القانون اليمني)

       def _format_rag_context(self, search_results: List[Dict[str, Any]]) -> str:
           # (تنسيق السياق المسترجع من RAG)
           if not search_results:
               return ""
           context = "\n\nRelevant Legal Documents:\n" # (وثائق قانونية ذات صلة)
           for i, result in enumerate(search_results):
               content = result.get("page_content", "")
               source = result.get("metadata", {}).get("source", "Unknown Source")
               context += f"---\nDocument {i+1} (Source: {source}):\n{content}\n"
           return context

       def _build_ollama_messages(self, user_query: str, rag_context: str, conversation_history: List[Dict[str, str]]) -> List[Dict[str, str]]:
           # (بناء رسائل المحادثة لـ Ollama)
           messages = []
           messages.append({"role": "system", "content": self.system_prompt})
           
           # Add few-shot examples (أمثلة قليلة للمساعدة في التوجيه)
           # Example 1: Simple legal query
           messages.append({"role": "user", "content": "ما هي شروط عقد البيع في القانون اليمني؟"})
           messages.append({"role": "assistant", "content": "وفقًا للقانون المدني اليمني رقم 19 لسنة 1992، المادة 419، يشترط لصحة عقد البيع أن يكون المبيع معلومًا علمًا نافيًا للجهالة الفاحشة، وأن يكون الثمن معلومًا ومحددًا، وأن يكون كل من البائع والمشتري أهلاً للتعاقد. كما يجب أن يكون المبيع مملوكًا للبائع أو مأذونًا له ببيعه."})
           
           # Example 2: Case analysis query
           messages.append({"role": "user", "content": "شخص قام بالاستيلاء على أرض مملوكة للدولة وقام بالبناء عليها. ما هو التكييف القانوني لهذا الفعل وما هي الإجراءات المتخذة؟"})
           messages.append({"role": "assistant", "content": "هذا الفعل يندرج تحت جريمة الاعتداء على الأملاك العامة، والتي يعاقب عليها قانون الجرائم والعقوبات اليمني. وفقًا للمادة 261 من قانون الجرائم والعقوبات، يعاقب بالحبس كل من اعتدى على ملك عام أو خاص بقصد الاستيلاء عليه. الإجراءات المتخذة تشمل تحرير محضر بالواقعة، التحقيق، وإحالة القضية إلى النيابة العامة ثم المحكمة المختصة لإصدار الحكم المناسب، مع الأمر بإزالة التعدي."})

           # Add conversation history (إضافة سجل المحادثة)
           messages.extend(conversation_history)

           # Add RAG context if available (إضافة سياق RAG إذا كان متاحًا)
           if rag_context:
               messages.append({"role": "user", "content": f"Based on the following legal documents and the previous conversation, answer the user's query:\n{rag_context}\nUser Query: {user_query}"})
           else:
               messages.append({"role": "user", "content": user_query})
           
           return messages

       def get_ai_response(self, user_query: str, conversation_history: List[Dict[str, str]] = None) -> Dict[str, Any]:
           # (الحصول على استجابة من المساعد الذكي)
           if conversation_history is None:
               conversation_history = []

           rag_context = ""
           try:
               # Chain-of-Thought: First, search for relevant documents
               # (سلسلة التفكير: أولاً، البحث عن المستندات ذات الصلة)
               search_results = self.rag_service.search(user_query, k=5)
               rag_context = self._format_rag_context(search_results)
               logger.info(f"RAG search successful. Context length: {len(rag_context)} characters.")
           except ConnectionError as e:
               logger.warning(f"RAG service unavailable, proceeding without RAG context: {e}")
               # Fallback: Proceed without RAG context if RAG service fails
               # (خطة بديلة: المتابعة بدون سياق RAG إذا فشلت خدمة RAG)
           except Exception as e:
               logger.error(f"Unexpected error during RAG search: {e}")
               # Fallback: Proceed without RAG context

           messages = self._build_ollama_messages(user_query, rag_context, conversation_history)

           try:
               # Generate response from Ollama
               # (توليد الاستجابة من Ollama)
               ollama_response = self.ollama_service.generate_response(messages)
               assistant_message = ollama_response.get("message", {}).get("content", "")
               logger.info("Ollama response generated successfully.")
               return {"response": assistant_message, "source_documents": search_results}
           except ConnectionError as e:
               logger.error(f"Ollama service unavailable: {e}")
               # Fallback: Provide a generic error message if Ollama fails
               # (خطة بديلة: تقديم رسالة خطأ عامة إذا فشلت خدمة Ollama)
               return {"response": "عذرًا، لا يمكنني معالجة طلبك حاليًا بسبب مشكلة في خدمة الذكاء الاصطناعي. يرجى المحاولة لاحقًا.", "source_documents": []}
           except Exception as e:
               logger.error(f"Unexpected error during Ollama response generation: {e}")
               return {"response": "حدث خطأ غير متوقع أثناء معالجة طلبك. يرجى المحاولة مرة أخرى.", "source_documents": []}

   ```

**4. Create `ai_assistant/views.py`:**

   This will define the API endpoints for the AI assistant.

   **File: `ai_assistant/views.py`** (New file)

   ```python
   # ai_assistant/views.py

   from rest_framework.views import APIView
   from rest_framework.response import Response
   from rest_framework import status
   from .services import AIAssistantService, RAGService
   from .serializers import ChatRequestSerializer, ChatResponseSerializer, AddDocumentsSerializer
   import logging
   from drf_yasg.utils import swagger_auto_schema
   from drf_yasg import openapi

   logger = logging.getLogger(__name__)

   class AIChatView(APIView):
       # (نقطة نهاية للدردشة مع المساعد الذكي)
       ai_assistant_service = AIAssistantService()

       @swagger_auto_schema(
           request_body=ChatRequestSerializer,
           responses={200: ChatResponseSerializer, 400: "Bad Request", 500: "Internal Server Error"},
           operation_description="Send a query to the AI legal assistant and get a response."
       )
       def post(self, request, *args, **kwargs):
           serializer = ChatRequestSerializer(data=request.data)
           if serializer.is_valid():
               user_query = serializer.validated_data['query']
               conversation_history = serializer.validated_data.get('conversation_history', [])
               
               logger.info(f"Received chat query: {user_query}")
               try:
                   response_data = self.ai_assistant_service.get_ai_response(user_query, conversation_history)
                   response_serializer = ChatResponseSerializer(data=response_data)
                   response_serializer.is_valid(raise_exception=True)
                   return Response(response_serializer.data, status=status.HTTP_200_OK)
               except Exception as e:
                   logger.exception(f"Error in AI chat view: {e}")
                   return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
           return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

   class AddLegalDocumentsView(APIView):
       # (نقطة نهاية لإضافة مستندات قانونية إلى محرك RAG)
       rag_service = RAGService()

       @swagger_auto_schema(
           request_body=openapi.Schema(
               type=openapi.TYPE_OBJECT,
               properties={
                   'files': openapi.Schema(
                       type=openapi.TYPE_ARRAY,
                       items=openapi.Schema(type=openapi.TYPE_FILE),
                       description='List of PDF, Word, or Text files to upload.'
                   )
               },
               required=['files']
           ),
           responses={200: "Success", 400: "Bad Request", 500: "Internal Server Error"},
           operation_description="Upload legal documents (PDF, Word, Text) to the RAG engine for indexing."
       )
       def post(self, request, *args, **kwargs):
           if 'files' not in request.FILES:
               return Response({"detail": "No files provided."}, status=status.HTTP_400_BAD_REQUEST)
           
           uploaded_files = request.FILES.getlist('files')
           files_for_rag = []
           for uploaded_file in uploaded_files:
               files_for_rag.append((uploaded_file.name, uploaded_file.read(), uploaded_file.content_type))

           try:
               response = self.rag_service.add_documents(files_for_rag)
               return Response(response, status=status.HTTP_200_OK)
           except Exception as e:
               logger.exception(f"Error adding legal documents: {e}")
               return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

   class DeleteLegalDocumentsView(APIView):
       # (نقطة نهاية لحذف مستندات قانونية من محرك RAG)
       rag_service = RAGService()

       @swagger_auto_schema(
           request_body=openapi.Schema(
               type=openapi.TYPE_OBJECT,
               properties={
                   'source': openapi.Schema(type=openapi.TYPE_STRING, description='Source filename to delete.')
               },
               required=['source']
           ),
           responses={200: "Success", 400: "Bad Request", 500: "Internal Server Error"},
           operation_description="Delete legal documents from the RAG engine by source filename."
       )
       def delete(self, request, *args, **kwargs):
           source = request.data.get('source')
           if not source:
               return Response({"detail": "'source' parameter is required."}, status=status.HTTP_400_BAD_REQUEST)
           
           try:
               response = self.rag_service.delete_documents(source)
               return Response(response, status=status.HTTP_200_OK)
           except Exception as e:
               logger.exception(f"Error deleting legal documents: {e}")
               return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

   ```

**5. Create `ai_assistant/serializers.py`:**

   Define serializers for request and response data.

   **File: `ai_assistant/serializers.py`** (New file)

   ```python
   # ai_assistant/serializers.py

   from rest_framework import serializers

   class ChatRequestSerializer(serializers.Serializer):
       # (سيريالايزر لطلب الدردشة)
       query = serializers.CharField(max_length=1000)
       conversation_history = serializers.ListField(
           child=serializers.DictField(child=serializers.CharField()), 
           required=False, 
           default=[]
       )

   class SourceDocumentSerializer(serializers.Serializer):
       # (سيريالايزر لوثيقة المصدر)
       page_content = serializers.CharField()
       metadata = serializers.DictField()

   class ChatResponseSerializer(serializers.Serializer):
       # (سيريالايزر لاستجابة الدردشة)
       response = serializers.CharField()
       source_documents = serializers.ListField(
           child=SourceDocumentSerializer(), 
           required=False, 
           default=[]
       )

   class AddDocumentsSerializer(serializers.Serializer):
       # (سيريالايزر لإضافة المستندات - يستخدم للتوثيق فقط، الملفات تُعالج مباشرة)
       files = serializers.ListField(
           child=serializers.FileField(), 
           help_text="List of PDF, Word, or Text files to upload."
       )
   ```

**6. Create `ai_assistant/urls.py`:**

   Define URL patterns for the new AI assistant app.

   **File: `ai_assistant/urls.py`** (New file)

   ```python
   # ai_assistant/urls.py

   from django.urls import path
   from .views import AIChatView, AddLegalDocumentsView, DeleteLegalDocumentsView

   urlpatterns = [
       # (مسارات API للمساعد الذكي)
       path('chat/', AIChatView.as_view(), name='ai_chat'),
       path('documents/add/', AddLegalDocumentsView.as_view(), name='add_legal_documents'),
       path('documents/delete/', DeleteLegalDocumentsView.as_view(), name='delete_legal_documents'),
   ]
   ```

**7. Include `ai_assistant` URLs in `smartju/urls.py`:**

   Modify the main `urls.py` to include the new app's URLs.

   **File: `smartju/urls.py`** (Modify existing file)

   ```python
   # smartju/urls.py

   from django.contrib import admin
   from django.urls import path, include
   from rest_framework import permissions
   from drf_yasg.views import get_schema_view
   from drf_yasg import openapi

   # ... existing imports ...

   schema_view = get_schema_view(
       openapi.Info(
           title="SmartJudi2 API",
           default_version='v1',
           description="API documentation for SmartJudi2 judicial platform",
           terms_of_service="https://www.google.com/policies/terms/",
           contact=openapi.Contact(email="contact@smartjudi.local"),
           license=openapi.License(name="BSD License"),
       ),
       public=True,
       permission_classes=(permissions.AllowAny,),
   )

   urlpatterns = [
       path('admin/', admin.site.urls),
       path('api/accounts/', include('accounts.urls')),
       path('api/courts/', include('courts.urls')),
       path('api/lawsuits/', include('lawsuits.urls')),
       path('api/parties/', include('parties.urls')),
       path('api/attachments/', include('attachments.urls')),
       path('api/responses/', include('responses.urls')),
       path('api/laws/', include('laws.urls')),
       path('api/judgments/', include('judgments.urls')),
       path('api/appeals/', include('appeals.urls')),
       path('api/hearings/', include('hearings.urls')),
       path('api/audit/', include('audit.urls')),
       path('api/payments/', include('payments.urls')),
       path('api/ai/', include('ai_assistant.urls')), # Add this line (إضافة هذا السطر)

       path('swagger<format>/', schema_view.without_ui(cache_timeout=0), name='schema-json'),
       path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
       path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
   ]
   ```

---

### Part 4: Modify Flutter Frontend (`lib`)

Navigate to the `lib` directory of the Flutter project. All modifications will be relative to this directory.

**1. Create `lib/services/ai_api_service.dart`:**

   This service will handle communication with the Django AI Assistant API.

   **File: `lib/services/ai_api_service.dart`** (New file)

   ```dart
   // lib/services/ai_api_service.dart

   import 'dart:convert';
   import 'package:http/http.dart' as http;
   import 'package:flutter/foundation.dart'; // For debugPrint

   class AIApiService {
     // (خدمة للتواصل مع API المساعد الذكي في Django)
     final String _baseUrl = 'YOUR_DJANGO_RENDER_URL/api/ai'; // Replace with your Django Render URL

     Future<Map<String, dynamic>> getChatResponse(
       String query, 
       List<Map<String, String>> conversationHistory
     ) async {
       // (الحصول على استجابة الدردشة من المساعد الذكي)
       final url = Uri.parse('$_baseUrl/chat/');
       try {
         final response = await http.post(
           url,
           headers: {'Content-Type': 'application/json'},
           body: json.encode({
             'query': query,
             'conversation_history': conversationHistory,
           }),
         );

         if (response.statusCode == 200) {
           return json.decode(utf8.decode(response.bodyBytes));
         } else {
           debugPrint('Error getting chat response: ${response.statusCode} ${response.body}');
           throw Exception('Failed to get chat response: ${response.body}');
         }
       } catch (e) {
         debugPrint('Exception during chat response: $e');
         throw Exception('Failed to connect to AI service: $e');
       }
     }

     Future<Map<String, dynamic>> uploadLegalDocuments(
       List<http.MultipartFile> files
     ) async {
       // (رفع المستندات القانونية إلى محرك RAG عبر Django)
       final url = Uri.parse('$_baseUrl/documents/add/');
       var request = http.MultipartRequest('POST', url);
       request.files.addAll(files);

       try {
         var response = await request.send();
         final responseBody = await response.stream.bytesToString();

         if (response.statusCode == 200) {
           return json.decode(utf8.decode(responseBody.runes.toList()));
         } else {
           debugPrint('Error uploading documents: ${response.statusCode} $responseBody');
           throw Exception('Failed to upload documents: $responseBody');
         }
       } catch (e) {
         debugPrint('Exception during document upload: $e');
         throw Exception('Failed to connect to AI service for upload: $e');
       }
     }

     Future<Map<String, dynamic>> deleteLegalDocuments(String source) async {
       // (حذف المستندات القانونية من محرك RAG عبر Django)
       final url = Uri.parse('$_baseUrl/documents/delete/');
       try {
         final response = await http.delete(
           url,
           headers: {'Content-Type': 'application/json'},
           body: json.encode({'source': source}),
         );

         if (response.statusCode == 200) {
           return json.decode(utf8.decode(response.bodyBytes));
         } else {
           debugPrint('Error deleting documents: ${response.statusCode} ${response.body}');
           throw Exception('Failed to delete documents: ${response.body}');
         }
       } catch (e) {
         debugPrint('Exception during document deletion: $e');
         throw Exception('Failed to connect to AI service for deletion: $e');
       }
     }
   }
   ```

**2. Create `lib/providers/ai_chat_provider.dart`:**

   This provider will manage the state of the AI chat interface.

   **File: `lib/providers/ai_chat_provider.dart`** (New file)

   ```dart
   // lib/providers/ai_chat_provider.dart

   import 'package:flutter/material.dart';
   import '../services/ai_api_service.dart';

   class AIChatProvider with ChangeNotifier {
     // (مزود الحالة لإدارة واجهة الدردشة مع المساعد الذكي)
     final AIApiService _apiService = AIApiService();
     List<Map<String, String>> _messages = [];
     bool _isLoading = false;
     String? _errorMessage;

     List<Map<String, String>> get messages => _messages;
     bool get isLoading => _isLoading;
     String? get errorMessage => _errorMessage;

     AIChatProvider() {
       // Initial system message (رسالة النظام الأولية)
       _messages.add({
         'role': 'assistant',
         'content': 'مرحبًا بك في مساعدك القانوني الذكي. كيف يمكنني مساعدتك اليوم؟',
       });
     }

     Future<void> sendMessage(String query) async {
       // (إرسال رسالة المستخدم والحصول على استجابة المساعد)
       _messages.add({'role': 'user', 'content': query});
       _isLoading = true;
       _errorMessage = null;
       notifyListeners();

       try {
         final response = await _apiService.getChatResponse(query, _messages.sublist(1)); // Exclude initial system message
         _messages.add({'role': 'assistant', 'content': response['response']});
         // Optionally, handle source_documents if needed for display
       } catch (e) {
         _errorMessage = 'فشل في الحصول على استجابة: $e';
         _messages.add({'role': 'assistant', 'content': 'عذرًا، حدث خطأ. يرجى المحاولة مرة أخرى.'});
       } finally {
         _isLoading = false;
         notifyListeners();
       }
     }

     void clearChat() {
       // (مسح سجل الدردشة)
       _messages = [{
         'role': 'assistant',
         'content': 'مرحبًا بك في مساعدك القانوني الذكي. كيف يمكنني مساعدتك اليوم؟',
       }];
       _errorMessage = null;
       notifyListeners();
     }
   }
   ```

**3. Create `lib/screens/ai_chat_screen.dart`:**

   This will be the main chat interface for the AI assistant.

   **File: `lib/screens/ai_chat_screen.dart`** (New file)

   ```dart
   // lib/screens/ai_chat_screen.dart

   import 'package:flutter/material.dart';
   import 'package:provider/provider.dart';
   import '../providers/ai_chat_provider.dart';

   class AIChatScreen extends StatefulWidget {
     // (شاشة واجهة الدردشة مع المساعد الذكي)
     static const String routeName = '/ai-chat';

     const AIChatScreen({Key? key}) : super(key: key);

     @override
     State<AIChatScreen> createState() => _AIChatScreenState();
   }

   class _AIChatScreenState extends State<AIChatScreen> {
     final TextEditingController _controller = TextEditingController();
     final ScrollController _scrollController = ScrollController();

     @override
     void dispose() {
       _controller.dispose();
       _scrollController.dispose();
       super.dispose();
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
           actions: [
             IconButton(
               icon: const Icon(Icons.clear_all),
               onPressed: () {
                 Provider.of<AIChatProvider>(context, listen: false).clearChat();
               },
               tooltip: 'مسح الدردشة',
             ),
           ],
         ),
         body: Column(
           children: [
             Expanded(
               child: Consumer<AIChatProvider>(
                 builder: (context, provider, child) {
                   _scrollToBottom();
                   return ListView.builder(
                     controller: _scrollController,
                     padding: const EdgeInsets.all(8.0),
                     itemCount: provider.messages.length,
                     itemBuilder: (context, index) {
                       final message = provider.messages[index];
                       final isUser = message['role'] == 'user';
                       return Align(
                         alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                         child: Container(
                           margin: const EdgeInsets.symmetric(vertical: 5.0),
                           padding: const EdgeInsets.all(10.0),
                           decoration: BoxDecoration(
                             color: isUser ? Colors.blue[100] : Colors.grey[200],
                             borderRadius: BorderRadius.circular(15.0),
                           ),
                           child: Text(message['content']!),
                         ),
                       );
                     },
                   );
                 },
               ),
             ),
             if (Provider.of<AIChatProvider>(context).isLoading)
               const Padding(
                 padding: EdgeInsets.all(8.0),
                 child: LinearProgressIndicator(),
               ),
             if (Provider.of<AIChatProvider>(context).errorMessage != null)
               Padding(
                 padding: const EdgeInsets.all(8.0),
                 child: Text(
                   Provider.of<AIChatProvider>(context).errorMessage!,
                   style: const TextStyle(color: Colors.red),
                 ),
               ),
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Row(
                 children: [
                   Expanded(
                     child: TextField(
                       controller: _controller,
                       decoration: InputDecoration(
                         hintText: 'اكتب استفسارك القانوني...', // (اكتب استفسارك القانوني)
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(20.0),
                         ),
                         contentPadding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                       ),
                       maxLines: null,
                       keyboardType: TextInputType.multiline,
                     ),
                   ),
                   const SizedBox(width: 8.0),
                   FloatingActionButton(
                     onPressed: Provider.of<AIChatProvider>(context).isLoading
                         ? null
                         : () {
                             if (_controller.text.isNotEmpty) {
                               Provider.of<AIChatProvider>(context, listen: false)
                                   .sendMessage(_controller.text);
                               _controller.clear();
                             }
                           },
                     child: const Icon(Icons.send),
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

**4. Create `lib/screens/case_analysis_screen.dart`:**

   This screen will allow users to input case details for AI analysis. For simplicity, this initial version will use the same chat API, but a more specialized API could be developed later.

   **File: `lib/screens/case_analysis_screen.dart`** (New file)

   ```dart
   // lib/screens/case_analysis_screen.dart

   import 'package:flutter/material.dart';
   import 'package:provider/provider.dart';
   import '../providers/ai_chat_provider.dart'; // Reusing for simplicity

   class CaseAnalysisScreen extends StatefulWidget {
     // (شاشة تحليل القضايا باستخدام المساعد الذكي)
     static const String routeName = '/case-analysis';

     const CaseAnalysisScreen({Key? key}) : super(key: key);

     @override
     State<CaseAnalysisScreen> createState() => _CaseAnalysisScreenState();
   }

   class _CaseAnalysisScreenState extends State<CaseAnalysisScreen> {
     final TextEditingController _caseDetailsController = TextEditingController();
     String _analysisResult = '';
     bool _isLoading = false;
     String? _errorMessage;

     @override
     void dispose() {
       _caseDetailsController.dispose();
       super.dispose();
     }

     Future<void> _analyzeCase() async {
       // (تحليل القضية باستخدام المساعد الذكي)
       if (_caseDetailsController.text.isEmpty) {
         setState(() {
           _errorMessage = 'الرجاء إدخال تفاصيل القضية للتحليل.'; // (الرجاء إدخال تفاصيل القضية)
         });
         return;
       }

       setState(() {
         _isLoading = true;
         _errorMessage = null;
         _analysisResult = '';
       });

       final query = "حلل القضية التالية وقدم التكييف القانوني والإجراءات المحتملة بناءً على القانون اليمني:\n" +
                     _caseDetailsController.text;

       try {
         final response = await Provider.of<AIChatProvider>(context, listen: false)
             ._apiService.getChatResponse(query, []); // Start new conversation for analysis
         setState(() {
           _analysisResult = response['response'];
         });
       } catch (e) {
         setState(() {
           _errorMessage = 'فشل في تحليل القضية: $e';
           _analysisResult = 'عذرًا، حدث خطأ أثناء تحليل القضية. يرجى المحاولة مرة أخرى.';
         });
       } finally {
         setState(() {
           _isLoading = false;
         });
       }
     }

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(
           title: const Text('تحليل القضايا بالذكاء الاصطناعي'), // (تحليل القضايا بالذكاء الاصطناعي)
         ),
         body: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               TextField(
                 controller: _caseDetailsController,
                 decoration: InputDecoration(
                   hintText: 'أدخل تفاصيل القضية هنا...', // (أدخل تفاصيل القضية هنا)
                   border: const OutlineInputBorder(),
                   labelText: 'تفاصيل القضية', // (تفاصيل القضية)
                 ),
                 maxLines: 10,
                 minLines: 5,
               ),
               const SizedBox(height: 16.0),
               _isLoading
                   ? const Center(child: CircularProgressIndicator())
                   : ElevatedButton(
                       onPressed: _analyzeCase,
                       child: const Text('تحليل القضية'), // (تحليل القضية)
                       style: ElevatedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 12.0),
                         textStyle: const TextStyle(fontSize: 18.0),
                       ),
                     ),
               if (_errorMessage != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 16.0),
                   child: Text(
                     _errorMessage!,
                     style: const TextStyle(color: Colors.red, fontSize: 16.0),
                     textAlign: TextAlign.center,
                   ),
                 ),
               const SizedBox(height: 24.0),
               Expanded(
                 child: SingleChildScrollView(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'نتائج التحليل:', // (نتائج التحليل)
                         style: Theme.of(context).textTheme.headlineSmall,
                       ),
                       const SizedBox(height: 8.0),
                       _analysisResult.isEmpty
                           ? const Text('لا توجد نتائج تحليل بعد.') // (لا توجد نتائج تحليل بعد)
                           : Text(_analysisResult),
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

**5. Update `lib/main.dart`:**

   Integrate the new provider and screens into the Flutter application.

   **File: `lib/main.dart`** (Modify existing file)

   ```dart
   // lib/main.dart

   import 'package:flutter/material.dart';
   import 'package:provider/provider.dart';
   import 'package:smartjudiflutter/providers/ai_chat_provider.dart'; // Import the new provider (استيراد المزود الجديد)
   import 'package:smartjudiflutter/screens/ai_chat_screen.dart'; // Import the new AI Chat Screen (استيراد شاشة الدردشة الجديدة)
   import 'package:smartjudiflutter/screens/case_analysis_screen.dart'; // Import the new Case Analysis Screen (استيراد شاشة تحليل القضايا الجديدة)
   // ... other imports ...

   void main() {
     runApp(const MyApp());
   }

   class MyApp extends StatelessWidget {
     const MyApp({Key? key}) : super(key: key);

     @override
     Widget build(BuildContext context) {
       return MultiProvider(
         providers: [
           ChangeNotifierProvider(create: (_) => AIChatProvider()), // Add AI Chat Provider (إضافة مزود الدردشة بالذكاء الاصطناعي)
           // ... other providers ...
         ],
         child: MaterialApp(
           title: 'SmartJudi2',
           theme: ThemeData(
             primarySwatch: Colors.blue,
             visualDensity: VisualDensity.adaptivePlatformDensity,
           ),
           initialRoute: '/',
           routes: {
             '/': (context) => const LoginScreen(), // Assuming LoginScreen is your initial screen
             AIChatScreen.routeName: (context) => const AIChatScreen(), // Add AI Chat Screen route (إضافة مسار شاشة الدردشة)
             CaseAnalysisScreen.routeName: (context) => const CaseAnalysisScreen(), // Add Case Analysis Screen route (إضافة مسار شاشة تحليل القضايا)
             // ... other routes ...
           },
         ),
       );
     }
   }
   ```

**6. Update Navigation (Example: Add buttons to an existing screen like `home_screen.dart` or a drawer):**

   To access the new screens, you'll need to add navigation elements. Here's an example of how you might add buttons to `home_screen.dart` (assuming it exists and is a main navigation point).

   **File: `lib/screens/home_screen.dart`** (Modify existing file - example)

   ```dart
   // lib/screens/home_screen.dart

   import 'package:flutter/material.dart';
   import 'package:smartjudiflutter/screens/ai_chat_screen.dart';
   import 'package:smartjudiflutter/screens/case_analysis_screen.dart';
   // ... other imports ...

   class HomeScreen extends StatelessWidget {
     const HomeScreen({Key? key}) : super(key: key);

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(
           title: const Text('SmartJudi2'),
         ),
         drawer: Drawer(
           child: ListView(
             padding: EdgeInsets.zero,
             children: <Widget>[
               const DrawerHeader(
                 decoration: BoxDecoration(
                   color: Colors.blue,
                 ),
                 child: Text(
                   'قائمة SmartJudi2',
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 24,
                   ),
                 ),
               ),
               ListTile(
                 leading: const Icon(Icons.chat_bubble_outline),
                 title: const Text('المساعد القانوني بالذكاء الاصطناعي'), // (المساعد القانوني بالذكاء الاصطناعي)
                 onTap: () {
                   Navigator.pop(context); // Close the drawer
                   Navigator.pushNamed(context, AIChatScreen.routeName);
                 },
               ),
               ListTile(
                 leading: const Icon(Icons.analytics_outlined),
                 title: const Text('تحليل القضايا بالذكاء الاصطناعي'), // (تحليل القضايا بالذكاء الاصطناعي)
                 onTap: () {
                   Navigator.pop(context); // Close the drawer
                   Navigator.pushNamed(context, CaseAnalysisScreen.routeName);
                 },
               ),
               // ... other existing drawer items ...
             ],
           ),
         ),
         body: Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const Text(
                 'مرحبًا بك في SmartJudi2!', // (مرحبًا بك في SmartJudi2!)
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 20),
               ElevatedButton.icon(
                 onPressed: () {
                   Navigator.pushNamed(context, AIChatScreen.routeName);
                 },
                 icon: const Icon(Icons.chat),
                 label: const Text('ابدأ الدردشة مع المساعد القانوني'), // (ابدأ الدردشة مع المساعد القانوني)
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                   textStyle: const TextStyle(fontSize: 18),
                 ),
               ),
               const SizedBox(height: 10),
               ElevatedButton.icon(
                 onPressed: () {
                   Navigator.pushNamed(context, CaseAnalysisScreen.routeName);
                 },
                 icon: const Icon(Icons.gavel),
                 label: const Text('تحليل قضية جديدة'), // (تحليل قضية جديدة)
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                   textStyle: const TextStyle(fontSize: 18),
                 ),
               ),
               // ... other existing home screen content ...
             ],
           ),
         ),
       );
     }
   }
   ```

---

### Part 5: Legal Data Loading Script

This Python script will be used to load and index legal documents into the Hugging Face RAG engine. This script should be run locally or in a dedicated environment with access to the legal documents and the RAG API.

**File: `load_legal_data.py`** (New Python script, outside the Django project, e.g., in a `scripts` directory)

```python
# load_legal_data.py

import os
import requests
import argparse
import mimetypes
import logging
from dotenv import load_dotenv

# Configure logging
# (تكوين التسجيل)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables from .env file (if any)
# (تحميل متغيرات البيئة من ملف .env)
load_dotenv()

def upload_documents_to_rag(rag_api_url: str, file_paths: list[str]):
    # (رفع المستندات إلى محرك RAG)
    add_documents_endpoint = f"{rag_api_url}/add_documents"
    files_to_upload = []

    for file_path in file_paths:
        if not os.path.exists(file_path):
            logger.warning(f"File not found: {file_path}. Skipping.")
            continue
        
        try:
            with open(file_path, 'rb') as f:
                file_content = f.read()
            filename = os.path.basename(file_path)
            content_type = mimetypes.guess_type(file_path)[0] or 'application/octet-stream'
            files_to_upload.append(('files', (filename, file_content, content_type)))
            logger.info(f"Prepared file for upload: {filename} ({content_type})")
        except Exception as e:
            logger.error(f"Error reading file {file_path}: {e}")
            continue

    if not files_to_upload:
        logger.info("No valid files to upload.")
        return

    try:
        logger.info(f"Attempting to upload {len(files_to_upload)} files to RAG engine at {add_documents_endpoint}")
        response = requests.post(add_documents_endpoint, files=files_to_upload, timeout=120)
        response.raise_for_status() # Raise HTTPError for bad responses (4xx or 5xx)
        logger.info(f"Documents uploaded successfully: {response.json()}")
    except requests.exceptions.Timeout:
        logger.error(f"Upload request to RAG engine timed out.")
    except requests.exceptions.RequestException as e:
        logger.error(f"Error uploading documents to RAG engine: {e}")
    except Exception as e:
        logger.error(f"An unexpected error occurred during upload: {e}")

def delete_documents_from_rag(rag_api_url: str, source_filename: str):
    # (حذف المستندات من محرك RAG)
    delete_documents_endpoint = f"{rag_api_url}/delete_documents"
    payload = {"source": source_filename}
    try:
        logger.info(f"Attempting to delete documents with source '{source_filename}' from RAG engine at {delete_documents_endpoint}")
        response = requests.delete(delete_documents_endpoint, json=payload, timeout=60)
        response.raise_for_status()
        logger.info(f"Documents deleted successfully: {response.json()}")
    except requests.exceptions.Timeout:
        logger.error(f"Delete request to RAG engine timed out.")
    except requests.exceptions.RequestException as e:
        logger.error(f"Error deleting documents from RAG engine: {e}")
    except Exception as e:
        logger.error(f"An unexpected error occurred during deletion: {e}")

def main():
    parser = argparse.ArgumentParser(description="Upload or delete legal documents to the SmartJudi2 RAG engine.")
    parser.add_argument('--rag_api_url', type=str, default=os.getenv("RAG_API_URL"),
                        help='Base URL of the Hugging Face RAG API (e.g., https://your-rag-space.hf.space)')
    parser.add_argument('--upload', nargs='+', help='List of file paths to upload (PDF, Word, Text).')
    parser.add_argument('--delete', type=str, help='Source filename to delete documents by.')

    args = parser.parse_args()

    if not args.rag_api_url:
        logger.error("RAG_API_URL is not provided. Please set it as an environment variable or via --rag_api_url argument.")
        return

    if args.upload:
        upload_documents_to_rag(args.rag_api_url, args.upload)
    elif args.delete:
        delete_documents_from_rag(args.rag_api_url, args.delete)
    else:
        logger.info("Please specify either --upload with file paths or --delete with a source filename.")

if __name__ == "__main__":
    main()
```

**Usage Example:**

To upload documents:
```bash
python load_legal_data.py --rag_api_url "https://your-rag-space.hf.space" --upload "./data/law1.pdf" "./data/law2.txt"
```

To delete documents by source filename:
```bash
python load_legal_data.py --rag_api_url "https://your-rag-space.hf.space" --delete "law1.pdf"
```

---

### Part 6: Execution Order and Important Notes

**Execution Order:**

1.  **Hugging Face Space (RAG Engine):**
    -   Create the Hugging Face Space project.
    -   Add `Dockerfile`, `requirements.txt`, `main.py`, and `.env` to the root of the space.
    -   Deploy the space. Ensure it's running and the `/health` endpoint returns `"ok"`.

2.  **Local Machine (Ollama Setup):**
    -   Follow the user instructions to install Ollama and download the Qwen model.
    -   Configure `OLLAMA_HOST`.
    -   Set up Cloudflare Tunnel or ngrok to expose Ollama to the internet. **Crucially, obtain the public URL.**
    -   Create and apply the custom `Modelfile` for `smartjudi-qwen`.

3.  **Django Backend (`smartju`):**
    -   Create the `ai_assistant` app.
    -   Update `smartju/settings.py` to include `ai_assistant`.
    -   Create `.env` variables `RAG_API_URL` (from Hugging Face Space) and `OLLAMA_API_URL` (from Cloudflare/ngrok).
    -   Create `ai_assistant/services.py`, `ai_assistant/serializers.py`, `ai_assistant/views.py`, and `ai_assistant/urls.py`.
    -   Update `smartju/urls.py` to include `ai_assistant.urls`.
    -   Run Django migrations if any new models were introduced (though none are in this plan).
    -   Test the Django API endpoints (`/api/ai/chat/`, `/api/ai/documents/add/`, `/api/ai/documents/delete/`) using a tool like Postman or `curl`.

4.  **Legal Data Loading:**
    -   Run the `load_legal_data.py` script to upload your Yemeni legal documents to the Hugging Face RAG engine.

5.  **Flutter Frontend (`lib`):**
    -   Create `lib/services/ai_api_service.dart`.
    -   **Update `_baseUrl` in `AIApiService` with your deployed Django Render URL.**
    -   Create `lib/providers/ai_chat_provider.dart`.
    -   Create `lib/screens/ai_chat_screen.dart` and `lib/screens/case_analysis_screen.dart`.
    -   Update `lib/main.dart` to include the `AIChatProvider` and the new screen routes.
    -   Modify an existing navigation screen (e.g., `home_screen.dart`) to add links to `AIChatScreen` and `CaseAnalysisScreen`.
    -   Test the Flutter application.

**Testing:**

-   **RAG Engine:** Verify the `/health` endpoint. Upload a few test documents and perform searches to ensure relevant results are returned.
-   **Ollama:** Confirm Ollama is running locally and accessible via the tunnel. Test with `curl` to the tunnel URL.
-   **Django Backend:** Use Postman or `curl` to test the `/api/ai/chat/` endpoint with sample queries. Verify that RAG context is being used and Ollama responses are received.
-   **Flutter Frontend:** Navigate to the new AI chat and case analysis screens. Send queries and observe responses. Ensure the UI/UX is professional and responsive.

**Important Notes:**

-   **Security:** Ensure that your Cloudflare Tunnel or ngrok setup is secure. For production, consider more robust authentication and authorization for your RAG and Ollama APIs.
-   **Error Handling:** The provided code includes basic error handling and logging. Enhance this further for a production environment, including more specific error messages and monitoring.
-   **Scalability:** The current RAG setup uses ChromaDB in-memory/local persistence. For very large datasets or high concurrency, consider a distributed vector store solution.
-   **Model Choice:** Qwen 2.5 (7B or 14B) is suggested. Experiment with other models available on Ollama if performance or response quality needs adjustment.
-   **Prompt Engineering:** The system prompt and few-shot examples are crucial for LLM performance. Continuously refine them based on user feedback and desired output quality.
-   **Data Privacy:** Be mindful of data privacy when handling legal documents. Ensure sensitive information is handled appropriately, especially when uploading to Hugging Face Spaces.
-   **Flutter UI/UX:** The provided Flutter UI is functional. Further design and polish will be required to meet professional UI/UX standards.

```

