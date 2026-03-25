import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/farm/farm_main_screen.dart';
import 'screens/center/center_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('ko_KR', null);

  final appProvider = AppProvider();
  await appProvider.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const AquaConnectApp(),
    ),
  );
}

class AquaConnectApp extends StatelessWidget {
  const AquaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppProvider>().themeMode;
    return MaterialApp(
      title: 'AquaConnect',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
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
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'pretendard',
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

    // Firebase 로그인 안 됨 → 로그인 화면
    if (!prov.isFirebaseLoggedIn) return const LoginScreen();

    // Firebase 로그인은 됐지만 역할 미선택 → 역할 선택 화면
    if (!prov.isLoggedIn) return const RoleSelectionScreen();

    // 역할까지 선택 완료 → 메인 화면
    return prov.currentUser?.role == 'farm'
        ? const FarmMainScreen()
        : const CenterMainScreen();
  }
}

// 이 코드는 가장 처음 실행되는 메인 코드입니다.
