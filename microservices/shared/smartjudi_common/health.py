"""
Standard health check endpoint for all services.

Usage in each service's urls.py:
    from smartjudi_common.health import health_check
    urlpatterns = [
        path('health/', health_check),
        ...
    ]
"""
import os
from django.http import JsonResponse
from django.db import connection


def health_check(request):
    """Return service health status."""
    service_name = os.environ.get('SERVICE_NAME', 'unknown')
    status = {'status': 'ok', 'service': service_name}

    # Check database connectivity
    try:
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1')
        status['database'] = 'ok'
    except Exception as e:
        status['database'] = 'error'
        status['database_error'] = str(e)
        return JsonResponse(status, status=503)

    return JsonResponse(status)
