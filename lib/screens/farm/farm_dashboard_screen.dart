import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../utils/formatters.dart';

class FarmDashboardScreen extends StatelessWidget {
  const FarmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final tankStats = prov.getTankStats();
    final resStats = prov.getReservationStats();
    final myTanks = prov.tanks.where((t) => t.farmId == 'farm_001').toList();
    final warningTanks = myTanks.where((t) => t.status == 'warning' || t.status == 'danger').toList();
    final recentRes = prov.reservations.where((r) => r.farmId == 'farm_001').toList().reversed.take(3).toList();

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
          const Text('오늘도 건강한 양식장 운영하세요 🐟', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          const SizedBox(height: 16),

          // Alert
          if (warningTanks.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCD34D), width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('수조 상태 확인 필요', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                        Text(
                          '${warningTanks.map((t) => t.name).join(', ')} 수조에 주의가 필요합니다.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFFB45309)),
                        ),
                      ],
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
              StatCard(label: '전체 수조', value: '${tankStats.total}', sub: '개', color: 'blue', icon: '🪣'),
              StatCard(label: '정상 수조', value: '${tankStats.healthy}', sub: '주의 ${tankStats.warning} | 위험 ${tankStats.danger}', color: 'green', icon: '✅'),
              StatCard(label: '총 어류', value: _fmt(tankStats.totalFish), sub: '마리', color: 'teal', icon: '🐟'),
              StatCard(label: '예약 건수', value: '${resStats.total}', sub: '대기 ${resStats.pending} | 승인 ${resStats.approved}', color: 'purple', icon: '📅'),
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
            children: const [
              _QuickAction(label: '수조 관리', desc: '수조 현황 확인', icon: Icons.water, color: Color(0xFF2563EB), pageIndex: 1),
              _QuickAction(label: '예약 신청', desc: '접종 예약하기', icon: Icons.event, color: Color(0xFF0F766E), pageIndex: 2),
              _QuickAction(label: '쇼핑몰', desc: '사료/의약품 구매', icon: Icons.shopping_cart, color: Color(0xFF7C3AED), pageIndex: 3),
              _QuickAction(label: '구인 공고', desc: '인력 채용 공고', icon: Icons.work, color: Color(0xFFD97706), pageIndex: 4),
            ],
          ),
          const SizedBox(height: 20),

          // Tank status
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.water, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 6),
                    Text('수조 현황', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  ],
                ),
                const SizedBox(height: 12),
                ...myTanks.take(4).map((tank) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Text(tank.status == 'healthy' ? '🟢' : tank.status == 'warning' ? '🟡' : '🔴', style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tank.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
                              Text('어류 ${_fmt(tank.totalFish)}마리 · 불량 ${tank.injuredFish}마리', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        StatusBadge(status: tank.status),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent reservations
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event, color: Color(0xFF0F766E), size: 20),
                    SizedBox(width: 6),
                    Text('최근 예약', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  ],
                ),
                const SizedBox(height: 12),
                if (recentRes.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('예약 내역이 없습니다', style: TextStyle(color: Color(0xFF9CA3AF))),
                    ),
                  )
                else
                  ...recentRes.map((res) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Text(res.status == 'approved' ? '✅' : res.status == 'pending' ? '⏳' : res.status == 'completed' ? '🎉' : '❌', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(res.centerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
                                Text('${formatDate(res.scheduledDate)} ${res.scheduledTime}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusBadge(status: res.status),
                              const SizedBox(height: 4),
                              Text(formatCurrency(res.serviceAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                            ],
                          ),
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

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _QuickAction extends StatelessWidget {
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final int pageIndex;

  const _QuickAction({required this.label, required this.desc, required this.icon, required this.color, required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 탭을 이용하세요'), duration: const Duration(seconds: 1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis),
            Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
