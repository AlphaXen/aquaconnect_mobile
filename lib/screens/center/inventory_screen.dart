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
  String _filter = '전체';

  static const _categories = ['전체', '백신', '의약품', '사료', '장비'];

  void _showEditStockSheet(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditStockSheet(
        product: product,
        onSave: (newStock) {
          context.read<AppProvider>().updateProductStock(product.id, newStock);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddProductSheet(
        onSave: (product) {
          context.read<AppProvider>().addProduct(product);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final allProducts = prov.products;
    final filtered = _filter == '전체'
        ? allProducts
        : allProducts.where((p) => p.category == _filter).toList();

    final inStock = allProducts.where((p) => p.stock > 5).length;
    final lowStock = allProducts.where((p) => p.stock > 0 && p.stock <= 5).length;
    final outOfStock = allProducts.where((p) => p.stock == 0).length;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('재고 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                      Text('전체 ${allProducts.length}개 상품', style: const TextStyle(color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddProductSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('상품 추가', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _StatChip(label: '정상', count: inStock, color: const Color(0xFF16A34A)),
                const SizedBox(width: 8),
                _StatChip(label: '부족', count: lowStock, color: const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _StatChip(label: '품절', count: outOfStock, color: const Color(0xFFDC2626)),
              ],
            ),
          ),

          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _categories.map((cat) {
                final selected = _filter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF0F766E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? const Color(0xFF0F766E) : const Color(0xFFE5E7EB)),
                        boxShadow: selected
                            ? [const BoxShadow(color: Color(0x220F766E), blurRadius: 6)]
                            : null,
                      ),
                      child: Text(
                        cat,
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

          // Product list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFD1D5DB)),
                        SizedBox(height: 12),
                        Text('상품이 없습니다', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _ProductInventoryCard(
                      product: filtered[i],
                      onEditStock: () => _showEditStockSheet(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label $count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _ProductInventoryCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEditStock;

  const _ProductInventoryCard({required this.product, required this.onEditStock});

  String get _stockStatus {
    if (product.stock == 0) return 'outofstock';
    if (product.stock <= 5) return 'lowstock';
    return 'instock';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.stock == 0 ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(product.category, style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: _stockStatus),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                    const SizedBox(height: 2),
                    Text(
                      product.description,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatCurrency(product.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))),
                  const Text('단가', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text('재고 ', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        Text(
                          '${product.stock}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: product.stock == 0
                                ? const Color(0xFFDC2626)
                                : product.stock <= 5
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF16A34A),
                          ),
                        ),
                        const Text(' 개', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: product.stock > 0 ? (product.stock / 200).clamp(0.0, 1.0) : 0.0,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: product.stock == 0
                            ? const Color(0xFFDC2626)
                            : product.stock <= 5
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onEditStock,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('재고 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditStockSheet extends StatefulWidget {
  final Product product;
  final void Function(int) onSave;

  const _EditStockSheet({required this.product, required this.onSave});

  @override
  State<_EditStockSheet> createState() => _EditStockSheetState();
}

class _EditStockSheetState extends State<_EditStockSheet> {
  late final TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(text: '${widget.product.stock}');
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  void _save() {
    final newStock = int.tryParse(_stockController.text);
    if (newStock == null || newStock < 0) return;
    widget.onSave(newStock);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('재고 수정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text(widget.product.name, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('현재 재고: ', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              Text('${widget.product.stock}개', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '새 재고 수량 (개)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('빠른 입력', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [10, 20, 50, 100].map((qty) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    final current = int.tryParse(_stockController.text) ?? 0;
                    _stockController.text = '${current + qty}';
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Text('+$qty', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E), fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddProductSheet extends StatefulWidget {
  final void Function(Product) onSave;
  const _AddProductSheet({required this.onSave});

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  String _category = '백신';

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.isEmpty || _price.text.isEmpty || _stock.text.isEmpty) return;
    final stockCount = int.tryParse(_stock.text) ?? 0;
    widget.onSave(Product(
      id: '',
      centerId: 'center_001',
      category: _category,
      name: _name.text,
      description: _desc.text,
      price: int.tryParse(_price.text) ?? 0,
      stock: stockCount,
      available: stockCount > 0,
    ));
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('상품 추가', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _dec('카테고리'),
              items: const [
                DropdownMenuItem(value: '백신', child: Text('백신')),
                DropdownMenuItem(value: '의약품', child: Text('의약품')),
                DropdownMenuItem(value: '사료', child: Text('사료')),
                DropdownMenuItem(value: '장비', child: Text('장비')),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: _dec('상품명 *')),
            const SizedBox(height: 12),
            TextField(controller: _desc, decoration: _dec('상품 설명'), maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _price, decoration: _dec('단가 (원) *'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _stock, decoration: _dec('초기 재고 (개) *'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('추가하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
