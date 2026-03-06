# test_database_connection.py
# سكربت لاختبار الاتصال بقاعدة البيانات
# Script to test database connection

import os
import sys

# إضافة مسار smartju إلى Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'smartju'))

def test_database_connection():
    """اختبار الاتصال بقاعدة البيانات"""
    print("=" * 60)
    print("اختبار الاتصال بقاعدة البيانات")
    print("Testing Database Connection")
    print("=" * 60)
    print()
    
    # Internal Database URL (للاستخدام من Render services)
    internal_url = "postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a/smartjudi_dpck"
    
    # External Database URL (للاستخدام من خارج Render)
    external_url = "postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a.singapore-postgres.render.com/smartjudi_dpck"
    
    print("📋 معلومات قاعدة البيانات:")
    print("📋 Database Information:")
    print(f"   Hostname: dpg-d6kv9v7tskes73e6erhg-a")
    print(f"   Port: 5432")
    print(f"   Database: smartjudi_dpck")
    print(f"   Username: smartjudi_dpck_user")
    print()
    
    print("🔗 Internal Database URL (للاستخدام من Render):")
    print("🔗 Internal Database URL (for use from Render):")
    print(f"   {internal_url}")
    print()
    
    print("🔗 External Database URL (للاستخدام من خارج Render):")
    print("🔗 External Database URL (for use from outside Render):")
    print(f"   {external_url}")
    print()
    
    # محاولة الاتصال
    try:
        import psycopg2
        from urllib.parse import urlparse
        
        print("🔌 محاولة الاتصال...")
        print("🔌 Attempting connection...")
        
        # استخدام External URL للاختبار المحلي
        parsed = urlparse(external_url)
        
        conn = psycopg2.connect(
            host=parsed.hostname,
            port=parsed.port or 5432,
            database=parsed.path[1:],  # إزالة '/' الأول
            user=parsed.username,
            password=parsed.password,
            sslmode='require'  # Render يتطلب SSL
        )
        
        cur = conn.cursor()
        cur.execute("SELECT version();")
        version = cur.fetchone()
        
        print("✅ الاتصال نجح!")
        print("✅ Connection successful!")
        print(f"   PostgreSQL Version: {version[0]}")
        
        # اختبار الجداول
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tables = cur.fetchall()
        
        if tables:
            print(f"\n📊 الجداول الموجودة ({len(tables)}):")
            print(f"📊 Existing tables ({len(tables)}):")
            for table in tables[:10]:  # أول 10 جداول
                print(f"   - {table[0]}")
            if len(tables) > 10:
                print(f"   ... و {len(tables) - 10} جدول آخر")
        else:
            print("\n⚠️  لا توجد جداول (قد تحتاج لتشغيل migrations)")
            print("⚠️  No tables found (may need to run migrations)")
        
        cur.close()
        conn.close()
        
        print()
        print("=" * 60)
        print("✅ الاختبار نجح!")
        print("✅ Test successful!")
        print("=" * 60)
        
        return True
        
    except ImportError:
        print("❌ psycopg2 غير مثبت")
        print("❌ psycopg2 not installed")
        print("   قم بتثبيته: pip install psycopg2-binary")
        print("   Install it: pip install psycopg2-binary")
        return False
    except Exception as e:
        print("❌ فشل الاتصال:")
        print("❌ Connection failed:")
        print(f"   {e}")
        print()
        print("💡 نصائح:")
        print("💡 Tips:")
        print("   1. تحقق من أن قاعدة البيانات تعمل في Render")
        print("      Check that database is running in Render")
        print("   2. تحقق من إعدادات Firewall/Network")
        print("      Check Firewall/Network settings")
        print("   3. استخدم External URL للاتصال من خارج Render")
        print("      Use External URL for connection from outside Render")
        return False

if __name__ == "__main__":
    success = test_database_connection()
    
    if success:
        print()
        print("📝 الخطوة التالية:")
        print("📝 Next step:")
        print("   أضف DATABASE_URL إلى Render Web Service Environment Variables")
        print("   Add DATABASE_URL to Render Web Service Environment Variables")
        print("   استخدم Internal URL إذا كان Web Service على Render")
        print("   Use Internal URL if Web Service is on Render")
