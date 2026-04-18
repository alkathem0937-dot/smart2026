from django.urls import path, include
from rest_framework.routers import DefaultRouter
from smartjudi_common.health import health_check
from search_app.views import SearchLogViewSet, AIChatLogViewSet

router = DefaultRouter()
router.register(r'search-logs', SearchLogViewSet, basename='searchlog')
router.register(r'ai-chat-logs', AIChatLogViewSet, basename='aichatlog')

urlpatterns = [
    path('health/', health_check),
    path('api/', include(router.urls)),
]
