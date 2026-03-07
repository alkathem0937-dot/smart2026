#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
سكربت لرفع بيانات المواد القانونية اليمنية إلى قاعدة بيانات Render
Script to load Yemen legal dataset to Render database

الاستخدام:
    python scripts/load_yemen_legal_data_to_render.py
    
أو مع DATABASE_URL:
    set DATABASE_URL=postgresql://user:pass@host/db
    python scripts/load_yemen_legal_data_to_render.py
"""

import os
import sys
import re
import time
import json
from pathlib import Path
from django.db import connection, transaction
from django.db.utils import OperationalError

# إضافة مسار smartju إلى Python path
project_root = Path(__file__).parent.parent
smartju_path = project_root / 'smartju'
sys.path.insert(0, str(smartju_path))

# إعداد Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'smartju.settings.production')

import django
django.setup()

from django.db import connection, transaction
from laws.models import LegalArticleFlat

# معلومات قاعدة البيانات (يمكن تعديلها)
# Database information (can be modified)
EXTERNAL_DATABASE_URL = os.environ.get(
    'DATABASE_URL',
    'postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a.singapore-postgres.render.com/smartjudi_dpck'
)


def parse_sql_file(file_path):
    """
    تحليل ملف SQL واستخراج البيانات
    Parse SQL file and extract data
    """
    print(f"📂 جاري قراءة الملف: {file_path}")
    print(f"📂 Reading file: {file_path}")
    
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"❌ الملف غير موجود: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # البحث عن جميع INSERT statements
    # Pattern: INSERT INTO legal_articles (...) VALUES ('value1','value2',...), (...), ...
    records = []
    
    # استخراج جميع القيم من INSERT statements
    # النمط: ('value1','value2','value3','value4','value5','value6','value7')
    pattern = r"\('([^']*(?:''[^']*)*)','([^']*(?:''[^']*)*)','([^']*(?:''[^']*)*)','([^']*(?:''[^']*)*)','([^']*(?:''[^']*)*)','([^']*(?:''[^']*)*)','([^']*(?:''[^']*)*)'\)"
    
    matches = re.findall(pattern, content)
    
    for match in matches:
        record = {
            'source_title': match[0].replace("''", "'"),
            'book_title': match[1].replace("''", "'") if match[1] else None,
            'section_title': match[2].replace("''", "'") if match[2] else None,
            'chapter_title': match[3].replace("''", "'") if match[3] else None,
            'branch_title': match[4].replace("''", "'") if match[4] else None,
            'article_number': match[5].replace("''", "'"),
            'article_text': match[6].replace("''", "'"),
        }
        records.append(record)
    
    return records


def save_checkpoint(processed_count, checkpoint_file='.import_checkpoint.json'):
    """حفظ نقطة التحقق للاستمرار لاحقاً"""
    checkpoint = {
        'processed_count': processed_count,
        'timestamp': time.time()
    }
    with open(checkpoint_file, 'w') as f:
        json.dump(checkpoint, f)


def load_checkpoint(checkpoint_file='.import_checkpoint.json'):
    """تحميل نقطة التحقق"""
    if os.path.exists(checkpoint_file):
        with open(checkpoint_file, 'r') as f:
            return json.load(f)
    return None


def clear_checkpoint(checkpoint_file='.import_checkpoint.json'):
    """حذف نقطة التحقق"""
    if os.path.exists(checkpoint_file):
        os.remove(checkpoint_file)


def retry_connection(max_retries=3, delay=2):
    """إعادة محاولة الاتصال بقاعدة البيانات"""
    for attempt in range(max_retries):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            return True
        except (OperationalError, Exception) as e:
            if attempt < max_retries - 1:
                print(f"⚠️ محاولة الاتصال {attempt + 1}/{max_retries}...")
                print(f"⚠️ Connection attempt {attempt + 1}/{max_retries}...")
                time.sleep(delay)
            else:
                print(f"❌ فشل الاتصال بعد {max_retries} محاولات: {e}")
                print(f"❌ Connection failed after {max_retries} attempts: {e}")
                return False
    return False


def import_data_orm(records, batch_size=100, start_from=0):
    """
    استيراد البيانات باستخدام Django ORM
    Import data using Django ORM
    
    Args:
        records: قائمة السجلات للاستيراد
        batch_size: حجم الدفعة
        start_from: الفهرس للبدء منه (للاستمرار من نقطة التحقق)
    """
    total = len(records)
    created_count = 0
    updated_count = 0
    error_count = 0
    
    print(f"📊 إجمالي السجلات: {total}")
    print(f"📊 Total records: {total}")
    if start_from > 0:
        print(f"🔄 الاستمرار من السجل {start_from + 1}")
        print(f"🔄 Resuming from record {start_from + 1}")
    print(f"⏳ جاري الاستيراد...")
    print(f"⏳ Starting import...")
    
    start_time = time.time()
    checkpoint_file = '.import_checkpoint.json'
    
    for i in range(start_from, total, batch_size):
        batch = records[i:i+batch_size]
        batch_num = (i // batch_size) + 1
        total_batches = (total + batch_size - 1) // batch_size
        
        # التحقق من الاتصال قبل كل دفعة
        if not retry_connection():
            print(f"⏸️ تم إيقاف الاستيراد بسبب مشكلة الاتصال. تم حفظ التقدم عند السجل {i}")
            print(f"⏸️ Import paused due to connection issue. Progress saved at record {i}")
            save_checkpoint(i, checkpoint_file)
            break
        
        try:
            with transaction.atomic():
                for record in batch:
                    # get_or_create يتخطى السجلات الموجودة تلقائياً
                    obj, created = LegalArticleFlat.objects.get_or_create(
                        source_title=record['source_title'],
                        article_number=record['article_number'],
                        defaults={
                            'book_title': record['book_title'],
                            'section_title': record['section_title'],
                            'chapter_title': record['chapter_title'],
                            'branch_title': record['branch_title'],
                            'article_text': record['article_text'],
                        }
                    )
                    if created:
                        created_count += 1
                    # else: السجل موجود بالفعل - لا نحتاج لتحديثه
        except (OperationalError, Exception) as e:
            # إذا كان خطأ اتصال، حاول إعادة الاتصال
            if 'could not translate host name' in str(e) or 'OperationalError' in str(type(e).__name__):
                print(f"⚠️ مشكلة في الاتصال في الدفعة {batch_num}...")
                print(f"⚠️ Connection issue in batch {batch_num}...")
                if retry_connection():
                    # إعادة المحاولة
                    try:
                        with transaction.atomic():
                            for record in batch:
                                obj, created = LegalArticleFlat.objects.get_or_create(
                                    source_title=record['source_title'],
                                    article_number=record['article_number'],
                                    defaults={
                                        'book_title': record['book_title'],
                                        'section_title': record['section_title'],
                                        'chapter_title': record['chapter_title'],
                                        'branch_title': record['branch_title'],
                                        'article_text': record['article_text'],
                                    }
                                )
                                if created:
                                    created_count += 1
                    except Exception as retry_e:
                        error_count += len(batch)
                        print(f"❌ فشلت إعادة المحاولة: {retry_e}")
                        print(f"❌ Retry failed: {retry_e}")
                        save_checkpoint(i, checkpoint_file)
                        break
                else:
                    error_count += len(batch)
                    save_checkpoint(i, checkpoint_file)
                    break
            else:
                error_count += len(batch)
                print(f"❌ خطأ في الدفعة {batch_num}: {e}")
                print(f"❌ Error in batch {batch_num}: {e}")
                # محاولة حفظ السجلات واحداً تلو الآخر
                for record in batch:
                    try:
                        obj, created = LegalArticleFlat.objects.get_or_create(
                            source_title=record['source_title'],
                            article_number=record['article_number'],
                            defaults={
                                'book_title': record['book_title'],
                                'section_title': record['section_title'],
                                'chapter_title': record['chapter_title'],
                                'branch_title': record['branch_title'],
                                'article_text': record['article_text'],
                            }
                        )
                        if created:
                            created_count += 1
                    except Exception as inner_e:
                        error_count += 1
                        print(f"   ⚠️ فشل حفظ السجل: {record.get('article_number', 'unknown')}")
                        print(f"   ⚠️ Failed to save record: {inner_e}")
        
        # حفظ نقطة التحقق كل 10 دفعات
        if batch_num % 10 == 0:
            save_checkpoint(i + batch_size, checkpoint_file)
        
        # عرض التقدم
        elapsed = time.time() - start_time
        progress = min(i + batch_size, total)
        percent = (progress / total) * 100
        avg_time = elapsed / progress if progress > 0 else 0
        remaining = (total - progress) * avg_time
        
        print(f"📈 التقدم: {batch_num}/{total_batches} | {progress}/{total} ({percent:.1f}%) | "
              f"متبقي: {remaining/60:.1f} دقيقة | "
              f"جديد: {created_count} | محدث: {updated_count} | أخطاء: {error_count}")
        print(f"📈 Progress: {batch_num}/{total_batches} | {progress}/{total} ({percent:.1f}%) | "
              f"Remaining: {remaining/60:.1f} min | "
              f"Created: {created_count} | Updated: {updated_count} | Errors: {error_count}")
    
    # حذف نقطة التحقق عند اكتمال الاستيراد
    if i >= total - batch_size:
        clear_checkpoint(checkpoint_file)
        print("✅ تم حذف نقطة التحقق - اكتمل الاستيراد")
        print("✅ Checkpoint cleared - import completed")
    
    return created_count, updated_count, error_count


def import_data_sql(records, batch_size=100):
    """
    استيراد البيانات باستخدام SQL مباشرة (أسرع - يتطلب unique constraint)
    Import data using direct SQL (faster - requires unique constraint)
    
    ملاحظة: هذه الطريقة تتطلب وجود unique constraint على (source_title, article_number)
    Note: This method requires a unique constraint on (source_title, article_number)
    """
    total = len(records)
    created_count = 0
    error_count = 0
    
    print(f"📊 إجمالي السجلات: {total}")
    print(f"📊 Total records: {total}")
    print(f"⏳ جاري الاستيراد باستخدام SQL...")
    print(f"⏳ Starting import using SQL...")
    print("⚠️ ملاحظة: هذه الطريقة تتطلب unique constraint على (source_title, article_number)")
    print("⚠️ Note: This method requires unique constraint on (source_title, article_number)")
    
    start_time = time.time()
    
    with connection.cursor() as cursor:
        for i in range(0, total, batch_size):
            batch = records[i:i+batch_size]
            batch_num = (i // batch_size) + 1
            total_batches = (total + batch_size - 1) // batch_size
            
            try:
                with transaction.atomic():
                    # استخدام ORM بدلاً من SQL المباشر لتجنب مشاكل unique constraint
                    # Use ORM instead of direct SQL to avoid unique constraint issues
                    for record in batch:
                        obj, created = LegalArticleFlat.objects.get_or_create(
                            source_title=record['source_title'],
                            article_number=record['article_number'],
                            defaults={
                                'book_title': record['book_title'],
                                'section_title': record['section_title'],
                                'chapter_title': record['chapter_title'],
                                'branch_title': record['branch_title'],
                                'article_text': record['article_text'],
                            }
                        )
                        if created:
                            created_count += 1
                            
            except Exception as e:
                # إذا فشل، استخدم ORM كبديل
                print(f"⚠️ فشل SQL المباشر، استخدام ORM للدفعة {batch_num}: {e}")
                print(f"⚠️ Direct SQL failed, using ORM for batch {batch_num}: {e}")
                try:
                    with transaction.atomic():
                        for record in batch:
                            obj, created = LegalArticleFlat.objects.get_or_create(
                                source_title=record['source_title'],
                                article_number=record['article_number'],
                                defaults={
                                    'book_title': record['book_title'],
                                    'section_title': record['section_title'],
                                    'chapter_title': record['chapter_title'],
                                    'branch_title': record['branch_title'],
                                    'article_text': record['article_text'],
                                }
                            )
                            if created:
                                created_count += 1
                except Exception as inner_e:
                    error_count += len(batch)
                    print(f"❌ خطأ في الدفعة {batch_num}: {inner_e}")
                    print(f"❌ Error in batch {batch_num}: {inner_e}")
            
            # عرض التقدم
            elapsed = time.time() - start_time
            progress = min(i + batch_size, total)
            percent = (progress / total) * 100
            avg_time = elapsed / progress if progress > 0 else 0
            remaining = (total - progress) * avg_time
            
            print(f"📈 التقدم: {batch_num}/{total_batches} | {progress}/{total} ({percent:.1f}%) | "
                  f"متبقي: {remaining/60:.1f} دقيقة | "
                  f"جديد: {created_count} | أخطاء: {error_count}")
            print(f"📈 Progress: {batch_num}/{total_batches} | {progress}/{total} ({percent:.1f}%) | "
                  f"Remaining: {remaining/60:.1f} min | "
                  f"Created: {created_count} | Errors: {error_count}")
    
    return created_count, 0, error_count


def main():
    """الدالة الرئيسية"""
    print("=" * 70)
    print("🚀 سكربت رفع البيانات القانونية اليمنية إلى Render")
    print("🚀 Yemen Legal Data Loader to Render")
    print("=" * 70)
    print()
    
    # التحقق من الاتصال بقاعدة البيانات
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        print("✅ الاتصال بقاعدة البيانات نجح")
        print("✅ Database connection successful")
    except Exception as e:
        print(f"❌ فشل الاتصال بقاعدة البيانات: {e}")
        print(f"❌ Database connection failed: {e}")
        print()
        print("💡 تأكد من:")
        print("💡 Make sure:")
        print("   1. إعداد DATABASE_URL في متغيرات البيئة")
        print("      Set DATABASE_URL in environment variables")
        print("   2. استخدام External Database URL للاتصال من خارج Render")
        print("      Use External Database URL for connection from outside Render")
        print()
        print(f"   DATABASE_URL={EXTERNAL_DATABASE_URL[:50]}...")
        sys.exit(1)
    
    print()
    
    # مسار ملف SQL
    sql_file = project_root / 'yemen_legal_dataset.sql'
    
    if not sql_file.exists():
        print(f"❌ الملف غير موجود: {sql_file}")
        print(f"❌ File not found: {sql_file}")
        sys.exit(1)
    
    # تحليل ملف SQL
    try:
        records = parse_sql_file(str(sql_file))
        print(f"✅ تم تحليل {len(records)} سجل")
        print(f"✅ Parsed {len(records)} records")
    except Exception as e:
        print(f"❌ خطأ في تحليل الملف: {e}")
        print(f"❌ Error parsing file: {e}")
        sys.exit(1)
    
    if not records:
        print("⚠️ لم يتم العثور على بيانات للاستيراد")
        print("⚠️ No data found to import")
        sys.exit(0)
    
    print()
    
    # التحقق من وجود نقطة تحقق للاستمرار
    checkpoint = load_checkpoint()
    start_from = 0
    if checkpoint:
        start_from = checkpoint.get('processed_count', 0)
        print(f"📌 تم العثور على نقطة تحقق - الاستمرار من السجل {start_from + 1}")
        print(f"📌 Checkpoint found - resuming from record {start_from + 1}")
        response = input("هل تريد الاستمرار من نقطة التحقق؟ (y/n): ").strip().lower()
        if response != 'y':
            start_from = 0
            clear_checkpoint()
            print("🔄 البدء من البداية...")
            print("🔄 Starting from beginning...")
    
    print()
    
    # اختيار طريقة الاستيراد
    # استخدام ORM (أكثر أماناً ولكن أبطأ قليلاً)
    use_orm = True
    
    if use_orm:
        created, updated, errors = import_data_orm(records, batch_size=100, start_from=start_from)
    else:
        created, updated, errors = import_data_sql(records, batch_size=100)
    
    print()
    print("=" * 70)
    print("✅ اكتمل الاستيراد!")
    print("✅ Import completed!")
    print("=" * 70)
    print(f"📊 السجلات الجديدة: {created}")
    print(f"📊 New records: {created}")
    if updated > 0:
        print(f"📊 السجلات المحدثة: {updated}")
        print(f"📊 Updated records: {updated}")
    if errors > 0:
        print(f"⚠️ الأخطاء: {errors}")
        print(f"⚠️ Errors: {errors}")
    
    # عرض إجمالي السجلات (مع إعادة محاولة الاتصال)
    try:
        if retry_connection():
            total_in_db = LegalArticleFlat.objects.count()
            print(f"📈 إجمالي السجلات في قاعدة البيانات: {total_in_db}")
            print(f"📈 Total records in database: {total_in_db}")
        else:
            print("⚠️ لا يمكن الاتصال بقاعدة البيانات لعرض الإجمالي")
            print("⚠️ Cannot connect to database to show total")
    except Exception as e:
        print(f"⚠️ خطأ في عرض الإجمالي: {e}")
        print(f"⚠️ Error showing total: {e}")
    
    print("=" * 70)
    
    # التحقق من وجود نقطة تحقق
    checkpoint = load_checkpoint()
    if checkpoint:
        print("💡 ملاحظة: تم حفظ نقطة تحقق. يمكنك إعادة تشغيل السكربت للاستمرار")
        print("💡 Note: Checkpoint saved. You can rerun the script to continue")


if __name__ == '__main__':
    main()
