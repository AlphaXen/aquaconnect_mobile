import 'package:flutter/material.dart';
import '../models/models.dart';

class AppToast extends StatelessWidget {
  final ToastMessage? toast;

  const AppToast({super.key, this.toast});

  @override
  Widget build(BuildContext context) {
    if (toast == null) return const SizedBox.shrink();

    Color bg;
    Color fg;
    IconData iconData;
    switch (toast!.type) {
      case 'error':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        iconData = Icons.error_outline;
        break;
      case 'info':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        iconData = Icons.info_outline;
        break;
      default:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        iconData = Icons.check_circle_outline;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fg.withAlpha(77)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(iconData, color: fg, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(toast!.message, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
