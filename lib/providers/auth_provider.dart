import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Authentication Provider using Provider pattern
class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  
  AuthProvider({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  
  // Get access token for other services
  String? get accessToken => _apiService.accessToken;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');

      if (accessToken != null && refreshToken != null) {
        // Check if token is expired
        if (JwtDecoder.isExpired(accessToken)) {
          // Try to refresh
          _apiService.setTokens(accessToken, refreshToken);
          final refreshed = await _apiService.refreshAccessToken();
          if (refreshed) {
            final newAccessToken = prefs.getString('access_token');
            if (newAccessToken != null) {
              await prefs.setString('access_token', newAccessToken);
            }
          } else {
            // Refresh failed, clear tokens
            await _clearStoredTokens();
            _isLoading = false;
            notifyListeners();
            return;
          }
        } else {
          _apiService.setTokens(accessToken, refreshToken);
        }

        // Get user profile
        try {
          _currentUser = await _apiService.getCurrentUser();
        } catch (e) {
          // Failed to get user, clear tokens
          await _clearStoredTokens();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _currentUser = null; // Reset user
    notifyListeners();

    try {
      // Step 1: Login to get tokens
      final response = await _apiService.login(username, password);
      
      final accessToken = response['access'];
      final refreshToken = response['refresh'];

      if (accessToken == null || refreshToken == null) {
        _errorMessage = 'فشل في الحصول على tokens من الخادم';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Store tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);

      // Set tokens in API service
      _apiService.setTokens(accessToken, refreshToken);

      // Step 2: Get user profile
      try {
        print('🔐 [Auth] Attempting to get user profile...');
        developer.log('Attempting to get user profile...', name: 'AuthProvider');
        _currentUser = await _apiService.getCurrentUser();
        print('✅ [Auth] User profile loaded: ${_currentUser?.username}, role: ${_currentUser?.role}');
        developer.log('User profile loaded: ${_currentUser?.username}', name: 'AuthProvider');
        
        // Verify user was loaded
        if (_currentUser == null) {
          print('❌ [Auth] User profile is null after loading');
          developer.log('User profile is null after loading', name: 'AuthProvider');
          await _clearStoredTokens();
          _apiService.clearTokens();
          _errorMessage = 'فشل في جلب معلومات المستخدم: البيانات فارغة';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        print('✅ [Auth] User authenticated successfully: ${_currentUser?.username}');
      } catch (e, stackTrace) {
        print('❌ [Auth] Error getting user profile: $e');
        print('📋 [Auth] Stack trace: $stackTrace');
        developer.log('Error getting user profile: $e', name: 'AuthProvider', error: e);
        // Failed to get user profile - clear tokens and show error
        await _clearStoredTokens();
        _apiService.clearTokens();
        _currentUser = null;
        
        // Extract error message
        String errorMsg = e.toString();
        if (errorMsg.contains('404') || errorMsg.contains('Profile not found')) {
          _errorMessage = 'ملف المستخدم غير موجود. يرجى إنشاء ملف شخصي من لوحة التحكم.';
        } else if (errorMsg.contains('401') || errorMsg.contains('Unauthorized')) {
          _errorMessage = 'غير مصرح بالوصول. يرجى المحاولة مرة أخرى.';
        } else {
          _errorMessage = 'فشل في جلب معلومات المستخدم:\n$errorMsg';
        }
        
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Success - user is loaded
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _currentUser = null;
      
      // تحسين رسائل الخطأ بناءً على نوع الخطأ
      String errorMsg = e.toString();
      
      // أخطاء الاتصال/الإنترنت
      if (e is SocketException || 
          errorMsg.contains('SocketException') || 
          errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('Network is unreachable')) {
        _errorMessage = 'لا يوجد اتصال بالإنترنت\nيرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
      } 
      // أخطاء انتهاء المهلة
      else if (errorMsg.contains('TimeoutException') || 
               errorMsg.contains('timeout') ||
               errorMsg.contains('Connection timed out')) {
        _errorMessage = 'انتهت مهلة الاتصال\nيرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
      }
      // أخطاء رفض الاتصال
      else if (errorMsg.contains('Connection refused') ||
               errorMsg.contains('Unable to connect')) {
        _errorMessage = 'لا يمكن الاتصال بالخادم\nيرجى التحقق من اتصال الإنترنت والمحاولة لاحقاً';
      }
      // أخطاء المصادقة (اسم المستخدم/كلمة المرور)
      else if (errorMsg.contains('401') || 
               errorMsg.contains('Unauthorized') ||
               errorMsg.contains('Invalid credentials') ||
               errorMsg.contains('Unable to log in') ||
               errorMsg.contains('No active account found') ||
               errorMsg.contains('Invalid username/password')) {
        _errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة\nيرجى التحقق من البيانات والمحاولة مرة أخرى';
      }
      // أخطاء 400 (Bad Request)
      else if (errorMsg.contains('400') || 
               errorMsg.contains('Bad Request')) {
        _errorMessage = 'بيانات الدخول غير صحيحة\nيرجى التحقق من اسم المستخدم وكلمة المرور';
      }
      // أخطاء 404
      else if (errorMsg.contains('404') || 
               errorMsg.contains('Not found')) {
        _errorMessage = 'الخدمة غير متاحة حالياً\nيرجى المحاولة لاحقاً';
      }
      // أخطاء 500 (Server Error)
      else if (errorMsg.contains('500') || 
               errorMsg.contains('Internal Server Error')) {
        _errorMessage = 'خطأ في الخادم\nيرجى المحاولة لاحقاً أو الاتصال بالدعم الفني';
      }
      // أخطاء أخرى
      else {
        // إزالة التفاصيل التقنية من رسالة الخطأ
        String cleanError = errorMsg;
        if (cleanError.contains('Exception: ')) {
          cleanError = cleanError.replaceFirst('Exception: ', '');
        }
        _errorMessage = 'حدث خطأ أثناء تسجيل الدخول\n$cleanError';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _clearStoredTokens();
    _apiService.clearTokens();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear stored tokens
  Future<void> _clearStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
  
  // Get ApiService instance (for use in screens)
  ApiService get apiService => _apiService;
  
  // Refresh user profile
  Future<void> refreshProfile() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      developer.log('Error refreshing profile: $e', name: 'AuthProvider');
    }
  }
}

