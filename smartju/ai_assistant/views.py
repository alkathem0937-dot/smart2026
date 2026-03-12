# ai_assistant/views.py
# واجهات API للمساعد الذكي

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
# Import from old services.py for backward compatibility
try:
    from . import services as old_services_module
    OldAIAssistantService = getattr(old_services_module, 'AIAssistantService', None)
    OldRAGService = getattr(old_services_module, 'RAGService', None)
except (ImportError, AttributeError):
    OldAIAssistantService = None
    OldRAGService = None

# Import from new services package (explicit import from services directory)
from .services.ai_assistant_service import AIAssistantService
from .services.rag_service import RAGService
from .serializers import ChatRequestSerializer, ChatResponseSerializer
import logging
import os
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

logger = logging.getLogger(__name__)


class AIChatView(APIView):
    """نقطة نهاية للدردشة مع المساعد الذكي"""

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        try:
            # محاولة استخدام Groq إذا كان متاحاً (أسهل وأسرع)
            groq_api_key = os.getenv("GROQ_API_KEY")
            if groq_api_key:
                try:
                    from .services_groq import AIAssistantServiceGroq
                    self.ai_assistant_service = AIAssistantServiceGroq(use_groq=True)
                    logger.info("Using Groq Cloud API for AI Assistant")
                except Exception as e:
                    logger.warning(f"Failed to initialize Groq service: {e}, falling back to Ollama")
                    self.ai_assistant_service = AIAssistantService()
            else:
                # استخدام Ollama المحلي (افتراضي)
                self.ai_assistant_service = AIAssistantService()
                logger.info("Using local Ollama for AI Assistant")
        except ValueError as e:
            logger.warning(f"AIAssistantService not initialized: {e}")
            self.ai_assistant_service = None

    @swagger_auto_schema(
        request_body=ChatRequestSerializer,
        responses={
            200: ChatResponseSerializer,
            400: "Bad Request",
            500: "Internal Server Error",
            503: "Service Unavailable"
        },
        operation_description="إرسال استفسار للمساعد القانوني الذكي والحصول على استجابة"
    )
    def post(self, request, *args, **kwargs):
        if self.ai_assistant_service is None:
            return Response(
                {"detail": "خدمة المساعد الذكي غير متاحة حالياً. يرجى التحقق من إعدادات الخادم."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        serializer = ChatRequestSerializer(data=request.data)
        if serializer.is_valid():
            # Support both user_query (new) and query (legacy)
            user_query = serializer.validated_data.get('user_query') or serializer.validated_data.get('query')
            conversation_history = serializer.validated_data.get('conversation_history', [])

            logger.info(f"Received chat query: {user_query}")
            # Debug: Log API key status (without showing the actual key)
            groq_key = os.getenv("GROQ_API_KEY")
            logger.info(f"GROQ_API_KEY present: {bool(groq_key)}")
            logger.info(f"GROQ_API_KEY length: {len(groq_key) if groq_key else 0}")
            try:
                # Try new service first, fallback to old service
                try:
                    new_service = AIAssistantService()
                    ai_response_content = new_service.get_ai_response(user_query, conversation_history)
                    response_data = {
                        "ai_response": ai_response_content,
                        "conversation_history": conversation_history + [
                            {"role": "user", "content": user_query},
                            {"role": "assistant", "content": ai_response_content}
                        ]
                    }
                except Exception as e:
                    logger.warning(f"New service failed, using legacy service: {e}")
                    # Fallback to legacy service
                    response_data = self.ai_assistant_service.get_ai_response(
                        user_query, conversation_history
                    )
                    # Convert legacy format to new format
                    if isinstance(response_data, dict) and "response" in response_data:
                        response_data = {
                            "ai_response": response_data["response"],
                            "conversation_history": conversation_history + [
                                {"role": "user", "content": user_query},
                                {"role": "assistant", "content": response_data["response"]}
                            ],
                            "source_documents": response_data.get("source_documents", [])
                        }
                
                response_serializer = ChatResponseSerializer(data=response_data)
                response_serializer.is_valid(raise_exception=True)
                return Response(response_serializer.data, status=status.HTTP_200_OK)
            except Exception as e:
                logger.exception(f"Error in AI chat view: {e}")
                # Provide more user-friendly error messages
                error_message = str(e)
                if "GROQ_API_KEY" in error_message or "API key" in error_message.lower() or "credentials" in error_message.lower() or "دخول" in error_message:
                    error_message = "عذراً، يرجى التحقق من إعدادات API Key. تأكد من إضافة GROQ_API_KEY أو HUGGINGFACE_API_KEY إلى ملف .env"
                return Response(
                    {"detail": error_message},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AddLegalDocumentsView(APIView):
    """نقطة نهاية لإضافة مستندات قانونية إلى محرك RAG"""

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        try:
            self.rag_service = RAGService()
        except ValueError as e:
            logger.warning(f"RAGService not initialized: {e}")
            self.rag_service = None

    @swagger_auto_schema(
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'files': openapi.Schema(
                    type=openapi.TYPE_ARRAY,
                    items=openapi.Schema(type=openapi.TYPE_FILE),
                    description='قائمة ملفات PDF أو Word أو نصية لرفعها'
                )
            },
            required=['files']
        ),
        responses={200: "Success", 400: "Bad Request", 500: "Internal Server Error"},
        operation_description="رفع مستندات قانونية (PDF, Word, Text) إلى محرك RAG للفهرسة"
    )
    def post(self, request, *args, **kwargs):
        if self.rag_service is None:
            return Response(
                {"detail": "خدمة RAG غير متاحة حالياً. يرجى التحقق من إعدادات الخادم."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        if 'files' not in request.FILES:
            return Response(
                {"detail": "لم يتم تقديم ملفات."},
                status=status.HTTP_400_BAD_REQUEST
            )

        uploaded_files = request.FILES.getlist('files')
        files_for_rag = []
        for uploaded_file in uploaded_files:
            files_for_rag.append(
                (uploaded_file.name, uploaded_file.read(), uploaded_file.content_type)
            )

        try:
            response = self.rag_service.add_documents(files_for_rag)
            return Response(response, status=status.HTTP_200_OK)
        except Exception as e:
            logger.exception(f"Error adding legal documents: {e}")
            return Response(
                {"detail": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class DeleteLegalDocumentsView(APIView):
    """نقطة نهاية لحذف مستندات قانونية من محرك RAG"""

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        try:
            self.rag_service = RAGService()
        except ValueError as e:
            logger.warning(f"RAGService not initialized: {e}")
            self.rag_service = None

    @swagger_auto_schema(
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'source': openapi.Schema(
                    type=openapi.TYPE_STRING,
                    description='اسم الملف المصدر للحذف'
                )
            },
            required=['source']
        ),
        responses={200: "Success", 400: "Bad Request", 500: "Internal Server Error"},
        operation_description="حذف مستندات قانونية من محرك RAG حسب اسم الملف المصدر"
    )
    def delete(self, request, *args, **kwargs):
        if self.rag_service is None:
            return Response(
                {"detail": "خدمة RAG غير متاحة حالياً. يرجى التحقق من إعدادات الخادم."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        source = request.data.get('source')
        if not source:
            return Response(
                {"detail": "معامل 'source' مطلوب."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            response = self.rag_service.delete_documents(source)
            return Response(response, status=status.HTTP_200_OK)
        except Exception as e:
            logger.exception(f"Error deleting legal documents: {e}")
            return Response(
                {"detail": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
