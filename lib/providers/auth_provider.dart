import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
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
  bool _isGuest = false;
  Future<void>? _guestTimer;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null || _isGuest;
  bool get isGuest => _isGuest;

  void setGuestMode(bool value) {
    _isGuest = value;
    if (_isGuest) {
      // إعداد مستخدم ضيف افتراضي
      _currentUser = UserModel(
        id: 0,
        username: 'guest',
        email: 'guest@smartjudi.com',
        firstName: 'ضيف',
        lastName: 'النظام',
        role: 'guest',
      );
      
      // بدء مؤقت لمدة دقيقتين
      _guestTimer = Future.delayed(const Duration(minutes: 2), () {
        if (_isGuest) {
          logout();
        }
      });
    }
    notifyListeners();
  }
  
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
          // Cache successful profile
          await _cacheUserProfile(_currentUser!);
        } catch (e) {
          print('⚠️ [Auth] Could not fetch profile from server, trying cache: $e');
          _currentUser = await _loadCachedProfile();
          if (_currentUser == null) {
            // Failed to get user from both, clear tokens
            await _clearStoredTokens();
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Caching helpers
  Future<void> _cacheUserProfile(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user_profile', user.toJsonString());
    print('💾 [Auth] User profile cached for offline use');
  }

  Future<UserModel?> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('cached_user_profile');
    if (json == null) return null;
    try {
      return UserModel.fromJsonString(json);
    } catch (e) {
      return null;
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
        await _cacheUserProfile(_currentUser!);
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

      // Success — update biometric credentials if enabled
      try {
        final bio = BiometricService.instance;
        if (await bio.isEnabled) {
          await bio.enable(username, password);
        }
      } catch (_) {}

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
        if (ApiConfig.baseUrl.contains('127.0.0.1')) {
          _errorMessage =
              'انتهت مهلة الاتصال: لم يُعثر على الخادم على الشبكة.\n'
              'شغّل Django على جهاز الكمبيوتر ثم اضغط زر التحديث بجانب عنوان الخادم في شاشة الدخول.';
        } else {
          _errorMessage =
              'انتهت مهلة الاتصال بالخادم ${ApiConfig.baseUrl}\n'
              'تأكد من تشغيل الخادم ومن جدار الحماية (المنفذ 8000).';
        }
      }
      // أخطاء رفض الاتصال
      else if (errorMsg.contains('Connection refused') ||
               errorMsg.contains('Unable to connect')) {
        if (ApiConfig.baseUrl.contains('127.0.0.1')) {
          _errorMessage =
              'لم يُعثر على خادم Django على شبكة Wi‑Fi.\n'
              'شغّل الخادم: python manage.py runserver 0.0.0.0:8000\n'
              'ثم اضغط زر التحديث بجانب «الخادم على شبكة Wi‑Fi» أعلاه.';
        } else {
          _errorMessage =
              'لا يمكن الاتصال بالخادم على:\n${ApiConfig.baseUrl}\n'
              'تأكد من تشغيل Django (runserver 0.0.0.0:8000) ومن الشبكة.';
        }
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
    _isGuest = false;
    _guestTimer = null;
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
  
  /// تسجيل الدخول بالبصمة
  Future<bool> biometricLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credentials =
          await BiometricService.instance.authenticateAndGetCredentials();
      if (credentials == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      return await login(credentials.username, credentials.password);
    } catch (e) {
      _errorMessage = 'فشل تسجيل الدخول بالبصمة';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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

