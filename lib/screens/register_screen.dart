import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

/// Register Screen - انشاء حساب
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  String _selectedRole = 'citizen';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمات المرور غير متطابقة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final apiService = ApiService();
    try {
      await apiService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        firstName: _fullNameController.text.trim().split(' ').first,
        lastName: _fullNameController.text.trim().split(' ').length > 1
            ? _fullNameController.text.trim().split(' ').skip(1).join(' ')
            : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        nationalId: _nationalIdController.text.trim().isNotEmpty ? _nationalIdController.text.trim() : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب بنجاح. يرجى تسجيل الدخول'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      developer.log('Error registering: $e', name: 'RegisterScreen');
      if (mounted) {
        // Extract error message
        String errorMessage = 'خطأ في التسجيل';
        final errorStr = e.toString();
        IconData errorIcon = Icons.error_outline;
        Color errorColor = Colors.red;
        
        // Check for specific error messages
        if (errorStr.contains('اسم المستخدم موجود بالفعل') || 
            errorStr.contains('username') && errorStr.contains('already exists')) {
          errorMessage = 'اسم المستخدم موجود بالفعل\nيرجى اختيار اسم آخر';
          errorIcon = Icons.person_off;
        } else if (errorStr.contains('البريد الإلكتروني موجود بالفعل') || 
                   errorStr.contains('email') && errorStr.contains('already exists')) {
          errorMessage = 'البريد الإلكتروني موجود بالفعل\nيرجى استخدام بريد آخر';
          errorIcon = Icons.email;
        } else if (errorStr.contains('الرقم الوطني موجود بالفعل') ||
                   errorStr.contains('national_id') && errorStr.contains('already exists')) {
          errorMessage = 'الرقم الوطني موجود بالفعل\nيرجى التحقق من الرقم المدخل';
          errorIcon = Icons.badge;
        } else if (errorStr.contains('SocketException') || 
                   errorStr.contains('Failed host lookup') ||
                   errorStr.contains('Network is unreachable')) {
          errorMessage = 'لا يوجد اتصال بالإنترنت\nيرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        } else if (errorStr.contains('TimeoutException') || 
                   errorStr.contains('timeout')) {
          errorMessage = 'انتهت مهلة الاتصال\nيرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        } else if (errorStr.contains('Connection refused') ||
                   errorStr.contains('Network error') || 
                   errorStr.contains('Connection')) {
          errorMessage = 'لا يمكن الاتصال بالخادم\nيرجى التحقق من اتصال الإنترنت والمحاولة لاحقاً';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        } else if (errorStr.contains('400') || 
                   errorStr.contains('Bad Request')) {
          errorMessage = 'بيانات التسجيل غير صحيحة\nيرجى التحقق من جميع الحقول المدخلة';
          errorIcon = Icons.warning_amber_rounded;
        } else if (errorStr.contains('Request failed')) {
          // Try to extract the actual error from the exception
          final match = RegExp(r'Exception: (.+)').firstMatch(errorStr);
          if (match != null) {
            errorMessage = match.group(1) ?? 'خطأ في التسجيل';
          } else {
            errorMessage = 'خطأ في التسجيل\nيرجى التحقق من البيانات المدخلة';
          }
        } else {
          errorMessage = errorStr.replaceAll('Exception: ', '');
          if (errorMessage.length > 100) {
            errorMessage = 'خطأ في التسجيل\nيرجى التحقق من البيانات المدخلة';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'حسناً',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'يرجى إدخال الاسم الكامل' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  prefixIcon: Icon(Icons.account_circle),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'يرجى إدخال اسم المستخدم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!value!.contains('@')) {
                    return 'البريد الإلكتروني غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nationalIdController,
                decoration: const InputDecoration(
                  labelText: 'الرقم الوطني',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'الدور',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'citizen', child: Text('مواطن')),
                  DropdownMenuItem(value: 'lawyer', child: Text('محامي')),
                  DropdownMenuItem(value: 'judge', child: Text('قاضي')),
                  DropdownMenuItem(value: 'notary', child: Text('كاتب عدل')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (value!.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'يرجى تأكيد كلمة المرور' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إنشاء حساب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

