import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/lawsuit_provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/register_screen.dart';
import 'screens/legal_library_screen.dart';
import 'screens/smart_assistant_screen.dart';
import 'screens/training_screen.dart';
import 'screens/inquiries_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/blog_screen.dart';
import 'screens/laws_screen.dart';
import 'screens/services_screen.dart';
import 'screens/complaint_screen.dart';
import 'screens/daily_sessions_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/electronic_lawsuit_screen.dart';
import 'screens/supreme_court_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/subscribe_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/payment_order_screen.dart';
import 'screens/appeal_screen.dart';
import 'screens/legal_database_screen.dart';
import 'screens/ai_case_analysis_screen.dart';
import 'screens/case_management_screen.dart';
import 'screens/case_accounting_screen.dart';
import 'screens/legal_forms_screen.dart';
import 'screens/remote_consultations_screen.dart';
import 'screens/procedures_guide_screen.dart';
import 'screens/inheritance_calculation_screen.dart';
import 'screens/area_calculation_screen.dart';
import 'screens/notary_accounting_screen.dart';
import 'screens/contracts_agencies_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/electronic_services_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    final prefs = await SharedPreferences.getInstance();
    final bool showOnboarding = prefs.getBool('onboarding_completed') != true;

    runApp(MyApp(showOnboarding: showOnboarding));
  }, (error, stack) {
    if (kDebugMode) debugPrint('❌ [Zone Error] $error');
  });
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService: apiService)..initialize()),
        ChangeNotifierProvider(create: (_) => LawsuitProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(apiService),
          update: (_, auth, prev) => NotificationProvider(apiService),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'SmartJudi',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Cairo', // تأكد من وجود الخط في pubspec.yaml
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFD4AF37), // ذهبي
                primary: const Color(0xFFD4AF37),
                secondary: const Color(0xFFB8860B),
                surface: const Color(0xFFFDFBF7), // بيج فاتح جداً كخلفية
              ),
              scaffoldBackgroundColor: const Color(0xFFFDFBF7),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
              ),
            ),
            home: showOnboarding ? const OnboardingScreen() : const AuthWrapper(),

            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const EditProfileScreen(),
              '/change-password': (context) => const ChangePasswordScreen(),
              '/electronic-services': (context) => const ElectronicServicesScreen(),
              '/services': (context) => const ServicesScreen(),
              '/legal-library': (context) => const LegalLibraryScreen(),
              '/smart-assistant': (context) => const SmartAssistantScreen(),
              '/inquiries': (context) => const InquiriesScreen(),
              '/daily-sessions': (context) => const DailySessionsScreen(),
              '/electronic-lawsuit': (context) => const ElectronicLawsuitScreen(),
              '/laws': (context) => const LawsScreen(),
              '/training': (context) => const TrainingScreen(),
              '/supreme-court': (context) => const SupremeCourtScreen(),
              '/blog': (context) => const BlogScreen(),
              '/faq': (context) => const FAQScreen(),
              '/about-us': (context) => const AboutUsScreen(),
              '/contact-us': (context) => const ContactUsScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/subscribe': (context) => const SubscribeScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
