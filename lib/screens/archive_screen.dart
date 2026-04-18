import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/lawsuit_provider.dart';
import '../models/lawsuit_model.dart';
import '../models/case_model.dart';
import '../services/api_service.dart';
import '../services/local_lookup_service.dart';
import 'inquiries_screen.dart';
import 'settings_screen.dart';
import 'case_archive_details_screen.dart';
import 'case_detail_screen.dart';

/// Archive Screen - شاشة الأرشيف المركزية الشاملة
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late TabController _tabController;
  bool _isGridView = false;

  int? _extractHijriYear(String? hijriDate) {
    if (hijriDate == null || hijriDate.trim().isEmpty) return null;
    final parts = hijriDate.split('/');
    if (parts.isEmpty) return null;
    return int.tryParse(parts[0].trim());
  }

  List _extractListFromApiResponse(dynamic response) {
    if (response == null) return const [];
    if (response is List) return response;
    if (response is Map) {
      final dynamic directResults = response['results'] ?? response['data'] ?? response['items'];
      if (directResults is List) return directResults;
      if (directResults is Map) {
        final dynamic nestedResults = directResults['results'] ?? directResults['data'] ?? directResults['items'];
        if (nestedResults is List) return nestedResults;
      }
    }
    return const [];
  }

  List<String> _getCaseSubtypes(String caseType) {
    switch (caseType) {
      case 'civil':
      case 'مدنية':
        return ['ضريبية', 'جمركية', 'زكوية', 'مدنية', 'مستعجل'];
      case 'criminal':
      case 'جزائية':
        return ['تعرض للانحراف', 'جسيمة', 'غير جسيمة', 'مستعجلة'];
      case 'personal_status':
      case 'شخصية':
        return ['شخصية', 'مستعجل'];
      case 'administrative':
      case 'إدارية':
        return ['إدارية', 'مستعجل', 'عمالية'];
      case 'commercial':
      case 'تجارية':
        return ['تجارية', 'مستعجل'];
      case 'تنفيذ':
        return ['إدارية', 'أوامر', 'مستعجل', 'تجارية', 'شخصية', 'عمالية', 'جنائية', 'مدنية'];
      default:
        return const [];
    }
  }

  // Filter selections
  String? _selectedCaseType;
  String? _selectedCaseStatus;
  String? _selectedArchiveStatus;
  String? _selectedOrdering;

  static const _caseTypes = [
    {'value': 'دعوى', 'label': 'دعوى'},
    {'value': 'امر_اداء', 'label': 'أمر أداء'},
    {'value': 'رد_على_دعوى', 'label': 'رد على دعوى'},
    {'value': 'استئناف', 'label': 'استئناف'},
    {'value': 'طعن', 'label': 'طعن'},
    {'value': 'civil', 'label': 'مدني'},
    {'value': 'criminal', 'label': 'جنائي'},
    {'value': 'commercial', 'label': 'تجاري'},
    {'value': 'personal_status', 'label': 'أحوال شخصية'},
    {'value': 'labor', 'label': 'عمالي'},
    {'value': 'administrative', 'label': 'إداري'},
  ];

  static const _caseStatuses = [
    {'value': 'جديد', 'label': 'جديد'},
    {'value': 'قيد_النظر', 'label': 'قيد النظر'},
    {'value': 'مكتمل', 'label': 'مكتمل'},
    {'value': 'مغلق', 'label': 'مغلق'},
  ];

  static const _archiveStatuses = [
    {'value': 'active', 'label': 'نشط', 'icon': Icons.folder_open, 'color': Colors.green},
    {'value': 'semi_active', 'label': 'شبه نشط', 'icon': Icons.folder_shared, 'color': Colors.orange},
    {'value': 'archived', 'label': 'محفوظ', 'icon': Icons.archive, 'color': Colors.grey},
  ];

  static const _orderingOptions = [
    {'value': '-created_at', 'label': 'الأحدث أولاً'},
    {'value': 'created_at', 'label': 'الأقدم أولاً'},
    {'value': '-filing_date', 'label': 'تاريخ الرفع (الأحدث)'},
    {'value': 'filing_date', 'label': 'تاريخ الرفع (الأقدم)'},
    {'value': 'case_number', 'label': 'رقم الدعوى'},
    {'value': '-updated_at', 'label': 'آخر تحديث'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LawsuitProvider>(context, listen: false);
      provider.loadLawsuits(refresh: true);
      provider.loadCases(refresh: true);
      provider.loadArchiveStats();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final provider = Provider.of<LawsuitProvider>(context, listen: false);
      switch (_tabController.index) {
        case 0: // الكل
          provider.setArchiveStatusFilter(null);
          break;
        case 1: // نشط
          provider.setArchiveStatusFilter('active');
          break;
        case 2: // محفوظ
          provider.setArchiveStatusFilter('archived');
          break;
      }
      _selectedArchiveStatus = provider.archiveStatusFilter;
      provider.loadLawsuits(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<LawsuitProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadLawsuits();
      }
    }
  }

  void _applySearch() {
    final provider = Provider.of<LawsuitProvider>(context, listen: false);
    provider.setSearchQuery(_searchController.text.trim().isEmpty ? null : _searchController.text.trim());
    provider.loadLawsuits(refresh: true);
  }

  void _applyFilters() {
    final provider = Provider.of<LawsuitProvider>(context, listen: false);
    provider.setCaseTypeFilter(_selectedCaseType);
    provider.setCaseStatusFilter(_selectedCaseStatus);
    provider.setArchiveStatusFilter(_selectedArchiveStatus);
    provider.setOrdering(_selectedOrdering);
    provider.loadLawsuits(refresh: true);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        selectedCaseType: _selectedCaseType,
        selectedCaseStatus: _selectedCaseStatus,
        selectedArchiveStatus: _selectedArchiveStatus,
        selectedOrdering: _selectedOrdering,
        onApply: (caseType, caseStatus, archiveStatus, ordering) {
          setState(() {
            _selectedCaseType = caseType;
            _selectedCaseStatus = caseStatus;
            _selectedArchiveStatus = archiveStatus;
            _selectedOrdering = ordering;
          });
          _applyFilters();
        },
        onClear: () {
          _clearFilters();
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCaseType = null;
      _selectedCaseStatus = null;
      _selectedArchiveStatus = null;
      _selectedOrdering = null;
      _searchController.clear();
    });
    final provider = Provider.of<LawsuitProvider>(context, listen: false);
    provider.clearFilters();
    provider.loadLawsuits(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search (reduced padding when keyboard is visible)
            _buildHeader(isKeyboardVisible: isKeyboardVisible),
            // Stats bar (hidden when keyboard is visible to save space)
            if (!isKeyboardVisible) _buildStatsBar(),
            // Tabs (hidden when keyboard is visible to save space)
            if (!isKeyboardVisible) _buildTabs(),
            // Filter chips (hidden when keyboard is visible to save space)
            if (!isKeyboardVisible) _buildActiveFilterChips(),
            // Results list (takes remaining space, scrollable)
            Expanded(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: isKeyboardVisible ? null : FloatingActionButton.extended(
        heroTag: 'add_new_case',
        backgroundColor: const Color(0xFFD4A940),
        onPressed: _showNewCaseForm,
        icon: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
        label: const Text('إنشاء ملف قضية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader({bool isKeyboardVisible = false}) {
    final provider = Provider.of<LawsuitProvider>(context, listen: false);
    return Container(
      padding: EdgeInsets.fromLTRB(6, isKeyboardVisible ? 1 : 1, 1, isKeyboardVisible ? 1 : 1),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row (hidden when keyboard is visible)
          if (!isKeyboardVisible)
            Row(
              children: [
                // Toggle view
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, 
                    color: Colors.grey[600]),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  tooltip: _isGridView ? 'عرض قائمة' : 'عرض شبكة',
                ),
                // Filter button
                Consumer<LawsuitProvider>(
                  builder: (context, provider, _) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: provider.hasActiveFilters ? const Color(0xFFD4A940) : Colors.grey[600],
                          ),
                          onPressed: _showFilterSheet,
                          tooltip: 'فلترة',
                        ),
                        if (provider.hasActiveFilters)
                          Positioned(
                            top: 8, right: 8,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4A940),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                // Purge button (Delete All)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                  onPressed: () => _confirmResetDatabase(provider),
                  tooltip: 'مسح الأرشيف بالكامل',
                ),
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFFD4A940)),
                  onPressed: () => provider.loadLawsuits(refresh: true),
                  tooltip: 'تحديث',
                ),
                Expanded(
                  child: Text(
                    'أرشيف القضايا',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2138),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(Icons.archive_outlined, color: Color(0xFFD4A940), size: 28),
              ],
            ),
          if (!isKeyboardVisible) const SizedBox(height: 3),
          // Search bar with compact controls when keyboard is visible
          if (isKeyboardVisible) const SizedBox(height: 0.5),
          Row(
            children: [
              // Toggle view (shown when keyboard is visible)
              if (isKeyboardVisible)
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, 
                    color: Colors.grey[500], size: 12),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _isGridView ? 'عرض قائمة' : 'عرض شبكة',
                ),
              // Filter button (shown when keyboard is visible)
              if (isKeyboardVisible)
                Consumer<LawsuitProvider>(
                  builder: (context, provider, _) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: provider.hasActiveFilters ? const Color(0xFFD4A940) : Colors.grey[400],
                            size: 14,
                          ),
                          onPressed: _showFilterSheet,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'فلترة',
                        ),
                        if (provider.hasActiveFilters)
                          Positioned(
                            top: 4, right: 4,
                            child: Container(
                              width: 5, height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4A940),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              if (isKeyboardVisible) const SizedBox(width: 1),
              // Search bar
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textDirection: ui.TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث برقم الدعوى، الموضوع، الأطراف...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFFD4A940)),
                      onPressed: _applySearch,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            _applySearch();
                          },
                        )
                      : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10, 
                      vertical: isKeyboardVisible ? 1 : 1,
                    ),
                  ),
                  onSubmitted: (_) => _applySearch(),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<LawsuitProvider>(
      builder: (context, provider, _) {
        final stats = provider.archiveStats;
        final total = stats?['total'] ?? provider.totalCount;
        final active = stats?['by_archive_status']?['active'] ?? 0;
        final archived = stats?['by_archive_status']?['archived'] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildStatChip('الكل', total, const Color(0xFF1A2138)),
                const SizedBox(width: 6),
                _buildStatChip('نشط', active, Colors.green),
                const SizedBox(width: 6),
                _buildStatChip('محفوظ', archived, Colors.grey),
                const SizedBox(width: 6),
                _buildStatChip('النتائج', provider.totalCount, const Color(0xFFD4A940)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, dynamic count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFD4A940),
        labelColor: const Color(0xFFD4A940),
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'جميع القضايا'),
          Tab(text: 'النشطة'),
          Tab(text: 'المحفوظة'),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    return Consumer<LawsuitProvider>(
      builder: (context, provider, _) {
        if (!provider.hasActiveFilters) return const SizedBox.shrink();
        
        final chips = <Widget>[];
        
        if (provider.searchQuery != null && provider.searchQuery!.isNotEmpty) {
          chips.add(_buildChip('بحث: ${provider.searchQuery}', () {
            _searchController.clear();
            provider.setSearchQuery(null);
            provider.loadLawsuits(refresh: true);
          }));
        }
        if (provider.caseTypeFilter != null) {
          final label = _caseTypes.firstWhere(
            (t) => t['value'] == provider.caseTypeFilter,
            orElse: () => {'label': provider.caseTypeFilter!},
          )['label']!;
          chips.add(_buildChip('النوع: $label', () {
            setState(() => _selectedCaseType = null);
            provider.setCaseTypeFilter(null);
            provider.loadLawsuits(refresh: true);
          }));
        }
        if (provider.caseStatusFilter != null) {
          final label = _caseStatuses.firstWhere(
            (s) => s['value'] == provider.caseStatusFilter,
            orElse: () => {'label': provider.caseStatusFilter!},
          )['label']!;
          chips.add(_buildChip('الحالة: $label', () {
            setState(() => _selectedCaseStatus = null);
            provider.setCaseStatusFilter(null);
            provider.loadLawsuits(refresh: true);
          }));
        }

        chips.add(
          ActionChip(
            label: const Text('مسح الكل', style: TextStyle(color: Colors.red, fontSize: 12)),
            backgroundColor: Colors.red.withOpacity(0.05),
            side: BorderSide(color: Colors.red.withOpacity(0.3)),
            onPressed: _clearFilters,
          ),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(left: 6), child: c)).toList()),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: const Color(0xFFD4A940).withOpacity(0.08),
      deleteIconColor: const Color(0xFFD4A940),
      side: BorderSide(color: const Color(0xFFD4A940).withOpacity(0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildResultsList() {
    return Consumer<LawsuitProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.lawsuits.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4A940)));
        }

        if (provider.errorMessage != null && provider.lawsuits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 14),
                Text(
                  provider.errorMessage ?? 'حدث خطأ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[300]),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => provider.loadLawsuits(refresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A940),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.lawsuits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.archive_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 14),
                Text(
                  provider.hasActiveFilters ? 'لا توجد نتائج مطابقة' : 'الأرشيف فارغ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  provider.hasActiveFilters
                      ? 'جرّب تغيير معايير البحث أو الفلترة'
                      : 'اضغط + لإضافة دعوى جديدة',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                if (provider.hasActiveFilters) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_list_off),
                    label: const Text('مسح الفلاتر'),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFFD4A940),
          onRefresh: () async {
            await provider.loadLawsuits(refresh: true);
            await provider.loadCases(refresh: true);
            await provider.loadArchiveStats();
          },
          child: _isGridView ? _buildGridView(provider) : _buildListView(provider),
        );
      },
    );
  }

  Widget _buildListView(LawsuitProvider provider) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final cases = provider.cases;
    final lawsuits = provider.lawsuits;
    // Cases section count: header + items (or 0 if empty)
    final caseSectionCount = cases.isEmpty ? 0 : cases.length + 1;
    final totalCount = caseSectionCount + lawsuits.length + (provider.isLoading ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(3, 1, 1, isKeyboardVisible ? 0 : 30),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // Cases header
        if (cases.isNotEmpty && index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(children: [
              const Icon(Icons.folder_rounded, color: Color(0xFFD4A940), size: 20),
              const SizedBox(width: 6),
              Text('ملفات القضايا (${cases.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E3B))),
            ]),
          );
        }
        // Cases items
        if (cases.isNotEmpty && index > 0 && index <= cases.length) {
          final c = cases[index - 1];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFD4A940).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.folder_open_rounded, color: Color(0xFFD4A940), size: 22),
              ),
              title: Text(c.subject ?? 'بدون موضوع', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text('${c.caseNumber} • ${c.caseType ?? ''} • ${c.caseStatus ?? ''}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: c.id!))),
            ),
          );
        }
        // Lawsuits
        final lawsuitIndex = index - caseSectionCount;
        if (lawsuitIndex >= lawsuits.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(color: Color(0xFFD4A940))));
        }
        return _ArchiveLawsuitCard(
          lawsuit: lawsuits[lawsuitIndex],
          onArchive: () => _showArchiveDialog(lawsuits[lawsuitIndex]),
        );
      },
    );
  }

  Widget _buildGridView(LawsuitProvider provider) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        4, 
        1, 
        4, 
        isKeyboardVisible ? 0 : 30,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: provider.lawsuits.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.lawsuits.length) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4A940)));
        }
        return _ArchiveGridCard(lawsuit: provider.lawsuits[index]);
      },
    );
  }

  void _showNewCaseForm() {
    final outerContext = context;
    final navigator = Navigator.of(context);
    final caseNumberController = TextEditingController();
    final subjectController = TextEditingController();
    int? selectedCaseYear;

    String selectedCaseType = 'مدنية';
    String? selectedCaseSubtype;
    List<String> subtypeOptions = [];
    String selectedCaseStatus = 'جديد';
    DateTime? filingDateGregorian = DateTime.now();

    // Governorate -> Courts (local-first)
    List<Map<String, dynamic>> governorates = [];
    List<Map<String, dynamic>> courts = [];
    bool isLoadingGovernorates = false;
    bool isLoadingCourts = false;
    bool didInit = false;
    String? selectedGovernorateName;
    int? selectedGovernorateId;
    int? selectedCourtId;

    // Parties
    List<Map<String, dynamic>> clientParties = [];
    List<Map<String, dynamic>> opponentParties = [];

    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {

          // ── Load governorates (local first, then API) ──
          Future<void> loadGovernorates() async {
            if (isLoadingGovernorates) return;
            setSheetState(() => isLoadingGovernorates = true);
            try {
              // Try local cache first
              var cached = await LocalLookupService.getGovernorates();
              if (cached.isNotEmpty) {
                setSheetState(() => governorates = cached);
              }
              // Sync from API in background
              final apiService = Provider.of<ApiService>(ctx, listen: false);
              final synced = await LocalLookupService.syncGovernorates(apiService);
              if (synced.isNotEmpty) {
                setSheetState(() => governorates = synced);
              }
            } catch (_) {}
            finally { setSheetState(() => isLoadingGovernorates = false); }
          }

          Future<void> loadCourts({required int governorateId}) async {
            if (isLoadingCourts) return;
            setSheetState(() => isLoadingCourts = true);
            try {
              final gov = governorates.firstWhere(
                (g) => g['id'] == governorateId,
                orElse: () => <String, dynamic>{},
              );
              if (gov.isNotEmpty && gov['courts'] != null) {
                final courtsData = gov['courts'] as List?;
                setSheetState(() {
                  courts = (courtsData ?? [])
                      .map((e) => {'id': e['id'], 'name': e['name'] ?? e['court_name'] ?? ''})
                      .toList().cast<Map<String, dynamic>>();
                });
              } else {
                final apiService = Provider.of<ApiService>(ctx, listen: false);
                final dynamic response = await apiService.getCourts(queryParams: {'governorate': governorateId.toString()});
                final List results = _extractListFromApiResponse(response);
                setSheetState(() {
                  courts = results
                      .map((e) => {'id': e['id'], 'name': e['court_name'] ?? e['name'] ?? ''})
                      .toList().cast<Map<String, dynamic>>();
                });
              }
            } catch (_) {}
            finally { setSheetState(() => isLoadingCourts = false); }
          }

          Future<void> loadSubtypes(String caseType) async {
            final subs = await LocalLookupService.getSubtypes(caseType);
            setSheetState(() {
              subtypeOptions = subs;
              selectedCaseSubtype = null;
            });
          }

          if (!didInit) {
            didInit = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              loadGovernorates();
              loadSubtypes(selectedCaseType);
            });
          }

          // ── Helper for input decoration ──
          InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: const Color(0xFF1B5E3B), size: 20),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          );

          // ── Party add dialog ──
          void addParty(String role) {
            final nameCtrl = TextEditingController();
            final phoneCtrl = TextEditingController();
            final idCtrl = TextEditingController();
            final idFromCtrl = TextEditingController();
            final addressCtrl = TextEditingController();
            String entityType = 'person';

            showDialog(
              context: ctx,
              builder: (dCtx) => StatefulBuilder(
                builder: (dCtx, setDState) => AlertDialog(
                  title: Text(role == 'client' ? 'إضافة موكل (طرف أول)' : 'إضافة خصم (طرف ثاني)', textAlign: TextAlign.right),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('شخص'),
                                selected: entityType == 'person',
                                onSelected: (_) => setDState(() => entityType = 'person'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('مؤسسة'),
                                selected: entityType == 'organization',
                                onSelected: (_) => setDState(() => entityType = 'organization'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: nameCtrl, textDirection: ui.TextDirection.rtl, decoration: _inputDeco('الاسم *', Icons.person)),
                        const SizedBox(height: 10),
                        if (role == 'client')
                          TextField(controller: phoneCtrl, textDirection: ui.TextDirection.rtl, keyboardType: TextInputType.phone, decoration: _inputDeco('رقم الهاتف', Icons.phone)),
                        if (role == 'client') const SizedBox(height: 10),
                        TextField(controller: idCtrl, textDirection: ui.TextDirection.rtl, decoration: _inputDeco('رقم الهوية / السجل', Icons.badge)),
                        const SizedBox(height: 10),
                        TextField(controller: idFromCtrl, textDirection: ui.TextDirection.rtl, decoration: _inputDeco('جهة الإصدار', Icons.location_on)),
                        const SizedBox(height: 10),
                        TextField(controller: addressCtrl, textDirection: ui.TextDirection.rtl, decoration: _inputDeco('العنوان', Icons.home)),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final p = {
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'id_number': idCtrl.text.trim(),
                          'id_issued_from': idFromCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'entity_type': entityType,
                          'role': role,
                        };
                        setSheetState(() {
                          if (role == 'client') { clientParties.add(p); }
                          else { opponentParties.add(p); }
                        });
                        Navigator.pop(dCtx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E3B)),
                      child: const Text('إضافة', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget partyChip(Map<String, dynamic> p, String role, int idx) {
            final isOrg = p['entity_type'] == 'organization';
            return Chip(
              avatar: Icon(isOrg ? Icons.business : Icons.person, size: 18),
              label: Text(p['name'] ?? '', style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setSheetState(() {
                if (role == 'client') clientParties.removeAt(idx);
                else opponentParties.removeAt(idx);
              }),
            );
          }

          return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Handle bar ──
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                // ── Title ──
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFD4A940).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.create_new_folder_rounded, color: Color(0xFFD4A940), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إنشاء ملف قضية جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('أدخل بيانات القضية الأساسية', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  )),
                ]),
                const SizedBox(height: 24),

                // ── رقم القضية + سنة القضية (بجانب بعض) ──
                Row(children: [
                  Expanded(flex: 3, child: TextField(
                    controller: caseNumberController,
                    textDirection: ui.TextDirection.rtl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('رقم القضية', Icons.numbers_rounded),
                  )),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: DropdownButtonFormField<int>(
                    value: selectedCaseYear,
                    decoration: _inputDeco('السنة', Icons.event_rounded),
                    isExpanded: true,
                    menuMaxHeight: 300,
                    items: List.generate(1447 - 1400 + 1, (i) => 1447 - i)
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedCaseYear = v),
                  )),
                ]),
                const SizedBox(height: 14),

                // ── تاريخ الورود (ميلادي فقط) ──
                TextFormField(
                  readOnly: true,
                  decoration: _inputDeco('تاريخ الورود', Icons.calendar_today_rounded),
                  controller: TextEditingController(
                    text: filingDateGregorian != null ? DateFormat('yyyy-MM-dd').format(filingDateGregorian!) : '',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: filingDateGregorian ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setSheetState(() => filingDateGregorian = picked);
                  },
                ),
                const SizedBox(height: 14),

                // ── نوع القضية ──
                DropdownButtonFormField<String>(
                  value: selectedCaseType,
                  decoration: _inputDeco('نوع القضية', Icons.category_rounded),
                  items: LocalLookupService.caseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) {
                    setSheetState(() => selectedCaseType = v ?? 'مدنية');
                    loadSubtypes(v ?? 'مدنية');
                  },
                ),
                const SizedBox(height: 14),

                // ── النوع الفرعي ──
                if (subtypeOptions.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedCaseSubtype,
                    decoration: _inputDeco('النوع الفرعي', Icons.list_alt_rounded),
                    items: subtypeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setSheetState(() => selectedCaseSubtype = v),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── المحافظة ──
                if (isLoadingGovernorates)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))))
                else if (governorates.isEmpty)
                  SizedBox(height: 48, child: OutlinedButton.icon(
                    onPressed: loadGovernorates,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('تحميل المحافظات'),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ))
                else
                  DropdownButtonFormField<String>(
                    value: selectedGovernorateName,
                    decoration: _inputDeco('المحافظة', Icons.location_city_rounded),
                    items: governorates.where((g) => (g['name'] as String?)?.isNotEmpty ?? false)
                        .map((g) => DropdownMenuItem(value: g['name'] as String, child: Text(g['name'] as String))).toList(),
                    onChanged: (v) async {
                      setSheetState(() {
                        selectedGovernorateName = v;
                        final gov = governorates.firstWhere((g) => g['name'] == v, orElse: () => <String, dynamic>{});
                        selectedGovernorateId = gov['id'] as int?;
                        selectedCourtId = null;
                        courts = [];
                      });
                      if (selectedGovernorateId != null) await loadCourts(governorateId: selectedGovernorateId!);
                    },
                  ),
                const SizedBox(height: 14),

                // ── المحكمة ──
                isLoadingCourts
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))))
                    : DropdownButtonFormField<int>(
                        value: selectedCourtId,
                        decoration: _inputDeco('المحكمة', Icons.gavel_rounded),
                        items: courts.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name'] as String))).toList(),
                        onChanged: (v) => setSheetState(() => selectedCourtId = v),
                      ),
                const SizedBox(height: 14),

                // ── الحالة الراهنة ──
                DropdownButtonFormField<String>(
                  value: selectedCaseStatus,
                  decoration: _inputDeco('الحالة الراهنة', Icons.flag_rounded),
                  items: _caseStatuses.map((s) => DropdownMenuItem(value: s['value'] as String, child: Text(s['label'] as String))).toList(),
                  onChanged: (v) => setSheetState(() => selectedCaseStatus = v ?? 'جديد'),
                ),
                const SizedBox(height: 14),

                // ── موضوع القضية ──
                TextField(
                  controller: subjectController,
                  textDirection: ui.TextDirection.rtl,
                  maxLines: 2,
                  decoration: _inputDeco('موضوع القضية *', Icons.subject_rounded),
                ),
                const SizedBox(height: 20),

                // ── أطراف القضية ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('أطراف القضية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),

                      // الطرف الأول – الموكل
                      Row(children: [
                        const Expanded(child: Text('الطرف الأول (الموكل)', style: TextStyle(fontSize: 13, color: Color(0xFF1B5E3B), fontWeight: FontWeight.w600))),
                        IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF1B5E3B), size: 22), onPressed: () => addParty('client')),
                      ]),
                      if (clientParties.isNotEmpty)
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          for (var i = 0; i < clientParties.length; i++) partyChip(clientParties[i], 'client', i),
                        ]),
                      if (clientParties.isEmpty)
                        Text('لم يتم إضافة موكل بعد', style: TextStyle(fontSize: 12, color: Colors.grey[500])),

                      const Divider(height: 20),

                      // الطرف الثاني – الخصم
                      Row(children: [
                        const Expanded(child: Text('الطرف الثاني (الخصم)', style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600))),
                        IconButton(icon: const Icon(Icons.add_circle, color: Colors.red, size: 22), onPressed: () => addParty('opponent')),
                      ]),
                      if (opponentParties.isNotEmpty)
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          for (var i = 0; i < opponentParties.length; i++) partyChip(opponentParties[i], 'opponent', i),
                        ]),
                      if (opponentParties.isEmpty)
                        Text('لم يتم إضافة خصم بعد', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── زر الإنشاء ──
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isCreating ? null : () async {
                      final caseNumText = caseNumberController.text.trim();
                      if (caseNumText.isEmpty || int.tryParse(caseNumText) == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى إدخال رقم القضية (رقم صحيح)'), backgroundColor: Colors.red));
                        return;
                      }
                      if (selectedCaseYear == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى اختيار سنة القضية'), backgroundColor: Colors.red));
                        return;
                      }
                      if (subjectController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى إدخال موضوع القضية'), backgroundColor: Colors.red));
                        return;
                      }
                      if (selectedCourtId == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى اختيار المحكمة'), backgroundColor: Colors.red));
                        return;
                      }
                      if (subtypeOptions.isNotEmpty && (selectedCaseSubtype == null || selectedCaseSubtype!.isEmpty)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى اختيار النوع الفرعي'), backgroundColor: Colors.red));
                        return;
                      }

                      setSheetState(() => isCreating = true);

                      try {
                        final apiService = Provider.of<ApiService>(ctx, listen: false);
                        final caseNumber = caseNumberController.text.trim();

                        final newCase = CaseModel(
                          caseNumber: caseNumber,
                          subject: subjectController.text.trim(),
                          filingDate: filingDateGregorian ?? DateTime.now(),
                          gregorianDate: filingDateGregorian,
                          caseYearHijri: selectedCaseYear,
                          caseStatus: selectedCaseStatus,
                          caseType: selectedCaseType,
                          caseSubtype: selectedCaseSubtype,
                          governorate: selectedGovernorateName,
                          courtId: selectedCourtId,
                        );

                        final created = await apiService.createCase(newCase);

                        // Create parties linked to this case
                        final allParties = [...clientParties, ...opponentParties];
                        final List<String> generatedPasswords = [];

                        for (final p in allParties) {
                          final party = CasePartyModel(
                            caseId: created.id!,
                            role: p['role'],
                            entityType: p['entity_type'] ?? 'person',
                            name: p['name'],
                            phone: p['phone'],
                            idNumber: p['id_number'],
                            idIssuedFrom: p['id_issued_from'],
                            address: p['address'],
                          );
                          final createdParty = await apiService.createCaseParty(party);
                          if (createdParty.generatedPassword != null && createdParty.generatedPassword!.isNotEmpty) {
                            generatedPasswords.add('${createdParty.name}: ${createdParty.phone} / ${createdParty.generatedPassword}');
                          }
                        }

                        if (mounted) {
                          Navigator.of(ctx).pop();
                          final provider = Provider.of<LawsuitProvider>(outerContext, listen: false);
                          provider.loadLawsuits(refresh: true);
                          provider.loadCases(refresh: true);

                          // Show generated passwords if any
                          if (generatedPasswords.isNotEmpty) {
                            showDialog(
                              context: outerContext,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('حسابات الموكلين', textAlign: TextAlign.right),
                                content: SingleChildScrollView(child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('تم إنشاء حسابات تلقائية للموكلين:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ...generatedPasswords.map((s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(s, textDirection: ui.TextDirection.rtl, style: const TextStyle(fontSize: 13)),
                                    )),
                                    const SizedBox(height: 8),
                                    Text('احفظ هذه البيانات - لن تظهر مرة أخرى', style: TextStyle(color: Colors.red[700], fontSize: 12)),
                                  ],
                                )),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(dCtx);
                                      navigator.push(MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: created.id!)));
                                    },
                                    child: const Text('حسناً'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            navigator.push(MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: created.id!)));
                          }
                        }
                      } catch (e) {
                        setSheetState(() => isCreating = false);
                        if (mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    icon: isCreating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.folder_open_rounded),
                    label: Text(isCreating ? 'جارٍ الإنشاء...' : 'إنشاء ملف القضية'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A940),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  void _showArchiveDialog(LawsuitModel lawsuit) {
    final reasonController = TextEditingController();
    final isArchived = lawsuit.archiveStatus == 'archived';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isArchived ? 'استعادة من الأرشيف' : 'أرشفة الدعوى',
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isArchived
                  ? 'هل تريد استعادة الدعوى رقم ${lawsuit.caseNumber} من الأرشيف؟'
                  : 'هل تريد أرشفة الدعوى رقم ${lawsuit.caseNumber}؟',
              textAlign: TextAlign.right,
            ),
            if (!isArchived) ...[
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                textDirection: ui.TextDirection.rtl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'سبب الأرشفة (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<LawsuitProvider>(context, listen: false);
              if (isArchived) {
                await provider.unarchiveLawsuit(lawsuit.id!);
              } else {
                await provider.archiveLawsuit(
                  lawsuit.id!,
                  reason: reasonController.text.isNotEmpty ? reasonController.text : null,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isArchived ? Colors.green : const Color(0xFFD4A940),
              foregroundColor: Colors.white,
            ),
            child: Text(isArchived ? 'استعادة' : 'أرشفة'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDatabase(LawsuitProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تحديث الأرشيف؟'),
        content: const Text('سيتم تحميل بيانات القضايا من السيرفر.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.loadLawsuits(refresh: true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث البيانات بنجاح.'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('نعم، تحديث'),
          ),
        ],
      ),
    );
  }
}

