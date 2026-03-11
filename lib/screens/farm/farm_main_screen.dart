import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_toast.dart';
import 'farm_dashboard_screen.dart';
import 'tank_management_screen.dart';
import 'reservation_screen.dart';
import 'commerce_screen.dart';
import 'farm_jobs_screen.dart';

class FarmMainScreen extends StatefulWidget {
  const FarmMainScreen({super.key});

  @override
  State<FarmMainScreen> createState() => _FarmMainScreenState();
}

class _FarmMainScreenState extends State<FarmMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FarmDashboardScreen(),
    TankManagementScreen(),
    ReservationScreen(),
    CommerceScreen(),
    FarmJobsScreen(),
  ];

  void _logout() {
    context.read<AppProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final toast = context.watch<AppProvider>().toast;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.set_meal, size: 22),
            SizedBox(width: 8),
            Text('AquaConnect', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            SizedBox(width: 8),
            _RoleBadge(label: '양식장'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Stack(
        children: [
          _pages[_currentIndex],
          AppToast(toast: toast),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDBEAFE),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: '대시보드'),
          NavigationDestination(icon: Icon(Icons.water_outlined), selectedIcon: Icon(Icons.water), label: '수조 관리'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: '예약 신청'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: '쇼핑몰'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: '구인 공고'),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
    );
  }
}
