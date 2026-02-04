"""
Django settings for smartju project - Base/Development Settings
"""

from pathlib import Path
from datetime import timedelta
import os
import sys

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-4cyci@v!&=khm4+b)(^n@&k0((=5o5=o^r8w&)#4h=wdl)cjx=')
DEBUG = True
ALLOWED_HOSTS = ['127.0.0.1', 'localhost', '192.168.43.198', '192.168.0.157', '10.0.2.2', '*']

# Application definition
INSTALLED_APPS = [
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
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'smartju.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'smartju.wsgi.application'

# Database Configuration with Fallback
try:
    import psycopg2
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': 'smartjudi',
            'USER': 'jood',
            'PASSWORD': '123456',
            'HOST': 'localhost',
            'PORT': '5432',
        }
    }
    # Test connection driver
    from django.db.utils import load_backend
    load_backend(DATABASES['default']['ENGINE'])
except (ImportError, Exception):
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# Internationalization
LANGUAGE_CODE = 'ar'
TIME_ZONE = 'Asia/Aden'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': ('rest_framework_simplejwt.authentication.JWTAuthentication',),
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.IsAuthenticated',],
    'DEFAULT_PAGINATION_CLASS': 'smartju.pagination.StandardResultsSetPagination',
    'PAGE_SIZE': 20,
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=24),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
CORS_ALLOW_ALL_ORIGINS = DEBUG
CORS_ALLOW_CREDENTIALS = True
