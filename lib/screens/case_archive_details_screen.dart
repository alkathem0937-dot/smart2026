import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../providers/lawsuit_archive_provider.dart';
import '../models/hearing_model.dart';
import '../models/attachment_model.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import 'lawsuit_detail_screen.dart';
import 'electronic_lawsuit_screen.dart';
import 'appeal_screen.dart';
import 'payment_order_screen.dart';
import 'package:intl/intl.dart';
import '../utils/feature_guard.dart';

class CaseArchiveDetailsScreen extends StatefulWidget {
  final int lawsuitId;
  final String caseTitle;
  final String caseNumber;

  const CaseArchiveDetailsScreen({
    super.key,
    required this.lawsuitId,
    required this.caseTitle,
    required this.caseNumber,
  });

  @override
  State<CaseArchiveDetailsScreen> createState() => _CaseArchiveDetailsScreenState();
}

class _CaseArchiveDetailsScreenState extends State<CaseArchiveDetailsScreen> with SingleTickerProviderStateMixin, FeatureGuard {
  late TabController _tabController;
  late LawsuitArchiveProvider _archiveProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() => setState(() {}));
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    _archiveProvider = LawsuitArchiveProvider(apiService: apiService, lawsuitId: widget.lawsuitId);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _archiveProvider.loadArchiveData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _archiveProvider,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.caseTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text('رقم القضية: ${widget.caseNumber}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 22),
              onPressed: () {
                _archiveProvider.loadArchiveData(); // This currently triggers sync logic in providers
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري المزامنة والنسخ الاحتياطي...'), backgroundColor: AppColors.primary),
                );
              },
              tooltip: 'نسخة احتياطية',
            ),
            Consumer<LawsuitArchiveProvider>(
              builder: (context, provider, _) => provider.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    )
                  : IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => _archiveProvider.loadArchiveData()),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'المستندات', icon: Icon(Icons.folder_copy_rounded, size: 18)),
              Tab(text: 'مسار القضية', icon: Icon(Icons.timeline_rounded, size: 18)),
              Tab(text: 'الجلسات', icon: Icon(Icons.gavel_rounded, size: 18)),
              Tab(text: 'المهام', icon: Icon(Icons.task_alt_rounded, size: 18)),
              Tab(text: 'الأتعاب', icon: Icon(Icons.account_balance_wallet_rounded, size: 18)),
              Tab(text: 'تحليل AI', icon: Icon(Icons.psychology_rounded, size: 18)),
            ],
          ),
        ),
        body: Consumer<LawsuitArchiveProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.lawsuit == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('جاري تحميل ملف القضية...', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildDocsTab(provider),
                _buildTimelineTab(provider),
                _buildSessionsTab(provider),
                _buildTasksTab(provider),
                _buildBillingTab(provider),
                _buildAITab(provider),
              ],
            );
          },
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget? _buildFab() {
    IconData icon = Icons.add;
    String label = 'إضافة';
    VoidCallback? action;

    switch (_tabController.index) {
      case 0:
        icon = Icons.add_to_photos_rounded;
        label = 'إضافة مرفقات';
        action = _showUploadOptionsSheet;
        break;
      case 1: // Timeline
        return null;
      case 2: // Sessions
        icon = Icons.event_note_rounded;
        label = 'إضافة جلسة';
        action = _showAddHearingSheet;
        break;
      case 3: // Tasks
        icon = Icons.add_task_rounded;
        label = 'إضافة مهمة';
        action = _showAddTaskSheet;
        break;
      case 4: // Billing
        icon = Icons.add_card_rounded;
        label = 'تسجيل أتعاب';
        action = _showAddFinancialClaimSheet;
        break;
      case 5: // AI 
        return null;
      default:
        return null;
    }

    return FloatingActionButton.extended(
      onPressed: action,
      backgroundColor: AppColors.primary,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // --- Tabs Implementation ---

  Widget _buildDocsTab(LawsuitArchiveProvider provider) {
    // Show loading indicator while docs are loading
    if (provider.isLoadingDocs && provider.attachments.isEmpty && provider.caseFileItems.isEmpty) {
      return _buildLoadingState('جاري تحميل المستندات...');
    }

    // Show error if loading failed
    if (provider.docsError != null && provider.attachments.isEmpty) {
      return _buildErrorState(provider.docsError!, () {
        provider.loadArchiveData();
      });
    }

    // Combine attachments and case file items
    final allDocs = <_DocItem>[];

    // Add case file items
    for (final item in provider.caseFileItems) {
      allDocs.add(_DocItem(
        id: item.id,
        title: item.title,
        type: item.itemType,
        typeDisplay: item.itemTypeDisplay,
        date: item.createdAt,
        fileSize: item.fileSizeDisplay ?? '-',
        source: 'casefile',
      ));
    }

    // Add appeals
    for (final appeal in provider.appeals) {
      allDocs.add(_DocItem(
        id: appeal.id ?? 0,
        title: 'طعن: ${appeal.appealNumber}',
        type: 'appeal',
        typeDisplay: appeal.appealTypeDisplay,
        date: appeal.createdAt,
        fileSize: '-',
        source: 'appeal',
      ));
    }

    // Add payment orders
    for (final payment in provider.payments) {
      allDocs.add(_DocItem(
        id: payment.id ?? 0,
        title: 'أمر أداء: ${payment.orderNumber}',
        type: 'payment_order',
        typeDisplay: 'أمر أداء',
        date: payment.createdAt,
        fileSize: '${payment.amount} ر.ي',
        source: 'payment',
      ));
    }
    
    // Add attachments that aren't already in case file items
    final caseFileAttIds = provider.caseFileItems
        .where((i) => i.relatedObjectType == 'attachment')
        .map((i) => i.relatedObjectId)
        .toSet();
    
    for (final att in provider.attachments) {
      if (att.id != null && caseFileAttIds.contains(att.id)) continue;
      allDocs.add(_DocItem(
        id: att.id ?? 0,
        title: att.content.replaceFirst('اسم المستند: ', ''),
        type: att.documentType,
        typeDisplay: att.typeDisplay,
        date: att.createdAt,
        fileSize: att.fileSizeDisplay,
        source: 'attachment',
      ));
    }
    
    // Sort descending by date
    allDocs.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });

    if (allDocs.isEmpty) {
      return _buildEmptyStateWithActions('ملف القضية فارغ', Icons.folder_zip_rounded);
    }

    return Column(
      children: [
        // Sync banner
        if (provider.caseFileItems.isEmpty && provider.attachments.isNotEmpty)
          _buildSyncBanner(provider),
        // Document count header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(Icons.folder_copy_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('محتويات ملف القضية (${allDocs.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              if (provider.isLoadingDocs || provider.isLoadingCaseFile)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: allDocs.length,
            itemBuilder: (context, index) => _buildDocItem(allDocs[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab(LawsuitArchiveProvider provider) {
    if (provider.isLoading) return _buildLoadingState('جاري تجميع مسار القضية...');
    
    // Aggregate events
    List<Map<String, dynamic>> events = [];
    
    // Lawsuit origin
    if (provider.lawsuit?.filingDate != null) {
      events.add({
        'date': provider.lawsuit!.filingDate!,
        'title': 'تأسيس القضية',
        'sub': provider.lawsuit!.caseTypeDisplay,
        'type': 'lawsuit'
      });
    }

    // Hearings
    for (var h in provider.hearings) {
      events.add({
        'date': h.hearingDate,
        'title': 'جلسة: ${h.hearingType}',
        'sub': h.notes.isNotEmpty ? h.notes : 'لا توجد ملاحظات',
        'type': 'hearing'
      });
    }

    // Attachments
    for (var a in provider.attachments) {
      if (a.createdAt != null) {
        events.add({
          'date': a.createdAt!,
          'title': 'مرفق: ${a.typeDisplay}',
          'sub': a.originalFilename ?? 'مستند',
          'type': 'attachment'
        });
      }
    }

    // Sort descending (newest first)
    events.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (events.isEmpty) return _buildEmptyState('لا يوجد مسار زمني', Icons.timeline, 'لم يتم تسجيل أي أحداث لهذه القضية');

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final ev = events[index];
        final isFuture = (ev['date'] as DateTime).isAfter(DateTime.now());
        return _buildTimelineItem(
          DateFormat('yyyy-MM-dd').format(ev['date']),
          ev['title'],
          ev['sub'],
          isFuture
        );
      },
    );
  }


  Widget _buildSyncBanner(LawsuitArchiveProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text('يوجد مرفقات لم تتم مزامنتها مع ملف القضية', style: TextStyle(fontSize: 12))),
          TextButton(
            onPressed: () async {
              final ok = await provider.syncCaseFile();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'تمت المزامنة بنجاح ✅' : 'لا توجد عناصر جديدة للمزامنة'),
                ));
              }
            },
            child: const Text('مزامنة الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab(LawsuitArchiveProvider provider) {
    if (provider.isLoadingSessions && provider.hearings.isEmpty) {
      return _buildLoadingState('جاري تحميل الجلسات...');
    }

    if (provider.sessionsError != null && provider.hearings.isEmpty) {
      return _buildErrorState(provider.sessionsError!, () => provider.loadArchiveData());
    }

    if (provider.hearings.isEmpty) {
      return _buildEmptyState('لا توجد جلسات', Icons.gavel_rounded, 'قم بإضافة جلسة جديدة لمتابعة المواعيد');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.hearings.length,
      itemBuilder: (context, index) {
        final h = provider.hearings[index];
        bool isFuture = h.hearingDate.isAfter(DateTime.now());
        return _buildTimelineItem(
          DateFormat('yyyy-MM-dd').format(h.hearingDate),
          h.typeDisplay,
          h.notes,
          isFuture,
        );
      },
    );
  }

  Widget _buildTasksTab(LawsuitArchiveProvider provider) {
    if (provider.tasks.isEmpty) {
      return _buildEmptyState('لا توجد مهام', Icons.playlist_add_check_rounded, 'أضف مهام العمل لمتابعة الإنجاز');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.tasks.length,
      itemBuilder: (context, index) {
        final task = provider.tasks[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
          child: CheckboxListTile(
            value: task.isCompleted,
            onChanged: (v) => provider.toggleTask(task.id),
            title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('الأولوية: ${task.priority}', style: TextStyle(fontSize: 12, color: _getPriorityColor(task.priority))),
          ),
        );
      },
    );
  }

  Widget _buildBillingTab(LawsuitArchiveProvider provider) {
    if (provider.isLoadingPayments && provider.financialClaims.isEmpty && provider.payments.isEmpty) {
      return _buildLoadingState('جاري تحميل الأتعاب...');
    }

    return Column(
      children: [
        _buildFinancialCard(provider),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Align(child: Text('سجل المطالبات المالية والأتعاب', style: TextStyle(fontWeight: FontWeight.bold)), alignment: Alignment.centerRight),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ...provider.financialClaims.map((claim) => _buildTransactionItem(
                claim['description'] ?? 'أتعاب قانونية',
                claim['due_date'] ?? '',
                '${NumberFormat("#,###").format(double.tryParse(claim['amount']?.toString() ?? '0') ?? 0)} ${claim['currency'] ?? 'ر.ي'}',
                false,
              )),
              if (provider.payments.isEmpty && provider.financialClaims.isEmpty)
                _buildEmptyState('لا توجد أتعاب', Icons.account_balance_wallet_outlined, 'قم بتوثيق المطالبات والرسوم هنا'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAITab(LawsuitArchiveProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildAIHeader(),
          const SizedBox(height: 24),
          _buildActionCard(
            'تحليل استراتيجي للقضية', 
            Icons.analytics_outlined, 
            color: Colors.indigo,
            onTap: () => _showAIAnalysisModal(provider),
          ),
          _buildActionCard(
            'توليد مسودة طعن قانوني', 
            Icons.description_outlined, 
            color: Colors.blue,
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('سيتم تفعيل هذه الميزة قريباً ضمن باقة المحامي الذكي.'))
               );
            }
          ),
        ],
      ),
    );
  }

  void _showAIAnalysisModal(LawsuitArchiveProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          bool analyzing = true;
          Map<String, dynamic>? analysisResult;

          // Run analysis once when opened
          if (analysisResult == null) {
            provider.analyzeCaseData().then((result) {
              if (mounted) {
                setModalState(() {
                  analysisResult = result;
                  analyzing = false;
                });
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: analyzing
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.indigo),
                        const SizedBox(height: 16),
                        Text('جاري تحليل ملف القضية والمرفقات...', style: TextStyle(color: Colors.grey[700], fontFamily: 'Cairo')),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology, color: Colors.indigo, size: 32),
                            const SizedBox(width: 12),
                            const Text('نتائج التحليل الذكي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            const Spacer(),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                          ],
                        ),
                        const Divider(height: 32),
                        const Text('ملخص القضية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(analysisResult?['summary'] ?? '', style: const TextStyle(fontSize: 14, height: 1.5)),
                        const SizedBox(height: 24),
                        const Text('المخاطر والتنبيهات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                        const SizedBox(height: 8),
                        ...((analysisResult?['risks'] as List<String>?) ?? []).map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(r, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        )),
                        const SizedBox(height: 24),
                        const Text('الإجراءات المقترحة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                        const SizedBox(height: 8),
                        ...((analysisResult?['suggestions'] as List<String>?) ?? []).map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  // --- Interaction Models ---

  void _showUploadOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إضافة مرفق / ملف جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('اختر نوع المستند لإضافته إلى ملف القضية', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionIcon(Icons.description_rounded, 'مستند', Colors.blue, () => _handleFileUpload('document')),
                _buildOptionIcon(Icons.gavel_rounded, 'دعوى', Colors.green, () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectronicLawsuitScreen())).then((_) => _archiveProvider.loadArchiveData());
                }),
                _buildOptionIcon(Icons.history_edu_rounded, 'طعن', Colors.red, () {
                   Navigator.pop(ctx);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const AppealScreen())).then((_) => _archiveProvider.loadArchiveData());
                }),
                _buildOptionIcon(Icons.request_page_rounded, 'أمر أداء', Colors.amber[800]!, () {
                   Navigator.pop(ctx);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentOrderScreen())).then((_) => _archiveProvider.loadArchiveData());
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileUpload(String type) async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final nameController = TextEditingController(text: result.files.single.name);
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تسمية المستند'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المرفق', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              Text('الملف: ${result.files.single.name}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              onPressed: () async {
                Navigator.pop(ctx);
                // Show uploading indicator
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Row(children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 12),
                      Text('جاري رفع المستند...'),
                    ]),
                    duration: Duration(seconds: 10),
                  ));
                }
                final success = await _archiveProvider.uploadAttachment(
                  filePath: result.files.single.path!,
                  documentType: type,
                  customName: nameController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'تم رفع المستند بنجاح ✅' : 'فشل رفع المستند ❌'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ));
                }
              },
              label: const Text('رفع الآن'),
            ),
          ],
        ),
      );
    }
  }

  void _showAddHearingSheet() {
    final typeController = TextEditingController(text: 'جلسة مرافعة');
    final notesController = TextEditingController();
    DateTime date = DateTime.now();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تسجيل موعد جلسة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(date)}'),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (picked != null) setSS(() => date = picked);
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: typeController, decoration: const InputDecoration(labelText: 'نوع الجلسة', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'نتائج أو ملاحظات الجلسة', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    print('🟢 [UI] Save button pressed');
                    print('🟢 [UI] Hearing type: ${typeController.text}');
                    print('🟢 [UI] Notes: ${notesController.text}');
                    print('🟢 [UI] Date: $date');
                    print('🟢 [UI] Lawsuit ID: ${widget.lawsuitId}');
                    
                    if (typeController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال نوع الجلسة'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    
                    setSS(() => isSaving = true);
                    
                    try {
                      print('🟢 [UI] Creating HearingModel...');
                      final hearing = HearingModel(
                        id: 0,
                        lawsuitId: widget.lawsuitId,
                        hearingDate: date,
                        hearingType: typeController.text.trim(),
                        notes: notesController.text.trim(),
                      );
                      print('🟢 [UI] HearingModel created: ${hearing.toJson()}');
                      
                      print('🟢 [UI] Calling addHearing...');
                      final success = await _archiveProvider.addHearing(hearing);
                      print('🟢 [UI] addHearing returned: $success');
                      
                      setSS(() => isSaving = false);
                      
                      if (success) {
                        print('🟢 [UI] Success - closing dialog');
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تسجيل الجلسة بنجاح ✅'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        print('🔴 [UI] Failed: ${_archiveProvider.errorMessage}');
                        if (mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(_archiveProvider.errorMessage ?? 'فشل حفظ الجلسة'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e, stackTrace) {
                      print('🔴 [UI] Exception: $e');
                      print('🔴 [UI] Stack trace: $stackTrace');
                      setSS(() => isSaving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('حفظ الجلسة'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddFinancialClaimSheet() {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String currency = 'YER';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تسجيل أتعاب جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: currency,
                items: const [DropdownMenuItem(value: 'YER', child: Text('ريال يمني')), DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي'))],
                onChanged: (v) => setSS(() => currency = v!),
                decoration: const InputDecoration(labelText: 'العملة', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'البيان (مثلاً: دفعة مكاتبة)', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await _archiveProvider.addFinancialClaim(
                      amount: double.tryParse(amountController.text) ?? 0,
                      currency: currency,
                      description: descController.text,
                      dueDate: DateTime.now(),
                    );
                    if (ok) {
                      Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الأتعاب بنجاح ✅'), backgroundColor: Colors.green));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('حفظ المطالبة'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    String priority = 'متوسط';
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (ctx) => StatefulBuilder(builder: (ctx, setSS) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('إضافة مهمة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 20), TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان المهمة', border: OutlineInputBorder())), const SizedBox(height: 16), DropdownButtonFormField<String>(value: priority, items: const [DropdownMenuItem(value: 'عالي', child: Text('عالي')), DropdownMenuItem(value: 'متوسط', child: Text('متوسط')), DropdownMenuItem(value: 'منخفض', child: Text('منخفض'))], onChanged: (v) => setSS(() => priority = v!), decoration: const InputDecoration(labelText: 'الأولوية', border: OutlineInputBorder())), const SizedBox(height: 24), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { if (titleController.text.isNotEmpty) { _archiveProvider.addTask(titleController.text, priority); Navigator.pop(ctx); } }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('حفظ المهمة'))), const SizedBox(height: 40)]))));
  }

  // --- UI Helpers ---

  Widget _buildDocItem(_DocItem doc) {
    IconData icon = Icons.insert_drive_file_rounded;
    Color color = Colors.blue;
    
    switch (doc.type) {
      case 'lawsuit':
        icon = Icons.gavel_rounded; color = Colors.green;
        break;
      case 'appeal':
        icon = Icons.history_edu_rounded; color = Colors.red;
        break;
      case 'payment_order':
        icon = Icons.request_page_rounded; color = Colors.amber[800]!;
        break;
      case 'judgment':
        icon = Icons.balance_rounded; color = Colors.purple;
        break;
      case 'hearing_record':
        icon = Icons.event_note_rounded; color = Colors.teal;
        break;
      case 'contract':
        icon = Icons.handshake_rounded; color = Colors.indigo;
        break;
      case 'evidence':
        icon = Icons.search_rounded; color = Colors.deepOrange;
        break;
      default:
        icon = Icons.insert_drive_file_rounded; color = Colors.blue;
    }

    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(doc.typeDisplay, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            if (doc.date != null)
              Text(DateFormat('yyyy-MM-dd').format(doc.date!), style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text('• ${doc.fileSize}', style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.indigo, size: 20), 
              onPressed: () => _showEditDocDialog(context, doc),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), 
              onPressed: () => _confirmDeleteDoc(context, doc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(LawsuitArchiveProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withBlue(30)]), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [const Text('إجمالي المستحقات', style: TextStyle(color: Colors.white70, fontSize: 12)), Text('${NumberFormat("#,###").format(provider.totalBilled)} ر.ي', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Column(children: [Text(NumberFormat.compact().format(provider.totalPaid), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const Text('تم السداد', style: TextStyle(color: Colors.white60, fontSize: 10))]), Column(children: [Text(NumberFormat.compact().format(provider.remainingAmount), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const Text('المتبقي', style: TextStyle(color: Colors.white60, fontSize: 10))])])]),
    );
  }

  // --- State Helpers ---

  void _confirmDeleteDoc(BuildContext context, _DocItem doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستند'),
        content: Text('هل أنت متأكد من رغبتك في حذف "${doc.title}"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = false;
              if (doc.source == 'casefile') {
                success = await _archiveProvider.deleteCaseFileItem(doc.id);
              } else {
                success = await _archiveProvider.deleteAttachment(doc.id);
              }
              if (mounted && success) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المستند بنجاح.'), backgroundColor: Colors.green));
                 _archiveProvider.loadArchiveData(); // Force refresh the list
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[200]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[400])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithActions(String title, IconData icon) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Colors.grey[200]), const SizedBox(height: 16), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 24), ElevatedButton.icon(onPressed: _showUploadOptionsSheet, icon: const Icon(Icons.add_to_photos_rounded), label: const Text('إضافة مرفق الآن'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)))]));

  Widget _buildEmptyState(String msg, IconData icon, String sub) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Colors.grey[200]), const SizedBox(height: 16), Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey))]));

  Widget _buildTimelineItem(String date, String title, String sub, bool isFuture) {
    final color = isFuture ? AppColors.primary : Colors.grey[400]!;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Column(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))), Container(width: 2, height: 60, color: color.withOpacity(0.3))]), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(date, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])), const SizedBox(height: 20)]))]);
  }

  Widget _buildTransactionItem(String title, String date, String amount, bool isPaid) => ListTile(contentPadding: EdgeInsets.zero, title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text(date, style: const TextStyle(fontSize: 11)), trailing: Text(amount, style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14)));

  Widget _buildOptionIcon(IconData icon, String label, Color color, VoidCallback onTap) => InkWell(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));

  Widget _buildActionCard(String title, IconData icon, {required Color color, VoidCallback? onTap}) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.2))), child: ListTile(onTap: onTap, leading: Icon(icon, color: color), title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.chevron_left_rounded)));

  Widget _buildAIHeader() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.auto_awesome, color: Colors.indigo), SizedBox(width: 12), Expanded(child: Text('المحلل الذكي جاهز لمراجعة مستنداتك وتقديم التوصيات الاستراتيجية.', style: TextStyle(fontSize: 13, height: 1.5)))]));

  Color _getPriorityColor(String p) => (p == 'عالي') ? Colors.red : (p == 'متوسط' ? Colors.orange : Colors.green);


  void _showEditDocDialog(BuildContext context, _DocItem doc) {
    final nameController = TextEditingController(text: doc.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل اسم المستند'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'اسم المرفق', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = false;
              if (doc.source == 'casefile') {
                success = await _archiveProvider.updateCaseFileItem(doc.id, title: nameController.text.trim());
              } else {
                success = await _archiveProvider.updateAttachmentTitle(doc.id, nameController.text.trim());
              }
              if (mounted && success) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث المستند بنجاح.'), backgroundColor: Colors.green));
                 _archiveProvider.loadArchiveData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
  }
}

/// Internal model for unified document display
class _DocItem {
  final int id;
  final String title;
  final String type;
  final String typeDisplay;
  final DateTime? date;
  final String fileSize;
  final String source; // 'attachment' or 'casefile'

  _DocItem({
    required this.id,
    required this.title,
    required this.type,
    required this.typeDisplay,
    this.date,
    required this.fileSize,
    required this.source,
  });
}
