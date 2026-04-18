"""
Django settings for smartju project - Production Settings for Render
"""
from .base import *  # noqa
import os
import dj_database_url

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

# SECURITY WARNING: enforce real SECRET_KEY in production!
if SECRET_KEY == 'django-insecure-4cyci@v!&=khm4+b)(^n@&k0((=5o5=o^r8w&)#4h=wdl)cjx=':
    from django.core.exceptions import ImproperlyConfigured
    raise ImproperlyConfigured("SECRET_KEY must be set in the environment for production.")


# Update allowed hosts from environment variable
ALLOWED_HOSTS_STR = os.environ.get('ALLOWED_HOSTS', '')
if ALLOWED_HOSTS_STR:
    ALLOWED_HOSTS = [host.strip() for host in ALLOWED_HOSTS_STR.split(',') if host.strip()]
else:
    ALLOWED_HOSTS = ['*']  # Fallback for initial setup

# Add Render internal host for health checks
ALLOWED_HOSTS.append('smartjudi-nls1.onrender.com')
ALLOWED_HOSTS.append('*.onrender.com')

# Database - use Render's DATABASE_URL
DATABASES = {
    'default': dj_database_url.config(
        default=os.environ.get('DATABASE_URL'),
        conn_max_age=600,
        conn_health_checks=True,
    )
}

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'  # noqa
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Security settings
# Disable SSL redirect for health checks (Render handles SSL)
SECURE_SSL_REDIRECT = False  # Render handles SSL termination
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# CORS settings for production
# Allow Flutter Web and other Render domains
CORS_ALLOWED_ORIGINS_ENV = os.environ.get('CORS_ALLOWED_ORIGINS', '')
if CORS_ALLOWED_ORIGINS_ENV:
    CORS_ALLOWED_ORIGINS = [origin.strip() for origin in CORS_ALLOWED_ORIGINS_ENV.split(',') if origin.strip()]
    CORS_ALLOW_ALL_ORIGINS = False
else:
    # Default: Allow all Render domains (for Flutter Web)
    CORS_ALLOWED_ORIGINS = []
    # Allow all Render domains by default
    CORS_ALLOWED_ORIGIN_REGEXES = [
        r"^https://.*\.onrender\.com$",
    ]
    CORS_ALLOW_ALL_ORIGINS = True  # Allow all origins by default if not specified

# Allow credentials for authenticated requests
CORS_ALLOW_CREDENTIALS = True
