from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from smartjudi_common.health import health_check
from attachments.views import AttachmentViewSet

router = DefaultRouter()
router.register(r'attachments', AttachmentViewSet, basename='attachment')

urlpatterns = [
    path('health/', health_check),
    path('api/', include(router.urls)),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
