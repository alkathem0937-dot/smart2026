from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django_filters import rest_framework as django_filters
from django.db.models import Q, Count
from django.utils import timezone
from .models import Lawsuit, LegalTemplate, FinancialClaim
from .serializers import (
    LawsuitSerializer, LawsuitCreateSerializer, LawsuitUpdateSerializer,
    LegalTemplateSerializer, FinancialClaimSerializer
)
from accounts.permissions import IsJudgeOrLawyerOrAdmin


class LawsuitFilter(django_filters.FilterSet):
    """
    Advanced filter for Lawsuit - فلترة متقدمة للدعاوى
    """
    # Date range filters
    filing_date_from = django_filters.DateFilter(
        field_name='filing_date', lookup_expr='gte',
        label='تاريخ الرفع من'
    )
    filing_date_to = django_filters.DateFilter(
        field_name='filing_date', lookup_expr='lte',
        label='تاريخ الرفع إلى'
    )
    created_from = django_filters.DateFilter(
        field_name='created_at', lookup_expr='gte',
        label='تاريخ الإنشاء من'
    )
    created_to = django_filters.DateFilter(
        field_name='created_at', lookup_expr='lte',
        label='تاريخ الإنشاء إلى'
    )
    
    # Text search in parties (via related models)
    party_name = django_filters.CharFilter(
        method='filter_by_party_name',
        label='اسم طرف التقاضي'
    )
    
    # Archive status
    archive_status = django_filters.ChoiceFilter(
        choices=Lawsuit.ARCHIVE_STATUS_CHOICES,
        label='حالة الأرشفة'
    )
    
    # Exclude soft-deleted by default
    include_deleted = django_filters.BooleanFilter(
        method='filter_include_deleted',
        label='تضمين المحذوفة'
    )
    
    class Meta:
        model = Lawsuit
        fields = [
            'case_type', 'case_status', 'status', 'court', 
            'governorate', 'archive_status', 'court_fk',
        ]
    
    def filter_by_party_name(self, queryset, name, value):
        """Search in plaintiff and defendant names"""
        return queryset.filter(
            Q(plaintiffs__name__icontains=value) |
            Q(defendants__name__icontains=value)
        ).distinct()
    
    def filter_include_deleted(self, queryset, name, value):
        """Include soft-deleted items"""
        if value:
            return queryset
        return queryset.filter(is_deleted=False)


class LegalTemplateViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for LegalTemplate (read-only)
    """
    queryset = LegalTemplate.objects.all()
    serializer_class = LegalTemplateSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['case_type', 'section_key', 'is_required']
    search_fields = ['section_title', 'default_text']
    
    @action(detail=False, methods=['get'])
    def by_case_type(self, request):
        """
        Get all templates for a specific case type
        GET /api/legal-templates/by_case_type/?case_type=دعوى
        """
        case_type = request.query_params.get('case_type')
        if not case_type:
            return Response(
                {'error': 'case_type parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        templates = self.queryset.filter(case_type=case_type)
        serializer = self.get_serializer(templates, many=True)
        
        # Group by section_key for easier access
        grouped = {}
        for template in serializer.data:
            key = template['section_key']
            if key not in grouped:
                grouped[key] = {
                    'section_key': key,
                    'section_title': template['section_title'],
                    'default_text': template['default_text'],
                    'is_required': template['is_required'],
                }
        
        return Response({
            'case_type': case_type,
            'templates': list(grouped.values())
        })


class FinancialClaimViewSet(viewsets.ModelViewSet):
    """
    ViewSet for FinancialClaim
    """
    queryset = FinancialClaim.objects.select_related('lawsuit').all()
    serializer_class = FinancialClaimSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['lawsuit', 'currency']
    search_fields = ['description']
    
    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsJudgeOrLawyerOrAdmin()]
        return [IsAuthenticated()]


class LawsuitViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Lawsuit - with advanced archive features
    """
    queryset = Lawsuit.objects.select_related(
        'created_by', 'court_fk', 'archived_by', 'parent_lawsuit'
    ).prefetch_related('financial_claims').all()
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = LawsuitFilter
    search_fields = [
        'case_number', 'subject', 'court', 'governorate',
        'description', 'facts', 'legal_basis', 'notes',
    ]
    ordering_fields = [
        'created_at', 'filing_date', 'case_number',
        'updated_at', 'archive_date', 'case_status',
    ]
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.action == 'create':
            return LawsuitCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return LawsuitUpdateSerializer
        return LawsuitSerializer
    
    def get_permissions(self):
        if self.action in ['update', 'partial_update', 'destroy']:
            return [IsJudgeOrLawyerOrAdmin()]
        return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    def perform_update(self, serializer):
        instance = serializer.instance
        user = self.request.user
        if hasattr(user, 'profile'):
            user_role = user.profile.role
            if user_role == 'citizen' and instance.created_by != user:
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("You can only update your own lawsuits")
        serializer.save()
    
    def perform_destroy(self, instance):
        """Soft delete instead of hard delete"""
        user = self.request.user
        if hasattr(user, 'profile'):
            user_role = user.profile.role
            if user_role == 'citizen' and instance.created_by != user:
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("You can only delete your own lawsuits")
        # Soft delete
        instance.is_deleted = True
        instance.deleted_at = timezone.now()
        instance.save(update_fields=['is_deleted', 'deleted_at'])
    
    def get_queryset(self):
        queryset = super().get_queryset()
        # Filter out soft-deleted by default
        if not self.request.query_params.get('include_deleted'):
            queryset = queryset.filter(is_deleted=False)
        # Citizens can only see their own lawsuits
        if hasattr(self.request.user, 'profile'):
            user_role = self.request.user.profile.role
            if user_role == 'citizen':
                queryset = queryset.filter(created_by=self.request.user)
        return queryset
    
    # ========== Archive Actions ==========
    
    @action(detail=True, methods=['post'])
    def archive(self, request, pk=None):
        """
        Archive a lawsuit - أرشفة دعوى
        POST /api/lawsuits/{id}/archive/
        """
        lawsuit = self.get_object()
        reason = request.data.get('reason', '')
        
        lawsuit.archive_status = Lawsuit.ARCHIVE_ARCHIVED
        lawsuit.archive_date = timezone.now()
        lawsuit.archive_reason = reason
        lawsuit.archived_by = request.user
        lawsuit.save(update_fields=[
            'archive_status', 'archive_date', 'archive_reason', 'archived_by'
        ])
        
        serializer = self.get_serializer(lawsuit)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def unarchive(self, request, pk=None):
        """
        Restore a lawsuit from archive - استعادة دعوى من الأرشيف
        POST /api/lawsuits/{id}/unarchive/
        """
        lawsuit = self.get_object()
        lawsuit.archive_status = Lawsuit.ARCHIVE_ACTIVE
        lawsuit.archive_date = None
        lawsuit.archive_reason = None
        lawsuit.archived_by = None
        lawsuit.save(update_fields=[
            'archive_status', 'archive_date', 'archive_reason', 'archived_by'
        ])
        
        serializer = self.get_serializer(lawsuit)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def restore(self, request, pk=None):
        """
        Restore a soft-deleted lawsuit - استعادة دعوى محذوفة
        POST /api/lawsuits/{id}/restore/
        """
        try:
            lawsuit = Lawsuit.objects.get(pk=pk, is_deleted=True)
        except Lawsuit.DoesNotExist:
            return Response(
                {'error': 'الدعوى غير موجودة أو غير محذوفة'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        lawsuit.is_deleted = False
        lawsuit.deleted_at = None
        lawsuit.save(update_fields=['is_deleted', 'deleted_at'])
        
        serializer = self.get_serializer(lawsuit)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Get archive statistics - إحصائيات الأرشيف
        GET /api/lawsuits/stats/
        """
        qs = self.get_queryset()
        
        # Count by archive status
        archive_counts = {}
        for choice_value, choice_label in Lawsuit.ARCHIVE_STATUS_CHOICES:
            archive_counts[choice_value] = qs.filter(archive_status=choice_value).count()
        
        # Count by case status
        status_counts = {}
        for choice_value, choice_label in Lawsuit.STATUS_CHOICES:
            status_counts[choice_value] = qs.filter(case_status=choice_value).count()
        
        # Count by case type
        type_counts = {}
        for choice_value, choice_label in Lawsuit.CASE_TYPE_CHOICES:
            count = qs.filter(case_type=choice_value).count()
            if count > 0:
                type_counts[choice_value] = {
                    'count': count,
                    'label': choice_label,
                }
        
        return Response({
            'total': qs.count(),
            'deleted': Lawsuit.objects.filter(is_deleted=True).count() if hasattr(request.user, 'profile') and request.user.profile.role in ['admin', 'judge'] else 0,
            'by_archive_status': archive_counts,
            'by_case_status': status_counts,
            'by_case_type': type_counts,
        })
    
    @action(detail=False, methods=['get'])
    def get_templates(self, request):
        """
        Get legal templates for a case type
        GET /api/lawsuits/get_templates/?case_type=دعوى
        """
        case_type = request.query_params.get('case_type')
        if not case_type:
            return Response(
                {'error': 'case_type parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        templates = LegalTemplate.objects.filter(case_type=case_type)
        serializer = LegalTemplateSerializer(templates, many=True)
        
        grouped = {}
        for template in serializer.data:
            key = template['section_key']
            if key not in grouped:
                grouped[key] = {
                    'section_key': key,
                    'section_title': template['section_title'],
                    'default_text': template['default_text'],
                    'is_required': template['is_required'],
                }
        
        return Response({
            'case_type': case_type,
            'templates': list(grouped.values())
        })
