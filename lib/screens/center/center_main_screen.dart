import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_toast.dart';
import 'center_dashboard_screen.dart';
import 'reservation_management_screen.dart';
import 'inventory_screen.dart';
import 'center_jobs_screen.dart';

class CenterMainScreen extends StatefulWidget {
  const CenterMainScreen({super.key});

  @override
  State<CenterMainScreen> createState() => _CenterMainScreenState();
}

class _CenterMainScreenState extends State<CenterMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CenterDashboardScreen(),
    ReservationManagementScreen(),
    InventoryScreen(),
    CenterJobsScreen(),
  ];

  void _logout() => context.read<AppProvider>().logout();

  @override
  Widget build(BuildContext context) {
    final toast = context.watch<AppProvider>().toast;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.set_meal, size: 22),
            SizedBox(width: 8),
            Text('AquaConnect', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            SizedBox(width: 8),
            _RoleBadge(label: '수산질병관리원'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: '로그아웃'),
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
        indicatorColor: const Color(0xFFCCFBF1),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: '대시보드'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: '예약 관리'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: '재고 관리'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: '구인 공고'),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
  );
}
