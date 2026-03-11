import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

class CenterDashboardScreen extends StatelessWidget {
  const CenterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final allRes = prov.reservations;
    final pending = allRes.where((r) => r.status == 'pending').toList();
    final approved = allRes.where((r) => r.status == 'approved').toList();
    final completed = allRes.where((r) => r.status == 'completed').toList();
    final totalRevenue = completed.fold<int>(0, (s, r) => s + r.serviceAmount);
    final totalCommission = completed.fold<int>(0, (s, r) => s + r.commissionAmount);
    final lowStock = prov.products.where((p) => p.stock <= 5).toList();
    final openJobs = prov.jobs.where((j) => j.status == 'open').toList();
    final recentRes = allRes.reversed.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '안녕하세요, ${prov.currentUser?.name} 님',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 4),
          const Text('오늘의 예약 현황을 확인하세요 🏥', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          const SizedBox(height: 16),

          // Pending alert
          if (pending.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCD34D), width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('대기 중인 예약이 ${pending.length}건 있습니다', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                      const Text('빠른 승인으로 양식장을 도와주세요!', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(10)),
                    child: const Text('확인하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Low stock alert
          if (lowStock.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Color(0xFFDC2626), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '재고 부족 알림: ${lowStock.map((p) => p.name).join(', ')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              StatCard(label: '대기 예약', value: '${pending.length}', sub: '건', color: 'amber', icon: '⏳'),
              StatCard(label: '승인 예약', value: '${approved.length}', sub: '건', color: 'green', icon: '✅'),
              StatCard(label: '완료 수익', value: '${(totalRevenue / 10000).toStringAsFixed(0)}만', sub: '수수료 ${(totalCommission / 10000).toStringAsFixed(0)}만', color: 'blue', icon: '💰'),
              StatCard(label: '구인 공고', value: '${openJobs.length}', sub: '모집 중', color: 'purple', icon: '👥'),
            ],
          ),
          const SizedBox(height: 20),

          // Quick actions
          const Text('빠른 메뉴', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _QuickAction(label: '예약 관리', desc: '승인/거절 처리', icon: Icons.event, color: const Color(0xFF0F766E)),
              _QuickAction(label: '재고 관리', desc: '백신/의약품 현황', icon: Icons.inventory_2, color: const Color(0xFF2563EB)),
              _QuickAction(label: '구인 공고', desc: '구인 등록/관리', icon: Icons.people, color: const Color(0xFF7C3AED)),
              _RevenueBox(revenue: totalRevenue),
            ],
          ),
          const SizedBox(height: 20),

          // Recent reservations
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('최근 예약', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 12),
                ...recentRes.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Text(r.status == 'approved' ? '✅' : r.status == 'pending' ? '⏳' : r.status == 'completed' ? '🎉' : '❌', style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r.farmName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
                            Text('${formatDate(r.scheduledDate)} ${r.scheduledTime}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          StatusBadge(status: r.status),
                          const SizedBox(height: 4),
                          Text(formatCurrency(r.serviceAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                        ]),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label, desc;
  final IconData icon;
  final Color color;
  const _QuickAction({required this.label, required this.desc, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 24)),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis),
      Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _RevenueBox extends StatelessWidget {
  final int revenue;
  const _RevenueBox({required this.revenue});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.trending_up, color: Colors.white, size: 24)),
      const SizedBox(height: 8),
      const Text('수익 분석', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
      FittedBox(fit: BoxFit.scaleDown, child: Text(formatCurrency(revenue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)))),
    ]),
  );
}
