import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/lawsuit_provider.dart';
import '../models/lawsuit_model.dart';
import 'lawsuit_detail_screen.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
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
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE91E63),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LawsuitDetailScreen()),
          ).then((_) {
            Provider.of<LawsuitProvider>(context, listen: false).loadLawsuits(refresh: true);
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader({bool isKeyboardVisible = false}) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: isKeyboardVisible ? 80 : double.infinity,
      ),
      padding: EdgeInsets.fromLTRB(16, isKeyboardVisible ? 4 : 8, 16, isKeyboardVisible ? 4 : 8),
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
                            color: provider.hasActiveFilters ? const Color(0xFFE91E63) : Colors.grey[600],
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
                                color: Color(0xFFE91E63),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                Expanded(
                  child: Text(
                    'أرشيف القضايا',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.archive_outlined, color: Color(0xFFE91E63), size: 28),
              ],
            ),
          if (!isKeyboardVisible) const SizedBox(height: 8),
          // Search bar with compact controls when keyboard is visible
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle view (shown when keyboard is visible)
              if (isKeyboardVisible)
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, 
                    color: Colors.grey[600], size: 20),
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
                            color: provider.hasActiveFilters ? const Color(0xFFE91E63) : Colors.grey[600],
                            size: 20,
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
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE91E63),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              if (isKeyboardVisible) const SizedBox(width: 4),
              // Search bar
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textDirection: ui.TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث برقم الدعوى، الموضوع، الأطراف...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFFE91E63)),
                      onPressed: _applySearch,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _applySearch();
                          },
                        )
                      : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: isKeyboardVisible ? 10 : 12,
                    ),
                    isDense: isKeyboardVisible,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildStatChip('الكل', total, const Color(0xFF1A1A1A)),
                const SizedBox(width: 6),
                _buildStatChip('نشط', active, Colors.green),
                const SizedBox(width: 6),
                _buildStatChip('محفوظ', archived, Colors.grey),
                const SizedBox(width: 6),
                _buildStatChip('النتائج', provider.totalCount, const Color(0xFFE91E63)),
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
        indicatorColor: const Color(0xFFE91E63),
        labelColor: const Color(0xFFE91E63),
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
          constraints: const BoxConstraints(maxHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: chips.map((c) => Padding(padding: const EdgeInsets.only(left: 6), child: c)).toList(),
            ),
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
      backgroundColor: const Color(0xFFE91E63).withOpacity(0.08),
      deleteIconColor: const Color(0xFFE91E63),
      side: BorderSide(color: const Color(0xFFE91E63).withOpacity(0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildResultsList() {
    return Consumer<LawsuitProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.lawsuits.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        }

        if (provider.errorMessage != null && provider.lawsuits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage ?? 'حدث خطأ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[300]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.loadLawsuits(refresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
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
                const SizedBox(height: 16),
                Text(
                  provider.hasActiveFilters ? 'لا توجد نتائج مطابقة' : 'الأرشيف فارغ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.hasActiveFilters
                      ? 'جرّب تغيير معايير البحث أو الفلترة'
                      : 'اضغط + لإضافة دعوى جديدة',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                if (provider.hasActiveFilters) ...[
                  const SizedBox(height: 16),
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
          color: const Color(0xFFE91E63),
          onRefresh: () async {
            await provider.loadLawsuits(refresh: true);
            await provider.loadArchiveStats();
          },
          child: _isGridView ? _buildGridView(provider) : _buildListView(provider),
        );
      },
    );
  }

  Widget _buildListView(LawsuitProvider provider) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = keyboardHeight > 0 ? 16.0 : 80.0;
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomPadding),
      shrinkWrap: false,
      itemCount: provider.lawsuits.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.lawsuits.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            ),
          );
        }
        return _ArchiveLawsuitCard(
          lawsuit: provider.lawsuits[index],
          onArchive: () => _showArchiveDialog(provider.lawsuits[index]),
        );
      },
    );
  }

  Widget _buildGridView(LawsuitProvider provider) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = keyboardHeight > 0 ? 16.0 : 80.0;
    
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomPadding),
      shrinkWrap: false,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: provider.lawsuits.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.lawsuits.length) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        }
        return _ArchiveGridCard(lawsuit: provider.lawsuits[index]);
      },
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
              const SizedBox(height: 16),
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
              backgroundColor: isArchived ? Colors.green : const Color(0xFFE91E63),
              foregroundColor: Colors.white,
            ),
            child: Text(isArchived ? 'استعادة' : 'أرشفة'),
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
              builder: (context) => LawsuitDetailScreen(lawsuitId: lawsuit.id!),
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
                      color: Color(0xFF1A1A1A),
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
                      color: const Color(0xFFE91E63).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lawsuit.caseTypeDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE91E63),
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
              builder: (context) => LawsuitDetailScreen(lawsuitId: lawsuit.id!),
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
                    backgroundColor: const Color(0xFFE91E63),
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
