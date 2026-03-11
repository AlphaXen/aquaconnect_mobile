import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

class TankManagementScreen extends StatefulWidget {
  const TankManagementScreen({super.key});

  @override
  State<TankManagementScreen> createState() => _TankManagementScreenState();
}

class _TankManagementScreenState extends State<TankManagementScreen> {
  String _filter = 'all';

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => TankFormSheet(
        onSave: (tank) {
          context.read<AppProvider>().addTank(tank);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditDialog(Tank tank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => TankFormSheet(
        initial: tank,
        onSave: (updated) {
          context.read<AppProvider>().updateTank(tank.id, updated);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, String id, String name) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('수조 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('"$name" 수조를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () { ctx.read<AppProvider>().deleteTank(id); Navigator.pop(ctx); },
            child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final myTanks = prov.tanks.where((t) => t.farmId == 'farm_001').toList();
    final filtered = _filter == 'all' ? myTanks : myTanks.where((t) => t.status == _filter).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('수조 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                      Text('전체 ${myTanks.length}개 수조', style: const TextStyle(color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('수조 추가', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _FilterChip(label: '전체 ${myTanks.length}', value: 'all', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(label: '정상 ${myTanks.where((t) => t.status == 'healthy').length}', value: 'healthy', selected: _filter == 'healthy', onTap: () => setState(() => _filter = 'healthy')),
                const SizedBox(width: 8),
                _FilterChip(label: '주의 ${myTanks.where((t) => t.status == 'warning').length}', value: 'warning', selected: _filter == 'warning', onTap: () => setState(() => _filter = 'warning')),
                const SizedBox(width: 8),
                _FilterChip(label: '위험 ${myTanks.where((t) => t.status == 'danger').length}', value: 'danger', selected: _filter == 'danger', onTap: () => setState(() => _filter = 'danger')),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water, size: 64, color: Color(0xFFD1D5DB)),
                        const SizedBox(height: 12),
                        const Text('수조가 없습니다', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _showAddDialog,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('첫 수조 추가하기', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _TankCard(
                      tank: filtered[i],
                      onEdit: () => _showEditDialog(filtered[i]),
                      onDelete: () => _confirmDelete(ctx, filtered[i].id, filtered[i].name),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
          boxShadow: selected ? [const BoxShadow(color: Color(0x332563EB), blurRadius: 6)] : null,
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class _TankCard extends StatelessWidget {
  final Tank tank;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TankCard({required this.tank, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final injuryRate = tank.totalFish > 0 ? (tank.injuredFish / tank.totalFish * 100).toStringAsFixed(1) : '0.0';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tank.status == 'healthy' ? '🟢' : tank.status == 'warning' ? '🟡' : '🔴', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tank.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                    StatusBadge(status: tank.status),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF), foregroundColor: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFFEF2F2), foregroundColor: const Color(0xFFDC2626)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _InfoBox(bg: const Color(0xFFEFF6FF), label: '총 어류', value: _fmt(tank.totalFish), unit: '마리', valueColor: const Color(0xFF1E40AF))),
              const SizedBox(width: 8),
              Expanded(child: _InfoBox(bg: const Color(0xFFFEF2F2), label: '불량 어류', value: '${tank.injuredFish}', unit: '$injuryRate%', valueColor: const Color(0xFFDC2626))),
              const SizedBox(width: 8),
              Expanded(child: _InfoBox(bg: const Color(0xFFF0FDFA), label: '수온', value: '${tank.waterTemp}', unit: '℃', valueColor: const Color(0xFF0F766E))),
            ],
          ),
          const SizedBox(height: 8),
          Text('마지막 접종: ${formatDate(tank.lastInjectionDate)} | 다음 예정: ${formatDate(tank.nextInjectionDate)}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          if (tank.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)), child: Text(tank.notes, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
            ),
        ],
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _InfoBox extends StatelessWidget {
  final Color bg;
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  const _InfoBox({required this.bg, required this.label, required this.value, required this.unit, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: valueColor)),
          Text(unit, style: TextStyle(fontSize: 10, color: valueColor.withAlpha(153))),
        ],
      ),
    );
  }
}

// Tank form bottom sheet
class TankFormSheet extends StatefulWidget {
  final Tank? initial;
  final void Function(Tank) onSave;

  const TankFormSheet({super.key, this.initial, required this.onSave});

  @override
  State<TankFormSheet> createState() => _TankFormSheetState();
}

class _TankFormSheetState extends State<TankFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _totalFish;
  late final TextEditingController _injuredFish;
  late final TextEditingController _waterTemp;
  late final TextEditingController _lastDate;
  late final TextEditingController _nextDate;
  late final TextEditingController _notes;
  String _status = 'healthy';

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _name = TextEditingController(text: t?.name ?? '');
    _totalFish = TextEditingController(text: t != null ? '${t.totalFish}' : '');
    _injuredFish = TextEditingController(text: t != null ? '${t.injuredFish}' : '');
    _waterTemp = TextEditingController(text: t != null ? '${t.waterTemp}' : '');
    _lastDate = TextEditingController(text: t?.lastInjectionDate ?? '');
    _nextDate = TextEditingController(text: t?.nextInjectionDate ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _status = t?.status ?? 'healthy';
  }

  @override
  void dispose() {
    _name.dispose(); _totalFish.dispose(); _injuredFish.dispose();
    _waterTemp.dispose(); _lastDate.dispose(); _nextDate.dispose(); _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.isEmpty || _totalFish.text.isEmpty) return;
    widget.onSave(Tank(
      id: widget.initial?.id ?? '',
      farmId: 'farm_001',
      name: _name.text,
      totalFish: int.tryParse(_totalFish.text) ?? 0,
      injuredFish: int.tryParse(_injuredFish.text) ?? 0,
      waterTemp: double.tryParse(_waterTemp.text) ?? 0.0,
      status: _status,
      lastInjectionDate: _lastDate.text,
      nextInjectionDate: _nextDate.text,
      notes: _notes.text,
    ));
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.initial == null ? '새 수조 추가' : '수조 수정', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: _dec('수조명 *')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _totalFish, decoration: _dec('총 어류 수 (마리) *'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _injuredFish, decoration: _dec('불량 어류 수'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _waterTemp, decoration: _dec('수온 (℃)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: _dec('수조 상태'),
                  items: const [
                    DropdownMenuItem(value: 'healthy', child: Text('정상')),
                    DropdownMenuItem(value: 'warning', child: Text('주의')),
                    DropdownMenuItem(value: 'danger', child: Text('위험')),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _lastDate, decoration: _dec('마지막 접종일'), onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) _lastDate.text = d.toIso8601String().split('T')[0];
              }, readOnly: true)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _nextDate, decoration: _dec('다음 접종 예정일'), onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) _nextDate.text = d.toIso8601String().split('T')[0];
              }, readOnly: true)),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _notes, decoration: _dec('비고'), maxLines: 2),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
