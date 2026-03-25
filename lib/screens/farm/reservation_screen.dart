import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

const _timeSlots = ['09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'];
const _serviceTypes = [
  ('vaccination', '정기 접종', 500000),
  ('emergency', '긴급 방문', 800000),
  ('checkup', '건강 검진', 300000),
  ('treatment', '질병 치료', 1000000),
];

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  bool _showHistory = false;
  int _step = 1;
  String _centerId = '';
  String _centerName = '';
  String _date = '';
  String _time = '';
  String _serviceType = 'vaccination';
  List<String> _selectedTanks = [];
  String _notes = '';
  Reservation? _submitted;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<AppProvider>();
      final userId = prov.currentUser?.id ?? '';
      prov.loadCenters();
      prov.loadReservationsForFarm(userId);
    });
  }

  int get _serviceAmount => _serviceTypes.firstWhere((s) => s.$1 == _serviceType).$3;
  int get _commissionAmount => (_serviceAmount * 0.10).round();
  int get _netAmount => _serviceAmount - _commissionAmount;
  String get _serviceLabel => _serviceTypes.firstWhere((s) => s.$1 == _serviceType).$2;

  int _totalFishSelected(List<Tank> tanks) => _selectedTanks.fold(0, (sum, id) {
    final t = tanks.where((x) => x.id == id).firstOrNull;
    return sum + (t?.totalFish ?? 0);
  });

  void _reset() {
    setState(() {
      _step = 1; _centerId = ''; _centerName = ''; _date = ''; _time = '';
      _serviceType = 'vaccination'; _selectedTanks = []; _notes = ''; _submitted = null;
      _showHistory = true;
    });
  }

  Future<void> _submit(BuildContext context, List<Tank> myTanks) async {
    setState(() => _isSubmitting = true);
    final res = await context.read<AppProvider>().createReservationApi(
      centerId: _centerId, centerName: _centerName,
      scheduledDate: _date, scheduledTime: _time,
      selectedTanks: _selectedTanks, serviceType: _serviceType,
      totalFish: _totalFishSelected(myTanks), notes: _notes,
      serviceAmount: _serviceAmount, commissionAmount: _commissionAmount,
    );
    if (mounted) setState(() { _submitted = res; _isSubmitting = false; });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final userId = prov.currentUser?.id ?? 'farm_001';
    final myTanks = prov.tanks.where((t) => t.farmId == userId).toList();
    final myRes = prov.reservations.where((r) => r.farmId == userId).toList().reversed.toList();

    if (_submitted != null) return _SuccessView(res: _submitted!, serviceLabel: _serviceLabel, commissionAmount: _commissionAmount, netAmount: _netAmount, onDone: _reset);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('예약 신청', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
          const SizedBox(height: 12),

          // Tabs
          Row(children: [
            _Tab(label: '새 예약 신청', selected: !_showHistory, onTap: () => setState(() => _showHistory = false)),
            const SizedBox(width: 8),
            _Tab(label: '예약 내역', selected: _showHistory, onTap: () => setState(() => _showHistory = true)),
          ]),
          const SizedBox(height: 16),

          if (_showHistory)
            _HistoryView(reservations: myRes)
          else
            _StepForm(
              step: _step,
              centerId: _centerId,
              centerName: _centerName,
              date: _date,
              time: _time,
              serviceType: _serviceType,
              selectedTanks: _selectedTanks,
              notes: _notes,
              myTanks: myTanks,
              centers: prov.centers,
              serviceAmount: _serviceAmount,
              commissionAmount: _commissionAmount,
              netAmount: _netAmount,
              serviceLabel: _serviceLabel,
              totalFishSelected: _totalFishSelected(myTanks),
              onSelectCenter: (id, name) => setState(() { _centerId = id; _centerName = name; }),
              onSelectDate: (d) => setState(() => _date = d),
              onSelectTime: (t) => setState(() => _time = t),
              onSelectService: (s) => setState(() => _serviceType = s),
              onToggleTank: (id) => setState(() {
                if (_selectedTanks.contains(id)) {
                  _selectedTanks = _selectedTanks.where((x) => x != id).toList();
                } else {
                  _selectedTanks = [..._selectedTanks, id];
                }
              }),
              onNotesChange: (n) => setState(() => _notes = n),
              onNext: () => setState(() => _step++),
              onBack: () => setState(() => _step--),
              onSubmit: () => _submit(context, myTanks),
            ),
        ],
      ),
    );
  }
}

class _StepForm extends StatelessWidget {
  final int step;
  final String centerId, centerName, date, time, serviceType, notes, serviceLabel;
  final List<String> selectedTanks;
  final List<Tank> myTanks;
  final List<AquaCenter> centers;
  final int serviceAmount, commissionAmount, netAmount, totalFishSelected;
  final void Function(String, String) onSelectCenter;
  final void Function(String) onSelectDate, onSelectTime, onSelectService, onNotesChange;
  final void Function(String) onToggleTank;
  final VoidCallback onNext, onBack, onSubmit;

