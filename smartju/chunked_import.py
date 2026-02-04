import os
import django
import json
import time
from django.conf import settings
import dj_database_url
from django.db import transaction, connection

# Configure settings manually
if not settings.configured:
    settings.configure(
        DATABASES={
            'default': dj_database_url.config(
                default=os.environ.get('DATABASE_URL'),
                conn_max_age=600,
                conn_health_checks=True,
            )
        },
        INSTALLED_APPS=[
            'django.contrib.admin',
            'django.contrib.auth',
            'django.contrib.contenttypes',
            'django.contrib.sessions',
            'django.contrib.messages',
            'django.contrib.staticfiles',
            'corsheaders',
            'rest_framework',
            'rest_framework_simplejwt',
            'drf_yasg',
            'django_filters',
            'accounts',
            'courts',
            'lawsuits',
            'parties',
            'attachments',
            'responses',
            'appeals',
            'hearings',
            'judgments',
            'payments',
            'laws',
            'logs',
            'audit',
        ],
        SECRET_KEY='temp_key_for_import',
        TIME_ZONE='UTC',
    )
    django.setup()

from django.core import serializers

def import_data():
    file_path = 'data_backup.json'
    print(f"Reading {file_path}...")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    total = len(data)
    print(f"Found {total} objects. Starting import in batches...")
    
    # Deserialize all objects
    objects = list(serializers.deserialize("json", json.dumps(data), ignorenonexistent=True))
    
    batch_size = 50
    total_batches = (len(objects) + batch_size - 1) // batch_size
    
    start_time = time.time()
    
    for i in range(0, len(objects), batch_size):
        batch = objects[i:i+batch_size]
        batch_num = (i // batch_size) + 1
        
        try:
            with transaction.atomic():
                for obj in batch:
                    obj.save()
            
            elapsed = time.time() - start_time
            avg_per_obj = elapsed / (i + len(batch))
            remaining = (total - (i + len(batch))) * avg_per_obj
            
            print(f"Batch {batch_num}/{total_batches}: Saved {len(batch)} objects. (Total: {i+len(batch)}/{total}) - Est. remaining: {remaining/60:.1f} min")
            
        except Exception as e:
            print(f"❌ Error in batch {batch_num}: {e}")
            # Optional: continue or break? Better to stop and see.
            break

    print("✓ Import process finished.")

if __name__ == "__main__":
    import_data()
