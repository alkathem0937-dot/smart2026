import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

/// Login Screen - المحسنة مع ميزة الحفظ التلقائي والدخول كضيف
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

  @override
  void initState() {
    super.initState();
    _loadSavedUsername();
  }

  // تحميل اسم المستخدم المحفوظ تلقائياً
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    ScaffoldMessenger.of(context).clearSnackBars();
    
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // حفظ اسم المستخدم إذا كان خيار "تذكرني" مفعلاً
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_username', _usernameController.text.trim());
      } else {
        await prefs.remove('saved_username');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بنجاح'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'فشل تسجيل الدخول'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleGuestLogin() {
    // توجيه المستخدم للشاشة الرئيسية كضيف (بدون تسجيل دخول حقيقي)
    // يمكن إضافة منطق خاص بالضيف في الـ AuthProvider لاحقاً إذا لزم الأمر
    Navigator.pushReplacementNamed(context, '/home');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('أهلاً بك! أنت تتصفح التطبيق كضيف الآن.'), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // الشعار
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(Icons.gavel_rounded, size: 70, color: colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'SmartJudi',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1E3A8A)),
                    ),
                    const Text('منصة الخدمات القضائية الذكية', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                    const SizedBox(height: 50),

                    // حقل اسم المستخدم
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال اسم المستخدم' : null,
                    ),
                    const SizedBox(height: 20),

                    // حقل كلمة المرور
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال كلمة المرور' : null,
                    ),

                    // خيار تذكرني
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v!),
                          activeColor: colorScheme.primary,
                        ),
                        const Text('تذكر اسم المستخدم', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {}, // إضافة استعادة كلمة المرور لاحقاً
                          child: const Text('نسيت كلمة المرور؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // زر تسجيل الدخول
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) => SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // زر الدخول كضيف
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: _handleGuestLogin,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1E3A8A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('تصفح كضيف', style: TextStyle(fontSize: 16, fontFamily: 'Cairo', color: Color(0xFF1E3A8A))),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ليس لديك حساب؟', style: TextStyle(fontFamily: 'Cairo')),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text('إنشاء حساب جديد', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
