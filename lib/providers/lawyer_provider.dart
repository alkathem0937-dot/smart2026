import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/lawyer_model.dart';
import 'dart:convert';

class LawyerProvider with ChangeNotifier {
  final ApiService _apiService;
  
  LawyerProvider({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  List<LawyerModel> _lawyers = [];
  LawyerModel? _selectedLawyer;
  bool _isLoading = false;
  String? _errorMessage;
  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 20;
  bool _hasMore = true;

  // Current filters
  String? _searchQuery;
  String? _branchFilter;
  String? _gradeFilter;

  // Available filter options
  List<String> _availableBranches = [];
  List<String> _availableGrades = [];
  bool _isLoadingFilters = false;
  bool _useLocalCache = true;

  List<LawyerModel> get lawyers => _lawyers;
  LawyerModel? get selectedLawyer => _selectedLawyer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;

  List<String> get availableBranches => _availableBranches;
  List<String> get availableGrades => _availableGrades;
  bool get isLoadingFilters => _isLoadingFilters;
  int get pageSize => _pageSize;
  bool get useLocalCache => _useLocalCache;

  void setUseLocalCache(bool value) {
    _useLocalCache = value;
    notifyListeners();
  }

  void setPageSize(int size) {
    _pageSize = size;
    notifyListeners();
  }

  // Filter getters
  String? get searchQuery => _searchQuery;
  String? get branchFilter => _branchFilter;
  String? get gradeFilter => _gradeFilter;

  bool get hasActiveFilters =>
      (_searchQuery != null && _searchQuery!.isNotEmpty) ||
      _branchFilter != null ||
      _gradeFilter != null;

  // Set filters
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setBranchFilter(String? branch) {
    _branchFilter = branch;
    notifyListeners();
  }

  void setGradeFilter(String? grade) {
    _gradeFilter = grade;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = null;
    _branchFilter = null;
    _gradeFilter = null;
    notifyListeners();
  }

  // Load filter options from server
  Future<void> loadFilterOptions({bool forceRefresh = false}) async {
    _isLoadingFilters = true;
    notifyListeners();

    try {
      // Try to load from local storage first if enabled
      if (_useLocalCache && !forceRefresh) {
        final prefs = await SharedPreferences.getInstance();
        final cachedBranches = prefs.getStringList('lawyer_branches');
        final cachedGrades = prefs.getStringList('lawyer_grades');
        
        if (cachedBranches != null && cachedGrades != null) {
          _availableBranches = cachedBranches;
          _availableGrades = cachedGrades;
          _isLoadingFilters = false;
          notifyListeners();
          return;
        }
      }

      // Fetch from server
      final branches = await _apiService.getLawyerBranches();
      final grades = await _apiService.getLawyerGrades();
      
      _availableBranches = branches;
      _availableGrades = grades;
      
      // Save to local storage if enabled
      if (_useLocalCache) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('lawyer_branches', branches);
        await prefs.setStringList('lawyer_grades', grades);
      }
      
      _isLoadingFilters = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFilters = false;
      notifyListeners();
      print('Error loading filter options: $e');
    }
  }

  // Clear cached filters
  Future<void> clearCachedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lawyer_branches');
    await prefs.remove('lawyer_grades');
  }

  /// Build query params from current filters
  Map<String, String> _buildQueryParams() {
    final params = <String, String>{
      'page': _currentPage.toString(),
      'page_size': _pageSize.toString(),
    };

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      params['search'] = _searchQuery!;
    }
    if (_branchFilter != null) {
      params['branch'] = _branchFilter!;
    }
    if (_gradeFilter != null) {
      params['grade'] = _gradeFilter!;
    }

    return params;
  }

  // Load lawyers with filters
  Future<void> loadLawyers({bool refresh = false, Map<String, String>? filters}) async {
    if (refresh) {
      _currentPage = 1;
      _lawyers = [];
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = _buildQueryParams();
      if (filters != null) {
        queryParams.addAll(filters);
      }

      final response = await _apiService.getLawyers(queryParams: queryParams);
      
      List<dynamic> resultsList = [];
      int totalCount = 0;
      bool hasMore = false;
      
      if (response is List) {
        resultsList = response;
        totalCount = response.length;
        hasMore = false;
      } else if (response is Map) {
        if (response.containsKey('data')) {
          final data = response['data'];
          if (data is Map && data.containsKey('results')) {
            resultsList = data['results'] as List? ?? [];
            totalCount = data['count'] as int? ?? 0;
            hasMore = data['next'] != null;
          } else if (data is List) {
            resultsList = data;
            totalCount = data.length;
            hasMore = false;
          }
        } else if (response.containsKey('results')) {
          resultsList = (response['results'] as List?) ?? [];
          totalCount = response['count'] as int? ?? 0;
          hasMore = response['next'] != null;
        }
      }
      
      final results = resultsList
          .map((json) {
            try {
              return LawyerModel.fromJson(json);
            } catch (e) {
              print('Error parsing lawyer: $e');
              return null;
            }
          })
          .whereType<LawyerModel>()
          .toList();

      if (refresh) {
        _lawyers = results;
      } else {
        _lawyers.addAll(results);
      }

      _totalCount = totalCount ?? 0;
      _hasMore = hasMore;
      _currentPage++;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _lawyers.isEmpty ? e.toString() : null;
      _isLoading = false;
      notifyListeners();
      print('API Fetch error: $e');
    }
  }

  // Load single lawyer
  Future<void> loadLawyer(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getLawyer(id);
      _selectedLawyer = LawyerModel.fromJson(response);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear selected lawyer
  void clearSelectedLawyer() {
    _selectedLawyer = null;
    notifyListeners();
  }
}
