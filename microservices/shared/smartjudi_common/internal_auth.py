"""
Internal API key authentication for service-to-service calls.

Usage in each service's views.py:
    from smartjudi_common.internal_auth import IsInternalService

    class InternalUserView(APIView):
        permission_classes = [IsInternalService]
"""
import os
from rest_framework.permissions import BasePermission


class IsInternalService(BasePermission):
    """
    Grants access only to requests bearing a valid X-Internal-API-Key header.
    Used for /internal/* endpoints that should never be exposed publicly.
    """

    def has_permission(self, request, view):
        expected_key = os.environ.get('INTERNAL_API_KEY', '')
        if not expected_key:
            return False
        provided_key = request.META.get('HTTP_X_INTERNAL_API_KEY', '')
        return provided_key == expected_key
