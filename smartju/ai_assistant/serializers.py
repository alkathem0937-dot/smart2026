# ai_assistant/serializers.py
# سيريالايزر للمساعد الذكي

from rest_framework import serializers


class ChatRequestSerializer(serializers.Serializer):
    """سيريالايزر لطلب الدردشة"""
    query = serializers.CharField(max_length=2000)
    conversation_history = serializers.ListField(
        child=serializers.DictField(child=serializers.CharField()),
        required=False,
        default=[]
    )


class SourceDocumentSerializer(serializers.Serializer):
    """سيريالايزر لوثيقة المصدر"""
    page_content = serializers.CharField()
    metadata = serializers.DictField()


class ChatResponseSerializer(serializers.Serializer):
    """سيريالايزر لاستجابة الدردشة"""
    response = serializers.CharField()
    source_documents = serializers.ListField(
        child=SourceDocumentSerializer(),
        required=False,
        default=[]
    )


class AddDocumentsSerializer(serializers.Serializer):
    """سيريالايزر لإضافة المستندات - يستخدم للتوثيق فقط، الملفات تُعالج مباشرة"""
    files = serializers.ListField(
        child=serializers.FileField(),
        help_text="List of PDF, Word, or Text files to upload."
    )
