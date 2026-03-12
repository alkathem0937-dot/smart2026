# smartjudi2/scripts/load_governorates_courts_to_db.py
# سكربت لرفع المحافظات والمحاكم من ملف JSON إلى قاعدة البيانات على Render
# Script to load governorates and courts from JSON file to Render database

import os
import sys
import json
import logging
import time
from dotenv import load_dotenv

# Load environment variables FIRST (before Django setup)
load_dotenv()

# إضافة مسار smartju إلى Python path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
smartju_path = os.path.join(project_root, 'smartju')
sys.path.insert(0, smartju_path)

# إعداد Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'smartju.settings.production')

import django
django.setup()

from courts.models import Governorate, Court

# For progress bar
try:
    from tqdm import tqdm
    HAS_TQDM = True
except ImportError:
    HAS_TQDM = False
    print("Info: tqdm not installed. Progress will be shown with simple logging.")

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def load_json_file(json_file_path: str) -> list:
    """
    Load governorates and courts data from JSON file.
    تحميل بيانات المحافظات والمحاكم من ملف JSON.
    """
    try:
        with open(json_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        logger.info(f"Successfully loaded {len(data)} governorates from JSON file.")
        return data
    except FileNotFoundError:
        logger.error(f"JSON file not found: {json_file_path}")
        return []
    except json.JSONDecodeError as e:
        logger.error(f"Error parsing JSON file: {e}")
        return []
    except Exception as e:
        logger.error(f"Error loading JSON file: {e}", exc_info=True)
        return []


def create_or_get_governorate(governorate_name: str) -> tuple:
    """
    Create or get existing governorate.
    إنشاء أو الحصول على محافظة موجودة.
    Returns: (governorate, created)
    """
    governorate, created = Governorate.objects.get_or_create(
        name=governorate_name,
        defaults={'name': governorate_name}
    )
    
    if created:
        logger.debug(f"Created new governorate: {governorate_name}")
    else:
        logger.debug(f"Found existing governorate: {governorate_name}")
    
    return governorate, created


def create_or_get_court(court_name: str, governorate: Governorate) -> tuple:
    """
    Create or get existing court for a governorate.
    إنشاء أو الحصول على محكمة موجودة لمحافظة.
    Returns: (court, created)
    """
    # Check if court already exists with this name and governorate
    court = Court.objects.filter(
        name=court_name,
        governorate=governorate
    ).first()
    
    if court:
        logger.debug(f"Found existing court: {court_name} in {governorate.name}")
        return court, False
    
    # Create new court
    court = Court.objects.create(
        name=court_name,
        governorate=governorate,
        is_active=True
    )
    
    logger.debug(f"Created new court: {court_name} in {governorate.name}")
    return court, True


def load_governorates_courts_to_database(json_file_path: str) -> bool:
    """
    Load governorates and courts from JSON file to database.
    رفع المحافظات والمحاكم من ملف JSON إلى قاعدة البيانات.
    """
    # Load JSON data
    logger.info("=" * 60)
    logger.info("🚀 Starting governorates and courts loading process")
    logger.info("=" * 60)
    logger.info(f"📁 JSON file: {json_file_path}")
    logger.info("")
    
    if not os.path.exists(json_file_path):
        logger.error(f"❌ JSON file {json_file_path} does not exist.")
        return False
    
    data = load_json_file(json_file_path)
    
    if not data:
        logger.warning("❌ No data found in JSON file. Exiting.")
        return False
    
    logger.info(f"📖 Found {len(data)} governorates to process")
    logger.info("")
    
    # Statistics
    total_governorates = 0
    total_courts = 0
    created_governorates = 0
    created_courts = 0
    existing_governorates = 0
    existing_courts = 0
    
    start_time = time.time()
    
    # Process each governorate
    if HAS_TQDM:
        governorates_iter = tqdm(enumerate(data), total=len(data), desc="Processing governorates", unit="gov")
    else:
        governorates_iter = enumerate(data)
    
    for idx, gov_data in governorates_iter:
        governorate_name = gov_data.get('governorate', '').strip()
        courts_list = gov_data.get('courts', [])
        courts_count = gov_data.get('courts_count', 0)
        
        if not governorate_name:
            logger.warning(f"Skipping entry {idx + 1}: No governorate name")
            continue
        
        try:
            # Create or get governorate
            governorate, gov_created = create_or_get_governorate(governorate_name)
            total_governorates += 1
            
            if gov_created:
                created_governorates += 1
            else:
                existing_governorates += 1
            
            # Process courts for this governorate
            if courts_list and len(courts_list) > 0:
                if not HAS_TQDM:
                    logger.info(f"Processing {governorate_name}: {len(courts_list)} courts")
                
                for court_name in courts_list:
                    court_name = court_name.strip()
                    if not court_name:
                        continue
                    
                    try:
                        # Create or get court
                        court, court_created = create_or_get_court(court_name, governorate)
                        
                        if court_created:
                            created_courts += 1
                        else:
                            existing_courts += 1
                        
                        total_courts += 1
                    except Exception as e:
                        logger.warning(f"Error creating court '{court_name}' for {governorate_name}: {e}")
                        continue
            else:
                if not HAS_TQDM:
                    logger.info(f"Processing {governorate_name}: No courts (courts_count={courts_count})")
        
        except Exception as e:
            logger.error(f"Error processing governorate '{governorate_name}': {e}", exc_info=True)
            continue
    
    total_time = time.time() - start_time
    
    # Print summary
    logger.info("")
    logger.info("=" * 60)
    logger.info("✅ Governorates and courts loading completed!")
    logger.info("=" * 60)
    logger.info(f"📊 Statistics:")
    logger.info(f"   • Total governorates processed: {total_governorates}")
    logger.info(f"   • New governorates created: {created_governorates}")
    logger.info(f"   • Existing governorates: {existing_governorates}")
    logger.info(f"   • Total courts processed: {total_courts}")
    logger.info(f"   • New courts created: {created_courts}")
    logger.info(f"   • Existing courts: {existing_courts}")
    logger.info(f"   • Total time: {total_time:.2f}s")
    logger.info("=" * 60)
    
    return True


def main():
    """
    Main function.
    الدالة الرئيسية.
    """
    # Default JSON file path
    JSON_FILE_PATH = os.getenv("GOVERNORATES_COURTS_JSON", "./governorates_courts_final.json")
    
    # Try to find the file
    if not os.path.exists(JSON_FILE_PATH):
        # Try relative to scripts directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        JSON_FILE_PATH = os.path.join(project_root, "governorates_courts_final.json")
    
    if not os.path.exists(JSON_FILE_PATH):
        logger.error(f"JSON file not found at {JSON_FILE_PATH}")
        logger.info("Please specify the path to governorates_courts_final.json")
        logger.info("Usage: python load_governorates_courts_to_db.py")
        logger.info("Or set GOVERNORATES_COURTS_JSON environment variable")
        exit(1)
    
    # Check database connection
    try:
        from django.db import connection
        connection.ensure_connection()
        logger.info("✅ Database connection successful")
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
        logger.error("Please check your DATABASE_URL environment variable")
        exit(1)
    
    # Load data
    success = load_governorates_courts_to_database(JSON_FILE_PATH)
    
    if not success:
        logger.error("❌ Failed to load governorates and courts.")
        exit(1)


if __name__ == "__main__":
    main()
