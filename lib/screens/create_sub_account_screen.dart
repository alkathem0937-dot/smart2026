import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class CreateSubAccountScreen extends StatefulWidget {
  const CreateSubAccountScreen({super.key});

  @override
  State<CreateSubAccountScreen> createState() => _CreateSubAccountScreenState();
}

class _CreateSubAccountScreenState extends State<CreateSubAccountScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController(text: 'smartjudi123');
  String _selectedRole = 'citizen';
  bool _isLoading = false;

  Future<void> _createAccount() async {
    if (_phoneController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.post('/api/register/create-sub-account/', {
        'phone': _phoneController.text,
        'full_name': _nameController.text,
        'role': _selectedRole,
        'password': _passwordController.text,
      });

      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('تم إنشاء الحساب بنجاح')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('خطأ: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('إنشاء حساب فرعي', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يمكنك إنشاء حسابات لموكليك أو لمعاونيك في المكتب. سيتم تسجيل الدخول برقم الهاتف.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildTextField('رقم الهاتف (كإسم مستخدم)', _phoneController, Icons.phone_android_rounded),
            const SizedBox(height: 20),
            _buildTextField('الاسم الكامل', _nameController, Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildTextField('كلمة المرور الافتراضية', _passwordController, Icons.lock_outline_rounded),
            const SizedBox(height: 32),
            const Text('نوع الحساب الصلاحية:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRoleSelector(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _createAccount,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('إنشاء الحساب الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: context.isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleCard('مواطن (موكل)', 'citizen', Icons.person_pin_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRoleCard('معاون محامي', 'assistant', Icons.support_agent_rounded),
        ),
      ],
    );
  }

  Widget _buildRoleCard(String title, String role, IconData icon) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (context.isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
