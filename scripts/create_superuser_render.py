"""
Script to create superuser on Render database from local machine
Usage: python scripts/create_superuser_render.py
"""
import os
import sys
import django

# Add smartju to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'smartju'))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'smartju.settings.production')
django.setup()

from django.contrib.auth.models import User
from django.db import connection

def create_superuser():
    """Create superuser on Render database"""
    
    # Superuser credentials
    username = 'admin'
    email = 'admin@smartjudi.local'
    password = 'admin123'
    
    print("=" * 60)
    print("🚀 Creating Superuser on Render Database")
    print("=" * 60)
    
    # Test database connection
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        print("✅ Database connection successful!")
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        print("\n⚠️  Make sure you have:")
        print("   1. DATABASE_URL environment variable set")
        print("   2. External Database URL from Render (not internal)")
        return False
    
    # Check if superuser already exists
    if User.objects.filter(is_superuser=True).exists():
        print("\n⚠️  Superuser already exists!")
        existing = User.objects.filter(is_superuser=True).first()
        print(f"   Username: {existing.username}")
        print(f"   Email: {existing.email}")
        
        response = input("\n❓ Do you want to create another superuser? (y/n): ")
        if response.lower() != 'y':
            print("❌ Cancelled.")
            return False
        
        # Check if username already exists
        if User.objects.filter(username=username).exists():
            print(f"\n⚠️  Username '{username}' already exists!")
            response = input("❓ Do you want to update the existing user? (y/n): ")
            if response.lower() != 'y':
                print("❌ Cancelled.")
                return False
            
            # Update existing user
            user = User.objects.get(username=username)
            user.email = email
            user.is_superuser = True
            user.is_staff = True
            user.set_password(password)
            user.save()
            print(f"\n✅ Updated existing user '{username}' to superuser!")
            return True
    
    # Create new superuser
    try:
        user = User.objects.create_superuser(
            username=username,
            email=email,
            password=password,
        )
        print(f"\n✅ Superuser created successfully!")
        print(f"   Username: {user.username}")
        print(f"   Email: {user.email}")
        print(f"   Password: {password}")
        print("\n" + "=" * 60)
        print("🎉 You can now login to Admin Panel:")
        print(f"   URL: https://smartjudi-nls1.onrender.com/admin/")
        print(f"   Username: {username}")
        print(f"   Password: {password}")
        print("=" * 60)
        return True
    except Exception as e:
        print(f"\n❌ Error creating superuser: {e}")
        return False

if __name__ == '__main__':
    # Check for DATABASE_URL
    if not os.environ.get('DATABASE_URL'):
        print("=" * 60)
        print("⚠️  DATABASE_URL environment variable not found!")
        print("=" * 60)
        print("\n📋 To get DATABASE_URL from Render:")
        print("   1. Go to Render Dashboard → Database → smartjudi")
        print("   2. Copy the 'External Database URL'")
        print("   3. Set it as environment variable:")
        print("\n   Windows PowerShell:")
        print("   $env:DATABASE_URL='postgresql://user:pass@host:port/dbname'")
        print("\n   Windows CMD:")
        print("   set DATABASE_URL=postgresql://user:pass@host:port/dbname")
        print("\n   Linux/Mac:")
        print("   export DATABASE_URL='postgresql://user:pass@host:port/dbname'")
        print("\n" + "=" * 60)
        sys.exit(1)
    
    success = create_superuser()
    sys.exit(0 if success else 1)
