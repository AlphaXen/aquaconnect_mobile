import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/server_config.dart';

void showSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  final _urlController = TextEditingController();
  bool _urlSaved = false;
  bool _loadingUrl = true;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final url = await ServerConfig.getUrl();
    if (mounted) {
      setState(() {
        _urlController.text = url;
        _loadingUrl = false;
      });
    }
  }

  Future<void> _saveUrl() async {
    await ServerConfig.setUrl(_urlController.text);
    if (mounted) {
      setState(() => _urlSaved = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _urlSaved = false);
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final current = prov.themeMode;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // 서버 IP 설정
            Row(
              children: [
                const Icon(Icons.computer, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                const Text('젯슨 나노 서버 주소', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    enabled: !_loadingUrl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'http://192.168.0.100:8000',
                      hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
                      prefixIcon: const Icon(Icons.link, size: 18, color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: _urlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _urlController.clear()),
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _saveUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _urlSaved ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_urlSaved ? '저장됨' : '저장', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '예) http://192.168.0.100:8000  (젯슨 나노의 IP:포트)',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // 다크 모드
            Row(
              children: [
                const Icon(Icons.dark_mode, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                const Text('다크 모드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            _ThemeOption(
              icon: Icons.brightness_auto,
              label: '자동 (시스템 설정)',
              selected: current == ThemeMode.system,
              onTap: () => prov.setThemeMode(ThemeMode.system),
            ),
            _ThemeOption(
              icon: Icons.light_mode,
              label: '끄기 (라이트 모드)',
              selected: current == ThemeMode.light,
              onTap: () => prov.setThemeMode(ThemeMode.light),
            ),
            _ThemeOption(
              icon: Icons.dark_mode,
              label: '켜기 (다크 모드)',
              selected: current == ThemeMode.dark,
              onTap: () => prov.setThemeMode(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: selected ? color : null),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      trailing: selected ? Icon(Icons.check_circle, color: color) : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: selected ? color.withAlpha(20) : null,
    );
  }
}
