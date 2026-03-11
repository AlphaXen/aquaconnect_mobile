import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Map<String, int> _stocks;
  String _catFilter = '전체';
  bool _initialized = false;

  void _initStocks(List<Product> products) {
    if (!_initialized) {
      _stocks = {for (final p in products) p.id: p.stock};
      _initialized = true;
    }
  }

  void _restock(BuildContext context, String id, String name) {
    setState(() => _stocks[id] = (_stocks[id] ?? 0) + 50);
    context.read<AppProvider>().showToast('$name 재고 50개 입고 완료');
  }

  String _getStatus(String id) {
    final s = _stocks[id] ?? 0;
    if (s == 0) return 'outofstock';
    if (s <= 5) return 'lowstock';
    return 'instock';
  }

  String _emoji(String cat) => switch (cat) {
    '백신' => '💉',
    '의약품' => '💊',
    '사료' => '🐟',
    _ => '📦',
  };

  @override
  Widget build(BuildContext context) {
    final products = context.watch<AppProvider>().products;
    _initStocks(products);

    final categories = ['전체', ...products.map((p) => p.category).toSet()];
    final filtered = _catFilter == '전체' ? products : products.where((p) => p.category == _catFilter).toList();
    final lowCount = products.where((p) => (_stocks[p.id] ?? 0) <= 5).length;
    final normalCount = products.where((p) => (_stocks[p.id] ?? 0) > 5).length;
    final warningCount = products.where((p) { final s = _stocks[p.id] ?? 0; return s > 0 && s <= 5; }).length;
    final outCount = products.where((p) => (_stocks[p.id] ?? 0) == 0).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('재고 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            if (lowCount > 0)
              Text('⚠️ 재고 부족 $lowCount개 품목', style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),

        // Summary cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Expanded(child: _SummaryCard(value: normalCount, label: '정상 재고', bg: const Color(0xFFF0FDF4), border: const Color(0xFF86EFAC), valueColor: const Color(0xFF16A34A))),
            const SizedBox(width: 10),
            Expanded(child: _SummaryCard(value: warningCount, label: '재고 부족', bg: const Color(0xFFFFFBEB), border: const Color(0xFFFDE68A), valueColor: const Color(0xFFD97706))),
            const SizedBox(width: 10),
            Expanded(child: _SummaryCard(value: outCount, label: '품절', bg: const Color(0xFFFEF2F2), border: const Color(0xFFFCA5A5), valueColor: const Color(0xFFDC2626))),
          ]),
        ),

        // Category filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: categories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _catFilter = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _catFilter == c ? const Color(0xFF0F766E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _catFilter == c ? const Color(0xFF0F766E) : const Color(0xFFE5E7EB)),
                  ),
                  child: Text(c, style: TextStyle(color: _catFilter == c ? Colors.white : const Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            )).toList(),
          ),
        ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
              itemBuilder: (ctx, i) {
                final p = filtered[i];
                final stock = _stocks[p.id] ?? 0;
                final status = _getStatus(p.id);
                Color rowBg = Colors.white;
                if (status == 'outofstock') rowBg = const Color(0xFFFEF2F2);
                if (status == 'lowstock') rowBg = const Color(0xFFFFFBEB);

                return Container(
                  color: rowBg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(_emoji(p.category), style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1F2937))),
                          Row(children: [
                            Text(p.category, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                            const SizedBox(width: 8),
                            StatusBadge(status: status),
                          ]),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(children: [
                          Text('$stock', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: stock <= 5 ? const Color(0xFFDC2626) : const Color(0xFF1F2937))),
                          const Text('개', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(formatCurrency(p.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF374151))),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _restock(ctx, p.id, p.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(10)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.add, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('입고', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ]),
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int value;
  final String label;
  final Color bg, border, valueColor;
  const _SummaryCard({required this.value, required this.label, required this.bg, required this.border, required this.valueColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
    child: Column(children: [
      Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valueColor)),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: valueColor)),
    ]),
  );
}
