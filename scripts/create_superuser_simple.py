"""
Simple script to create superuser on Render database
Uses manage.py directly to avoid settings import issues
"""
import os
import sys
import subprocess

def main():
    """Create superuser using manage.py"""
    
    # Set environment variables
    database_url = "postgresql://smartjudi_dpck_user:klf3YHKEq0VbQjAC2tyKIGjKcviNSzjz@dpg-d6kv9v7tskes73e6erhg-a.singapore-postgres.render.com/smartjudi_dpck"
    
    os.environ['DATABASE_URL'] = database_url
    os.environ['DJANGO_SETTINGS_MODULE'] = 'smartju.settings.production'
    
    # Change to smartju directory
    smartju_dir = os.path.join(os.path.dirname(__file__), '..', 'smartju')
    os.chdir(smartju_dir)
    
    print("=" * 60)
    print("🚀 Creating Superuser on Render Database")
    print("=" * 60)
    print(f"\n📋 Database: smartjudi_dpck")
    print(f"📋 Username: admin")
    print(f"📋 Email: admin@smartjudi.local")
    print(f"📋 Password: admin123")
    print("\n" + "=" * 60)
    
    # Use management command
    try:
        result = subprocess.run(
            ['python', 'manage.py', 'create_superuser_auto', '--no-input'],
            env=os.environ,
            check=True,
            capture_output=True,
            text=True
        )
        print(result.stdout)
        if result.stderr:
            print("Warnings:", result.stderr)
        print("\n✅ Superuser creation completed!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Error: {e}")
        print(f"Output: {e.stdout}")
        print(f"Error: {e.stderr}")
        return False

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
