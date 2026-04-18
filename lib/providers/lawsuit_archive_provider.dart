import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/hearing_model.dart';
import '../models/attachment_model.dart';
import '../models/payment_order_model.dart';
import '../models/appeal_model.dart';
import '../models/lawsuit_model.dart';
import '../models/task_model.dart';
import '../services/local_db_service.dart';
import '../services/local_file_service.dart';

class CaseFileItemModel {
  final int id;
  final int lawsuitId;
  final String itemType;
  final String itemTypeDisplay;
  final String title;
  final String description;
  final String? fileUrl;
  final String? originalFilename;
  final int? fileSize;
  final String? fileSizeDisplay;
  final int? relatedObjectId;
  final String? relatedObjectType;
  final int sortOrder;
  final String? createdByName;
  final DateTime? createdAt;

  CaseFileItemModel({
    required this.id,
    required this.lawsuitId,
    required this.itemType,
    required this.itemTypeDisplay,
    required this.title,
    this.description = '',
    this.fileUrl,
    this.originalFilename,
    this.fileSize,
    this.fileSizeDisplay,
    this.relatedObjectId,
    this.relatedObjectType,
    this.sortOrder = 0,
    this.createdByName,
    this.createdAt,
  });

  factory CaseFileItemModel.fromJson(Map<String, dynamic> json) {
    return CaseFileItemModel(
      id: json['id'] ?? 0,
      lawsuitId: json['lawsuit'] is int
          ? json['lawsuit']
          : (json['lawsuit'] is Map ? json['lawsuit']['id'] : 0),
      itemType: json['item_type'] ?? 'document',
      itemTypeDisplay: json['item_type_display'] ?? 'مستند',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileUrl: json['file_url'],
      originalFilename: json['original_filename'],
      fileSize: json['file_size'],
      fileSizeDisplay: json['file_size_display'],
      relatedObjectId: json['related_object_id'],
      relatedObjectType: json['related_object_type'],
      sortOrder: json['sort_order'] ?? 0,
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class LawsuitArchiveProvider with ChangeNotifier {
  final ApiService _apiService;
  final int lawsuitId;
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;

  LawsuitArchiveProvider({ApiService? apiService, required this.lawsuitId}) 
      : _apiService = apiService ?? ApiService();

  List<HearingModel> _hearings = [];
  List<AttachmentModel> _attachments = [];
  List<PaymentOrderModel> _payments = [];
  List<AppealModel> _appeals = [];
  List<Map<String, dynamic>> _financialClaims = [];
  List<TaskModel> _tasks = [];
  List<CaseFileItemModel> _caseFileItems = [];
  LawsuitModel? _lawsuit;
  
  bool _isLoading = false;
  String? _errorMessage;

  // Per-section loading states
  bool _isLoadingDocs = false;
  bool _isLoadingSessions = false;
  bool _isLoadingPayments = false;
  bool _isLoadingCaseFile = false;
  String? _docsError;
  String? _sessionsError;
  String? _paymentsError;
  String? _caseFileError;

  List<HearingModel> get hearings => _hearings;
  List<AttachmentModel> get attachments => _attachments;
  List<PaymentOrderModel> get payments => _payments;
  List<AppealModel> get appeals => _appeals;
  List<Map<String, dynamic>> get financialClaims => _financialClaims;
  List<TaskModel> get tasks => _tasks;
  List<CaseFileItemModel> get caseFileItems => _caseFileItems;
  LawsuitModel? get lawsuit => _lawsuit;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoadingDocs => _isLoadingDocs;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get isLoadingPayments => _isLoadingPayments;
  bool get isLoadingCaseFile => _isLoadingCaseFile;
  String? get docsError => _docsError;
  String? get sessionsError => _sessionsError;
  String? get paymentsError => _paymentsError;
  String? get caseFileError => _caseFileError;

  double get totalBilled => _payments.fold(0.0, (sum, item) => sum + item.amount) + 
      _financialClaims.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0));
  
  double get totalPaid => _payments.fold(0.0, (sum, item) => sum + item.paidAmount);
  double get remainingAmount => totalBilled - totalPaid;

  Future<void> loadArchiveData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadLawsuit();
      // Load in parallel for speed
      await Future.wait([
        _loadAttachments(),
        _loadHearings(),
        _loadPayments(),
        _loadAppeals(),
        _loadFinancialClaims(),
        _loadCaseFileItems(),
        _loadTasks(),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLawsuit() async {
    try {
      // 1. Try local first
      final all = await _localDb.getAllLawsuits();
      final local = all.cast<LawsuitModel?>().firstWhere((l) => l?.id == lawsuitId, orElse: () => null);
      if (local != null) {
        _lawsuit = local;
        notifyListeners();
      }

      // 2. Fetch from API
      final response = await _apiService.get('/api/lawsuits/$lawsuitId/');
      if (response != null) {
        _lawsuit = LawsuitModel.fromJson(response);
        await _localDb.insertLawsuit(_lawsuit!);
      }
    } catch (e) { print('Error loading lawsuit: $e (working offline)'); }
  }

  Future<void> _loadHearings() async {
    _isLoadingSessions = true;
    _sessionsError = null;
    try {
      // 1. Load from local first
      final localHearings = await _localDb.getHearingsForLawsuit(lawsuitId);
      if (localHearings.isNotEmpty) {
        _hearings = localHearings;
        notifyListeners();
      }

      // 2. Fetch from API
      final response = await _apiService.get('/api/hearings/?lawsuit=$lawsuitId');
      if (response != null) {
        List<dynamic> results = _extractResultsList(response);
        final serverHearings = results.map((json) => HearingModel.fromJson(json)).toList();
        
        // Update local DB
        for (var h in serverHearings) {
          await _localDb.insertHearing(h);
        }
        
        _hearings = await _localDb.getHearingsForLawsuit(lawsuitId);
      }
      _isLoadingSessions = false;
    } catch (e) {
      _sessionsError = 'فشل تحميل الجلسات من السيرفر (تعمل محلياً)';
      _isLoadingSessions = false;
      print('Error loading hearings: $e');
    }
  }

  Future<void> _loadAttachments() async {
    _isLoadingDocs = true;
    _docsError = null;
    try {
      // 1. Load from local first
      final localDocs = await _localDb.getAttachmentsForLawsuit(lawsuitId);
      if (localDocs.isNotEmpty) {
        _attachments = localDocs;
        notifyListeners();
      }

      // 2. Fetch from API
      final response = await _apiService.get('/api/attachments/?lawsuit=$lawsuitId');
      if (response != null) {
        List<dynamic> results = _extractResultsList(response);
        final serverDocs = results.map((json) => AttachmentModel.fromJson(json)).toList();
        
        // Update local DB
        for (var doc in serverDocs) {
          await _localDb.insertAttachment(doc);
        }
        
        _attachments = await _localDb.getAttachmentsForLawsuit(lawsuitId);
        print('✅ Synchronized ${_attachments.length} attachments');
      }
      _isLoadingDocs = false;
    } catch (e) {
      _docsError = 'فشل تحميل المرفقات من السيرفر (تعمل محلياً)';
      _isLoadingDocs = false;
      print('Error loading attachments: $e');
    }
  }

  Future<void> _loadPayments() async {
    _isLoadingPayments = true;
    _paymentsError = null;
    try {
      final response = await _apiService.get('/api/payment-orders/?lawsuit=$lawsuitId');
      if (response != null) {
        List<dynamic> results = _extractResultsList(response);
        _payments = results.map((json) => PaymentOrderModel.fromJson(json)).toList();
      }
      _isLoadingPayments = false;
    } catch (e) {
      _paymentsError = 'فشل تحميل الأتعاب';
      _isLoadingPayments = false;
      print('Error loading payments: $e');
    }
  }

  Future<void> _loadAppeals() async {
    try {
      final response = await _apiService.get('/api/appeals/?lawsuit=$lawsuitId');
      if (response != null) {
        List<dynamic> results = _extractResultsList(response);
        _appeals = results.map((json) => AppealModel.fromJson(json)).toList();
        print('✅ Loaded ${_appeals.length} appeals for lawsuit $lawsuitId');
      }
    } catch (e) {
      print('Error loading appeals: $e');
    }
  }

  Future<void> _loadFinancialClaims() async {
    try {
      final response = await _apiService.get('/api/financial-claims/?lawsuit=$lawsuitId');
      if (response != null) {
        List<dynamic> results = _extractResultsList(response);
        _financialClaims = results.cast<Map<String, dynamic>>();
      }
    } catch (e) { print('Error loading financial claims: $e'); }
  }

  Future<void> _loadCaseFileItems() async {
    _isLoadingCaseFile = true;
    _caseFileError = null;
    try {
      final response = await _apiService.getCaseFileByLawsuit(lawsuitId);
      if (response != null) {
        // Also apply the new helper here, but getCaseFileByLawsuit might return dict with 'items' or directly list depending on backend
        List<dynamic> items = _extractResultsList(response);
        if (items.isEmpty && response is Map && response.containsKey('items')) {
            items = response['items'] as List<dynamic>;
        } else if (items.isEmpty && response is Map && response.containsKey('data') && response['data'] is Map && response['data'].containsKey('items')) {
            items = response['data']['items'] as List<dynamic>;
        }
        
        _caseFileItems = items.map((json) => CaseFileItemModel.fromJson(json)).toList();
        print('✅ Loaded ${_caseFileItems.length} case file items');
      }
      _isLoadingCaseFile = false;
    } catch (e) {
      _caseFileError = 'فشل تحميل ملف القضية';
      _isLoadingCaseFile = false;
      print('Error loading case file items: $e');
    }
  }

  Future<void> _loadTasks() async {
    _tasks = [
      TaskModel(id: 1, lawsuitId: lawsuitId, title: 'تجهيز مسودة الرد على الخصم', priority: 'عالي'),
      TaskModel(id: 2, lawsuitId: lawsuitId, title: 'سحب نسخة من محضر الجلسة السابقة', priority: 'متوسط', isCompleted: true),
    ];
  }

  Future<bool> addTask(String title, String priority) async {
    final newTask = TaskModel(id: DateTime.now().millisecondsSinceEpoch, lawsuitId: lawsuitId, title: title, priority: priority);
    _tasks.add(newTask);
    notifyListeners();
    return true;
  }

  Future<void> toggleTask(int taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
    }
  }

  Future<bool> addHearing(HearingModel hearing) async {
    try {
      print('🔵 [Provider] Adding hearing: ${hearing.toJson()}');
      
      // 1. Save Locally
      try {
        await _localDb.insertHearing(hearing);
        _hearings = await _localDb.getHearingsForLawsuit(lawsuitId);
        notifyListeners();
        print('✅ [Provider] Hearing saved locally');
      } catch (e) {
        print('❌ [Provider] Local save failed: $e');
        _errorMessage = 'فشل الحفظ المحلي: $e';
        notifyListeners();
        return false;
      }

      // 2. Try Sync to Backend
      try {
        final data = hearing.toJson();
        // Remove read-only fields that backend doesn't accept on create
        data.remove('archive_status');
        data.remove('archive_date');
        data.remove('archive_reason');
        data.remove('archived_by');
        data.remove('is_deleted');
        data.remove('deleted_at');
        data.remove('created_at');
        data.remove('updated_at');
        data.remove('is_synced');
        data.remove('lawsuit_id'); // Remove existing lawsuit_id from toJson
        
        data['lawsuit_id'] = lawsuitId;
        print('📤 [Provider] Syncing to backend: $data');
        await _apiService.createHearing(data);
        print('✅ [Provider] Hearing synced to backend');
        // Refresh to get server ID
        await _loadHearings();
      } catch (e) {
        print('❌ [Provider] Backend sync failed (saved locally): $e');
        _errorMessage = 'تم الحفظ محلياً فقط (فشل المزامنة): $e';
        notifyListeners();
        // Return true since local save succeeded
        return true;
      }

      return true;
    } catch (e) {
      print('❌ [Provider] addHearing error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAttachment({
    required String filePath,
    required String documentType,
    required String customName,
  }) async {
    try {
      // 1. Save File Locally first
      final String localPath = await LocalFileService.saveFileLocally(filePath, 'lawsuit_$lawsuitId');
      
      final attachment = AttachmentModel(
        lawsuitId: lawsuitId,
        documentType: documentType,
        gregorianDate: DateTime.now(),
        hijriDate: '1445-01-01',
        pageCount: 1,
        content: 'اسم المستند: $customName',
        evidenceBasis: 'أرشيف قانوني',
        originalFilename: customName,
      );

      // 2. Save Metadata Locally
      await _localDb.insertAttachment(attachment, localPath: localPath);
      _attachments = await _localDb.getAttachmentsForLawsuit(lawsuitId);
      notifyListeners();

      // 3. Try Sync to Backend
      try {
        await _apiService.uploadAttachment(
          lawsuitId: lawsuitId,
          filePath: filePath,
          documentType: documentType,
          gregorianDate: attachment.gregorianDate.toIso8601String().split('T')[0],
          hijriDate: attachment.hijriDate,
          pageCount: attachment.pageCount,
          content: attachment.content,
          evidenceBasis: attachment.evidenceBasis,
        );
        await _loadAttachments();
        await _syncToCaseFile();
      } catch (e) {
        print('Attachment sync failed (saved locally): $e');
      }
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Upload a document directly to CaseFileItems (new flow)
  Future<bool> uploadCaseFileDocument({
    required String filePath,
    required String itemType,
    required String title,
    String? description,
  }) async {
    try {
      await _apiService.uploadCaseFileItem(
        lawsuitId: lawsuitId,
        filePath: filePath,
        itemType: itemType,
        title: title,
        description: description,
      );
      await _loadCaseFileItems();
      await _loadAttachments();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sync existing attachments/appeals/hearings to CaseFileItems
  Future<void> _syncToCaseFile() async {
    try {
      await _apiService.syncCaseFileFromAttachments(lawsuitId);
      await _loadCaseFileItems();
    } catch (e) {
      print('Sync to case file failed: $e');
    }
  }

  /// Manual sync trigger
  Future<bool> syncCaseFile() async {
    try {
      final result = await _apiService.syncCaseFileFromAttachments(lawsuitId);
      await _loadCaseFileItems();
      await _loadAttachments();
      notifyListeners();
      return (result['created_count'] ?? 0) > 0;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addFinancialClaim({
    required double amount,
    required String currency,
    required String description,
    required DateTime dueDate,
  }) async {
    try {
      final claimData = {
        'lawsuit': lawsuitId,
        'amount': amount.toString(),
        'currency': currency,
        'description': description,
        'due_date': dueDate.toIso8601String().split('T')[0],
      };
      await _apiService.createFinancialClaim(claimData);
      await _loadFinancialClaims();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCaseFileItem(int id) async {
    try {
      await _apiService.deleteCaseFileItem(id);
      _caseFileItems.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Helper method to safely extract results from wrapped API responses
  List<dynamic> _extractResultsList(dynamic response) {
    if (response == null) return [];
    if (response is List) return response;
    
    if (response is Map) {
      if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) return data;
        if (data is Map) {
          if (data.containsKey('results')) return data['results'] as List<dynamic>? ?? [];
          if (data.containsKey('items')) return data['items'] as List<dynamic>? ?? [];
        }
      }
      if (response.containsKey('results')) {
        return response['results'] as List<dynamic>? ?? [];
      }
    }
    return [];
  }

  // --- AI Analysis Logic ---
  Future<Map<String, dynamic>> analyzeCaseData() async {
    _isLoading = true;
    notifyListeners();

    // To ensure 100% offline support and adherence to the strict requirement 
    // of "using ONLY case data without external invention", 
    // we process the existing local data logically into a structured summary.
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing

    String summary = 'هذه القضية برقم ${_lawsuit?.caseNumber} ونوعها ${_lawsuit?.caseTypeDisplay}. ';
    if (_lawsuit?.subject != null) summary += 'موضوعها: ${_lawsuit?.subject}. ';
    if (attachments.isNotEmpty) summary += 'تحتوي على ${attachments.length} مرفقات. ';
    
    List<String> suggestions = [];
    if (hearings.isEmpty) {
      suggestions.add('يجب تحديد موعد أول جلسة لمتابعة مسار القضية.');
    }
    if (_lawsuit?.caseType == 'criminal' && attachments.isEmpty) {
      suggestions.add('يوصى بإرفاق الأدلة الجنائية ومحاضر الشرطة فوراً.');
    }
    if (_lawsuit?.caseType == 'دعوى' && _lawsuit?.status == 'pending') {
      suggestions.add('إعداد مذكرة الدعوى أو صحيفة الرد إن وجدت.');
    }

    List<String> risks = [];
    if (_lawsuit?.filingDate != null && DateTime.now().difference(_lawsuit!.filingDate!).inDays > 180) {
      risks.add('القضية عالقة لأكثر من 6 أشهر، قد تتعرض للشطب أو تأخير الحكم.');
    }
    if (_financialClaims.isNotEmpty) {
      final hasUnpaid = _financialClaims.any((c) => c['status'] != 'paid');
      if (hasUnpaid) risks.add('يوجد مطالبات مالية لم يتم سدادها قد تؤثر على الميزانية المحددة للقضية.');
    }

    _isLoading = false;
    notifyListeners();

    return {
      'summary': summary,
      'suggestions': suggestions.isEmpty ? ['الاستمرار في المتابعة الأسبوعية للملف.'] : suggestions,
      'risks': risks.isEmpty ? ['لا توجد مخاطر قانونية أو إجرائية واضحة حالياً.'] : risks,
    };
  }


  Future<bool> deleteAttachment(int attachmentId) async {
    try {
      // Delete locally
      await _localDb.deleteAttachment(attachmentId);
      
      // Try delete on server
      try {
        await _apiService.delete('/api/attachments/$attachmentId/');
      } catch (e) {
        print('Server delete failed (attachment removed locally): $e');
      }
      
      await _loadAttachments();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting attachment: $e');
      return false;
    }
  }

  /// CRITICAL: Clear all lawsuits and data from the local DB (Reset)
  Future<bool> clearAllDatabaseData() async {
    try {
      await _localDb.clearAllData();
      await _loadLawsuit();
      await _loadHearings();
      await _loadAttachments();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error clearing database: $e');
      return false;
    }
  }
  /// Update a case file item metadata
  Future<bool> updateCaseFileItem(int itemId, {String? title, String? description}) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      
      await _apiService.patch('/api/case-file-items/$itemId/', data);
      await _loadCaseFileItems();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating case file item: $e');
      return false;
    }
  }

  /// Update an attachment metadata (Local + Server)
  Future<bool> updateAttachmentTitle(int attachmentId, String newTitle) async {
    try {
      // 1. Update Locally
      await _localDb.updateAttachmentTitle(attachmentId, newTitle);
      
      // 2. Try update on Server
      try {
        await _apiService.patch('/api/attachments/$attachmentId/', {'original_filename': newTitle, 'content': 'اسم المستند: $newTitle'});
      } catch (e) {
        print('Server update failed (updated locally): $e');
      }
      
      await _loadAttachments();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating attachment: $e');
      return false;
    }
  }
}


