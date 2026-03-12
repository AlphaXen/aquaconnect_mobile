import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

class _CartItem {
  final Product product;
  int quantity;
  _CartItem({required this.product, this.quantity = 1});
}

class CommerceScreen extends StatefulWidget {
  const CommerceScreen({super.key});

  @override
  State<CommerceScreen> createState() => _CommerceScreenState();
}

class _CommerceScreenState extends State<CommerceScreen> {
  String _filter = '전체';
  final Map<String, _CartItem> _cart = {};
  bool _ordered = false;

  static const _categories = ['전체', '백신', '의약품', '사료', '장비'];

  int get _cartItemCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  int get _cartTotal => _cart.values.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  void _addToCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity++;
      } else {
        _cart[product.id] = _CartItem(product: product);
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        if (_cart[productId]!.quantity > 1) {
          _cart[productId]!.quantity--;
        } else {
          _cart.remove(productId);
        }
      }
    });
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CartSheet(
        cart: Map.from(_cart),
        total: _cartTotal,
        onAdd: _addToCart,
        onRemove: _removeFromCart,
        onOrder: () => _placeOrder(context),
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    Navigator.pop(context);
    setState(() {
      _ordered = true;
      _cart.clear();
    });
    context.read<AppProvider>().showToast('주문이 완료되었습니다! 🎉');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _ordered = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final allProducts = prov.products;
    final filtered = _filter == '전체'
        ? allProducts
        : allProducts.where((p) => p.category == _filter).toList();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('쇼핑몰', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                      Text('사료 · 백신 · 의약품 · 장비', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      onPressed: _cartItemCount > 0 ? () => _showCart(context) : null,
                      icon: Icon(
                        Icons.shopping_cart,
                        color: _cartItemCount > 0 ? const Color(0xFF7C3AED) : const Color(0xFFD1D5DB),
                        size: 28,
                      ),
                      style: _cartItemCount > 0
                          ? IconButton.styleFrom(backgroundColor: const Color(0xFFF5F3FF))
                          : null,
                    ),
                    if (_cartItemCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
                          child: Center(
                            child: Text('$_cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Order success banner
          if (_ordered)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '주문이 완료되었습니다! 담당자가 곧 연락드립니다.',
                      style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _categories.map((cat) {
                final count = cat == '전체'
                    ? allProducts.length
                    : allProducts.where((p) => p.category == cat).length;
                final selected = _filter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF7C3AED) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB)),
                        boxShadow: selected
                            ? [const BoxShadow(color: Color(0x227C3AED), blurRadius: 6)]
                            : null,
                      ),
                      child: Text(
                        '$cat $count',
                        style: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF6B7280),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Products
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Color(0xFFD1D5DB)),
                        SizedBox(height: 12),
                        Text('상품이 없습니다', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final product = filtered[i];
                      final cartQty = _cart[product.id]?.quantity ?? 0;
                      return _ProductCard(
                        product: product,
                        cartQty: cartQty,
                        onAdd: product.available ? () => _addToCart(product) : null,
                        onRemove: cartQty > 0 ? () => _removeFromCart(product.id) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _cartItemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCart(context),
              backgroundColor: const Color(0xFF7C3AED),
              label: Text(
                '장바구니 $_cartItemCount개 · ${formatCurrency(_cartTotal)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            )
          : null,
    );
  }
}

String _productStockStatus(Product product) {
  if (product.stock == 0) return 'outofstock';
  if (product.stock <= 5) return 'lowstock';
  return 'instock';
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final int cartQty;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const _ProductCard({
    required this.product,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: product.available ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(product.category, style: const TextStyle(fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: _productStockStatus(product)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: product.available ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCurrency(product.price),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
                  ),
                  Text('재고 ${product.stock}개', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
              const Spacer(),
              if (!product.available)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('품절', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold)),
                )
              else if (cartQty == 0)
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('담기', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.remove, size: 18),
                        style: IconButton.styleFrom(foregroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.all(8)),
                      ),
                      Text('$cartQty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7C3AED))),
                      IconButton(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add, size: 18),
                        style: IconButton.styleFrom(foregroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.all(8)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartSheet extends StatefulWidget {
  final Map<String, _CartItem> cart;
  final int total;
  final void Function(Product) onAdd;
  final void Function(String) onRemove;
  final VoidCallback onOrder;

  const _CartSheet({
    required this.cart,
    required this.total,
    required this.onAdd,
    required this.onRemove,
    required this.onOrder,
  });

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  late Map<String, _CartItem> _localCart;
  late int _localTotal;

  @override
  void initState() {
    super.initState();
    // Deep copy to avoid mutating parent's cart items
    _localCart = widget.cart.map(
      (key, item) => MapEntry(key, _CartItem(product: item.product, quantity: item.quantity)),
    );
    _localTotal = widget.total;
  }

  void _add(Product product) {
    setState(() {
      if (_localCart.containsKey(product.id)) {
        _localCart[product.id]!.quantity++;
      } else {
        _localCart[product.id] = _CartItem(product: product);
      }
      _localTotal = _localCart.values.fold(0, (s, i) => s + i.product.price * i.quantity);
    });
    widget.onAdd(product);
  }

  void _remove(String productId) {
    setState(() {
      if (_localCart.containsKey(productId)) {
        if (_localCart[productId]!.quantity > 1) {
          _localCart[productId]!.quantity--;
        } else {
          _localCart.remove(productId);
        }
      }
      _localTotal = _localCart.values.fold(0, (s, i) => s + i.product.price * i.quantity);
    });
    widget.onRemove(productId);
  }

  @override
  Widget build(BuildContext context) {
    final items = _localCart.values.toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('장바구니', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('장바구니가 비어있습니다', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15)),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
                                    Text(formatCurrency(item.product.price), style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFDDD6FE)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _remove(item.product.id),
                                      icon: const Icon(Icons.remove, size: 16),
                                      style: IconButton.styleFrom(foregroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.all(6)),
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7C3AED))),
                                    IconButton(
                                      onPressed: () => _add(item.product),
                                      icon: const Icon(Icons.add, size: 16),
                                      style: IconButton.styleFrom(foregroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.all(6)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatCurrency(item.product.price * item.quantity),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1F2937)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('합계', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                  Text(formatCurrency(_localTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED))),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: items.isEmpty ? null : widget.onOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE9D5FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  items.isEmpty ? '장바구니가 비어있습니다' : '주문하기 · ${formatCurrency(_localTotal)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
