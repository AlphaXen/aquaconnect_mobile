import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

const _mockApplicants = [
  '김철수 (수산질병관리사 1급)',
  '이영희 (어류 검진 전문)',
  '박민준 (백신 접종 5년 경력)',
];

class CenterJobsScreen extends StatefulWidget {
  const CenterJobsScreen({super.key});

  @override
  State<CenterJobsScreen> createState() => _CenterJobsScreenState();
}

class _CenterJobsScreenState extends State<CenterJobsScreen> {
  final Map<String, String> _applications = {};

  void _handleApplication(BuildContext context, String jobId, String name, String decision) {
    final status = decision == 'approve' ? '승인' : '거절';
    context.read<AppProvider>().showToast('$name 지원자 $status되었습니다.');
    setState(() => _applications['${jobId}_$name'] = decision);
  }

  void _showAddJobSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _JobFormSheet(
        onSave: (job) {
          context.read<AppProvider>().createJob(job);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final myJobs = prov.jobs.where((j) => j.centerId == 'center_001').toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('구인 공고 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                  Text('전체 ${myJobs.length}건 공고', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                ]),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddJobSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('공고 등록', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),

        Expanded(
          child: myJobs.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.work_outline, size: 64, color: Color(0xFFD1D5DB)),
                    const SizedBox(height: 12),
                    const Text('등록한 구인 공고가 없습니다', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _showAddJobSheet(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('첫 공고 등록하기', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: myJobs.length,
                  itemBuilder: (ctx, i) {
                    final job = myJobs[i];
                    return _JobCard(
                      job: job,
                      applications: _applications,
                      onApplication: (name, decision) => _handleApplication(context, job.id, name, decision),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final Map<String, String> applications;
  final void Function(String, String) onApplication;

  const _JobCard({required this.job, required this.applications, required this.onApplication});

  @override
  Widget build(BuildContext context) {
    final visibleApplicants = _mockApplicants.take(job.appliedCount > 0 ? job.appliedCount.clamp(1, 3) : 2).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(job.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)))),
                    StatusBadge(status: job.status),
                  ]),
                  Text('${formatDate(job.startDate)} ~ ${formatDate(job.endDate)}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatCurrency(job.wage), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F766E))),
                const Text('일당', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.description, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: job.skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(20)),
              child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          Text('지원자 ${job.appliedCount}명', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          ...visibleApplicants.map((applicant) {
            final key = '${job.id}_$applicant';
            final decision = applications[key];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: decision == 'approve' ? const Color(0xFFF0FDF4) : decision == 'reject' ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(applicant, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)))),
                  if (decision != null)
                    Text(
                      decision == 'approve' ? '✓ 승인됨' : '✗ 거절됨',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: decision == 'approve' ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                    )
                  else
                    Row(children: [
                      GestureDetector(
                        onTap: () => onApplication(applicant, 'approve'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(8)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('승인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => onApplication(applicant, 'reject'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(8)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.close, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('거절', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ]),
                        ),
                      ),
                    ]),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _JobFormSheet extends StatefulWidget {
  final void Function(Job) onSave;
  const _JobFormSheet({required this.onSave});

  @override
  State<_JobFormSheet> createState() => _JobFormSheetState();
}

class _JobFormSheetState extends State<_JobFormSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  final _wage = TextEditingController();
  final _location = TextEditingController();
  final _skills = TextEditingController();

  @override
  void dispose() {
    _title.dispose(); _desc.dispose(); _startDate.dispose();
    _endDate.dispose(); _wage.dispose(); _location.dispose(); _skills.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.isEmpty || _wage.text.isEmpty) return;
    widget.onSave(Job(
      id: '',
      centerId: 'center_001',
      centerName: '제주 수산질병관리원',
      title: _title.text,
      description: _desc.text,
      startDate: _startDate.text,
      endDate: _endDate.text,
      location: _location.text,
      wage: int.tryParse(_wage.text) ?? 0,
      skills: _skills.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      appliedCount: 0,
      status: 'open',
      createdAt: DateTime.now().toIso8601String().split('T')[0],
    ));
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
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
            const Text('구인 공고 등록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 16),
            TextField(controller: _title, decoration: _dec('공고 제목 *', hint: '예: 넙치 접종 보조 인력 모집')),
            const SizedBox(height: 12),
            TextField(controller: _desc, decoration: _dec('업무 내용'), maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _startDate, decoration: _dec('시작일'), readOnly: true, onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                if (d != null) _startDate.text = d.toIso8601String().split('T')[0];
              })),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _endDate, decoration: _dec('종료일'), readOnly: true, onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                if (d != null) _endDate.text = d.toIso8601String().split('T')[0];
              })),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _wage, decoration: _dec('일당 (원) *', hint: '150000'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _location, decoration: _dec('근무 위치', hint: '제주시 한림읍'))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _skills, decoration: _dec('필요 기술 (쉼표 구분)', hint: '수산질병관리사, 백신 접종')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('공고 등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
