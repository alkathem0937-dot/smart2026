import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/lawsuit_model.dart';

/// API Service for communicating with Django backend
class ApiService {
  String? _accessToken;
  String? _refreshToken;

  // Set tokens after login
  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  // Clear tokens on logout
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // Get authorization header
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // Make HTTP request
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? files,
  }) async {
    try {
      final fullUrl = '${ApiConfig.baseUrl}$endpoint';
      print('🌐 [API] Making $method request to: $fullUrl');
      final url = Uri.parse(fullUrl);
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(url, headers: _headers)
              .timeout(ApiConfig.timeout);
          break;
        case 'POST':
          if (files != null) {
            // For file uploads, use multipart
            var request = http.MultipartRequest('POST', url);
            request.headers.addAll(_headers);
            request.headers.remove('Content-Type'); // Let multipart set it
            
            body?.forEach((key, value) {
              request.fields[key] = value.toString();
            });
            
            // Add files asynchronously
            for (var entry in files.entries) {
              request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value));
            }
            
            var streamedResponse = await request.send();
            response = await http.Response.fromStream(streamedResponse);
          } else {
            print('📤 [API] POST body: ${body != null ? jsonEncode(body) : 'null'}');
            print('📤 [API] POST headers: $_headers');
            response = await http
                .post(url, headers: _headers, body: body != null ? jsonEncode(body) : null)
                .timeout(ApiConfig.timeout);
          }
          break;
        case 'PUT':
          response = await http
              .put(url, headers: _headers, body: jsonEncode(body))
              .timeout(ApiConfig.timeout);
          break;
        case 'PATCH':
          response = await http
              .patch(url, headers: _headers, body: jsonEncode(body))
              .timeout(ApiConfig.timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: _headers)
              .timeout(ApiConfig.timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('📡 [API] Response status: ${response.statusCode}');
      print('📡 [API] Response body: ${response.body}');
      
      // Handle empty response body
      Map<String, dynamic> responseData;
      if (response.body.isEmpty) {
        print('⚠️ [API] Empty response body');
        responseData = {};
      } else {
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          print('❌ [API] JSON decode error: $e');
          print('❌ [API] Response body was: ${response.body}');
          throw Exception('خطأ في قراءة البيانات من الخادم: ${e.toString()}');
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ [API] Request successful');
        return responseData;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        if (_refreshToken != null) {
          final refreshed = await refreshAccessToken();
          if (refreshed) {
            // Retry the request
            return _makeRequest(method, endpoint, body: body, files: files);
          }
        }
        throw Exception('Unauthorized: ${responseData['detail'] ?? 'Invalid credentials'}');
      } else {
        // Better error handling for validation errors
        String errorMessage = 'Request failed';
        if (responseData is Map<String, dynamic>) {
          // Handle Django REST Framework validation errors
          if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          } else {
            // Collect all validation errors
            final errors = <String>[];
            responseData.forEach((key, value) {
              if (value is List) {
                errors.addAll(value.map((e) => e.toString()));
              } else if (value is String) {
                errors.add(value);
              } else {
                errors.add('$key: ${value.toString()}');
              }
            });
            if (errors.isNotEmpty) {
              errorMessage = errors.join('\n');
            }
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('❌ [API] Exception in _makeRequest: $e');
      print('📋 [API] Stack trace: $stackTrace');
      
      String errorMessage;
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت والخادم على العنوان: ${ApiConfig.baseUrl}';
      } else if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        errorMessage = 'فشل الاتصال بالخادم. يرجى التحقق من:\n1. تشغيل الخادم على ${ApiConfig.baseUrl}\n2. اتصال الإنترنت\n3. عنوان IP الصحيح';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'تم رفض الاتصال بالخادم. تأكد من تشغيل الخادم على ${ApiConfig.baseUrl}';
      } else {
        errorMessage = 'خطأ في الشبكة: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
    }
  }

  // Refresh access token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshTokenEndpoint}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('⚠️ [API] Empty response body in refreshAccessToken');
          return false;
        }
        try {
          final data = jsonDecode(response.body);
          _accessToken = data['access'];
          return true;
        } catch (e) {
          print('❌ [API] JSON decode error in refreshAccessToken: $e');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ [API] Error in refreshAccessToken: $e');
      return false;
    }
  }

  // Authentication with retry logic
  Future<Map<String, dynamic>> login(String username, String password) async {
    int attempts = 0;
    Exception? lastException;
    
    while (attempts < ApiConfig.maxRetries) {
      try {
        final response = await _makeRequest(
          'POST',
          ApiConfig.loginEndpoint,
          body: {
            'username': username,
            'password': password,
          },
        );
        
        _accessToken = response['access'];
        _refreshToken = response['refresh'];
        
        return response;
      } catch (e) {
        attempts++;
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Don't retry on authentication errors (401, 400 with invalid credentials)
        if (e.toString().contains('Unauthorized') || 
            e.toString().contains('Invalid credentials') ||
            e.toString().contains('Unable to log in')) {
          rethrow;
        }
        
        // Wait before retrying (except on last attempt)
        if (attempts < ApiConfig.maxRetries) {
          print('🔄 [API] Login attempt $attempts failed, retrying in ${ApiConfig.retryDelay.inSeconds}s...');
          await Future.delayed(ApiConfig.retryDelay);
        }
      }
    }
    
    // All retries failed
    if (lastException != null) {
      throw lastException;
    }
    throw Exception('Failed to connect to server after ${ApiConfig.maxRetries} attempts');
  }

  // Update user profile
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      // Note: address might need to be added to UserProfile model
      
      final response = await _makeRequest(
        'PATCH',
        '${ApiConfig.profilesEndpoint}me/',
        body: body,
      );
      
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Get current user profile
  Future<UserModel> getCurrentUser() async {
    try {
      print('🔍 [API] Calling getCurrentUser: ${ApiConfig.profilesEndpoint}me/');
      final response = await _makeRequest('GET', '${ApiConfig.profilesEndpoint}me/');
      
      print('📦 [API] Response received: $response');
      
      // Validate response
      if (response == null || response.isEmpty) {
        print('❌ [API] Response is empty');
        throw Exception('Response is empty from server');
      }
      
      // Try to parse user model
      try {
        print('🔄 [API] Parsing user model...');
        final user = UserModel.fromJson(response);
        print('✅ [API] User model parsed successfully: ${user.username}');
        return user;
      } catch (e, stackTrace) {
        print('❌ [API] Failed to parse user data: $e');
        print('📋 [API] Stack trace: $stackTrace');
        print('📋 [API] Response data: $response');
        throw Exception('Failed to parse user data: ${e.toString()}\nResponse: $response');
      }
    } catch (e, stackTrace) {
      print('❌ [API] Error in getCurrentUser: $e');
      print('📋 [API] Stack trace: $stackTrace');
      
      // Provide more specific error message
      final errorStr = e.toString();
      if (errorStr.contains('404') || errorStr.contains('Profile not found') || errorStr.contains('not found')) {
        throw Exception('ملف المستخدم غير موجود. يرجى إنشاء ملف شخصي من لوحة التحكم في Django Admin.');
      } else if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        throw Exception('غير مصرح بالوصول. يرجى تسجيل الدخول مرة أخرى.');
      } else if (errorStr.contains('Connection') || errorStr.contains('timeout')) {
        throw Exception('فشل الاتصال بالخادم. تأكد من أن Django يعمل.');
      } else {
        throw Exception('فشل في جلب معلومات المستخدم:\n$errorStr');
      }
    }
  }

  // Lawsuits
  Future<Map<String, dynamic>> getLawsuits({Map<String, String>? queryParams}) async {
    String endpoint = ApiConfig.lawsuitsEndpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }

  Future<LawsuitModel> getLawsuit(int id) async {
    final response = await _makeRequest('GET', '${ApiConfig.lawsuitsEndpoint}$id/');
    return LawsuitModel.fromJson(response);
  }

  Future<LawsuitModel> createLawsuit(LawsuitModel lawsuit) async {
    final response = await _makeRequest(
      'POST',
      ApiConfig.lawsuitsEndpoint,
      body: lawsuit.toJson(),
    );
    return LawsuitModel.fromJson(response);
  }

  Future<LawsuitModel> updateLawsuit(int id, LawsuitModel lawsuit) async {
    final response = await _makeRequest(
      'PATCH',
      '${ApiConfig.lawsuitsEndpoint}$id/',
      body: lawsuit.toJson(),
    );
    return LawsuitModel.fromJson(response);
  }

  Future<void> deleteLawsuit(int id) async {
    await _makeRequest('DELETE', '${ApiConfig.lawsuitsEndpoint}$id/');
  }

  // ========== Archive API ==========

  /// Get archive statistics
  Future<Map<String, dynamic>> getArchiveStats() async {
    return await _makeRequest('GET', '${ApiConfig.lawsuitsEndpoint}stats/');
  }

  /// Archive a lawsuit
  Future<Map<String, dynamic>> archiveLawsuit(int id, {String? reason}) async {
    return await _makeRequest(
      'POST',
      '${ApiConfig.lawsuitsEndpoint}$id/archive/',
      body: {if (reason != null) 'reason': reason},
    );
  }

  /// Unarchive a lawsuit
  Future<Map<String, dynamic>> unarchiveLawsuit(int id) async {
    return await _makeRequest(
      'POST',
      '${ApiConfig.lawsuitsEndpoint}$id/unarchive/',
    );
  }

  /// Restore a soft-deleted lawsuit
  Future<Map<String, dynamic>> restoreLawsuit(int id) async {
    return await _makeRequest(
      'POST',
      '${ApiConfig.lawsuitsEndpoint}$id/restore/',
    );
  }

  // Legal Templates
  Future<Map<String, dynamic>> getLegalTemplates({String? caseType}) async {
    String endpoint = ApiConfig.legalTemplatesEndpoint;
    if (caseType != null) {
      endpoint += 'by_case_type/?case_type=${Uri.encodeComponent(caseType)}';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Get templates for lawsuit creation
  Future<Map<String, dynamic>> getLawsuitTemplates(String caseType) async {
    return await _makeRequest(
      'GET',
      '${ApiConfig.lawsuitsEndpoint}get_templates/?case_type=${Uri.encodeComponent(caseType)}',
    );
  }

  // Parties (Plaintiffs & Defendants)
  Future<Map<String, dynamic>> getPlaintiffs({int? lawsuitId}) async {
    String endpoint = ApiConfig.plaintiffsEndpoint;
    if (lawsuitId != null) {
      endpoint += '?lawsuit=$lawsuitId';
    }
    return await _makeRequest('GET', endpoint);
  }

  Future<Map<String, dynamic>> createPlaintiff(Map<String, dynamic> plaintiffData) async {
    return await _makeRequest('POST', ApiConfig.plaintiffsEndpoint, body: plaintiffData);
  }

  Future<Map<String, dynamic>> updatePlaintiff(int id, Map<String, dynamic> plaintiffData) async {
    return await _makeRequest('PATCH', '${ApiConfig.plaintiffsEndpoint}$id/', body: plaintiffData);
  }

  Future<void> deletePlaintiff(int id) async {
    await _makeRequest('DELETE', '${ApiConfig.plaintiffsEndpoint}$id/');
  }

  Future<Map<String, dynamic>> getDefendants({int? lawsuitId}) async {
    String endpoint = ApiConfig.defendantsEndpoint;
    if (lawsuitId != null) {
      endpoint += '?lawsuit=$lawsuitId';
    }
    return await _makeRequest('GET', endpoint);
  }

  Future<Map<String, dynamic>> createDefendant(Map<String, dynamic> defendantData) async {
    return await _makeRequest('POST', ApiConfig.defendantsEndpoint, body: defendantData);
  }

  Future<Map<String, dynamic>> updateDefendant(int id, Map<String, dynamic> defendantData) async {
    return await _makeRequest('PATCH', '${ApiConfig.defendantsEndpoint}$id/', body: defendantData);
  }

  Future<void> deleteDefendant(int id) async {
    await _makeRequest('DELETE', '${ApiConfig.defendantsEndpoint}$id/');
  }

  // Attachments
  Future<Map<String, dynamic>> getAttachments({int? lawsuitId}) async {
    String endpoint = ApiConfig.attachmentsEndpoint;
    if (lawsuitId != null) {
      endpoint += '?lawsuit=$lawsuitId';
    }
    return await _makeRequest('GET', endpoint);
  }

  Future<Map<String, dynamic>> uploadAttachment({
    required int lawsuitId,
    required String filePath,
    String? description,
  }) async {
    return await _makeRequest(
      'POST',
      ApiConfig.attachmentsEndpoint,
      body: {
        'lawsuit': lawsuitId,
        if (description != null) 'description': description,
      },
      files: {'file': filePath},
    );
  }

  // Hearings
  Future<Map<String, dynamic>> getHearings({int? lawsuitId}) async {
    String endpoint = ApiConfig.hearingsEndpoint;
    if (lawsuitId != null) {
      endpoint += '?lawsuit=$lawsuitId';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Judgments
  Future<Map<String, dynamic>> getJudgments({int? lawsuitId}) async {
    String endpoint = ApiConfig.judgmentsEndpoint;
    if (lawsuitId != null) {
      endpoint += '?lawsuit=$lawsuitId';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Appeals
  Future<Map<String, dynamic>> getAppeals({int? lawsuitId}) async {
    String endpoint = ApiConfig.appealsEndpoint;
    if (lawsuitId != null) {
      endpoint += '?lawsuit=$lawsuitId';
    }
    return await _makeRequest('GET', endpoint);
  }

  Future<Map<String, dynamic>> createAppeal(Map<String, dynamic> appealData) async {
    return await _makeRequest('POST', ApiConfig.appealsEndpoint, body: appealData);
  }

  Future<Map<String, dynamic>> updateAppeal(int id, Map<String, dynamic> appealData) async {
    return await _makeRequest('PATCH', '${ApiConfig.appealsEndpoint}$id/', body: appealData);
  }

  Future<void> deleteAppeal(int id) async {
    await _makeRequest('DELETE', '${ApiConfig.appealsEndpoint}$id/');
  }

  // Payment Orders
  Future<Map<String, dynamic>> getPaymentOrders({int? lawsuitId}) async {
    String endpoint = ApiConfig.paymentOrdersEndpoint;
    if (lawsuitId != null) {
      endpoint += '?lawsuit=$lawsuitId';
    }
    return await _makeRequest('GET', endpoint);
  }

  Future<Map<String, dynamic>> createPaymentOrder(Map<String, dynamic> orderData) async {
    return await _makeRequest('POST', ApiConfig.paymentOrdersEndpoint, body: orderData);
  }

  Future<Map<String, dynamic>> updatePaymentOrder(int id, Map<String, dynamic> orderData) async {
    return await _makeRequest('PATCH', '${ApiConfig.paymentOrdersEndpoint}$id/', body: orderData);
  }

  Future<void> deletePaymentOrder(int id) async {
    await _makeRequest('DELETE', '${ApiConfig.paymentOrdersEndpoint}$id/');
  }

  // ========== Courts API ==========
  
  // Governorates
  Future<Map<String, dynamic>> getGovernorates({Map<String, String>? queryParams}) async {
    String endpoint = ApiConfig.governoratesEndpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Districts
  Future<Map<String, dynamic>> getDistricts({int? governorateId, Map<String, String>? queryParams}) async {
    String endpoint = ApiConfig.districtsEndpoint;
    final params = <String, String>{};
    if (governorateId != null) {
      params['governorate'] = governorateId.toString();
    }
    if (queryParams != null) {
      params.addAll(queryParams);
    }
    if (params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Courts
  Future<Map<String, dynamic>> getCourts({Map<String, String>? queryParams}) async {
    String endpoint = ApiConfig.courtsEndpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }

  // ========== Laws API ==========
  
  // Legal Categories
  Future<Map<String, dynamic>> getLegalCategories({Map<String, String>? queryParams}) async {
    String endpoint = ApiConfig.legalCategoriesEndpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Laws
  Future<Map<String, dynamic>> getLaws({int? categoryId, Map<String, String>? queryParams}) async {
    String endpoint = ApiConfig.lawsEndpoint;
    final params = <String, String>{};
    if (categoryId != null) {
      params['category'] = categoryId.toString();
    }
    if (queryParams != null) {
      params.addAll(queryParams);
    }
    if (params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Law Articles
  Future<Map<String, dynamic>> getLawArticles({int? sectionId, Map<String, String>? queryParams}) async {
    String endpoint = ApiConfig.lawArticlesEndpoint;
    final params = <String, String>{};
    if (sectionId != null) {
      params['section'] = sectionId.toString();
    }
    if (queryParams != null) {
      params.addAll(queryParams);
    }
    if (params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Search Laws
  Future<Map<String, dynamic>> searchLaws(String query) async {
    return await getLaws(queryParams: {'search': query});
  }

  // ========== Legal Library API (Full-Text Search) ==========
  
  /// Get legal articles with optional search and filters
  Future<Map<String, dynamic>> getLegalLibrary({
    String? searchQuery,
    String? source,
    String? book,
    String? section,
    String? chapter,
    String? branch,
    String? articleNumber,
    String? ordering,
    int? page,
  }) async {
    String endpoint = '/api/legal-library/';
    final params = <String, String>{};
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      params['q'] = searchQuery;
    }
    if (source != null && source.isNotEmpty) {
      params['source'] = source;
    }
    if (book != null && book.isNotEmpty) {
      params['book'] = book;
    }
    if (section != null && section.isNotEmpty) {
      params['section'] = section;
    }
    if (chapter != null && chapter.isNotEmpty) {
      params['chapter'] = chapter;
    }
    if (branch != null && branch.isNotEmpty) {
      params['branch'] = branch;
    }
    if (articleNumber != null && articleNumber.isNotEmpty) {
      params['article_number'] = articleNumber;
    }
    if (ordering != null && ordering.isNotEmpty) {
      params['ordering'] = ordering;
    }
    if (page != null) {
      params['page'] = page.toString();
    }
    
    if (params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    
    return await _makeRequest('GET', endpoint);
  }
  
  /// Get legal article details
  Future<Map<String, dynamic>> getLegalArticle(int id) async {
    return await _makeRequest('GET', '/api/legal-library/$id/');
  }
  
  /// Get legal library sources (with article counts)
  Future<Map<String, dynamic>> getLegalLibrarySources() async {
    return await _makeRequest('GET', '/api/legal-library/sources/');
  }

  /// Get legal library books
  Future<Map<String, dynamic>> getLegalLibraryBooks({String? source}) async {
    String endpoint = '/api/legal-library/books/';
    if (source != null && source.isNotEmpty) {
      endpoint += '?source=${Uri.encodeComponent(source)}';
    }
    return await _makeRequest('GET', endpoint);
  }

  /// Get legal library chapters
  Future<Map<String, dynamic>> getLegalLibraryChapters({String? source, String? book}) async {
    String endpoint = '/api/legal-library/chapters/';
    final params = <String, String>{};
    if (source != null && source.isNotEmpty) {
      params['source'] = source;
    }
    if (book != null && book.isNotEmpty) {
      params['book'] = book;
    }
    if (params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }
  
  /// Search with highlighting
  Future<Map<String, dynamic>> searchLegalLibrary(String query) async {
    return await _makeRequest('GET', '/api/legal-library/search/?q=${Uri.encodeComponent(query)}');
  }
  
  /// Get legal library statistics
  Future<Map<String, dynamic>> getLegalLibraryStats() async {
    return await _makeRequest('GET', '/api/legal-library/stats/');
  }

  // ========== Hearings API (Daily Sessions) ==========
  
  // Get daily hearings
  Future<Map<String, dynamic>> getDailyHearings(DateTime date) async {
    String endpoint = ApiConfig.hearingsEndpoint;
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD
    endpoint += '?hearing_date=$dateStr';
    return await _makeRequest('GET', endpoint);
  }

  // ========== Logs API ==========
  
  // User Sessions
  Future<Map<String, dynamic>> getUserSessions({Map<String, String>? queryParams}) async {
    String endpoint = ApiConfig.userSessionsEndpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Search Logs
  Future<Map<String, dynamic>> createSearchLog(String searchQuery, {int? resultsCount}) async {
    return await _makeRequest(
      'POST',
      ApiConfig.searchLogsEndpoint,
      body: {
        'search_query': searchQuery,
        if (resultsCount != null) 'results_count': resultsCount,
      },
    );
  }

  // AI Chat Logs
  Future<Map<String, dynamic>> createAIChatLog(String question, String answer, {String? modelVersion}) async {
    return await _makeRequest(
      'POST',
      ApiConfig.aiChatLogsEndpoint,
      body: {
        'question': question,
        'answer': answer,
        if (modelVersion != null) 'model_version': modelVersion,
      },
    );
  }

  // ========== Inquiries API ==========
  
  // Search lawsuit by case number
  Future<Map<String, dynamic>> searchLawsuitByCaseNumber(String caseNumber) async {
    return await getLawsuits(queryParams: {'case_number': caseNumber});
  }

  // ========== Contact & Complaints API ==========
  
  // Submit contact message (Note: This might need a custom endpoint in Django)
  Future<Map<String, dynamic>> submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    // TODO: Create this endpoint in Django if it doesn't exist
    // For now, we'll use a placeholder
    return await _makeRequest(
      'POST',
      '/api/contact/', // This endpoint needs to be created
      body: {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      },
    );
  }

  // Submit complaint (Note: This might need a custom endpoint in Django)
  Future<Map<String, dynamic>> submitComplaint({
    required String subject,
    required String description,
  }) async {
    // TODO: Create this endpoint in Django if it doesn't exist
    // For now, we'll use a placeholder
    return await _makeRequest(
      'POST',
      '/api/complaints/', // This endpoint needs to be created
      body: {
        'subject': subject,
        'description': description,
      },
    );
  }

  // ========== Register API ==========
  
  // Register new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? nationalId,
  }) async {
    return await _makeRequest(
      'POST',
      '/api/register/',
      body: {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        if (nationalId != null && nationalId.isNotEmpty) 'national_id': nationalId,
      },
    );
  }

  // ========== Subscribe API ==========
  
  // Subscribe to newsletter (Note: This might need a custom endpoint in Django)
  Future<Map<String, dynamic>> subscribe({
    required String email,
    String? name,
  }) async {
    // TODO: Create this endpoint in Django if it doesn't exist
    return await _makeRequest(
      'POST',
      '/api/subscribe/', // This endpoint needs to be created
      body: {
        'email': email,
        if (name != null) 'name': name,
      },
    );
  }

  // ========== Notifications API ==========
  
  // Get all notifications
  Future<Map<String, dynamic>> getNotifications({Map<String, String>? queryParams}) async {
    String endpoint = '/api/notifications/';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint += '?$queryString';
    }
    return await _makeRequest('GET', endpoint);
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    return await _makeRequest(
      'PATCH',
      '/api/notifications/$notificationId/',
      body: {'is_read': true},
    );
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return await _makeRequest(
      'POST',
      '/api/notifications/mark-all-read/',
    );
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    return await _makeRequest('DELETE', '/api/notifications/$notificationId/');
  }

  // ========== Legal Procedures Guide API ==========
  
  /// Get legal procedures
  Future<Map<String, dynamic>> getLegalProcedures(
      {int page = 1, String? search, String? source, String? level}) async {
    final params = <String, String>{
      'page': page.toString(),
    };
    if (search != null && search.isNotEmpty) params['q'] = search;
    if (source != null && source.isNotEmpty) params['source'] = source;
    if (level != null && level.isNotEmpty) params['level'] = level;

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
        
    String endpoint = '/api/legal-procedures/';
    if (search != null && search.isNotEmpty) {
       endpoint = '/api/legal-procedures/search/';
    }
    
    endpoint += '?$queryString';

    return await _makeRequest('GET', endpoint);
  }

  /// Get legal procedures sources
  Future<Map<String, dynamic>> getLegalProceduresSources() async {
    return await _makeRequest('GET', '/api/legal-procedures/sources/');
  }
}

