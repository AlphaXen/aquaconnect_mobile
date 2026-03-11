import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

const _serviceLabels = {
  'vaccination': '정기 접종',
  'emergency': '긴급 방문',
  'checkup': '건강 검진',
  'treatment': '질병 치료',
};

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});

  @override
  State<ReservationManagementScreen> createState() => _ReservationManagementScreenState();
}

class _ReservationManagementScreenState extends State<ReservationManagementScreen> {
  String _filter = 'pending';

  void _showActionDialog(BuildContext context, Reservation res, String action) {
    final notesController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action == 'approved' ? '예약 승인 확인' : '예약 거절 확인',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: action == 'approved' ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: action == 'approved' ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(res.farmName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text('${formatDate(res.scheduledDate)} ${res.scheduledTime}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                Text(formatCurrency(res.serviceAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151))),
              ]),
            ),
            if (action == 'approved') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Expanded(child: Text('승인 시 전자계약서가 자동 생성됩니다', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600))),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '메모 (선택)',
                hintText: action == 'approved' ? '승인 관련 안내사항...' : '거절 사유를 입력해주세요...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('취소', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AppProvider>().updateReservationStatus(res.id, action, notes: notesController.text);
                    Navigator.pop(ctx);
                  },
                  icon: Icon(action == 'approved' ? Icons.check : Icons.close, size: 18),
                  label: Text(action == 'approved' ? '승인하기' : '거절하기', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action == 'approved' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final allRes = prov.reservations;
    final filtered = _filter == 'all' ? allRes : allRes.where((r) => r.status == _filter).toList();
    final pendingCount = allRes.where((r) => r.status == 'pending').length;

    final tabs = [
      ('pending', '대기중', allRes.where((r) => r.status == 'pending').length),
      ('approved', '승인됨', allRes.where((r) => r.status == 'approved').length),
      ('completed', '완료', allRes.where((r) => r.status == 'completed').length),
      ('rejected', '거절됨', allRes.where((r) => r.status == 'rejected').length),
      ('all', '전체', allRes.length),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('예약 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            if (pendingCount > 0)
              Text('⚠️ 대기 중인 예약 $pendingCount건', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),

        // Filter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: tabs.map((t) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _filter == t.$1 ? (t.$1 == 'pending' ? const Color(0xFFF59E0B) : const Color(0xFF0F766E)) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _filter == t.$1 ? Colors.transparent : const Color(0xFFE5E7EB)),
                  ),
                  child: Row(children: [
                    Text(t.$2, style: TextStyle(color: _filter == t.$1 ? Colors.white : const Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 13)),
                    if (t.$3 > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _filter == t.$1 ? Colors.white.withAlpha(77) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${t.$3}', style: TextStyle(fontSize: 11, color: _filter == t.$1 ? Colors.white : const Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                ),
              ),
            )).toList(),
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.event_outlined, size: 64, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 12),
                  Text('예약이 없습니다', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final r = filtered.reversed.toList()[i];
                    return _ReservationCard(
                      res: r,
                      onApprove: () => _showActionDialog(context, r, 'approved'),
                      onReject: () => _showActionDialog(context, r, 'rejected'),
                      onComplete: () => context.read<AppProvider>().updateReservationStatus(r.id, 'completed'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation res;
  final VoidCallback onApprove, onReject, onComplete;

  const _ReservationCard({required this.res, required this.onApprove, required this.onReject, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isPending = res.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFFBEB).withAlpha(128) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPending ? const Color(0xFFFCD34D) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(res.farmName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)))),
                    StatusBadge(status: res.status),
                  ]),
                  Text('${formatDate(res.scheduledDate)} ${res.scheduledTime}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ]),
              ),
              const SizedBox(width: 8),
              const Text('🐟', style: TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 12),

          // Info grid
          Row(children: [
            Expanded(child: _InfoCell(bg: const Color(0xFFEFF6FF), label: '서비스', value: _serviceLabels[res.serviceType] ?? res.serviceType, labelColor: const Color(0xFF2563EB))),
            const SizedBox(width: 8),
            Expanded(child: _InfoCell(bg: const Color(0xFFF0FDFA), label: '어류 수', value: '${_fmt(res.totalFish)}마리', labelColor: const Color(0xFF0F766E))),
            const SizedBox(width: 8),
            Expanded(child: _InfoCell(bg: const Color(0xFFF0FDF4), label: '서비스 금액', value: formatCurrency(res.serviceAmount), labelColor: const Color(0xFF16A34A))),
            const SizedBox(width: 8),
            Expanded(child: _InfoCell(bg: const Color(0xFFFFFBEB), label: '수수료 (10%)', value: formatCurrency(res.commissionAmount), labelColor: const Color(0xFFD97706))),
          ]),

          if (res.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)), child: Text('요청: ${res.notes}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          ],

          if (res.status == 'approved') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.description_outlined, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Expanded(child: Text('전자계약서 생성됨 ✓ ${res.contractUrl ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ],

          if (res.directorNotes != null && res.directorNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)), child: Text('처리 메모: ${res.directorNotes}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          ],

          const SizedBox(height: 12),

          if (res.status == 'pending')
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: onApprove, icon: const Icon(Icons.check_circle_outline, size: 18), label: const Text('승인', style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(onPressed: onReject, icon: const Icon(Icons.cancel_outlined, size: 18), label: const Text('거절', style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            ])
          else if (res.status == 'approved')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('서비스 완료 처리 (커미션 정산)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _InfoCell extends StatelessWidget {
  final Color bg, labelColor;
  final String label, value;
  const _InfoCell({required this.bg, required this.label, required this.value, required this.labelColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: labelColor)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
    ]),
  );
}
