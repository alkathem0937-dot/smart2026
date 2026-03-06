# main.py - FastAPI application for RAG engine
# محرك RAG لاسترجاع المستندات القانونية

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
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(title="SmartJudi2 RAG Engine", version="1.0.0")

# --- Configuration --- #

# Embedding model name
# (اسم نموذج التضمين)
EMBEDDING_MODEL_NAME = os.getenv(
    "EMBEDDING_MODEL_NAME",
    "sentence-transformers/multilingual-e5-large"
)

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
        os.makedirs(CHROMA_DB_DIR, exist_ok=True)
        client = Chroma(
            persist_directory=CHROMA_DB_DIR,
            embedding_function=embeddings
        )
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
    """استخراج النص من ملف PDF"""
    try:
        images = convert_from_path(pdf_path)
        text = ""
        for i, image in enumerate(images):
            # Support Arabic and English
            text += pytesseract.image_to_string(image, lang='ara+eng')
            logger.debug(f"Extracted text from page {i + 1} of {pdf_path}")
        return text
    except Exception as e:
        logger.error(f"Error extracting text from PDF {pdf_path}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to extract text from PDF: {e}"
        )


def process_document(file_content: bytes, file_name: str) -> List[Document]:
    """معالجة المستند وتقسيمه إلى أجزاء"""
    text = ""
    if file_name.endswith(".pdf"):
        with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_file:
            tmp_file.write(file_content)
            tmp_file_path = tmp_file.name
        try:
            text = extract_text_from_pdf(tmp_file_path)
        finally:
            os.unlink(tmp_file_path)
    elif file_name.endswith(".txt"):
        text = file_content.decode('utf-8')
    elif file_name.endswith(".docx") or file_name.endswith(".doc"):
        logger.warning(
            f"Word document processing not fully implemented for {file_name}. "
            "Treating as plain text."
        )
        text = file_content.decode('utf-8', errors='ignore')
    else:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file_name}"
        )

    if not text:
        raise HTTPException(
            status_code=400,
            detail="Could not extract text from document."
        )

    # Split text into chunks
    # (تقسيم النص إلى أجزاء)
    chunks = text_splitter.split_text(text)
    documents = [
        Document(page_content=chunk, metadata={"source": file_name})
        for chunk in chunks
    ]
    logger.info(f"Processed document {file_name} into {len(documents)} chunks.")
    return documents


# --- API Models ---

class DocumentAddRequest(BaseModel):
    documents: List[Dict[str, str]]


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
    """نقطة نهاية للتحقق من صحة الخدمة"""
    try:
        _ = vectorstore._collection.count()
        return HealthResponse(
            status="ok",
            message="RAG engine is healthy and ChromaDB is accessible."
        )
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"RAG engine unhealthy: {e}"
        )


@app.post("/add_documents")
async def add_documents(files: List[UploadFile] = File(...)):
    """نقطة نهاية لإضافة مستندات جديدة"""
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
            logger.error(
                f"Unexpected error processing file {file.filename}: {e}"
            )
            raise HTTPException(
                status_code=500,
                detail=f"Internal server error processing file {file.filename}"
            )

    if not all_documents:
        raise HTTPException(
            status_code=400,
            detail="No valid documents could be processed."
        )

    try:
        vectorstore.add_documents(all_documents)
        logger.info(
            f"Added {len(all_documents)} document chunks to ChromaDB."
        )
        return {
            "status": "success",
            "message": f"Added {len(all_documents)} document chunks.",
            "filenames": [f.filename for f in files]
        }
    except Exception as e:
        logger.error(f"Error adding documents to ChromaDB: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to add documents to vector store: {e}"
        )


@app.post("/search", response_model=SearchResponse)
async def search_documents(request: SearchRequest):
    """نقطة نهاية للبحث عن المستندات ذات الصلة"""
    try:
        results = vectorstore.similarity_search(request.query, k=request.k)
        formatted_results = []
        for doc in results:
            formatted_results.append({
                "page_content": doc.page_content,
                "metadata": doc.metadata
            })
        logger.info(
            f"Performed similarity search for query '{request.query}', "
            f"found {len(formatted_results)} results."
        )
        return SearchResponse(results=formatted_results)
    except Exception as e:
        logger.error(f"Error during document search: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to search documents: {e}"
        )


@app.delete("/delete_documents")
async def delete_documents(source: str = Form(...)):
    """نقطة نهاية لحذف المستندات بناءً على المصدر"""
    try:
        docs_to_delete = vectorstore.get(where={"source": source})
        if not docs_to_delete['ids']:
            return {
                "status": "info",
                "message": f"No documents found with source: {source}"
            }

        vectorstore.delete(ids=docs_to_delete['ids'])
        logger.info(
            f"Deleted {len(docs_to_delete['ids'])} document chunks "
            f"with source: {source}"
        )
        return {
            "status": "success",
            "message": f"Deleted documents with source: {source}"
        }
    except Exception as e:
        logger.error(f"Error deleting documents: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete documents: {e}"
        )
