import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'lawsuits_list_screen.dart';
import 'lawsuit_detail_screen.dart';
import 'inquiries_screen.dart';
import 'settings_screen.dart';
import 'payment_order_screen.dart';
import 'appeal_screen.dart';
import 'daily_sessions_screen.dart';
import 'calendar_screen.dart';
import 'legal_library_screen.dart';
import 'services_screen.dart';

/// Home Screen - Dashboard based on user role
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 5; // Start with Home selected (rightmost)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE91E63), width: 3),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side icons (Search, Notifications, AI)
                  Row(
                    children: [
                      // AI Icon with badge
                      _buildHeaderIcon(
                        icon: Icons.psychology,
                        badge: 'AI',
                        onTap: () => Navigator.pushNamed(context, '/smart-assistant'),
                      ),
                      const SizedBox(width: 12),
                      // Notifications Icon
                      Consumer<NotificationProvider>(
                        builder: (context, notificationProvider, _) {
                          final unreadCount = notificationProvider.unreadCount;
                          return _buildHeaderIcon(
                            icon: Icons.notifications_outlined,
                            badge: unreadCount > 0 ? (unreadCount > 99 ? '99+' : unreadCount.toString()) : null,
                            onTap: () {
                              Navigator.pushNamed(context, '/notifications');
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // Search Icon
                      _buildHeaderIcon(
                        icon: Icons.search,
                        onTap: () => Navigator.pushNamed(context, '/inquiries'),
                      ),
                    ],
                  ),
                  // Right side - Title
                  const Text(
                    'منصة القضاء الذكية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(user, authProvider),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0 - Menu (handled by drawer)
          _buildMainDashboard(user),
          // 1 - Calendar / Daily Sessions
          const CalendarScreen(),
          // 2 - Files / Archives
          const LawsuitsListScreen(),
          // 3 - Library / Books
          const LegalLibraryScreen(),
          // 4 - Layers / Services
          const ServicesScreen(),
          // 5 - Home / Dashboard
          _buildMainDashboard(user),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E0D5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            if (badge != null)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Menu (hamburger)
          _buildNavItem(
            index: 0,
            icon: _buildMenuIcon(),
            isCustomIcon: true,
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          // Calendar
          _buildNavItem(
            index: 1,
            icon: _buildCalendarIcon(),
            isCustomIcon: true,
          ),
          // Colorful Binders/Files
          _buildNavItem(
            index: 2,
            icon: _buildBindersIcon(),
            isCustomIcon: true,
          ),
          // Books/Documents
          _buildNavItem(
            index: 3,
            icon: _buildBooksIcon(),
            isCustomIcon: true,
          ),
          // Layers/Stack
          _buildNavItem(
            index: 4,
            icon: _buildLayersIcon(),
            isCustomIcon: true,
          ),
          // Home
          _buildNavItem(
            index: 5,
            icon: _buildHomeIcon(),
            isCustomIcon: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required Widget icon,
    bool isCustomIcon = false,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: onTap ?? () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Custom icon builders to match the design
  Widget _buildMenuIcon() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 24, height: 3, color: const Color(0xFFE57373)),
        const SizedBox(height: 4),
        Container(width: 24, height: 3, color: const Color(0xFFE57373)),
        const SizedBox(height: 4),
        Container(width: 24, height: 3, color: const Color(0xFFE57373)),
      ],
    );
  }

  Widget _buildCalendarIcon() {
    return Container(
      width: 28,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(1),
                topRight: Radius.circular(1),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '12',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBindersIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSingleBinder(const Color(0xFFFDD835)), // Yellow
        const SizedBox(width: 2),
        _buildSingleBinder(const Color(0xFF4CAF50)), // Green
        const SizedBox(width: 2),
        _buildSingleBinder(const Color(0xFFFF9800)), // Orange
      ],
    );
  }

  Widget _buildSingleBinder(Color color) {
    return Container(
      width: 10,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black45, width: 1),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black45, width: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksIcon() {
    return SizedBox(
      width: 32,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.rotate(
              angle: -0.15,
              child: Container(
                width: 24,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 5,
            left: 2,
            child: Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 22,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCD853F),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 9,
            left: 4,
            child: Container(
              width: 20,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD2691E),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 16,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.black26, width: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersIcon() {
    return SizedBox(
      width: 32,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: _buildDiamond(const Color(0xFF8B4513), 28, 12),
          ),
          Positioned(
            bottom: 6,
            child: _buildDiamond(const Color(0xFFFFD54F), 24, 10),
          ),
          Positioned(
            bottom: 12,
            child: _buildDiamond(const Color(0xFF4CAF50), 20, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildDiamond(Color color, double width, double height) {
    return Transform.rotate(
      angle: 0,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.black26, width: 0.5),
        ),
      ),
    );
  }

  Widget _buildHomeIcon() {
    return const Icon(
      Icons.home,
      size: 32,
      color: Colors.black87,
    );
  }

  Widget _buildMainDashboard(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'مرحباً، ${user.fullName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                Text(
                  'أهلاً بك في منصة القضاء الذكية',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Quick Actions Grid
          const Text(
            'الخدمات السريعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildQuickActionCard(
                icon: Icons.gavel,
                label: 'رفع دعوى',
                color: const Color(0xFFE91E63),
                onTap: () => Navigator.pushNamed(context, '/electronic-lawsuit'),
              ),
              _buildQuickActionCard(
                icon: Icons.search,
                label: 'استعلام',
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.pushNamed(context, '/inquiries'),
              ),
              _buildQuickActionCard(
                icon: Icons.calendar_today,
                label: 'الجلسات',
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.pushNamed(context, '/daily-sessions'),
              ),
              _buildQuickActionCard(
                icon: Icons.payment,
                label: 'أمر الأداء',
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentOrderScreen()),
                ),
              ),
              _buildQuickActionCard(
                icon: Icons.compare_arrows,
                label: 'الطعون',
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AppealScreen()),
                ),
              ),
              _buildQuickActionCard(
                icon: Icons.smart_toy,
                label: 'المساعد الذكي',
                color: const Color(0xFF00BCD4),
                onTap: () => Navigator.pushNamed(context, '/smart-assistant'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Additional Services
          const Text(
            'المزيد من الخدمات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildServiceCard(
                icon: Icons.library_books,
                label: 'المكتبة القانونية',
                onTap: () => Navigator.pushNamed(context, '/legal-library'),
              ),
              _buildServiceCard(
                icon: Icons.balance,
                label: 'المحكمة العليا',
                onTap: () => Navigator.pushNamed(context, '/supreme-court'),
              ),
              _buildServiceCard(
                icon: Icons.school,
                label: 'التدريب والتأهيل',
                onTap: () => Navigator.pushNamed(context, '/training'),
              ),
              _buildServiceCard(
                icon: Icons.contact_mail,
                label: 'تواصل معنا',
                onTap: () => Navigator.pushNamed(context, '/contact-us'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A1A1A), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(dynamic user, AuthProvider authProvider) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 11,
                right: 16,
                left: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFE91E63),
                    child: Text(
                      user.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home,
              label: 'الرئيسية',
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 5);
              },
            ),
            _buildDrawerItem(
              icon: Icons.person,
              label: 'الملف الشخصي',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            _buildDrawerItem(
              icon: Icons.gavel,
              label: 'الدعاوى',
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            _buildDrawerItem(
              icon: Icons.work,
              label: 'خدماتنا',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/services');
              },
            ),
            _buildDrawerItem(
              icon: Icons.library_books,
              label: 'المكتبة القانونية',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/legal-library');
              },
            ),
            _buildDrawerItem(
              icon: Icons.smart_toy,
              label: 'المساعد الذكي',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/smart-assistant');
              },
            ),
            _buildDrawerItem(
              icon: Icons.search,
              label: 'الاستعلامات',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/inquiries');
              },
            ),
            _buildDrawerItem(
              icon: Icons.event,
              label: 'الجلسات اليومية',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/daily-sessions');
              },
            ),
            _buildDrawerItem(
              icon: Icons.add_circle,
              label: 'رفع دعوى إلكترونية',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/electronic-lawsuit');
              },
            ),
            _buildDrawerItem(
              icon: Icons.payment,
              label: 'أمر الأداء',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentOrderScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.gavel,
              label: 'الطعون',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AppealScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.book,
              label: 'القوانين',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/laws');
              },
            ),
            _buildDrawerItem(
              icon: Icons.school,
              label: 'التدريب والتأهيل',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/training');
              },
            ),
            _buildDrawerItem(
              icon: Icons.balance,
              label: 'المحكمة العليا',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/supreme-court');
              },
            ),
            _buildDrawerItem(
              icon: Icons.article,
              label: 'مدونة',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/blog');
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline,
              label: 'أسئلة شائعة',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/faq');
              },
            ),
            _buildDrawerItem(
              icon: Icons.info,
              label: 'من نحن',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about-us');
              },
            ),
            _buildDrawerItem(
              icon: Icons.contact_mail,
              label: 'تواصل بنا',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/contact-us');
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              label: 'الإعدادات',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
                },
              ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.logout,
              label: 'تسجيل الخروج',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF1A1A1A)),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: color ?? Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
