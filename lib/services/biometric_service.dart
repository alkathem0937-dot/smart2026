import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة المصادقة البيومترية (بصمة / وجه)
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyBiometricEnabled = 'biometric_login_enabled';
  static const String _keyStoredUsername = 'bio_username';
  static const String _keyStoredPassword = 'bio_password';

  // ─── الحالة ────────────────────────────────────────────

  /// هل الجهاز يدعم البصمة/الوجه؟
  Future<bool> get isDeviceSupported async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// هل فعّل المستخدم تسجيل الدخول بالبصمة؟
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// هل توجد بيانات محفوظة يمكن استخدامها؟
  Future<bool> get hasStoredCredentials async {
    final enabled = await isEnabled;
    if (!enabled) return false;
    final username = await _secureStorage.read(key: _keyStoredUsername);
    return username != null && username.isNotEmpty;
  }

  /// أنواع البيومتري المتاحة
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // ─── التفعيل / الإلغاء ─────────────────────────────────

  /// تفعيل تسجيل الدخول بالبصمة وحفظ بيانات الاعتماد بشكل آمن
  Future<bool> enable(String username, String password) async {
    final supported = await isDeviceSupported;
    if (!supported) return false;

    // تأكد من المصادقة أولاً
    final authenticated = await authenticate();
    if (!authenticated) return false;

    // حفظ البيانات بشكل مشفّر
    await _secureStorage.write(key: _keyStoredUsername, value: username);
    await _secureStorage.write(key: _keyStoredPassword, value: password);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, true);

    debugPrint('🔐 [Biometric] Enabled for user: $username');
    return true;
  }

  /// إلغاء تسجيل الدخول بالبصمة وحذف البيانات المحفوظة
  Future<void> disable() async {
    await _secureStorage.delete(key: _keyStoredUsername);
    await _secureStorage.delete(key: _keyStoredPassword);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, false);

    debugPrint('🔐 [Biometric] Disabled');
  }

  // ─── المصادقة ──────────────────────────────────────────

  /// إظهار نافذة البصمة
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'ضع بصمتك لتسجيل الدخول',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('🔐 [Biometric] Auth error: $e');
      return false;
    }
  }

  /// تسجيل الدخول بالبصمة — يعيد (username, password) أو null
  Future<({String username, String password})?> authenticateAndGetCredentials() async {
    final hasCredentials = await hasStoredCredentials;
    if (!hasCredentials) return null;

    final authenticated = await authenticate();
    if (!authenticated) return null;

    final username = await _secureStorage.read(key: _keyStoredUsername);
    final password = await _secureStorage.read(key: _keyStoredPassword);

    if (username == null || password == null) return null;
    return (username: username, password: password);
  }
}
