import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'مرحباً بك في SmartJudi',
      'description': 'منصتك المتكاملة لإدارة القضايا والخدمات القانونية بذكاء وسهولة.',
      'image': 'Icons.gavel_rounded',
    },
    {
      'title': 'المساعد الذكي',
      'description': 'استخدم الذكاء الاصطناعي لتحليل القضايا والحصول على استشارات قانونية فورية.',
      'image': 'Icons.psychology_rounded',
    },
    {
      'title': 'الخدمات الإلكترونية',
      'description': 'تواصل مع المحاكم، ابحث عن القضايا، وتابع الجلسات اليومية من مكان واحد.',
      'image': 'Icons.account_balance_rounded',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      _getIcon(index),
                      size: 150,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _pages[index]['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _pages[index]['description']!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.orange : Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                        style: const TextStyle(fontSize: 18, fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0: return Icons.gavel_rounded;
      case 1: return Icons.psychology_rounded;
      case 2: return Icons.account_balance_rounded;
      default: return Icons.info;
    }
  }
}
