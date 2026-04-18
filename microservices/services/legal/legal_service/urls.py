"""URL configuration for legal-service."""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from smartjudi_common.health import health_check

from courts.views import (
    GovernorateViewSet, DistrictViewSet,
    CourtTypeViewSet, CourtSpecializationViewSet, CourtViewSet,
)

router = DefaultRouter()

# Courts
router.register(r'governorates', GovernorateViewSet)
router.register(r'districts', DistrictViewSet)
router.register(r'court-types', CourtTypeViewSet)
router.register(r'court-specializations', CourtSpecializationViewSet)
router.register(r'courts', CourtViewSet)

urlpatterns = [
    path('health/', health_check),
    path('api/', include(router.urls)),
]
