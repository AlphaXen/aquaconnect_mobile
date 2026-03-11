import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

class FarmJobsScreen extends StatefulWidget {
  const FarmJobsScreen({super.key});

  @override
  State<FarmJobsScreen> createState() => _FarmJobsScreenState();
}

class _FarmJobsScreenState extends State<FarmJobsScreen> {
  final Set<String> _applied = {};

  void _apply(BuildContext context, String jobId, String title) {
    if (_applied.contains(jobId)) return;
    setState(() => _applied.add(jobId));
    context.read<AppProvider>().showToast('"$title" 공고에 지원 완료!');
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<AppProvider>().jobs.where((j) => j.status == 'open').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('구인 공고', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          const Text('수산질병관리원의 구인 공고를 확인하세요', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          const SizedBox(height: 16),

          if (jobs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(children: const [
                  Icon(Icons.work_outline, size: 64, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 12),
                  Text('현재 구인 공고가 없습니다', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                ]),
              ),
            )
          else
            ...jobs.map((job) {
              final isApplied = _applied.contains(job.id);
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
                              Expanded(child: Text(job.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)))),
                              StatusBadge(status: job.status),
                            ]),
                            const SizedBox(height: 2),
                            Text(job.centerName, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 13)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        const Text('🏥', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(job.description, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
                    const SizedBox(height: 12),

                    // Info grid
                    Row(children: [
                      Expanded(child: _InfoBox(bg: const Color(0xFFEFF6FF), icon: Icons.calendar_today_outlined, iconColor: const Color(0xFF2563EB), label: '기간', value: formatDate(job.startDate), sub: '~ ${formatDate(job.endDate)}')),
                      const SizedBox(width: 8),
                      Expanded(child: _InfoBox(bg: const Color(0xFFF0FDF4), icon: Icons.payments_outlined, iconColor: const Color(0xFF16A34A), label: '급여', value: formatCurrency(job.wage), sub: '일당')),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _InfoBox(bg: const Color(0xFFFFFBEB), icon: Icons.location_on_outlined, iconColor: const Color(0xFFD97706), label: '위치', value: job.location, sub: '')),
                      const SizedBox(width: 8),
                      Expanded(child: _InfoBox(bg: const Color(0xFFF5F3FF), icon: Icons.people_outline, iconColor: const Color(0xFF7C3AED), label: '지원자', value: '${job.appliedCount}명', sub: '')),
                    ]),
                    const SizedBox(height: 12),

                    // Skills
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: job.skills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(20)),
                        child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isApplied ? null : () => _apply(context, job.id, job.title),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isApplied ? const Color(0xFFF0FDF4) : const Color(0xFF2563EB),
                          foregroundColor: isApplied ? const Color(0xFF16A34A) : Colors.white,
                          disabledBackgroundColor: const Color(0xFFF0FDF4),
                          disabledForegroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isApplied
                            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 6),
                                Text('지원 완료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ])
                            : const Text('지원하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color bg, iconColor;
  final IconData icon;
  final String label, value, sub;

  const _InfoBox({required this.bg, required this.icon, required this.iconColor, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      ]),
    );
  }
}
