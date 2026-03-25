import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleGoogleLogin() async {
    setState(() { _loading = true; _error = null; });
    final user = await context.read<AppProvider>().signInWithGoogle();
    if (!mounted) return;
    if (user == null) {
      setState(() { _loading = false; _error = '로그인이 취소되었거나 실패했습니다.'; });
    }
    // 성공 시 AppProvider가 notifyListeners() → _AppRouter가 RoleSelectionScreen으로 전환
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF0F766E), Color(0xFF1D4ED8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.set_meal, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('AquaConnect', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('넙치 자동 접종 O2O 플랫폼', style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(204), fontWeight: FontWeight.w500)),
                  Text('양식장 ↔ 수산질병관리원 연결 시스템', style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(153))),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const Text('로그인', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                        const SizedBox(height: 6),
                        const Text('Google 계정으로 시작하세요', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                        const SizedBox(height: 24),
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _loading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              )
                            : GestureDetector(
                                onTap: _handleGoogleLogin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                        width: 24, height: 24,
                                        errorBuilder: (ctx, err, stack) => const Icon(Icons.login, size: 24, color: Color(0xFF4285F4)),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Google로 로그인',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: Color(0xFF16A34A)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '보안 접속 · 역할 기반 접근 제어(RBAC) · 트랜잭션 로그 자동 저장',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('커미션율 기본 10% · 전자계약 자동 생성', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('AquaConnect MVP v1.0', style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
