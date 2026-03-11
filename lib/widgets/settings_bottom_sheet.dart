import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

void showSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final current = prov.themeMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
          const SizedBox(height: 16),
          const Text('다크 모드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
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
