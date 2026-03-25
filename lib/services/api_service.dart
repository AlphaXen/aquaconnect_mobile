import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../models/profile_models.dart';
import 'server_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  static const _timeout = Duration(seconds: 10);

  // ── 내부 헬퍼 ────────────────────────────────────────────────────

  Future<String> _base() async {
    final url = await ServerConfig.getUrl();
    if (url.isEmpty) throw const ApiException(0, 'Server not configured');
    return url;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final base = await _base();
    final res = await http.get(Uri.parse('$base$path')).timeout(_timeout);
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    throw ApiException(res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final base = await _base();
    final res = await http
        .put(Uri.parse('$base$path'), headers: {'Content-Type': 'application/json'}, body: json.encode(body))
        .timeout(_timeout);
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    throw ApiException(res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final base = await _base();
    final res = await http
        .post(Uri.parse('$base$path'), headers: {'Content-Type': 'application/json'}, body: json.encode(body))
        .timeout(_timeout);
    if (res.statusCode == 200 || res.statusCode == 201) return json.decode(res.body) as Map<String, dynamic>;
    throw ApiException(res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body) async {
    final base = await _base();
    final res = await http
        .patch(Uri.parse('$base$path'), headers: {'Content-Type': 'application/json'}, body: json.encode(body))
        .timeout(_timeout);
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    throw ApiException(res.statusCode, res.body);
  }

  // ── 양식장 프로필 ────────────────────────────────────────────────

  Future<FarmProfile?> getFarmProfile(String farmId) async {
    try {
      final data = await _get('/api/profiles/farm/$farmId');
      return FarmProfile.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<FarmProfile> saveFarmProfile(String farmId, FarmProfile profile) async {
    final data = await _put('/api/profiles/farm/$farmId', profile.toJson());
    return FarmProfile.fromJson(data);
  }

  // ── 수산질병관리원 프로필 ────────────────────────────────────────

  Future<CenterProfile?> getCenterProfile(String centerId) async {
    try {
      final data = await _get('/api/profiles/center/$centerId');
      return CenterProfile.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<CenterProfile> saveCenterProfile(String centerId, CenterProfile profile) async {
    final data = await _put('/api/profiles/center/$centerId', profile.toJson());
    return CenterProfile.fromJson(data);
  }

  Future<List<AquaCenter>> listCenters() async {
    final data = await _get('/api/profiles/centers');
    final list = (data['centers'] as List<dynamic>?) ?? [];
    return list.map((c) {
      final m = c as Map<String, dynamic>;
      return AquaCenter(
        id: m['id'] as String,
        name: m['center_name'] as String,
        directorName: m['director_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        location: m['location'] as String? ?? '',
        specialties: List<String>.from(m['specialties'] ?? []),
        rating: (m['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: m['review_count'] as int? ?? 0,
        distance: 0.0,
        isAvailable: m['is_available'] == true || m['is_available'] == 1,
        nextAvailable: m['business_hours'] as String? ?? '',
      );
    }).toList();
  }

  // ── 예약 ─────────────────────────────────────────────────────────

  Future<Reservation> createReservation(Reservation res) async {
    final data = await _post('/api/reservations', {
      'farm_id': res.farmId,
      'center_id': res.centerId,
      'farm_name': res.farmName,
      'center_name': res.centerName,
      'scheduled_date': res.scheduledDate,
      'scheduled_time': res.scheduledTime,
      'selected_tanks': res.selectedTanks,
      'total_fish': res.totalFish,
      'service_type': res.serviceType,
      'notes': res.notes,
      'service_amount': res.serviceAmount,
      'commission_rate': res.commissionRate,
      'commission_amount': res.commissionAmount,
    });
    return _reservationFromJson(data);
  }

  Future<List<Reservation>> getReservationsByFarm(String farmId) async {
    final data = await _get('/api/reservations/farm/$farmId');
    final list = (data['reservations'] as List<dynamic>?) ?? [];
    return list.map((r) => _reservationFromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Reservation>> getReservationsByCenter(String centerId) async {
    final data = await _get('/api/reservations/center/$centerId');
    final list = (data['reservations'] as List<dynamic>?) ?? [];
    return list.map((r) => _reservationFromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Reservation> updateReservationStatus(String reservationId, String status, {String directorNotes = ''}) async {
    final data = await _patch('/api/reservations/$reservationId/status', {
      'status': status,
      'director_notes': directorNotes,
    });
    return _reservationFromJson(data);
  }

  // ── 서버 상태 확인 ───────────────────────────────────────────────

  Future<bool> isServerReachable() async {
    try {
      await _get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── 내부 변환 헬퍼 ───────────────────────────────────────────────

  static Reservation _reservationFromJson(Map<String, dynamic> j) => Reservation(
    id: j['id'] as String,
    farmId: j['farm_id'] as String,
    centerId: j['center_id'] as String,
    farmName: j['farm_name'] as String,
    centerName: j['center_name'] as String,
    scheduledDate: j['scheduled_date'] as String,
    scheduledTime: j['scheduled_time'] as String,
    selectedTanks: List<String>.from(j['selected_tanks'] ?? []),
    totalFish: j['total_fish'] as int? ?? 0,
    serviceType: j['service_type'] as String,
    status: j['status'] as String? ?? 'pending',
    notes: j['notes'] as String? ?? '',
    contractUrl: j['contract_url'] as String?,
    serviceAmount: j['service_amount'] as int? ?? 0,
    commissionRate: (j['commission_rate'] as num?)?.toDouble() ?? 0.10,
    commissionAmount: j['commission_amount'] as int? ?? 0,
    createdAt: (j['created_at'] as String? ?? '').split('T')[0],
    directorNotes: j['director_notes'] as String?,
  );
}