  const _StepForm({
    required this.step, required this.centerId, required this.centerName,
    required this.date, required this.time, required this.serviceType,
    required this.selectedTanks, required this.notes, required this.myTanks,
    required this.centers,
    required this.serviceAmount, required this.commissionAmount, required this.netAmount,
    required this.totalFishSelected, required this.serviceLabel,
    required this.onSelectCenter, required this.onSelectDate, required this.onSelectTime,
    required this.onSelectService, required this.onNotesChange, required this.onToggleTank,
    required this.onNext, required this.onBack, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Row(children: List.generate(3, (i) {
            final s = i + 1;
            final active = step >= s;
            final done = step > s;
            return Expanded(child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: active ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(18)),
                child: Center(child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text('$s', style: TextStyle(color: active ? Colors.white : const Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
              ),
              if (i < 2) Expanded(child: Container(height: 2, color: step > s ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB))),
            ]));
          })),
          const SizedBox(height: 20),

          if (step == 1) _Step1(centerId: centerId, centers: centers, onSelect: onSelectCenter, onNext: onNext),
          if (step == 2) _Step2(date: date, time: time, serviceType: serviceType, notes: notes, onDate: onSelectDate, onTime: onSelectTime, onService: onSelectService, onNotes: onNotesChange, onNext: onNext, onBack: onBack),
          if (step == 3) _Step3(myTanks: myTanks, selectedTanks: selectedTanks, onToggle: onToggleTank, centerName: centerName, date: date, time: time, serviceLabel: serviceLabel, serviceAmount: serviceAmount, commissionAmount: commissionAmount, netAmount: netAmount, totalFish: totalFishSelected, tankCount: selectedTanks.length, onBack: onBack, onSubmit: onSubmit),
        ],
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final String centerId;
  final List<AquaCenter> centers;
  final void Function(String, String) onSelect;
  final VoidCallback onNext;

  const _Step1({required this.centerId, required this.centers, required this.onSelect, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('수산질병관리원 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
        const SizedBox(height: 12),
        ...centers.map((c) => GestureDetector(
          onTap: () => onSelect(c.id, c.name),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: centerId == c.id ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: centerId == c.id ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB), width: 2),
            ),
            child: Row(
              children: [
                const Text('🏥', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)))),
                        Row(children: [const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14), Text('${c.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
                      ]),
                      Text(c.location, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      const SizedBox(height: 6),
                      Wrap(spacing: 4, children: c.specialties.take(3).map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(20)),
                        child: Text(s, style: const TextStyle(fontSize: 10, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600)),
                      )).toList()),
                      const SizedBox(height: 4),
                      Text('다음 예약 가능: ${c.nextAvailable}', style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (centerId == c.id) const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: centerId.isNotEmpty ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('다음 단계', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), disabledBackgroundColor: const Color(0xFFD1D5DB)),
          ),
        ),
      ],
    );
  }
}

class _Step2 extends StatelessWidget {
  final String date, time, serviceType, notes;
  final void Function(String) onDate, onTime, onService, onNotes;
  final VoidCallback onNext, onBack;

  const _Step2({required this.date, required this.time, required this.serviceType, required this.notes, required this.onDate, required this.onTime, required this.onService, required this.onNotes, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('일정 및 서비스 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
        const SizedBox(height: 16),

        // Date picker
        const Text('방문 날짜 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime(2030));
            if (d != null) onDate(d.toIso8601String().split('T')[0]);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: date.isNotEmpty ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(date.isNotEmpty ? formatDate(date) : '날짜를 선택하세요', style: TextStyle(color: date.isNotEmpty ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // Time slots
        const Text('방문 시간 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _timeSlots.map((t) => GestureDetector(
            onTap: () => onTime(t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: time == t ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: time == t ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB), width: 2),
              ),
              child: Text(t, style: TextStyle(color: time == t ? Colors.white : const Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 14),

        // Service types
        const Text('서비스 종류 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        ..._serviceTypes.map((s) => GestureDetector(
          onTap: () => onService(s.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: serviceType == s.$1 ? const Color(0xFFF0FDFA) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: serviceType == s.$1 ? const Color(0xFF0F766E) : const Color(0xFFE5E7EB), width: 2),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(s.$2, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              Text(formatCurrency(s.$3), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F766E))),
            ]),
          ),
        )),
        const SizedBox(height: 10),

        // Notes
        TextField(
          onChanged: onNotes,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: '요청 사항',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
          ),
        ),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: onBack, icon: const Icon(Icons.chevron_left), label: const Text('이전', style: TextStyle(fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(onPressed: date.isNotEmpty && time.isNotEmpty ? onNext : null, icon: const Text('다음', style: TextStyle(fontWeight: FontWeight.bold)), label: const Icon(Icons.chevron_right), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), disabledBackgroundColor: const Color(0xFFD1D5DB)))),
        ]),
      ],
    );
  }
}

