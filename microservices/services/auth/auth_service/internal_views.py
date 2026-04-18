"""
Internal API endpoints for auth-service.
Only accessible to other services via X-Internal-API-Key header.
"""
from django.contrib.auth.models import User
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from smartjudi_common.internal_auth import IsInternalService


def _user_payload(user):
    """Build a minimal user dict for inter-service responses."""
    profile = getattr(user, 'profile', None)
    return {
        'id': user.id,
        'username': user.username,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'email': user.email,
        'role': profile.role if profile else 'citizen',
        'is_active': user.is_active,
        'is_superuser': user.is_superuser,
    }


class InternalUserDetailView(APIView):
    """GET /internal/users/{user_id}/"""
    permission_classes = [IsInternalService]

    def get(self, request, user_id):
        try:
            user = User.objects.select_related('profile').get(pk=user_id)
        except User.DoesNotExist:
            return Response({'error': 'user not found'}, status=status.HTTP_404_NOT_FOUND)
        return Response(_user_payload(user))


class InternalUserBulkView(APIView):
    """POST /internal/users/bulk/ — body: {"ids": [1,2,3]}"""
    permission_classes = [IsInternalService]

    def post(self, request):
        ids = request.data.get('ids', [])
        if not ids or not isinstance(ids, list):
            return Response({'error': 'ids list required'}, status=status.HTTP_400_BAD_REQUEST)
        users = User.objects.select_related('profile').filter(pk__in=ids)
        return Response([_user_payload(u) for u in users])


class InternalUserValidateView(APIView):
    """GET /internal/users/{user_id}/validate/"""
    permission_classes = [IsInternalService]

    def get(self, request, user_id):
        try:
            user = User.objects.select_related('profile').get(pk=user_id, is_active=True)
            profile = getattr(user, 'profile', None)
            return Response({
                'valid': True,
                'role': profile.role if profile else 'citizen',
            })
        except User.DoesNotExist:
            return Response({'valid': False, 'role': None})
