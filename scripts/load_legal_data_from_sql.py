# smartjudi2/scripts/load_legal_data_from_sql.py
# سكربت لاستخراج البيانات القانونية من ملف SQL وتحميلها إلى RAG Engine

import os
import re
import requests
import logging
import sys
import time
from dotenv import load_dotenv
from typing import List, Dict, Any

# For progress bar
try:
    from tqdm import tqdm
    HAS_TQDM = True
except ImportError:
    HAS_TQDM = False
    print("Info: tqdm not installed. Progress will be shown with simple logging.")

# For text splitting
try:
    from langchain_text_splitters import RecursiveCharacterTextSplitter
    from langchain_core.documents import Document as LangchainDocument
    HAS_LANGCHAIN = True
except ImportError:
    print("Warning: langchain not installed. Text splitting will use simple method.")
    HAS_LANGCHAIN = False

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()
RAG_API_URL = os.getenv("RAG_API_URL")

if not RAG_API_URL:
    logger.error("RAG_API_URL environment variable not set. Exiting.")
    exit(1)

# Initialize HTTP client for RAG API
rag_api_client = requests.Session()


def parse_sql_file(sql_file_path: str) -> List[Dict[str, Any]]:
    """
    Parse SQL INSERT statements and extract legal articles.
    يستخرج المواد القانونية من ملف SQL.
    """
    documents = []
    
    try:
        with open(sql_file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find the INSERT INTO statement
        insert_match = re.search(r"INSERT INTO\s+(\w+)\s*\(([^)]+)\)\s*VALUES", content, re.IGNORECASE)
        if not insert_match:
            logger.error("No INSERT INTO statement found in SQL file.")
            return []
        
        table_name = insert_match.group(1)
        columns_str = insert_match.group(2)
        columns = [col.strip() for col in columns_str.split(',')]
        
        logger.info(f"Found table: {table_name} with columns: {columns}")
        
        # Extract all VALUES rows - match pattern: ('value1','value2',...)
        # Handle multi-line and nested quotes
        values_pattern = r"\(((?:'[^']*(?:''[^']*)*'|\s*,\s*)*)\)"
        
        # More robust: find all rows between VALUES and end of statement
        values_start = insert_match.end()
        values_section = content[values_start:].strip()
        
        # Simple approach: split by ),\n( pattern (each row ends with ), and next starts with ()
        # Use regex to find all row patterns: ( ... ),
        # We'll match rows that end with ), and are followed by newline and (
        row_pattern = r"\([^)]*(?:'[^']*'[^)]*)*\),"
        
        # Actually, simpler: split by ),\n( pattern
        # But we need to handle quoted strings, so let's use a state machine
        rows = []
        current_row = ""
        paren_depth = 0
        in_quotes = False
        quote_char = None
        i = 0
        
        while i < len(values_section):
            char = values_section[i]
            next_chars = values_section[i:i+3] if i + 3 <= len(values_section) else ""
            
            if char == "'" and not in_quotes:
                in_quotes = True
                quote_char = "'"
                current_row += char
            elif char == "'" and in_quotes and quote_char == "'":
                # Check for escaped quote ('')
                if i + 1 < len(values_section) and values_section[i+1] == "'":
                    current_row += "''"
                    i += 1  # Skip next quote
                else:
                    in_quotes = False
                    quote_char = None
                    current_row += char
            elif char == '(' and not in_quotes:
                if paren_depth == 0:
                    # Start of new row
                    if current_row.strip():
                        rows.append(current_row.strip())
                    current_row = "("
                else:
                    current_row += char
                paren_depth += 1
            elif char == ')' and not in_quotes:
                paren_depth -= 1
                current_row += char
                if paren_depth == 0:
                    # End of row - check if next is comma and newline
                    # Look ahead for ),\n pattern
                    j = i + 1
                    while j < len(values_section) and values_section[j] in (' ', '\t', '\r', '\n'):
                        j += 1
                    if j < len(values_section) and values_section[j] == ',':
                        # Found ), - this is end of row
                        rows.append(current_row.strip())
                        current_row = ""
                        # Skip the comma and continue
                        i = j
                        continue
            else:
                current_row += char
            i += 1
        
        # Add last row if exists
        if current_row.strip():
            rows.append(current_row.strip())
        
        logger.info(f"Found {len(rows)} rows to parse")
        
        # Parse each row with progress bar
        if HAS_TQDM:
            rows_iter = tqdm(enumerate(rows), total=len(rows), desc="Parsing SQL rows", unit="row")
        else:
            rows_iter = enumerate(rows)
        
        for row_idx, row in rows_iter:
            try:
                # Remove outer parentheses
                row = row.strip()
                if row.startswith('(') and row.endswith(')'):
                    row = row[1:-1]
                
                # Parse values using CSV-like parsing (handles quoted strings with commas)
                # Split by comma, but respect quoted strings
                values = []
                current_value = ""
                in_quotes = False
                quote_char = None
                
                i = 0
                while i < len(row):
                    char = row[i]
                    
                    if char == "'":
                        if not in_quotes:
                            in_quotes = True
                            quote_char = "'"
                            current_value += char
                        elif quote_char == "'":
                            # Check for escaped quote ('')
                            if i + 1 < len(row) and row[i+1] == "'":
                                current_value += "''"
                                i += 1  # Skip next quote
                            else:
                                in_quotes = False
                                quote_char = None
                                current_value += char
                        else:
                            current_value += char
                    elif char == '"':
                        if not in_quotes:
                            in_quotes = True
                            quote_char = '"'
                            current_value += char
                        elif quote_char == '"':
                            in_quotes = False
                            quote_char = None
                            current_value += char
                        else:
                            current_value += char
                    elif char == ',' and not in_quotes:
                        values.append(current_value.strip())
                        current_value = ""
                    else:
                        current_value += char
                    i += 1
                
                # Add last value
                if current_value.strip() or len(values) < len(columns):
                    values.append(current_value.strip())
                
                # Clean values (remove quotes)
                cleaned_values = []
                for val in values:
                    val = val.strip()
                    if val.startswith("'") and val.endswith("'"):
                        val = val[1:-1]
                    elif val.startswith('"') and val.endswith('"'):
                        val = val[1:-1]
                    # Unescape SQL single quotes ('' -> ')
                    val = val.replace("''", "'")
                    cleaned_values.append(val)
                
                # Create document dictionary - ensure we have enough values
                if len(cleaned_values) >= len(columns):
                    doc_dict = {}
                    for i, col in enumerate(columns):
                        if i < len(cleaned_values):
                            doc_dict[col] = cleaned_values[i]
                        else:
                            doc_dict[col] = ''
                    
                    # Build page_content from article_text
                    article_text = doc_dict.get('article_text', '').strip()
                    if article_text:  # Only add if article_text is not empty
                        page_content = article_text
                        
                        # Build metadata
                        metadata = {
                            'source': 'yemen_legal_dataset.sql',
                            'source_title': doc_dict.get('source_title', ''),
                            'book_title': doc_dict.get('book_title', ''),
                            'section_title': doc_dict.get('section_title', ''),
                            'chapter_title': doc_dict.get('chapter_title', ''),
                            'branch_title': doc_dict.get('branch_title', ''),
                            'article_number': doc_dict.get('article_number', ''),
                        }
                        
                        documents.append({
                            'page_content': page_content,
                            'metadata': metadata
                        })
                elif len(cleaned_values) > 0:
                    # Log warning for rows with wrong number of values
                    if row_idx < 10:  # Only log first 10 to avoid spam
                        logger.warning(f"Row {row_idx + 1}: Expected {len(columns)} values, got {len(cleaned_values)}")
            except Exception as e:
                logger.warning(f"Error parsing row {row_idx + 1}: {e}")
                continue
        
        logger.info(f"Successfully parsed {len(documents)} legal articles from SQL file.")
        return documents
        
    except Exception as e:
        logger.error(f"Error parsing SQL file: {e}", exc_info=True)
        return []


def chunk_documents(documents: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Chunks documents into smaller pieces with overlap.
    يقسم المستندات إلى أجزاء أصغر مع تداخل.
    """
    if HAS_LANGCHAIN:
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len,
            add_start_index=True,
        )
        chunked_docs = []
        
        # Progress bar for chunking
        if HAS_TQDM:
            docs_iter = tqdm(documents, desc="Chunking documents", unit="doc")
        else:
            docs_iter = documents
        
        for doc in docs_iter:
            try:
                langchain_doc = LangchainDocument(
                    page_content=doc["page_content"],
                    metadata=doc["metadata"]
                )
                chunks = text_splitter.split_documents([langchain_doc])
                for chunk in chunks:
                    chunked_docs.append({
                        "page_content": chunk.page_content,
                        "metadata": chunk.metadata
                    })
            except Exception as e:
                logger.error(f"Error chunking document: {e}")
                # Fallback: add document as-is
                chunked_docs.append(doc)
        logger.info(f"Chunked {len(documents)} documents into {len(chunked_docs)} chunks.")
        return chunked_docs
    else:
        # Simple chunking without langchain
        logger.warning("Using simple chunking method (langchain not available).")
        chunked_docs = []
        chunk_size = 1000
        chunk_overlap = 200
        for doc in documents:
            content = doc["page_content"]
            metadata = doc["metadata"]
            start = 0
            while start < len(content):
                end = start + chunk_size
                chunk = content[start:end]
                chunked_docs.append({
                    "page_content": chunk,
                    "metadata": {**metadata, "chunk_start": start}
                })
                start = end - chunk_overlap
        logger.info(f"Chunked {len(documents)} documents into {len(chunked_docs)} chunks (simple method).")
        return chunked_docs


def index_documents_to_rag(chunked_documents: List[Dict[str, Any]]) -> bool:
    """
    Indexes chunked documents into the Hugging Face RAG API.
    يفهرس المستندات المقسمة إلى واجهة برمجة تطبيقات RAG المستضافة على Hugging Face.
    
    Note: The API expects file uploads, so we create temporary text files for each batch.
    """
    if not RAG_API_URL:
        logger.error("RAG_API_URL is not set. Cannot index documents.")
        return False

    add_docs_url = f"{RAG_API_URL}/add_documents"
    
    # Process in batches to avoid overwhelming the API
    batch_size = 20  # Smaller batches for file uploads
    total_batches = (len(chunked_documents) + batch_size - 1) // batch_size
    
    # Progress bar for indexing
    if HAS_TQDM:
        batch_range = tqdm(range(0, len(chunked_documents), batch_size), 
                          desc="Indexing to RAG", unit="batch", total=total_batches)
    else:
        batch_range = range(0, len(chunked_documents), batch_size)
    
    import tempfile
    import io
    
    for i in batch_range:
        batch = chunked_documents[i:i + batch_size]
        batch_num = (i // batch_size) + 1
        
        if not HAS_TQDM:
            logger.info(f"Indexing batch {batch_num}/{total_batches} ({len(batch)} documents)...")
        
        try:
            # Create temporary text files for each document in the batch
            files = []
            for idx, doc in enumerate(batch):
                # Get content from document - check both possible keys
                content = doc.get('page_content', '') or doc.get('article_text', '')
                if not content or not content.strip():
                    continue
                
                # Create file-like object
                filename = f"doc_{batch_num}_{idx}.txt"
                file_content = content.encode('utf-8')
                files.append(('files', (filename, file_content, 'text/plain')))
            
            if not files:
                logger.warning(f"No valid documents in batch {batch_num}, skipping...")
                continue
            
            # Send files as multipart/form-data
            # Note: requests library handles multiple files with same field name automatically
            response = rag_api_client.post(
                add_docs_url,
                files=files,
                timeout=180  # Increased timeout for file uploads
            )
            response.raise_for_status()
            
            if not HAS_TQDM:
                result = response.json()
                docs_added = result.get('documents_added', len(files))
                logger.info(f"✅ Successfully indexed batch {batch_num}: {docs_added} documents added")
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to index batch {batch_num} to RAG engine: {e}")
            if hasattr(e, 'response') and e.response is not None:
                logger.error(f"RAG API Error Response: {e.response.text}")
            return False
    
    logger.info(f"Successfully indexed all {len(chunked_documents)} chunks to RAG engine.")
    return True


def main(sql_file_path: str):
    """
    Main function to load, parse, chunk, and index legal data from SQL file.
    الدالة الرئيسية لتحميل وتحليل وتقسيم وفهرسة البيانات القانونية من ملف SQL.
    """
    start_time = time.time()
    logger.info("=" * 60)
    logger.info("🚀 Starting legal data loading process")
    logger.info("=" * 60)
    logger.info(f"📁 SQL file: {sql_file_path}")
    logger.info(f"🌐 RAG API URL: {RAG_API_URL}")
    logger.info("")
    
    if not os.path.exists(sql_file_path):
        logger.error(f"❌ SQL file {sql_file_path} does not exist.")
        return
    
    # 1. Parse SQL file
    # 1. تحليل ملف SQL
    logger.info("📖 Step 1/3: Parsing SQL file...")
    parse_start = time.time()
    raw_documents = parse_sql_file(sql_file_path)
    parse_time = time.time() - parse_start
    
    if not raw_documents:
        logger.warning("❌ No documents found in SQL file. Exiting.")
        return
    
    logger.info(f"✅ Successfully parsed {len(raw_documents)} legal articles in {parse_time:.2f}s")
    logger.info("")
    
    # 2. Chunk documents
    # 2. تقسيم المستندات
    logger.info("✂️  Step 2/3: Chunking documents...")
    chunk_start = time.time()
    chunked_documents = chunk_documents(raw_documents)
    chunk_time = time.time() - chunk_start
    logger.info(f"✅ Chunking completed in {chunk_time:.2f}s")
    logger.info("")

    # 3. Index documents to RAG engine
    # 3. فهرسة المستندات إلى محرك RAG
    logger.info("📤 Step 3/3: Indexing documents to RAG engine...")
    index_start = time.time()
    if index_documents_to_rag(chunked_documents):
        index_time = time.time() - index_start
        total_time = time.time() - start_time
        logger.info("")
        logger.info("=" * 60)
        logger.info("✅ Legal data indexing completed successfully!")
        logger.info("=" * 60)
        logger.info(f"📊 Statistics:")
        logger.info(f"   • Total articles: {len(raw_documents)}")
        logger.info(f"   • Total chunks: {len(chunked_documents)}")
        logger.info(f"   • Parse time: {parse_time:.2f}s")
        logger.info(f"   • Chunk time: {chunk_time:.2f}s")
        logger.info(f"   • Index time: {index_time:.2f}s")
        logger.info(f"   • Total time: {total_time:.2f}s")
        logger.info("=" * 60)
    else:
        logger.error("")
        logger.error("=" * 60)
        logger.error("❌ Legal data indexing failed.")
        logger.error("=" * 60)


if __name__ == "__main__":
    # Default SQL file path
    SQL_FILE_PATH = os.getenv("LEGAL_SQL_FILE", "./yemen_legal_dataset.sql")
    
    if not os.path.exists(SQL_FILE_PATH):
        # Try relative to scripts directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        SQL_FILE_PATH = os.path.join(project_root, "yemen_legal_dataset.sql")
    
    if not os.path.exists(SQL_FILE_PATH):
        logger.error(f"SQL file not found at {SQL_FILE_PATH}")
        logger.info("Please specify the path to yemen_legal_dataset.sql")
        logger.info("Usage: python load_legal_data_from_sql.py")
        logger.info("Or set LEGAL_SQL_FILE environment variable")
        exit(1)
    
    main(SQL_FILE_PATH)