class _Step3 extends StatelessWidget {
  final List<Tank> myTanks;
  final List<String> selectedTanks;
  final void Function(String) onToggle;
  final String centerName, date, time, serviceLabel;
  final int serviceAmount, commissionAmount, netAmount, totalFish, tankCount;
  final VoidCallback onBack, onSubmit;

  const _Step3({required this.myTanks, required this.selectedTanks, required this.onToggle, required this.centerName, required this.date, required this.time, required this.serviceLabel, required this.serviceAmount, required this.commissionAmount, required this.netAmount, required this.totalFish, required this.tankCount, required this.onBack, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('수조 선택 및 최종 확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
        const SizedBox(height: 12),

        const Text('접종 대상 수조 선택 (복수 가능)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.2,
          children: myTanks.map((t) {
            final sel = selectedTanks.contains(t.id);
            return GestureDetector(
              onTap: () => onToggle(t.id),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB), width: 2),
                ),
                child: Row(children: [
                  Text(t.status == 'healthy' ? '🟢' : t.status == 'warning' ? '🟡' : '🔴', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis),
                    Text('${_fmt(t.totalFish)}마리', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('예약 내용 확인', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF374151))),
              const SizedBox(height: 10),
              _Row('관리원', centerName), _Row('일시', '${formatDate(date)} $time'), _Row('서비스', serviceLabel),
              _Row('수조', '$tankCount개 (${_fmt(totalFish)}마리)'),
              const Divider(height: 16),
              _Row('서비스 금액', formatCurrency(serviceAmount)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('플랫폼 수수료 (10%)', style: TextStyle(fontSize: 13, color: Color(0xFFD97706))),
                Text(formatCurrency(commissionAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('실결제 금액', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                Text(formatCurrency(netAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Expanded(child: Text('승인 시 전자계약서가 자동 생성됩니다', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600))),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: onBack, icon: const Icon(Icons.chevron_left), label: const Text('이전', style: TextStyle(fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(onPressed: selectedTanks.isNotEmpty ? onSubmit : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), disabledBackgroundColor: const Color(0xFFD1D5DB)), child: const Text('예약 신청하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))),
        ]),
      ],
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
    ]),
  );
}

class _SuccessView extends StatelessWidget {
  final Reservation res;
  final String serviceLabel;
  final int commissionAmount, netAmount;
  final VoidCallback onDone;

  const _SuccessView({required this.res, required this.serviceLabel, required this.commissionAmount, required this.netAmount, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 16)]),
          child: Column(
            children: [
              const Text('✅', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              const Text('예약 신청 완료!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
              const SizedBox(height: 6),
              const Text('수산질병관리원의 승인을 기다리고 있습니다.', style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  _Row('관리원', res.centerName),
                  _Row('예약 일시', '${formatDate(res.scheduledDate)} ${res.scheduledTime}'),
                  _Row('서비스', serviceLabel),
                  _Row('서비스 금액', formatCurrency(res.serviceAmount)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('플랫폼 수수료 (10%)', style: TextStyle(fontSize: 13, color: Color(0xFFD97706))),
                      Text(formatCurrency(commissionAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ]),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('실결제 금액', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                      Text(formatCurrency(netAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Expanded(child: Text('승인 시 전자계약서가 자동 생성됩니다', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('예약 내역 보기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryView extends StatelessWidget {
  final List<Reservation> reservations;
  const _HistoryView({required this.reservations});

  String _svcLabel(String t) => switch(t) {
    'vaccination' => '정기 접종',
    'emergency'   => '긴급 방문',
    'checkup'     => '건강 검진',
    'treatment'   => '질병 치료',
    _ => t,
  };

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(children: [
            Icon(Icons.event_outlined, size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text('예약 내역이 없습니다', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
          ]),
        ),
      );
    }
    return Column(
      children: reservations.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.centerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
              Text('${formatDate(r.scheduledDate)} ${r.scheduledTime}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            StatusBadge(status: r.status),
          ]),
          const SizedBox(height: 8),
          Text('서비스: ${_svcLabel(r.serviceType)}  |  금액: ${formatCurrency(r.serviceAmount)}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          if (r.status == 'approved')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.description_outlined, size: 14, color: Color(0xFF16A34A)),
                  SizedBox(width: 6),
                  Text('전자계약서 생성됨 ✓', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          if (r.directorNotes != null && r.directorNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8)), child: Text('메모: ${r.directorNotes}', style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)))),
            ),
        ]),
      )).toList(),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2563EB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
      ),
      child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 13)),
    ),
  );
}
