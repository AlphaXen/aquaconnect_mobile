import 'package:intl/intl.dart';

String formatCurrency(int amount) {
  final formatter = NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
  return formatter.format(amount);
}

String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final d = DateTime.parse(dateStr);
    return DateFormat('yyyy년 M월 d일', 'ko_KR').format(d);
  } catch (_) {
    return dateStr;
  }
}
