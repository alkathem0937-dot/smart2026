import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class NotaryDashboardScreen extends StatelessWidget {
  const NotaryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('بوابة الأمين الشرعي (قيد التطوير)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.amber,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.amber.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.handyman_rounded, color: AppColors.amber, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('مرحباً بك في بوابة الأمين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('هذه البوابة لا تزال قيد التطوير وسيتم تفعيل جميع خدماتها قريباً.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('الخدمات السريعة للأمين الشرعي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildNotaryServiceCard(context, 'حساب المواريث', Icons.calculate_rounded, Colors.purple, '/inheritance'),
                _buildNotaryServiceCard(context, 'حساب المساحات', Icons.map_rounded, Colors.green, '/area'),
                _buildNotaryServiceCard(context, 'العقود والوكالات', Icons.edit_document, Colors.blue, '/agencies'),
                _buildNotaryServiceCard(context, 'سجلات الأمناء', Icons.receipt_long_rounded, Colors.orange, '/notary-accounting'),
              ],
            ),
            const SizedBox(height: 32),
            const Text('أدوات إضافية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.chat, color: Colors.white)),
                title: const Text('المراسلات والاستشارات', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('الرد على استفسارات الموكلين المعمارية والشرعية'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/messages'),
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.folder_shared, color: Colors.white)),
                title: const Text('أرشيف الأمين', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('أرشفة العقود والمعاملات الخاصة بك'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/lawsuits'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNotaryServiceCard(BuildContext context, String title, IconData icon, Color color, String route) {
    bool isDark = context.isDark;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
