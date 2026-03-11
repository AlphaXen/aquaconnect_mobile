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
  String? _selected;

  Future<void> _handleLogin(String role) async {
    setState(() { _loading = true; _selected = role; });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.read<AppProvider>().login(role);
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
                  // Logo
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

                  // Login card
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
                        const Text('역할을 선택하여 시작하세요', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                        const SizedBox(height: 24),

                        // Farm button
                        _LoginButton(
                          emoji: '🐟',
                          title: '양식장 관리자',
                          subtitle: '수조 관리 · 예약 신청 · 물품 구매',
                          activeColor: const Color(0xFF2563EB),
                          activeBg: const Color(0xFF2563EB),
                          borderColor: const Color(0xFFBFDBFE),
                          isSelected: _selected == 'farm' && _loading,
                          onTap: _loading ? null : () => _handleLogin('farm'),
                        ),
                        const SizedBox(height: 12),

                        // Center button
                        _LoginButton(
                          emoji: '🏥',
                          title: '수산질병관리원',
                          subtitle: '예약 승인 · 재고 관리 · 구인 공고',
                          activeColor: const Color(0xFF0F766E),
                          activeBg: const Color(0xFF0F766E),
                          borderColor: const Color(0xFF99F6E4),
                          isSelected: _selected == 'center' && _loading,
                          onTap: _loading ? null : () => _handleLogin('center'),
                        ),
                        const SizedBox(height: 20),

                        // Security notice
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              const Expanded(
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

class _LoginButton extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color activeColor;
  final Color activeBg;
  final Color borderColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const _LoginButton({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.activeColor,
    required this.activeBg,
    required this.borderColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeBg : borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(51) : borderColor.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF1F2937))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white.withAlpha(204) : const Color(0xFF6B7280))),
                ],
              ),
            ),
            isSelected
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(Icons.chevron_right, color: activeColor),
          ],
        ),
      ),
    );
  }
}
