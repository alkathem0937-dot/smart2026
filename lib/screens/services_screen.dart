import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'legal_library_screen.dart';
import 'smart_assistant_screen.dart';
import 'inquiries_screen.dart';
import 'electronic_lawsuit_screen.dart';
import 'daily_sessions_screen.dart';
import 'complaint_screen.dart';
import 'legal_database_screen.dart';
import 'ai_case_analysis_screen.dart';
import 'case_management_screen.dart';
import 'case_accounting_screen.dart';
import 'legal_forms_screen.dart';
import 'remote_consultations_screen.dart';
import 'procedures_guide_screen.dart';
import 'inheritance_calculation_screen.dart';
import 'area_calculation_screen.dart';
import 'notary_accounting_screen.dart';
import 'contracts_agencies_screen.dart';
import 'electronic_services_screen.dart';

/// Services Screen - خدماتنا
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isLawyer = user?.isLawyer ?? false;
    final isNotary = user?.isNotary ?? false;

    // Services for lawyers - الخدمات التي نقدمها للمحامي
    final lawyerServices = [
      {
        'title': 'الخدمات الإلكترونية والروابط',
        'description': 'الوصول إلى الخدمات الإلكترونية والروابط المهمة',
        'icon': Icons.link,
        'color': const Color(0xFF1E3A8A),
        'route': '/electronic-services',
        'screen': const ElectronicServicesScreen(),
      },
      {
        'title': 'قاعدة البيانات القانونية والدليل',
        'description': 'دليل الإجراءات، بحث ذكي، نسخ وتحميل، جميع القوانين اليمنية المحدثة، القرارات والمنشورات، دليل المحامين، معلومات المحاكم والنيابات',
        'icon': Icons.storage,
        'color': const Color(0xFF8B4513), // Brown color
        'route': '/legal-database',
        'screen': const LegalDatabaseScreen(),
      },
      {
        'title': 'المساعد القانوني الذكي',
        'description': 'مساعد ذكي للإجابة على الأسئلة والاستشارات القانونية بناءً على القوانين اليمنية، دليل الإجراءات، المنشورات، الفقه الإسلامي الصحيح، التفسيرات المبسطة، والقرآن الكريم',
        'icon': Icons.psychology,
        'color': Colors.purple,
        'route': '/smart-assistant',
        'screen': const SmartAssistantScreen(),
      },
      {
        'title': 'تحليل وإعداد القضايا بالذكاء الاصطناعي',
        'description': 'تحليل القضايا باستخدام الذكاء الاصطناعي بناءً على القوانين والتشريعات، إعداد الدعاوى حسب البيانات المقدمة وأطراف التقاضي، معالجة الردود على الدعاوى والطعون والخدمات المطلوبة',
        'icon': Icons.auto_awesome,
        'color': Colors.indigo,
        'route': '/ai-case-analysis',
        'screen': const AICaseAnalysisScreen(),
      },
      {
        'title': 'إدارة القضايا الإلكترونية والتواصل مع العملاء',
        'description': 'أرشفة القضايا إلكترونياً، مسح وتخزين الوثائق المتعلقة بكل قضية، تقويم الجلسات والإشعارات الذكية للمتابعة، متابعة تقدم القضايا، دردشة للتواصل مع العملاء عبر المنصة، منح العملاء صلاحيات الوصول لإجراءات القضايا وإرسال الملاحظات',
        'icon': Icons.folder_open,
        'color': Colors.teal,
        'route': '/case-management',
        'screen': const CaseManagementScreen(),
      },
      {
        'title': 'نظام محاسبة خاص بالقضايا',
        'description': 'نظام محاسبة لكل قضية يدير حساباتها، معالجة اتفاقيات الأتعاب المتعلقة بالمحاماة، مرتبط بالأرشيف والجلسات',
        'icon': Icons.account_balance_wallet,
        'color': Colors.green,
        'route': '/case-accounting',
        'screen': const CaseAccountingScreen(),
      },
      {
        'title': 'رفع الدعاوى الإلكترونية وإدارة المحاكم',
        'description': 'رفع الدعاوى إلكترونياً باستخدام النماذج الحكومية، الرد على الدعاوى والطعون، البحث عن القضايا وتواريخ الجلسات في المحاكم',
        'icon': Icons.gavel,
        'color': Colors.blue,
        'route': '/electronic-lawsuit',
        'screen': const ElectronicLawsuitScreen(),
      },
      {
        'title': 'النماذج القانونية الجاهزة والموارد',
        'description': 'نماذج جاهزة لجميع أنواع نماذج المحاكم والطلبات والردود، يوفر كل ما يحتاجه المحامي',
        'icon': Icons.description,
        'color': Colors.orange,
        'route': '/legal-forms',
        'screen': const LegalFormsScreen(),
      },
      {
        'title': 'الاستشارات القانونية عن بُعد',
        'description': 'استشارات قانونية مباشرة مع محامين مدفوعين، يتضمن ميزة الدردشة للعملاء، دفع إلكتروني للاستشارات عن بُعد',
        'icon': Icons.video_call,
        'color': Colors.red,
        'route': '/remote-consultations',
        'screen': const RemoteConsultationsScreen(),
      },
    ];

    // Services for notaries (الأمين الشرعي) - الخدمات التي نقدمها للأمين الشرعي
    final notaryServices = [
      {
        'title': 'الخدمات الإلكترونية والروابط',
        'description': 'الوصول إلى الخدمات الإلكترونية والروابط المهمة',
        'icon': Icons.link,
        'color': const Color(0xFF1E3A8A),
        'route': '/electronic-services',
        'screen': const ElectronicServicesScreen(),
      },
      {
        'title': 'دليل الإجراءات',
        'description': 'دليل الإجراءات للأمناء وميزة البحث الذكي والنسخ والتحميل، جميع القوانين اليمنية المحدثة والقرارات والتعميمات، معرفة الأمناء ومناطق اختصاصهم والبحث عنهم والتواصل معهم',
        'icon': Icons.book,
        'color': Colors.blue,
        'route': '/procedures-guide',
        'screen': const ProceduresGuideScreen(),
      },
      {
        'title': 'مساعد ذكي للإجابة',
        'description': 'مساعد ذكي للإجابة عن الأسئلة والفتاوى استناداً للقوانين اليمنية والدليل الإجرائي والتعاميم والفقه الإسلامي الصحيح والتفسير الميسر والقرآن الكريم',
        'icon': Icons.psychology,
        'color': Colors.purple,
        'route': '/smart-assistant',
        'screen': const SmartAssistantScreen(),
      },
      {
        'title': 'حساب المواريث',
        'description': 'حساب المواريث اليمنية استناداً لكتاب القسمة من وزارة العدل، تقسيم الورث حسب المدخلات وجمع وحصر التركة وحساب الديون والوصايا',
        'icon': Icons.calculate,
        'color': Colors.green,
        'route': '/inheritance-calculation',
        'screen': const InheritanceCalculationScreen(),
      },
      {
        'title': 'حساب المساحات',
        'description': 'حساب المساحات وإسقاط الأراضي عبر خرائط متقدمة وتقريبية، تخطيط المساحة وحفظ وأرشفة المساحات الخاصة بالعمل وبيع وشراء العقارات',
        'icon': Icons.map,
        'color': Colors.orange,
        'route': '/area-calculation',
        'screen': const AreaCalculationScreen(),
      },
      {
        'title': 'نظام محاسبي',
        'description': 'نظام محاسبي للموردين وأصحاب العقار والمشترين، التثمين وربط الحسابات بالأرشيف والمساعد الذكي، تحديثات أسعار الصرف والذهب والأسعار السابقة',
        'icon': Icons.account_balance,
        'color': Colors.teal,
        'route': '/notary-accounting',
        'screen': const NotaryAccountingScreen(),
      },
      {
        'title': 'العقود والوكالات',
        'description': 'العقود والوكالات وجميع المحررات الذكية والآلية، الإدخال بسهولة وتدقيق إملائية وصيغ جاهزة، تعمل بآلية الوزارة أرشيف المحررات مع تخزين محلي ونسخة احتياطية للبطائق والمستندات، تخزين الصور وجميع أنواع المستندات المهمة والسندات القبض والتوريد',
        'icon': Icons.description,
        'color': Colors.indigo,
        'route': '/contracts-agencies',
        'screen': const ContractsAgenciesScreen(),
      },
    ];

    // General services for all users
    final generalServices = [
      {
        'title': 'الخدمات الإلكترونية والروابط',
        'description': 'الوصول إلى الخدمات الإلكترونية والروابط المهمة',
        'icon': Icons.link,
        'color': const Color(0xFF1E3A8A),
        'route': '/electronic-services',
        'screen': const ElectronicServicesScreen(),
      },
      {
        'title': 'رفع دعوى إلكترونية',
        'description': 'رفع الدعاوى إلكترونياً بسهولة',
        'icon': Icons.gavel,
        'color': Colors.blue,
        'route': '/electronic-lawsuit',
        'screen': const ElectronicLawsuitScreen(),
      },
      {
        'title': 'المكتبة القانونية',
        'description': 'تصفح القوانين والمراجع القانونية',
        'icon': Icons.library_books,
        'color': Colors.green,
        'route': '/legal-library',
        'screen': const LegalLibraryScreen(),
      },
      {
        'title': 'المساعد الذكي',
        'description': 'احصل على إجابات لأسئلتك القانونية',
        'icon': Icons.smart_toy,
        'color': Colors.purple,
        'route': '/smart-assistant',
        'screen': const SmartAssistantScreen(),
      },
      {
        'title': 'الاستعلامات',
        'description': 'استعلم عن حالة دعواك',
        'icon': Icons.search,
        'color': Colors.orange,
        'route': '/inquiries',
        'screen': const InquiriesScreen(),
      },
      {
        'title': 'الجلسات اليومية',
        'description': 'عرض الجلسات اليومية',
        'icon': Icons.event,
        'color': Colors.red,
        'route': '/daily-sessions',
        'screen': const DailySessionsScreen(),
      },
      if (user != null)
        {
          'title': 'رفع شكوى',
          'description': 'رفع شكوى أو بلاغ',
          'icon': Icons.report_problem,
          'color': Colors.amber,
          'route': '/complaint',
          'screen': const ComplaintScreen(),
        },
    ];

    final services = isLawyer
        ? lawyerServices
        : isNotary
            ? notaryServices
            : generalServices;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLawyer
              ? 'الخدمات التي نقدمها للمحامي'
              : isNotary
                  ? 'الخدمات التي نقدمها للأمين الشرعي'
                  : 'خدماتنا',
        ),
      ),
      body: (isLawyer || isNotary)
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => service['screen'] as Widget,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: (service['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              service['icon'] as IconData,
                              size: 30,
                              color: service['color'] as Color,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  service['description'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => service['screen'] as Widget,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            service['icon'] as IconData,
                            size: 50,
                            color: service['color'] as Color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            service['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              service['description'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

