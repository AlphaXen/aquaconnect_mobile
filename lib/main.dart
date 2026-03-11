import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/farm/farm_main_screen.dart';
import 'screens/center/center_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const AquaConnectApp(),
    ),
  );
}

class AquaConnectApp extends StatelessWidget {
  const AquaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        fontFamily: 'pretendard',
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    if (!prov.isLoggedIn) return const LoginScreen();

    return prov.currentUser?.role == 'farm'
        ? const FarmMainScreen()
        : const CenterMainScreen();
  }
}
