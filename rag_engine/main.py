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
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
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

app = FastAPI(
    title="SmartJudi2 RAG Engine",
    description="FastAPI service for Retrieval-Augmented Generation using ChromaDB and HuggingFace Embeddings.",
    version="1.0.0",
)

# --- Configuration --- #

# Embedding model name
# (اسم نموذج التضمين)
# Note: Using intfloat/multilingual-e5-large instead of sentence-transformers/ prefix
EMBEDDING_MODEL_NAME = os.getenv(
    "EMBEDDING_MODEL_NAME",
    "intfloat/multilingual-e5-large"  # Changed from sentence-transformers/multilingual-e5-large
)

# Directory for ChromaDB persistence
# (مسار تخزين قاعدة بيانات ChromaDB)
CHROMA_DB_DIR = os.getenv("CHROMA_DB_DIR", "./chroma_db")
CHROMA_DB_PATH = os.getenv("CHROMA_DB_PATH", CHROMA_DB_DIR)  # Alias for compatibility

# Initialize embedding model (will be loaded asynchronously)
# (تهيئة نموذج التضمين - سيتم تحميله بشكل غير متزامن)
embeddings = None
model_loading = False
model_loaded = False


# Initialize ChromaDB client
# (تهيئة عميل ChromaDB)
vectorstore = None

def load_embedding_model():
    """Load embedding model synchronously"""
    global embeddings, model_loaded
    try:
        # Get Hugging Face token from environment
        HUGGINGFACE_TOKEN = os.getenv("HUGGINGFACE_API_KEY") or os.getenv("HF_TOKEN")
        
        # Use token if available for private/gated models
        model_kwargs = {}
        if HUGGINGFACE_TOKEN:
            model_kwargs["token"] = HUGGINGFACE_TOKEN
            logger.info("Using Hugging Face token for model access")
        
        embeddings = HuggingFaceEmbeddings(
            model_name=EMBEDDING_MODEL_NAME,
            model_kwargs=model_kwargs
        )
        logger.info(f"Successfully loaded embedding model: {EMBEDDING_MODEL_NAME}")
        model_loaded = True
        return embeddings
    except Exception as e:
        logger.error(f"Error loading embedding model: {e}")
        raise RuntimeError(f"Failed to load embedding model: {e}")

def get_chroma_client():
    global embeddings
    try:
        if embeddings is None:
            raise RuntimeError("Embeddings not loaded yet")
        os.makedirs(CHROMA_DB_DIR, exist_ok=True)
        client = Chroma(
            persist_directory=CHROMA_DB_DIR,
            embedding_function=embeddings
        )
        client.persist()
        logger.info(f"Successfully initialized ChromaDB at {CHROMA_DB_DIR}")
        return client
    except Exception as e:
        logger.error(f"Error initializing ChromaDB: {e}")
        raise RuntimeError(f"Failed to initialize ChromaDB: {e}")


# Initialize on startup (async to allow health check to work immediately)
@app.on_event("startup")
async def startup_event():
    """
    Initialize the embedding model and ChromaDB on application startup.
    تهيئة نموذج التضمين و ChromaDB عند بدء تشغيل التطبيق.
    
    Note: Model loading happens in background to allow Hugging Face Spaces
    health checks to pass immediately.
    """
    global vectorstore, model_loading, model_loaded
    
    # Initialize ChromaDB directory first (fast operation)
    try:
        os.makedirs(CHROMA_DB_DIR, exist_ok=True)
    except Exception as e:
        logger.warning(f"Could not create ChromaDB directory: {e}")
    
    # Start loading model in background (non-blocking)
    import asyncio
    model_loading = True
    model_loaded = False  # Ensure this is set correctly
    
    async def load_model_async():
        global vectorstore, model_loading, model_loaded
        try:
            logger.info("Starting to load embedding model in background...")
            # Load model in thread pool to avoid blocking
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, load_embedding_model)
            
            # Initialize ChromaDB after model is loaded
            logger.info("Initializing ChromaDB...")
            def init_chroma():
                global vectorstore
                vectorstore = get_chroma_client()
            await loop.run_in_executor(None, init_chroma)
            logger.info("ChromaDB initialized and persisted successfully.")
            model_loading = False
            model_loaded = True
        except Exception as e:
            logger.error(f"Failed to initialize RAG components: {e}", exc_info=True)
            model_loading = False
            model_loaded = False
            # Don't raise - allow app to start even if model loading fails
    
    # Start loading in background (don't await - this allows health check to work immediately)
    asyncio.create_task(load_model_async())
    
    # Log that startup is complete (health check can now respond)
    logger.info("Application startup complete. Health check endpoints are ready.")


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


