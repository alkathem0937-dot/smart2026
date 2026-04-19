import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Login Screen - شاشة الدخول بتصميم 2025+
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _discovering = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSavedUsername();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final bio = BiometricService.instance;
    final available = await bio.hasStoredCredentials;
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _handleBiometricLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.biometricLogin();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    if (savedUsername != null && mounted) {
      setState(() {
        _usernameController.text = savedUsername;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _rediscoverServer() async {
    setState(() => _discovering = true);
    try {
      final u = await ApiConfig.rediscoverLanServer();
      if (!mounted) return;
      setState(() {});
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            u != null
                ? 'تم ضبط الخادم تلقائياً: $u'
                : 'لم يُعثر على خادم على الشبكة. تأكد من تشغيل Django على المنفذ 8000.',
          ),
          backgroundColor: u != null ? AppColors.success : AppColors.warning,
        ),
      );
    } finally {
      if (mounted) setState(() => _discovering = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    ScaffoldMessenger.of(context).clearSnackBars();

    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (_rememberMe) {
        await prefs.setString('saved_username', _usernameController.text.trim());
      } else {
        await prefs.remove('saved_username');
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تسجيل الدخول بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to / so AuthWrapper can decide which dashboard to show
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else if (mounted) {
      final errorMessage = authProvider.errorMessage ?? 'فشل تسجيل الدخول';
      final isNetworkError = errorMessage.contains('لا يوجد اتصال') ||
          errorMessage.contains('انتهت مهلة') ||
          errorMessage.contains('لا يمكن الاتصال');
      final isAuthError = errorMessage.contains('اسم المستخدم') ||
          errorMessage.contains('كلمة المرور') ||
          errorMessage.contains('غير صحيحة');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isNetworkError
                    ? Icons.wifi_off_rounded
                    : isAuthError
                        ? Icons.error_outline_rounded
                        : Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: isNetworkError
              ? AppColors.warning
              : isAuthError
                  ? AppColors.error
                  : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleGuestLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setGuestMode(true);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أهلاً بك! أنت تتصفح " منصة القضاء الذكية" كضيف (لمدة دقيقتين فقط).'),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brand.withOpacity(isDark ? 0.1 : 0.05),
              ),
            ),
          ).animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.8, 0.8)),
          
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(isDark ? 0.1 : 0.05),
              ),
            ),
          ).animate().fadeIn(duration: 1.seconds, delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo & Branding
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: isDark ? AppShadows.darkMd : AppShadows.lg,
                            border: Border.all(
                              color: AppColors.brand.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 60,
                            width: 60,
                          ),
                        ),
                      ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: AppSpacing.xl),

                      Text(
                        'منصة القضاء الذكية',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.brandLight : AppColors.brand,
                        ),
                      ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: AppSpacing.xs),
                      
                      Text(
                        'منصة الخدمات القضائية الذكية',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ).animate().fade(delay: 500.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: AppSpacing.xxxl),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        validator: (v) => v!.isEmpty ? 'يرجى إدخال اسم المستخدم' : null,
                      ).animate().fade(delay: 600.ms).slideX(begin: 0.1),
                      
                      const SizedBox(height: AppSpacing.lg),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'يرجى إدخال كلمة المرور' : null,
                      ).animate().fade(delay: 700.ms).slideX(begin: 0.1),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // تم إزالة بطاقة خادم الشبكة المحلية بناءً على طلب المستخدم (تلقائي)

                      const SizedBox(height: AppSpacing.sm),

                      // Options Row
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v!),
                          ),
                          Text('تذكرني', style: theme.textTheme.bodyMedium),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text('نسيت المرور؟'),
                          ),
                        ],
                      ).animate().fade(delay: 900.ms),
                      
                      const SizedBox(height: AppSpacing.xl),

                      // Login Button
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('تسجيل الدخول'),
                        ),
                      ).animate().fade(delay: 1000.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: AppSpacing.md),

                      // Biometric Button
                      if (_biometricAvailable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: OutlinedButton.icon(
                            onPressed: _handleBiometricLogin,
                            icon: const Icon(Icons.fingerprint, size: 28),
                            label: const Text('تسجيل الدخول بالبصمة'),
                          ),
                        ).animate().fade(delay: 1050.ms).slideY(begin: 0.2),

                      // Guest Button
                      OutlinedButton(
                        onPressed: _handleGuestLogin,
                        child: const Text('تصفح كضيف'),
                      ).animate().fade(delay: 1100.ms).slideY(begin: 0.2),

                      const SizedBox(height: AppSpacing.xl),
                      
                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ليس لديك حساب؟', style: theme.textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            child: const Text('إنشاء حساب جديد'),
                          ),
                        ],
                      ).animate().fade(delay: 1200.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
