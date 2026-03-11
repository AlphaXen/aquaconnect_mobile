import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

const _categories = ['전체', '백신', '의약품', '사료', '장비', '소모품'];

class CommerceScreen extends StatefulWidget {
  const CommerceScreen({super.key});

  @override
  State<CommerceScreen> createState() => _CommerceScreenState();
}

class _CommerceScreenState extends State<CommerceScreen> {
  final Map<String, int> _cart = {};
  String _catFilter = '전체';

  void _addToCart(String id) => setState(() => _cart[id] = (_cart[id] ?? 0) + 1);
  void _removeFromCart(String id) => setState(() {
    final n = (_cart[id] ?? 0) - 1;
    if (n <= 0) {
      _cart.remove(id);
    } else {
      _cart[id] = n;
    }
  });

  int get _cartCount => _cart.values.fold(0, (s, v) => s + v);

  void _order(BuildContext context, int total) {
    context.read<AppProvider>().showToast('총 ${formatCurrency(total)} 주문이 완료되었습니다! 🛒');
    setState(() => _cart.clear());
  }

  String _stockStatus(Product p) {
    if (!p.available) return 'outofstock';
    if (p.stock <= 5) return 'lowstock';
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
    final filtered = _catFilter == '전체' ? products : products.where((p) => p.category == _catFilter).toList();
    final cartItems = _cart.entries.map((e) {
      final p = products.firstWhere((x) => x.id == e.key);
      return (p, e.value);
    }).toList();
    final totalAmount = cartItems.fold<int>(0, (s, i) => s + i.$1.price * i.$2);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('쇼핑몰', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                        Text('사료, 의약품, 장비 구매', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                      ],
                    ),
                  ),
                  if (_cartCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text('$_cartCount개', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                ],
              ),
            ),

            // Category filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: _categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _catFilter = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _catFilter == c ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _catFilter == c ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(c, style: TextStyle(color: _catFilter == c ? Colors.white : const Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                )).toList(),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 8, 16, _cartCount > 0 ? 100 : 24),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final qty = _cart[p.id] ?? 0;
                  final ss = _stockStatus(p);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Opacity(
                      opacity: p.available ? 1.0 : 0.6,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(_emoji(p.category), style: const TextStyle(fontSize: 36)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1F2937)))),
                                      StatusBadge(status: ss),
                                    ]),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                                      child: Text(p.category, style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(p.description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formatCurrency(p.price), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                              Text('재고 ${p.stock}개', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (!p.available)
                            const Center(child: Text('품절', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold)))
                          else if (qty > 0)
                            Row(children: [
                              GestureDetector(
                                onTap: () => _removeFromCart(p.id),
                                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.remove, size: 18)),
                              ),
                              Expanded(child: Center(child: Text('$qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
                              GestureDetector(
                                onTap: () => _addToCart(p.id),
                                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add, color: Colors.white, size: 18)),
                              ),
                            ])
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _addToCart(p.id),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                child: const Text('장바구니 담기', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // Cart bar
        if (_cartCount > 0)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 2)),
                boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('장바구니 ($_cartCount개)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                    Text(formatCurrency(totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                  ]),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: cartItems.map((i) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                        child: Text('${i.$1.name} x${i.$2}', style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _order(context, totalAmount),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('${formatCurrency(totalAmount)} 주문하기', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
