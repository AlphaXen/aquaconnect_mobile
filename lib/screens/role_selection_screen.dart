import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _loading = false;
  String? _selected;

  Future<void> _handleSelect(String role) async {
    setState(() { _loading = true; _selected = role; });
    await context.read<AppProvider>().selectRole(role);
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
                  Text('역할을 선택해주세요', style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(204), fontWeight: FontWeight.w500)),
                  Text('이후에는 선택한 역할로 바로 입장됩니다', style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(153))),
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
                        const Text('역할 선택', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                        const SizedBox(height: 6),
                        const Text('한 번 선택하면 다음부터 자동으로 입장됩니다', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        const SizedBox(height: 24),
                        _RoleButton(
                          emoji: '🐟',
                          title: '양식장 관리자',
                          subtitle: '수조 관리 · 예약 신청 · 물품 구매',
                          activeColor: const Color(0xFF2563EB),
                          activeBg: const Color(0xFF2563EB),
                          borderColor: const Color(0xFFBFDBFE),
                          isSelected: _selected == 'farm' && _loading,
                          onTap: _loading ? null : () => _handleSelect('farm'),
                        ),
                        const SizedBox(height: 12),
                        _RoleButton(
                          emoji: '🏥',
                          title: '수산질병관리원',
                          subtitle: '예약 승인 · 재고 관리 · 구인 공고',
                          activeColor: const Color(0xFF0F766E),
                          activeBg: const Color(0xFF0F766E),
                          borderColor: const Color(0xFF99F6E4),
                          isSelected: _selected == 'center' && _loading,
                          onTap: _loading ? null : () => _handleSelect('center'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color activeColor;
  final Color activeBg;
  final Color borderColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RoleButton({
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
