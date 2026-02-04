import os
import django
import json
import time
from django.conf import settings
import dj_database_url
from django.db import transaction

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
from django.contrib.auth.models import User

def import_data():
    file_path = 'data_backup.json'
    print(f"Reading {file_path}...")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    total = len(data)
    print(f"Found {total} objects. Analyzing dependencies...")

    # Separate Users from other data to ensure they exist before being referenced
    users_data = [item for item in data if item['model'] == 'auth.user']
    other_data = [item for item in data if item['model'] != 'auth.user']
    
    # 1. Import Users First
    print(f"Phase 1: Importing {len(users_data)} Users...")
    if users_data:
        try:
            user_objects = list(serializers.deserialize("json", json.dumps(users_data), ignorenonexistent=True))
            
            # Process users one by one to handle conflicts
            for obj in user_objects:
                try:
                    user_instance = obj.object
                    existing = User.objects.filter(username=user_instance.username).first()
                    
                    if existing:
                        # User exists
                        if existing.id != user_instance.id:
                            print(f"⚠️ User {user_instance.username} exists with different ID ({existing.id} vs {user_instance.id}). Overwriting...")
                            existing.delete() # Delete old to free up username
                            obj.save()        # Save new with correct ID
                        else:
                            # IDs match, simpler update
                            # obj.save() might fail if password fields etc conflict? usually fine.
                            # But deserialize sets PK. saving existing PK = update.
                            obj.save()
                    else:
                        # User does not exist, check if ID exists (username swap case?)
                        existing_id = User.objects.filter(id=user_instance.id).first()
                        if existing_id:
                            print(f"⚠️ ID {user_instance.id} exists but with different username ({existing_id.username}). Overwriting...")
                            existing_id.delete()
                            obj.save()
                        else:
                            obj.save()
                            
                except Exception as inner_e:
                    print(f"❌ Failed to save user {user_instance.username}: {inner_e}")
            
            print("✓ Users processed.")
            
        except Exception as e:
            print(f"❌ Error in user processing: {e}")


    # 2. Import Others in Batch
    print(f"Phase 2: Importing {len(other_data)} other objects...")
    
    # We serialize back to JSON string to use deserialize
    # But checking FKs immediately might still be an issue if we just pass the whole list.
    # However, since Users are now in DB, any FK to User should work.
    # For other inter-dependencies, we rely on dumpdata order (which usually sorts properly).
    
    # To be safe against self-referential or complex deps, we try to load them.
    # If deserialize fails on FK lookup, it means the target isn't in DB yet.
    # Standard loaddata handles this with 'handle_forward_references'.
    # Here we try simple batching. If it fails, we might need full loaddata logic.
    
    valid_objects = []
    
    # Try to deserialize all first? No, if one fails, it crashes.
    # We will try to deserialize one by one or in small chunks?
    # Deserializing *checks* the DB. So we must have the dep in DB.
    # If standard dumpdata sorted them, we should be fine IF we process sequentially.
    
    try:
        # We process the JSON items directly?
        # No, deserialize takes a stream or string.
        # Let's try deserializing everything now. Users are in DB, so user refs should work.
        
        objs = list(serializers.deserialize("json", json.dumps(other_data), ignorenonexistent=True))
        
        batch_size = 50
        total_batches = (len(objs) + batch_size - 1) // batch_size
        start_time = time.time()
        
        for i in range(0, len(objs), batch_size):
            batch = objs[i:i+batch_size]
            batch_num = (i // batch_size) + 1
            
            try:
                with transaction.atomic():
                    for obj in batch:
                        obj.save()
                
                elapsed = time.time() - start_time
                progress = i + len(batch)
                avg_per_obj = elapsed / progress if progress > 0 else 0
                remaining = (len(objs) - progress) * avg_per_obj
                
                print(f"Batch {batch_num}/{total_batches}: Saved {len(batch)} objects. (Total: {progress}/{len(other_data)}) - Est. remaining: {remaining/60:.1f} min")
                
            except Exception as e:
                print(f"⚠️ Error in batch {batch_num}: {e}")
                # Try saving individually to salvage what we can
                for obj in batch:
                    try:
                        obj.save()
                    except Exception as inner_e:
                        print(f"  ❌ Failed to save {obj.object}: {inner_e}")

    except Exception as e:
        print(f"❌ Critical error during deserialization: {e}")

    print("✓ Import process finished.")

if __name__ == "__main__":
    import_data()
