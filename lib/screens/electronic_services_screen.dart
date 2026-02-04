import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'webview_screen.dart';

/// Electronic Services Screen - الخدمات الإلكترونية والروابط
class ElectronicServicesScreen extends StatelessWidget {
  const ElectronicServicesScreen({super.key});

  // الخدمات الإلكترونية
  final List<Map<String, String>> _electronicServices = const [
    {
      'title': 'البحث عن قضية',
      'url': 'http://mojcitr.myftp.biz:8008/JUDDATALIST/CustomRetCaseMaster',
    },
    {
      'title': 'خدمة الدعاوى الإلكتروني',
      'url': 'https://judg.moj.gov.ye:8065/',
    },
    {
      'title': 'البحث عن الامناء الشرعيين',
      'url': 'http://mojcitr.myftp.biz:8008/OMANALIST/CustomGetOmanaWithPic',
    },
    {
      'title': 'البحث عن المعاملات',
      'url': 'http://mojcitr.myftp.biz:8008/InoutData/CustomInOutData',
    },
    {
      'title': 'البحث عن الجلسات اليومية',
      'url': 'http://mojcitr.myftp.biz:8008/JudgmentData/CustomRetCourtSittingByDate',
    },
  ];

  // روابط تهمك
  final List<Map<String, String>> _importantLinks = const [
    {
      'title': 'مجلس القضاء الأعلى',
      'url': 'http://www.sjc-yemen.com/',
    },
    {
      'title': 'المحكمة العليا',
      'url': 'https://ysc.org.ye/',
    },
    {
      'title': 'النيابة العامة',
      'url': 'https://agoye.gov.ye/',
    },
    {
      'title': 'المعهد العالي للقضاء',
      'url': 'http://www.hji-yemen.com/',
    },
    {
      'title': 'الجريدة الرسمية',
      'url': 'https://moj.gov.ye/OfficialGazette',
    },
  ];

  // روابط إضافية
  final List<Map<String, String>> _additionalLinks = const [
    {
      'title': 'وزارة العدل',
      'url': 'https://moj.gov.ye/',
    },
    {
      'title': 'تنزيل القوانين والتشريعات',
      'url': 'https://moj.gov.ye/LawsM',
    },
  ];

  void _handleLinkTap(BuildContext context, String url, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.apps, color: Color(0xFF1E3A8A)),
              title: const Text('فتح داخل التطبيق (سريع)', style: TextStyle(fontFamily: 'Cairo')),
              subtitle: const Text('عرض الموقع مباشرة هنا', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _openInWebView(context, url, title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_browser, color: Colors.orange),
              title: const Text('فتح في متصفح خارجي (Chrome)', style: TextStyle(fontFamily: 'Cairo')),
              subtitle: const Text('للحصول على أفضل توافقية وأمان', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _openExternally(url);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openInWebView(BuildContext context, String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: url,
          title: title,
        ),
      ),
    );
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخدمات الإلكترونية والروابط'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF1E40AF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context: context,
                title: 'الخدمات الالكترونية',
                items: _electronicServices,
              ),
              const SizedBox(height: 32),
              _buildSection(
                context: context,
                title: 'روابط تهمك',
                items: _importantLinks,
              ),
              const SizedBox(height: 32),
              _buildSection(
                context: context,
                title: 'روابط إضافية',
                items: _additionalLinks,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Map<String, String>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF60A5FA), width: 2),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _buildServiceItem(
          title: item['title']!,
          url: item['url']!,
          onTap: () => _handleLinkTap(context, item['url']!, item['title']!),
        )),
      ],
    );
  }

  Widget _buildServiceItem({
    required String title,
    required String url,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.language, color: Color(0xFF60A5FA)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
