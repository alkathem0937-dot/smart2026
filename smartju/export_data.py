"""
Export data from SQLite to JSON with UTF-8 encoding
"""
import os
import sys
import django
from io import StringIO

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'smartju.settings.sqlite_temp')
django.setup()

from django.core import serializers
from django.apps import apps

print("Exporting data from SQLite...")

# Get all models except contenttypes, permissions, and admin logs
all_objects = []
for model in apps.get_models():
    if model._meta.app_label == 'contenttypes':
        continue
    if model._meta.label == 'auth.Permission':
        continue
    if model._meta.label == 'admin.LogEntry':
        continue
    all_objects.extend(model.objects.all())

print(f"Found {len(all_objects)} objects to export")

# Serialize to string buffer
output = StringIO()
serializers.serialize(
    'json',
    all_objects,
    indent=2,
    use_natural_foreign_keys=True,
    use_natural_primary_keys=True,
    stream=output
)

# Write to file with UTF-8 encoding
with open('data_backup.json', 'w', encoding='utf-8') as f:
    f.write(output.getvalue())

print("✓ Data exported successfully to data_backup.json")

