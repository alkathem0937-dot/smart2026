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
  bool _showFilters = false;
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
    setState(() => _showFilters = false);
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
    return Scaffold(
      body: Column(
        children: [
          // Header with search
          _buildHeader(),
          // Stats bar
          _buildStatsBar(),
          // Tabs
          _buildTabs(),
          // Filter chips
          _buildActiveFilterChips(),
          // Filter panel (expandable)
          if (_showFilters) _buildFilterPanel(),
          // Results list
          Expanded(child: _buildResultsList()),
        ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
        children: [
          // Title row
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
                          _showFilters ? Icons.filter_list_off : Icons.filter_list,
                          color: provider.hasActiveFilters ? const Color(0xFFE91E63) : Colors.grey[600],
                        ),
                        onPressed: () => setState(() => _showFilters = !_showFilters),
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
              const Expanded(
                child: Text(
                  'أرشيف القضايا',
                  style: TextStyle(
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
          const SizedBox(height: 8),
          // Search bar
          TextField(
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _applySearch(),
            onChanged: (value) => setState(() {}),
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

        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildStatChip('الكل', total, const Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              _buildStatChip('نشط', active, Colors.green),
              const SizedBox(width: 8),
              _buildStatChip('محفوظ', archived, Colors.grey),
              const SizedBox(width: 8),
              _buildStatChip('النتائج', provider.totalCount, const Color(0xFFE91E63)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, dynamic count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      backgroundColor: const Color(0xFFE91E63).withOpacity(0.08),
      deleteIconColor: const Color(0xFFE91E63),
      side: BorderSide(color: const Color(0xFFE91E63).withOpacity(0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'فلترة متقدمة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          // Case type filter
          _buildFilterDropdown(
            label: 'نوع القضية',
            value: _selectedCaseType,
            items: _caseTypes.map((t) => DropdownMenuItem(
              value: t['value'] as String,
              child: Text(t['label'] as String),
            )).toList(),
            onChanged: (v) => setState(() => _selectedCaseType = v),
          ),
          const SizedBox(height: 10),
          // Case status filter
          _buildFilterDropdown(
            label: 'حالة القضية',
            value: _selectedCaseStatus,
            items: _caseStatuses.map((s) => DropdownMenuItem(
              value: s['value'] as String,
              child: Text(s['label'] as String),
            )).toList(),
            onChanged: (v) => setState(() => _selectedCaseStatus = v),
          ),
          const SizedBox(height: 10),
          // Archive status
          _buildFilterDropdown(
            label: 'حالة الأرشفة',
            value: _selectedArchiveStatus,
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
            onChanged: (v) => setState(() => _selectedArchiveStatus = v),
          ),
          const SizedBox(height: 10),
          // Ordering
          _buildFilterDropdown(
            label: 'الترتيب',
            value: _selectedOrdering,
            items: _orderingOptions.map((o) => DropdownMenuItem(
              value: o['value'] as String,
              child: Text(o['label'] as String),
            )).toList(),
            onChanged: (v) => setState(() => _selectedOrdering = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('مسح الكل'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('تطبيق الفلترة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      isExpanded: true,
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
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
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
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
