import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final String color;
  final String? icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.color = 'blue',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(color);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    ),
                    if (sub != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(sub!, style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              if (icon != null)
                Text(icon!, style: const TextStyle(fontSize: 28)),
            ],
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient(String c) {
    switch (c) {
      case 'green':  return const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]);
      case 'amber':  return const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]);
      case 'red':    return const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]);
      case 'teal':   return const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]);
      case 'purple': return const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF9333EA)]);
      case 'blue':
      default:       return const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]);
    }
  }
}
