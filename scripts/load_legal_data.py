# load_legal_data.py
# سكربت لرفع وحذف المستندات القانونية من/إلى محرك RAG

import os
import requests
import argparse
import mimetypes
import logging
from dotenv import load_dotenv

# Configure logging
# (تكوين التسجيل)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables from .env file (if any)
# (تحميل متغيرات البيئة من ملف .env)
load_dotenv()


def upload_documents_to_rag(rag_api_url: str, file_paths: list):
    """رفع المستندات إلى محرك RAG"""
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
        logger.info(
            f"Attempting to upload {len(files_to_upload)} files to RAG engine "
            f"at {add_documents_endpoint}"
        )
        response = requests.post(
            add_documents_endpoint,
            files=files_to_upload,
            timeout=120
        )
        response.raise_for_status()
        logger.info(f"Documents uploaded successfully: {response.json()}")
    except requests.exceptions.Timeout:
        logger.error("Upload request to RAG engine timed out.")
    except requests.exceptions.RequestException as e:
        logger.error(f"Error uploading documents to RAG engine: {e}")
    except Exception as e:
        logger.error(f"An unexpected error occurred during upload: {e}")


def delete_documents_from_rag(rag_api_url: str, source_filename: str):
    """حذف المستندات من محرك RAG"""
    delete_documents_endpoint = f"{rag_api_url}/delete_documents"
    payload = {"source": source_filename}
    try:
        logger.info(
            f"Attempting to delete documents with source '{source_filename}' "
            f"from RAG engine at {delete_documents_endpoint}"
        )
        response = requests.delete(
            delete_documents_endpoint,
            json=payload,
            timeout=60
        )
        response.raise_for_status()
        logger.info(f"Documents deleted successfully: {response.json()}")
    except requests.exceptions.Timeout:
        logger.error("Delete request to RAG engine timed out.")
    except requests.exceptions.RequestException as e:
        logger.error(f"Error deleting documents from RAG engine: {e}")
    except Exception as e:
        logger.error(f"An unexpected error occurred during deletion: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="Upload or delete legal documents to the SmartJudi2 RAG engine."
    )
    parser.add_argument(
        '--rag_api_url',
        type=str,
        default=os.getenv("RAG_API_URL"),
        help='Base URL of the Hugging Face RAG API (e.g., https://your-rag-space.hf.space)'
    )
    parser.add_argument(
        '--upload',
        nargs='+',
        help='List of file paths to upload (PDF, Word, Text).'
    )
    parser.add_argument(
        '--delete',
        type=str,
        help='Source filename to delete documents by.'
    )

    args = parser.parse_args()

    if not args.rag_api_url:
        logger.error(
            "RAG_API_URL is not provided. Please set it as an environment "
            "variable or via --rag_api_url argument."
        )
        return

    if args.upload:
        upload_documents_to_rag(args.rag_api_url, args.upload)
    elif args.delete:
        delete_documents_from_rag(args.rag_api_url, args.delete)
    else:
        logger.info(
            "Please specify either --upload with file paths or "
            "--delete with a source filename."
        )


if __name__ == "__main__":
    main()