/// Lawsuit Card for Archive List View
class _ArchiveLawsuitCard extends StatelessWidget {
  final LawsuitModel lawsuit;
  final VoidCallback? onArchive;

  const _ArchiveLawsuitCard({required this.lawsuit, this.onArchive});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: lawsuit.archiveStatus == 'archived'
              ? Colors.grey.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaseArchiveDetailsScreen(
                lawsuitId: lawsuit.id!,
                caseTitle: lawsuit.subject ?? 'بدون عنوان',
                caseNumber: lawsuit.caseNumber,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Top row: case number + archive badge + status
              Row(
                children: [
                  // Archive action
                  if (onArchive != null)
                    GestureDetector(
                      onTap: onArchive,
                      child: Icon(
                        lawsuit.archiveStatus == 'archived' ? Icons.unarchive : Icons.archive_outlined,
                        size: 20,
                        color: Colors.grey[500],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Sync indicator/button
                  if (!lawsuit.isSynced)
                    IconButton(
                      icon: const Icon(Icons.cloud_upload, color: Colors.orange, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Provider.of<LawsuitProvider>(context, listen: false).loadLawsuits(refresh: true);
                      },
                      tooltip: 'تحديث',
                    )
                  else
                    Icon(Icons.cloud_done, color: Colors.green.withOpacity(0.5), size: 16),
                  const SizedBox(width: 8),
                  // Status chip
                  _StatusBadge(status: lawsuit.caseStatus ?? lawsuit.status),
                  const Spacer(),
                  // Archive badge
                  if (lawsuit.archiveStatus != 'active')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: lawsuit.archiveStatus == 'archived'
                            ? Colors.grey.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lawsuit.archiveStatusDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          color: lawsuit.archiveStatus == 'archived' ? Colors.grey[700] : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // Case number
                  Text(
                    lawsuit.caseNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2138),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Subject
              if (lawsuit.subject != null && lawsuit.subject!.isNotEmpty)
                Text(
                  lawsuit.subject!,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              // Bottom row: type + date + counts
              Row(
                children: [
                  // Counts
                  if (lawsuit.attachmentsCount > 0)
                    _CountBadge(icon: Icons.attach_file, count: lawsuit.attachmentsCount),
                  if (lawsuit.hearingsCount > 0)
                    _CountBadge(icon: Icons.event, count: lawsuit.hearingsCount),
                  if (lawsuit.plaintiffsCount > 0 || lawsuit.defendantsCount > 0)
                    _CountBadge(
                      icon: Icons.people,
                      count: lawsuit.plaintiffsCount + lawsuit.defendantsCount,
                    ),
                  const Spacer(),
                  // Date
                  if (lawsuit.filingDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('yyyy/MM/dd').format(lawsuit.filingDate!),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                      ],
                    ),
                  const SizedBox(width: 12),
                  // Case type
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A940).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lawsuit.caseTypeDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD4A940),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid card for archive
class _ArchiveGridCard extends StatelessWidget {
  final LawsuitModel lawsuit;

  const _ArchiveGridCard({required this.lawsuit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaseArchiveDetailsScreen(
                lawsuitId: lawsuit.id!,
                caseTitle: lawsuit.subject ?? 'ملف قضية',
                caseNumber: lawsuit.caseNumber,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Archive badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusBadge(status: lawsuit.caseStatus ?? lawsuit.status),
                  Icon(
                    lawsuit.archiveStatus == 'archived' ? Icons.archive : Icons.folder_open,
                    color: lawsuit.archiveStatus == 'archived' ? Colors.grey : Colors.green,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lawsuit.caseNumber,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                lawsuit.caseTypeDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              ),
              if (lawsuit.subject != null) ...[
                const SizedBox(height: 6),
                Text(
                  lawsuit.subject!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              if (lawsuit.filingDate != null)
                Text(
                  DateFormat('yyyy/MM/dd').format(lawsuit.filingDate!),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  textAlign: TextAlign.right,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status ?? '') {
      case 'new': case 'جديد': return Colors.blue;
      case 'pending': case 'قيد الانتظار': return Colors.orange;
      case 'in_progress': case 'قيد_النظر': return Colors.blue;
      case 'completed': case 'مكتمل': return Colors.green;
      case 'appealed': case 'مستأنف': return Colors.purple;
      case 'closed': case 'مغلق': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String get _text {
    switch (status ?? '') {
      case 'new': case 'جديد': return 'جديد';
      case 'pending': case 'قيد الانتظار': return 'قيد الانتظار';
      case 'in_progress': case 'قيد_النظر': return 'قيد النظر';
      case 'completed': case 'مكتمل': return 'مكتمل';
      case 'appealed': case 'مستأنف': return 'مستأنف';
      case 'closed': case 'مغلق': return 'مغلق';
      default: return (status ?? '').isNotEmpty ? status! : '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _text,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Small count badge
class _CountBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  const _CountBadge({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(width: 2),
          Icon(icon, size: 14, color: Colors.grey[500]),
        ],
      ),
    );
  }
}

/// Filter Bottom Sheet
class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCaseType;
  final String? selectedCaseStatus;
  final String? selectedArchiveStatus;
  final String? selectedOrdering;
  final void Function(String?, String?, String?, String?) onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    this.selectedCaseType,
    this.selectedCaseStatus,
    this.selectedArchiveStatus,
    this.selectedOrdering,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _caseType;
  String? _caseStatus;
  String? _archiveStatus;
  String? _ordering;

  static const _caseTypes = [
    {'value': 'دعوى', 'label': 'دعوى'},
    {'value': 'امر_اداء', 'label': 'أمر أداء'},
    {'value': 'رد_على_دعوى', 'label': 'رد على دعوى'},
    {'value': 'استئناف', 'label': 'استئناف'},
    {'value': 'طعن', 'label': 'طعن'},
    {'value': 'civil', 'label': 'مدني'},
    {'value': 'criminal', 'label': 'جنائي'},
    {'value': 'commercial', 'label': 'تجاري'},
    {'value': 'personal_status', 'label': 'أحوال شخصية'},
    {'value': 'labor', 'label': 'عمالي'},
    {'value': 'administrative', 'label': 'إداري'},
  ];

  static const _caseStatuses = [
    {'value': 'جديد', 'label': 'جديد'},
    {'value': 'قيد_النظر', 'label': 'قيد النظر'},
    {'value': 'مكتمل', 'label': 'مكتمل'},
    {'value': 'مغلق', 'label': 'مغلق'},
  ];

  static const _archiveStatuses = [
    {'value': 'active', 'label': 'نشط', 'icon': Icons.folder_open, 'color': Colors.green},
    {'value': 'semi_active', 'label': 'شبه نشط', 'icon': Icons.folder_shared, 'color': Colors.orange},
    {'value': 'archived', 'label': 'محفوظ', 'icon': Icons.archive, 'color': Colors.grey},
  ];

  static const _orderingOptions = [
    {'value': '-created_at', 'label': 'الأحدث أولاً'},
    {'value': 'created_at', 'label': 'الأقدم أولاً'},
    {'value': '-filing_date', 'label': 'تاريخ الرفع (الأحدث)'},
    {'value': 'filing_date', 'label': 'تاريخ الرفع (الأقدم)'},
    {'value': 'case_number', 'label': 'رقم الدعوى'},
    {'value': '-updated_at', 'label': 'آخر تحديث'},
  ];

  @override
  void initState() {
    super.initState();
    _caseType = widget.selectedCaseType;
    _caseStatus = widget.selectedCaseStatus;
    _archiveStatus = widget.selectedArchiveStatus;
    _ordering = widget.selectedOrdering;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onClear();
                  },
                  child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
                ),
                const Text(
                  'فلترة متقدمة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filters - Scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDropdown(
                    label: 'نوع القضية',
                    value: _caseType,
                    items: _caseTypes.map((t) => DropdownMenuItem(
                      value: t['value'] as String,
                      child: Text(t['label'] as String),
                    )).toList(),
                    onChanged: (v) => setState(() => _caseType = v),
                  ),
                  const SizedBox(height: 14),
                  _buildDropdown(
                    label: 'حالة القضية',
                    value: _caseStatus,
                    items: _caseStatuses.map((s) => DropdownMenuItem(
                      value: s['value'] as String,
                      child: Text(s['label'] as String),
                    )).toList(),
                    onChanged: (v) => setState(() => _caseStatus = v),
                  ),
                  const SizedBox(height: 14),
                  _buildDropdown(
                    label: 'حالة الأرشفة',
                    value: _archiveStatus,
                    items: _archiveStatuses.map((a) => DropdownMenuItem(
                      value: a['value'] as String,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a['icon'] as IconData, size: 18, color: a['color'] as Color),
                          const SizedBox(width: 8),
                          Text(a['label'] as String),
                        ],
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() => _archiveStatus = v),
                  ),
                  const SizedBox(height: 14),
                  _buildDropdown(
                    label: 'الترتيب',
                    value: _ordering,
                    items: _orderingOptions.map((o) => DropdownMenuItem(
                      value: o['value'] as String,
                      child: Text(o['label'] as String),
                    )).toList(),
                    onChanged: (v) => setState(() => _ordering = v),
                  ),
                ],
              ),
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApply(_caseType, _caseStatus, _archiveStatus, _ordering);
                  },
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('تطبيق الفلترة', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A940),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      isExpanded: true,
    );
  }
}
