import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lawyer_provider.dart';
import '../models/lawyer_model.dart';
import 'lawyer_details_screen.dart';
import 'dart:async';

class LawyersSearchScreen extends StatefulWidget {
  const LawyersSearchScreen({super.key});

  @override
  State<LawyersSearchScreen> createState() => _LawyersSearchScreenState();
}

class _LawyersSearchScreenState extends State<LawyersSearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedBranch;
  String? _selectedGrade;
  Timer? _debounce;

  final List<int> _pageSizes = [10, 20, 30, 40, 50];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LawyerProvider>(context, listen: false);
      provider.loadFilterOptions();
      provider.loadLawyers(refresh: true);
    });
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<LawyerProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadLawyers();
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void _performSearch() {
    final provider = Provider.of<LawyerProvider>(context, listen: false);
    provider.setSearchQuery(_searchController.text);
    provider.setBranchFilter(_selectedBranch);
    provider.setGradeFilter(_selectedGrade);
    provider.loadLawyers(refresh: true);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedBranch = null;
      _selectedGrade = null;
    });
    Provider.of<LawyerProvider>(context, listen: false).clearFilters();
    Provider.of<LawyerProvider>(context, listen: false).loadLawyers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('البحث عن المحامين'),
        actions: [
          if (Provider.of<LawyerProvider>(context).hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'مسح الفلاتر',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          _buildPageSizeSelector(),
          Expanded(
            child: Consumer<LawyerProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.lawyers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.lawyers.isEmpty) {
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
                        ElevatedButton(
                          onPressed: _performSearch,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.lawyers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد نتائج',
                          style: TextStyle(color: Colors.grey[600], fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadLawyers(refresh: true),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          itemCount: provider.lawyers.length + (provider.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.lawyers.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final lawyer = provider.lawyers[index];
                            return _LawyerCard(lawyer: lawyer);
                          },
                        ),
                      ),
                      _buildPaginationInfo(provider),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو رقم القيد...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageSizeSelector() {
    return Consumer<LawyerProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عدد النتائج: ${provider.totalCount}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Row(
                children: [
                  Text(
                    'حجم الصفحة:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: provider.pageSize,
                    underline: const SizedBox.shrink(),
                    items: _pageSizes.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(size.toString()),
                      );
                    }).toList(),
                    onChanged: (size) {
                      if (size != null) {
                        provider.setPageSize(size);
                        provider.loadLawyers(refresh: true);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Consumer<LawyerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingFilters) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use SingleChildScrollView for small screens
              if (constraints.maxWidth < 600) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * 0.45,
                        child: _buildFilterDropdown(
                          label: 'الفرع',
                          value: _selectedBranch,
                          items: provider.availableBranches,
                          onChanged: (value) {
                            setState(() {
                              _selectedBranch = value;
                            });
                            _performSearch();
                          },
                          icon: Icons.business,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: constraints.maxWidth * 0.45,
                        child: _buildFilterDropdown(
                          label: 'الدرجة',
                          value: _selectedGrade,
                          items: provider.availableGrades,
                          onChanged: (value) {
                            setState(() {
                              _selectedGrade = value;
                            });
                            _performSearch();
                          },
                          icon: Icons.workspace_premium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          provider.loadFilterOptions(forceRefresh: true);
                        },
                        tooltip: 'تحديث الفلاتر من السيرفر',
                      ),
                    ],
                  ),
                );
              }
              
              // Use normal Row for larger screens
              return Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      label: 'الفرع',
                      value: _selectedBranch,
                      items: provider.availableBranches,
                      onChanged: (value) {
                        setState(() {
                          _selectedBranch = value;
                        });
                        _performSearch();
                      },
                      icon: Icons.business,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterDropdown(
                      label: 'الدرجة',
                      value: _selectedGrade,
                      items: provider.availableGrades,
                      onChanged: (value) {
                        setState(() {
                          _selectedGrade = value;
                        });
                        _performSearch();
                      },
                      icon: Icons.workspace_premium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      provider.loadFilterOptions(forceRefresh: true);
                    },
                    tooltip: 'تحديث الفلاتر من السيرفر',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPaginationInfo(LawyerProvider provider) {
    final start = (provider.lawyers.length > 0) ? 1 : 0;
    final end = provider.lawyers.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'عرض $start - $end من ${provider.totalCount}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (!provider.hasMore && provider.lawyers.isNotEmpty)
            const Text(
              'نهاية النتائج',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final LawyerModel lawyer;

  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LawyerDetailsScreen(lawyer: lawyer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lawyer.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      lawyer.gradeDisplay,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(context, Icons.badge, 'رقم القيد:', lawyer.registrationNumber),
              if (lawyer.branch != null && lawyer.branch!.isNotEmpty)
                _buildInfoRow(context, Icons.business, 'الفرع:', lawyer.branch!),
              if (lawyer.phone != null && lawyer.phone!.isNotEmpty)
                _buildInfoRow(context, Icons.phone, 'الهاتف:', lawyer.phone!, isPhone: true),
              if (lawyer.governorate != null)
                _buildInfoRow(context, Icons.location_on, 'العنوان:', lawyer.fullAddress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isPhone ? Theme.of(context).colorScheme.primary : Colors.grey[800],
                fontWeight: isPhone ? FontWeight.w500 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: isPhone ? null : 1,
            ),
          ),
        ],
      ),
    );
  }
}
