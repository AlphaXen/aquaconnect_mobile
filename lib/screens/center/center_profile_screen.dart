import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/profile_models.dart';

class CenterProfileScreen extends StatefulWidget {
  const CenterProfileScreen({super.key});

  @override
  State<CenterProfileScreen> createState() => _CenterProfileScreenState();
}

class _CenterProfileScreenState extends State<CenterProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _centerNameCtrl = TextEditingController();
  final _directorNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _businessHoursCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _specialtyInputCtrl = TextEditingController();

  List<String> _specialties = [];
  bool _isAvailable = true;
  double _rating = 0.0;
  int _reviewCount = 0;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final prov = context.read<AppProvider>();
    final userId = prov.currentUser?.id ?? '';
    await prov.loadCenterProfile(userId);
    _populateFields(prov.centerProfile);
    setState(() => _isLoading = false);
  }

  void _populateFields(CenterProfile? p) {
    if (p == null) return;
    _centerNameCtrl.text = p.centerName;
    _directorNameCtrl.text = p.directorName;
    _locationCtrl.text = p.location;
    _phoneCtrl.text = p.phone;
    _businessHoursCtrl.text = p.businessHours;
    _descriptionCtrl.text = p.description;
    setState(() {
      _specialties = List.from(p.specialties);
      _isAvailable = p.isAvailable;
      _rating = p.rating;
      _reviewCount = p.reviewCount;
    });
  }

  void _addSpecialty() {
    final s = _specialtyInputCtrl.text.trim();
    if (s.isNotEmpty && !_specialties.contains(s)) {
      setState(() => _specialties = [..._specialties, s]);
      _specialtyInputCtrl.clear();
    }
  }

  void _removeSpecialty(String s) => setState(() => _specialties = _specialties.where((x) => x != s).toList());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final prov = context.read<AppProvider>();
    final userId = prov.currentUser?.id ?? '';
    final profile = CenterProfile(
      id: userId,
      centerName: _centerNameCtrl.text.trim(),
      directorName: _directorNameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      specialties: _specialties,
      businessHours: _businessHoursCtrl.text.trim(),
      isAvailable: _isAvailable,
      rating: _rating,
      reviewCount: _reviewCount,
      description: _descriptionCtrl.text.trim(),
    );

    try {
      await prov.saveCenterProfileApi(profile);
    } catch (e) {
      if (mounted) {
        prov.showToast('저장 실패: 서버에 연결할 수 없습니다.', type: 'error');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _centerNameCtrl.dispose();
    _directorNameCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _businessHoursCtrl.dispose();
    _descriptionCtrl.dispose();
    _specialtyInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('관리원 정보 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            const Text('저장된 정보는 양식장의 예약 신청 화면에 표시됩니다.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),

            _card(children: [
              const _SectionTitle('기본 정보'),
              _field(label: '관리원명 *', ctrl: _centerNameCtrl, hint: '예: 제주 수산질병관리원', required: true),
              _field(label: '원장 이름', ctrl: _directorNameCtrl, hint: '예: 박영수'),
              _field(label: '위치/지역', ctrl: _locationCtrl, hint: '예: 제주시 노형동'),
              _field(label: '전화번호', ctrl: _phoneCtrl, hint: '예: 064-722-3456', inputType: TextInputType.phone),
              _field(label: '운영 시간', ctrl: _businessHoursCtrl, hint: '예: 09:00-18:00'),
            ]),

            const SizedBox(height: 16),

            _card(children: [
              const _SectionTitle('예약 가능 여부'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('현재 예약 가능', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    Text(
                      _isAvailable ? '양식장에서 예약 신청 가능' : '예약 신청 일시 중단',
                      style: TextStyle(fontSize: 12, color: _isAvailable ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF)),
                    ),
                  ]),
                  Switch(
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    activeThumbColor: const Color(0xFF0F766E),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 16),

            _card(children: [
              const _SectionTitle('전문 분야'),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _specialtyInputCtrl,
                    decoration: _inputDeco('전문 분야 입력 후 + 버튼'),
                    onSubmitted: (_) => _addSpecialty(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSpecialty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Icon(Icons.add),
                ),
              ]),
              if (_specialties.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _specialties.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 13)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeSpecialty(s),
                    backgroundColor: const Color(0xFFCCFBF1),
                    labelStyle: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                  )).toList(),
                ),
              ],
            ]),

            const SizedBox(height: 16),

            _card(children: [
              const _SectionTitle('소개'),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                decoration: _inputDeco('관리원 소개를 입력해주세요'),
              ),
            ]),

            if (_rating > 0 || _reviewCount > 0) ...[
              const SizedBox(height: 16),
              _card(children: [
                const _SectionTitle('평점 정보 (읽기 전용)'),
                Row(children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 6),
                  Text('$_rating', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(width: 8),
                  Text('리뷰 $_reviewCount건', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                ]),
              ]),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: const Color(0xFFD1D5DB),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    bool required = false,
    TextInputType inputType = TextInputType.text,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      decoration: _inputDeco(hint).copyWith(labelText: label),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label을(를) 입력해주세요' : null : null,
    ),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2)),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF374151))),
  );
}