# Note: vectorstore will be initialized asynchronously in startup event

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

from pydantic import Field
from typing import Optional

class DocumentSchema(BaseModel):
    """Schema for document content and metadata"""
    page_content: str = Field(..., description="The textual content of the document.")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Arbitrary metadata associated with the document.")


class SearchQuery(BaseModel):
    """Schema for search requests"""
    query_text: str = Field(..., description="The query string to search for.")
    k: int = Field(default=4, ge=1, le=10, description="The number of relevant documents to retrieve.")


class DeleteQuery(BaseModel):
    """Schema for delete requests"""
    ids: Optional[List[str]] = Field(None, description="List of document IDs to delete.")
    metadata_filter: Optional[Dict[str, Any]] = Field(None, description="Metadata to filter documents for deletion.")


class DocumentAddRequest(BaseModel):
    """Legacy model for backward compatibility"""
    documents: List[Dict[str, str]]


class SearchRequest(BaseModel):
    """Legacy model for backward compatibility"""
    query: str
    k: int = 4


class SearchResponse(BaseModel):
    """Legacy model for backward compatibility"""
    results: List[Dict[str, Any]]


class HealthResponse(BaseModel):
    status: str
    message: str


# --- API Endpoints ---

@app.get("/", summary="Root endpoint", response_model=Dict[str, str])
async def root():
    """
    Root endpoint for health check (used by Hugging Face Spaces).
    نقطة النهاية الجذرية للتحقق من الصحة (تُستخدم من قبل Hugging Face Spaces).
    """
    return {"status": "ok", "message": "RAG Engine is running"}

@app.get("/health", summary="Health Check", response_model=Dict[str, str])
async def health_check():
    """
    Checks the health of the RAG engine.
    يتحقق من حالة عمل محرك RAG.
    Note: Returns OK even if model is still loading to allow Hugging Face Spaces to start.
    """
    global model_loading, model_loaded, vectorstore
    
    # Always return OK immediately for health check - this allows Hugging Face Spaces to start
    # The model will load in background
    # Don't do any expensive operations here - just return OK
    if model_loading:
        return {"status": "ok", "message": "Model is loading in background"}
    elif model_loaded and vectorstore:
        # Don't call count() here - it might be slow
        # Just check if vectorstore exists
        return {"status": "ok", "message": "RAG engine is fully operational"}
    else:
        return {"status": "ok", "message": "RAG engine initializing"}


@app.post("/add_documents", summary="Add Documents to ChromaDB", response_model=Dict[str, str])
async def add_documents(
    documents: Optional[List[DocumentSchema]] = None,
    files: Optional[List[UploadFile]] = File(None)
):
    """
    Adds a list of documents to the ChromaDB vector store.
    يضيف قائمة من المستندات إلى مخزن المتجهات ChromaDB.
    Supports both JSON document list and file uploads.
    """
    all_documents = []
    
    # Handle JSON document list (new API)
    if documents:
        try:
            from langchain_core.documents import Document as LangchainDocument
            langchain_documents = [
                LangchainDocument(page_content=doc.page_content, metadata=doc.metadata) 
                for doc in documents
            ]
            all_documents.extend(langchain_documents)
            logger.info(f"Received {len(documents)} documents via JSON API")
        except Exception as e:
            logger.error(f"Error processing JSON documents: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Failed to process documents: {e}")
    
    # Handle file uploads (legacy API)
    if files:
        if not files:
            raise HTTPException(status_code=400, detail="No files provided.")

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
            detail="No documents provided. Please provide either documents list or files."
        )

    # Check if vectorstore is ready
    if vectorstore is None or embeddings is None:
        raise HTTPException(
            status_code=503,
            detail="RAG engine is still initializing. Please wait a moment and try again."
        )
    
    try:
        vectorstore.add_documents(all_documents)
        vectorstore.persist()
        logger.info(f"Successfully added {len(all_documents)} documents.")
        return {"message": f"Successfully added {len(all_documents)} documents."}
    except Exception as e:
        logger.error(f"Error adding documents: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to add documents: {e}"
        )


