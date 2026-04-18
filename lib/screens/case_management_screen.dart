import 'package:flutter/material.dart';

/// Electronic Case Management and Client Communication Screen
/// إدارة القضايا الإلكترونية والتواصل مع العملاء
class CaseManagementScreen extends StatelessWidget {
  const CaseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة القضايا الإلكترونية والتواصل مع العملاء'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeatureCard(
            context,
            icon: Icons.folder,
            title: 'أرشفة القضايا الإلكترونية',
            description: 'أرشفة القضايا إلكترونياً مع مسح وتخزين الوثائق المتعلقة بكل قضية',
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/lawsuits'),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.calendar_today,
            title: 'تقويم الجلسات والإشعارات',
            description: 'تقويم الجلسات مع إشعارات ذكية للمتابعة',
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, '/calendar'),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.track_changes,
            title: 'متابعة تقدم القضايا',
            description: 'تتبع حالة القضايا ومراحل تقدمها',
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/lawsuits'),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.chat,
            title: 'التواصل مع العملاء',
            description: 'دردشة للتواصل مع العملاء عبر المنصة',
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/messages'),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.share,
            title: 'منح صلاحيات الوصول',
            description: 'منح العملاء صلاحيات الوصول لإجراءات القضايا وإرسال الملاحظات',
            color: Colors.teal,
            onTap: () => Navigator.pushNamed(context, '/create-sub-account'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
