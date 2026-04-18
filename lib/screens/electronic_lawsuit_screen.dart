import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'lawsuit_detail_screen.dart';

class ElectronicLawsuitScreen extends StatelessWidget {
  const ElectronicLawsuitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isDark = context.isDark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('رفع دعوى إلكترونية')),
        body: const Center(child: Text('يرجى تسجيل الدخول أولاً')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('رفع دعوى إلكترونية', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.description_rounded, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'بدء إجراءات دعوى جديدة',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نظام الأتمتة القانونية يساعدك في صياغة الدعوى وفقاً للقواعد القانونية المتبعة',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildStepCard(
              '1',
              'تعبئة البيانات الأساسية',
              'رقم الدعوى، المحكمة المختصة، وموضوع النزاع',
              Icons.edit_note_rounded,
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              '2',
              'إضافة أطراف النزاع',
              'بيانات المدعين والمدعى عليهم والهوية الوطنية',
              Icons.people_alt_rounded,
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              '3',
              'صياغة البناء القانوني',
              'الوقائع، الأسانيد الشرعية والقانونية، والطلبات الختامية',
              Icons.balance_rounded,
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LawsuitDetailScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                label: const Text(
                  'بدء النموذج الإلكتروني الآن',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            number,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.grey.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}