@app.post("/search", response_model=List[DocumentSchema])
async def search_documents(query: SearchQuery):
    """
    Searches the ChromaDB vector store for documents relevant to the given query.
    يبحث في مخزن المتجهات ChromaDB عن المستندات ذات الصلة بالاستعلام المحدد.
    """
    # Check if vectorstore is ready
    if vectorstore is None or embeddings is None:
        raise HTTPException(
            status_code=503,
            detail="RAG engine is still initializing. Please wait a moment and try again."
        )
    
    try:
        logger.info(f"Searching ChromaDB for query: '{query.query_text}' with k={query.k}")
        results = vectorstore.similarity_search(query.query_text, k=query.k)
        logger.info(f"Found {len(results)} relevant documents.")
        return [DocumentSchema(page_content=doc.page_content, metadata=doc.metadata) for doc in results]
    except Exception as e:
        logger.error(f"Error searching documents: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to search documents: {e}"
        )


# Legacy endpoint for backward compatibility
@app.post("/search_legacy", response_model=SearchResponse)
async def search_documents_legacy(request: SearchRequest):
    """Legacy endpoint for backward compatibility"""
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


@app.post("/delete_documents", summary="Delete Documents from ChromaDB", response_model=Dict[str, str])
async def delete_documents(delete_query: DeleteQuery):
    """
    Deletes documents from the ChromaDB vector store based on IDs or metadata filter.
    يحذف المستندات من مخزن المتجهات ChromaDB بناءً على المعرفات أو فلتر البيانات الوصفية.
    """
    if not delete_query.ids and not delete_query.metadata_filter:
        raise HTTPException(
            status_code=400,
            detail="Either 'ids' or 'metadata_filter' must be provided."
        )

    # Check if vectorstore is ready
    if vectorstore is None or embeddings is None:
        raise HTTPException(
            status_code=503,
            detail="RAG engine is still initializing. Please wait a moment and try again."
        )

    try:
        if delete_query.ids:
            logger.info(f"Deleting documents with IDs: {delete_query.ids}")
            vectorstore.delete(ids=delete_query.ids)
            vectorstore.persist()
            logger.info(f"Successfully deleted documents with IDs: {delete_query.ids}")
            return {"message": f"Successfully deleted documents with IDs: {delete_query.ids}"}
        elif delete_query.metadata_filter:
            logger.info(f"Deleting documents with metadata filter: {delete_query.metadata_filter}")
            # ChromaDB's delete method supports where clause for metadata
            vectorstore.delete(where=delete_query.metadata_filter)
            vectorstore.persist()
            logger.info(f"Successfully deleted documents with metadata filter: {delete_query.metadata_filter}")
            return {"message": f"Successfully deleted documents with metadata filter: {delete_query.metadata_filter}"}
    except Exception as e:
        logger.error(f"Error deleting documents: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete documents: {e}"
        )


# Legacy endpoint for backward compatibility
@app.delete("/delete_documents_legacy")
async def delete_documents_legacy(source: str = Form(...)):
    """Legacy endpoint for backward compatibility"""
    try:
        docs_to_delete = vectorstore.get(where={"source": source})
        if not docs_to_delete['ids']:
            return {
                "status": "info",
                "message": f"No documents found with source: {source}"
            }

        vectorstore.delete(ids=docs_to_delete['ids'])
        vectorstore.persist()
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
