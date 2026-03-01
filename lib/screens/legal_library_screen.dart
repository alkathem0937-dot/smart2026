import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

/// Legal Library Screen - المكتبة القانونية مع Full-Text Search
class LegalLibraryScreen extends StatefulWidget {
  const LegalLibraryScreen({super.key});

  @override
  State<LegalLibraryScreen> createState() => _LegalLibraryScreenState();
}

class _LegalLibraryScreenState extends State<LegalLibraryScreen> {
  late ApiService _apiService;
  bool _isLoading = false;
  bool _isLoadingSources = false;
  bool _isLoadingBooks = false;
  bool _isLoadingChapters = false;
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _chapters = [];
  
  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSource;
  String? _selectedBook;
  String? _selectedChapter;
  
  // Pagination
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMore = true;
  
  // Stats
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService = Provider.of<AuthProvider>(context, listen: false).apiService;
      _loadSources();
      _loadBooks();
      _loadChapters();
      _loadStats();
      _searchArticles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSources() async {
    setState(() => _isLoadingSources = true);
    try {
      final response = await _apiService.getLegalLibrarySources();
      // Handle nested response: {success: true, data: {sources: [...]}}
      final data = response['data'] ?? response;
      if (data['sources'] != null) {
        setState(() {
          _sources = List<Map<String, dynamic>>.from(data['sources']);
        });
      }
    } catch (e) {
      developer.log('Error loading sources: $e', name: 'LegalLibraryScreen');
    } finally {
      setState(() => _isLoadingSources = false);
    }
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoadingBooks = true);
    try {
      final response = await _apiService.getLegalLibraryBooks(source: _selectedSource);
      final data = response['data'] ?? response;
      if (data['books'] != null) {
        setState(() {
          _books = List<Map<String, dynamic>>.from(data['books']);
        });
      }
    } catch (e) {
      developer.log('Error loading books: $e', name: 'LegalLibraryScreen');
    } finally {
      setState(() => _isLoadingBooks = false);
    }
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoadingChapters = true);
    try {
      final response = await _apiService.getLegalLibraryChapters(
        source: _selectedSource,
        book: _selectedBook,
      );
      final data = response['data'] ?? response;
      if (data['chapters'] != null) {
        setState(() {
          _chapters = List<Map<String, dynamic>>.from(data['chapters']);
        });
      }
    } catch (e) {
      developer.log('Error loading chapters: $e', name: 'LegalLibraryScreen');
    } finally {
      setState(() => _isLoadingChapters = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final response = await _apiService.getLegalLibraryStats();
      // Handle nested response
      final data = response['data'] ?? response;
      setState(() => _stats = data);
    } catch (e) {
      developer.log('Error loading stats: $e', name: 'LegalLibraryScreen');
    }
  }

  Future<void> _searchArticles({bool loadMore = false}) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getLegalLibrary(
        searchQuery: _searchController.text.trim(),
        source: _selectedSource,
        book: _selectedBook,
        chapter: _selectedChapter,
        page: loadMore ? _currentPage + 1 : 1,
      );
      
      // Handle nested response structure: {success: true, data: {count, results}}
      final data = response['data'] ?? response;
      final results = data['results'] as List?;
      final count = data['count'] as int? ?? 0;
      
      developer.log('Parsed results count: ${results?.length ?? 0}, total: $count', name: 'LegalLibraryScreen');
      
      setState(() {
        if (loadMore) {
          _articles.addAll(List<Map<String, dynamic>>.from(results ?? []));
          _currentPage++;
        } else {
          _articles = List<Map<String, dynamic>>.from(results ?? []);
          _currentPage = 1;
        }
        _totalCount = count;
        _hasMore = _articles.length < _totalCount;
      });
    } catch (e) {
      developer.log('Error searching articles: $e', name: 'LegalLibraryScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في البحث: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSource = null;
      _selectedBook = null;
      _selectedChapter = null;
    });
    _searchArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('المكتبة القانونية', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'فلترة',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _showStatsDialog(context),
            tooltip: 'إحصائيات',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Detect keyboard by available height (compact when < 400)
          final isCompact = constraints.maxHeight < 400;

          return Column(
            children: [
              // Search Header
              Container(
                padding: EdgeInsets.fromLTRB(16, isCompact ? 8 : 16, 16, isCompact ? 8 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: isCompact ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar - always visible
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'ابحث في نص المادة أو رقمها...',
                          hintStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchArticles();
                                  },
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                                  onPressed: () => _searchArticles(),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _searchArticles(),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    // Hide extra elements when keyboard is visible (compact mode)
                    if (!isCompact) ...[
                      const SizedBox(height: 8),
                      // Search Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _searchArticles(),
                          icon: const Icon(Icons.search),
                          label: const Text('بحث', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Browser Options
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showSourcesBrowser(context),
                              icon: const Icon(Icons.account_balance),
                              label: const Text('تصفح المصادر القانونية', style: TextStyle(fontFamily: 'Cairo')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Active Filters
                      if (_selectedSource != null || _selectedBook != null || _selectedChapter != null)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_selectedSource != null)
                                _buildFilterChip(_selectedSource!, () {
                                  setState(() => _selectedSource = null);
                                  _searchArticles();
                                }),
                              if (_selectedBook != null)
                                _buildFilterChip(_selectedBook!, () {
                                  setState(() => _selectedBook = null);
                                  _searchArticles();
                                }),
                              if (_selectedChapter != null)
                                _buildFilterChip(_selectedChapter!, () {
                                  setState(() => _selectedChapter = null);
                                  _searchArticles();
                                }),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.clear_all, color: Colors.white70, size: 18),
                                label: const Text('مسح الكل', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
                              ),
                            ],
                          ),
                        ),
                      // Results Count
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'عدد النتائج: $_totalCount مادة',
                          style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Results List
              Expanded(
                child: _isLoading && _articles.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _articles.isEmpty
                        ? _buildEmptyState()
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollEndNotification &&
                                  notification.metrics.extentAfter < 200 &&
                                  _hasMore &&
                                  !_isLoading) {
                                _searchArticles(loadMore: true);
                              }
                              return false;
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _articles.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _articles.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _buildArticleCard(_articles[index]);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label.length > 20 ? '${label.substring(0, 20)}...' : label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.white24,
        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
        onDeleted: onRemove,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب البحث بكلمات مختلفة أو قم بإزالة بعض الفلاتر',
            style: TextStyle(color: Colors.grey[500], fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showArticleDetails(article),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'مادة ${article['article_number'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 8),
              // Source Info
              Text(
                article['source_title'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF424242),
                  fontFamily: 'Cairo',
                ),
              ),
              if (article['chapter_title'] != null && article['chapter_title'].toString().isNotEmpty)
                Text(
                  article['chapter_title'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Cairo'),
                ),
              const SizedBox(height: 8),
              // Article Text Preview
              Text(
                article['article_text_preview'] ?? article['article_text'] ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], height: 1.5, fontFamily: 'Cairo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArticleDetails(Map<String, dynamic> article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArticleDetailsSheet(
        article: article,
        apiService: _apiService,
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'فلترة النتائج',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('مسح الكل', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'اختر المصدر القانوني',
                style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 8),
              _isLoadingSources
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedSource,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      hint: const Text('جميع المصادر', style: TextStyle(fontFamily: 'Cairo')),
                      isExpanded: true,
                      items: _sources.map<DropdownMenuItem<String>>((source) {
                        final title = source['source_title']?.toString() ?? '';
                        final count = source['articles_count'] ?? 0;
                        return DropdownMenuItem<String>(
                          value: title,
                          child: Text(
                            '$title ($count)',
                            style: const TextStyle(fontFamily: 'Cairo'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        // Update Source
                        setSheetState(() => _selectedSource = value);
                        setState(() => _selectedSource = value);
                        
                        // Reset dependent filters
                        setSheetState(() {
                          _selectedBook = null;
                          _selectedChapter = null;
                        });
                        setState(() {
                          _selectedBook = null;
                          _selectedChapter = null;
                        });

                        // Loading Indicators
                        setSheetState(() {
                          _isLoadingBooks = true;
                          _isLoadingChapters = true;
                        });

                        // Reload Books and Chapters
                        await Future.wait([_loadBooks(), _loadChapters()]);
                        
                        // Refresh sheet
                        if (context.mounted) {
                          setSheetState(() {
                            _isLoadingBooks = false;
                            _isLoadingChapters = false;
                          });
                        }
                      },
                    ),
              const SizedBox(height: 16),
              
              // Books Filter
              const Text(
                'اختر الكتاب',
                style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 8),
              _isLoadingBooks
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedBook,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      hint: const Text('جميع الكتب', style: TextStyle(fontFamily: 'Cairo')),
                      isExpanded: true,
                      items: _books.map<DropdownMenuItem<String>>((book) {
                        final title = book['book_title']?.toString() ?? '';
                        final count = book['articles_count'] ?? 0;
                        return DropdownMenuItem<String>(
                          value: title,
                          child: Text(
                            '$title ($count)',
                            style: const TextStyle(fontFamily: 'Cairo'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setSheetState(() => _selectedBook = value);
                        setState(() => _selectedBook = value);

                         // Reset dependent filters
                        setSheetState(() {
                          _selectedChapter = null;
                        });
                        setState(() {
                          _selectedChapter = null;
                        });

                        // Reload Chapters
                         setSheetState(() {
                          _isLoadingChapters = true;
                        });
                        
                        await _loadChapters();
                        
                         if (context.mounted) {
                          setSheetState(() {
                            _isLoadingChapters = false;
                          });
                        }
                      },
                    ),
              const SizedBox(height: 16),

              // Chapters Filter
              const Text(
                'اختر الفصل/الباب',
                style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 8),
              _isLoadingChapters
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedChapter,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      hint: const Text('جميع الفصول', style: TextStyle(fontFamily: 'Cairo')),
                      isExpanded: true,
                      items: _chapters.map<DropdownMenuItem<String>>((chapter) {
                        final title = chapter['chapter_title']?.toString() ?? '';
                        final count = chapter['articles_count'] ?? 0;
                        return DropdownMenuItem<String>(
                          value: title,
                          child: Text(
                            '$title ($count)',
                            style: const TextStyle(fontFamily: 'Cairo'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setSheetState(() => _selectedChapter = value);
                        setState(() => _selectedChapter = value);
                      },
                    ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _searchArticles();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'تطبيق الفلتر',
                    style: TextStyle(fontSize: 16, fontFamily: 'Cairo', color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSourcesBrowser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, color: Color(0xFF1A237E)),
                    const SizedBox(width: 12),
                    const Text(
                      'المصادر القانونية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: _isLoadingSources
                    ? const Center(child: CircularProgressIndicator())
                    : _sources.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد مصادر متاحة',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _sources.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final source = _sources[index];
                              final title = source['source_title']?.toString() ?? '';
                              final count = source['articles_count'] ?? 0;
                              final isSelected = _selectedSource == title;
                              
                              return ListTile(
                                onTap: () {
                                  setState(() {
                                    _selectedSource = title;
                                    _selectedBook = null;
                                    _selectedChapter = null;
                                  });
                                  Navigator.pop(context);
                                  // Reload books and chapters based on new source
                                  _loadBooks();
                                  _loadChapters();
                                  _searchArticles(); 
                                },
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF1A237E) : Colors.black87,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$count مادة',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_circle, color: Color(0xFF1A237E)),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.bar_chart, color: Color(0xFF1A237E)),
            const SizedBox(width: 8),
            const Text('إحصائيات المكتبة', style: TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        content: _stats == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatCard(
                    'إجمالي المواد',
                    '${_stats!['total_articles'] ?? 0}',
                    Icons.article,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'عدد المصادر',
                    '${_stats!['total_sources'] ?? 0}',
                    Icons.source,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'أكبر المصادر',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 8),
                  ...(_stats!['top_sources'] as List? ?? []).take(5).map((source) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            source['source_title'] ?? '',
                            style: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${source['count']} مادة',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A237E), size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Cairo'),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF1A237E),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget to show article details with full text fetched from API
class _ArticleDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> article;
  final ApiService apiService;

  const _ArticleDetailsSheet({
    required this.article,
    required this.apiService,
  });

  @override
  State<_ArticleDetailsSheet> createState() => _ArticleDetailsSheetState();
}

class _ArticleDetailsSheetState extends State<_ArticleDetailsSheet> {
  Map<String, dynamic>? _fullArticle;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFullArticle();
  }

  Future<void> _loadFullArticle() async {
    try {
      final articleId = widget.article['id'];
      if (articleId != null) {
        final response = await widget.apiService.getLegalArticle(articleId);
        final data = response['data'] ?? response;
        setState(() {
          _fullArticle = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _fullArticle = widget.article;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _fullArticle = widget.article;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = _fullArticle ?? widget.article;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'مادة ${article['article_number'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      // Copy to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ النص')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('المصدر', article['source_title']),
                          if (article['book_title'] != null && article['book_title'].toString().isNotEmpty)
                            _buildDetailRow('الكتاب', article['book_title']),
                          if (article['section_title'] != null && article['section_title'].toString().isNotEmpty)
                            _buildDetailRow('القسم', article['section_title']),
                          if (article['chapter_title'] != null && article['chapter_title'].toString().isNotEmpty)
                            _buildDetailRow('الفصل', article['chapter_title']),
                          if (article['branch_title'] != null && article['branch_title'].toString().isNotEmpty)
                            _buildDetailRow('الفرع', article['branch_title']),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'نص المادة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A237E),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: SelectableText(
                              article['article_text'] ?? 'لا يتوفر نص المادة',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 2,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
