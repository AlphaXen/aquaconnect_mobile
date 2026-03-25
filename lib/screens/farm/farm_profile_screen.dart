import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/profile_models.dart';

class FarmProfileScreen extends StatefulWidget {
  const FarmProfileScreen({super.key});

  @override
  State<FarmProfileScreen> createState() => _FarmProfileScreenState();
}

class _FarmProfileScreenState extends State<FarmProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _speciesInputCtrl = TextEditingController();

  List<String> _fishSpecies = [];
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
    await prov.loadFarmProfile(userId);
    _populateFields(prov.farmProfile);
    setState(() => _isLoading = false);
  }

  void _populateFields(FarmProfile? p) {
    if (p == null) return;
    _farmNameCtrl.text = p.farmName;
    _ownerNameCtrl.text = p.ownerName;
    _locationCtrl.text = p.location;
    _addressCtrl.text = p.address;
    _phoneCtrl.text = p.phone;
    _descriptionCtrl.text = p.description;
    setState(() => _fishSpecies = List.from(p.fishSpecies));
  }

  void _addSpecies() {
    final s = _speciesInputCtrl.text.trim();
    if (s.isNotEmpty && !_fishSpecies.contains(s)) {
      setState(() { _fishSpecies = [..._fishSpecies, s]; });
      _speciesInputCtrl.clear();
    }
  }

  void _removeSpecies(String s) => setState(() => _fishSpecies = _fishSpecies.where((x) => x != s).toList());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final prov = context.read<AppProvider>();
    final userId = prov.currentUser?.id ?? '';
    final profile = FarmProfile(
      id: userId,
      farmName: _farmNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      fishSpecies: _fishSpecies,
      phone: _phoneCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
    );

    try {
      await prov.saveFarmProfileApi(profile);
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
    _farmNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _locationCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _descriptionCtrl.dispose();
    _speciesInputCtrl.dispose();
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
            const Text('양식장 정보 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            const Text('저장된 정보는 수산질병관리원 예약 신청 시 표시됩니다.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),

            _card(children: [
              const _SectionTitle('기본 정보'),
              _field(label: '양식장명 *', ctrl: _farmNameCtrl, hint: '예: 제주 청정 넙치 양식장', required: true),
              _field(label: '대표자 이름', ctrl: _ownerNameCtrl, hint: '예: 홍길동'),
              _field(label: '지역', ctrl: _locationCtrl, hint: '예: 제주시'),
              _field(label: '주소', ctrl: _addressCtrl, hint: '예: 제주시 노형동 123-4'),
              _field(label: '전화번호', ctrl: _phoneCtrl, hint: '예: 064-000-0000', inputType: TextInputType.phone),
            ]),

            const SizedBox(height: 16),

            _card(children: [
              const _SectionTitle('양식 어종'),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _speciesInputCtrl,
                    decoration: _inputDeco('어종 입력 후 + 버튼'),
                    onSubmitted: (_) => _addSpecies(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSpecies,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Icon(Icons.add),
                ),
              ]),
              if (_fishSpecies.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _fishSpecies.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 13)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeSpecies(s),
                    backgroundColor: const Color(0xFFDBEAFE),
                    labelStyle: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
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
                decoration: _inputDeco('양식장 소개를 입력해주세요'),
              ),
            ]),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
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
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
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
