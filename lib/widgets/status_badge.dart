import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.$1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.$2),
      ),
      child: Text(
        config.$3,
        style: TextStyle(
          color: config.$2,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (Color, Color, String) _getConfig(String s) {
    switch (s) {
      case 'healthy':   return (const Color(0xFFDCFCE7), const Color(0xFF166534), '정상');
      case 'warning':   return (const Color(0xFFFEF3C7), const Color(0xFF92400E), '주의');
      case 'danger':    return (const Color(0xFFFEE2E2), const Color(0xFF991B1B), '위험');
      case 'pending':   return (const Color(0xFFFEF3C7), const Color(0xFF92400E), '대기중');
      case 'approved':  return (const Color(0xFFDCFCE7), const Color(0xFF166534), '승인됨');
      case 'rejected':  return (const Color(0xFFFEE2E2), const Color(0xFF991B1B), '거절됨');
      case 'completed': return (const Color(0xFFDBEAFE), const Color(0xFF1E40AF), '완료');
      case 'open':      return (const Color(0xFFDCFCE7), const Color(0xFF166534), '모집중');
      case 'closed':    return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), '마감');
      case 'instock':   return (const Color(0xFFDCFCE7), const Color(0xFF166534), '재고있음');
      case 'lowstock':  return (const Color(0xFFFEF3C7), const Color(0xFF92400E), '재고부족');
      case 'outofstock':return (const Color(0xFFFEE2E2), const Color(0xFF991B1B), '품절');
      default:          return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), s);
    }
  }
}
