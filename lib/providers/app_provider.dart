import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../models/profile_models.dart';
import '../services/api_service.dart';
import '../data/mock_data.dart';

class AppProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoggedIn = false;
  bool _isInitializing = true;
  ThemeMode _themeMode = ThemeMode.system;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();
  List<Tank> _tanks = List.from(mockTanks);
  List<Reservation> _reservations = List.from(mockReservations);
  final List<Product> _products = List.from(mockProducts);
  List<Job> _jobs = List.from(mockJobs);
  ToastMessage? _toast;

  // 프로필 & 센터 목록 (서버 연동)
  FarmProfile? _farmProfile;
  CenterProfile? _centerProfile;
  List<AquaCenter> _centers = List.from(mockCenters);
  bool _isLoadingReservations = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitializing => _isInitializing;
  bool get isFirebaseLoggedIn => _auth.currentUser != null;
  ThemeMode get themeMode => _themeMode;
  List<Tank> get tanks => _tanks;
  List<Reservation> get reservations => _reservations;
  List<Product> get products => _products;
  List<Job> get jobs => _jobs;
  ToastMessage? get toast => _toast;
  FarmProfile? get farmProfile => _farmProfile;
  CenterProfile? get centerProfile => _centerProfile;
  List<AquaCenter> get centers => _centers;
  bool get isLoadingReservations => _isLoadingReservations;

  /// 앱 시작 시 항상 로그아웃 → 매번 로그인 화면 표시
  Future<void> initialize() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _isInitializing = false;
    notifyListeners();
  }

  /// Google 로그인 → Firebase 인증 후 Firestore에서 기존 역할 조회
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final firebaseUser = result.user!;

      // Firestore에서 기존 사용자 역할 조회
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data()?['role'] != null) {
        final role = doc.data()!['role'] as String;
        _currentUser = _buildAppUser(firebaseUser, role);
        _isLoggedIn = true;
      }

      notifyListeners();
      return firebaseUser;
    } catch (e) {
      return null;
    }
  }

  /// 역할 선택 완료 → Firestore에 사용자 데이터 저장 후 앱 진입
  Future<void> selectRole(String role) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'uid': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'name': firebaseUser.displayName ?? '',
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _currentUser = _buildAppUser(firebaseUser, role);
    _isLoggedIn = true;
    notifyListeners();
  }

  AppUser _buildAppUser(User firebaseUser, String role) {
    return AppUser(
      id: firebaseUser.uid,
      role: role,
      name: firebaseUser.displayName ?? (role == 'farm' ? '양식장 관리자' : '수산질병관리원'),
      email: firebaseUser.email ?? '',
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    _isLoggedIn = false;
    _farmProfile = null;
    _centerProfile = null;
    notifyListeners();
  }

  /// 개발용 mock 로그인 (Firebase 없이 테스트)
  void login(String role) {
    _currentUser = mockUsers[role];
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    _farmProfile = null;
    _centerProfile = null;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void showToast(String message, {String type = 'success'}) {
    _toast = ToastMessage(
      message: message,
      type: type,
      id: DateTime.now().millisecondsSinceEpoch,
    );
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 3500), () {
      _toast = null;
      notifyListeners();
    });
  }

  void clearToast() {
    _toast = null;
    notifyListeners();
  }

  // ── Tank operations ────────────────────────────────────────────

  void addTank(Tank tank) {
    final newTank = tank.copyWith(
      id: 'tank_${DateTime.now().millisecondsSinceEpoch}',
      farmId: _currentUser?.id ?? 'farm_001',
      status: 'healthy',
    );
    _tanks = [..._tanks, newTank];
    showToast('${tank.name} 수조가 등록되었습니다.');
    notifyListeners();
  }

  void updateTank(String id, Tank updates) {
    _tanks = _tanks.map((t) => t.id == id ? updates.copyWith(id: id) : t).toList();
    showToast('수조 정보가 업데이트되었습니다.');
    notifyListeners();
  }

  void deleteTank(String id) {
    _tanks = _tanks.where((t) => t.id != id).toList();
    showToast('수조가 삭제되었습니다.', type: 'info');
    notifyListeners();
  }

  // ── Reservation operations ────────────────────────────────────

  /// 기존 동기 메서드 (fallback으로 유지)
  Reservation createReservation({
    required String centerId,
    required String centerName,
    required String scheduledDate,
    required String scheduledTime,
    required List<String> selectedTanks,
    required String serviceType,
    required int totalFish,
    required String notes,
    required int serviceAmount,
    required int commissionAmount,
  }) {
    final res = Reservation(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      farmId: _currentUser?.id ?? 'farm_001',
      centerId: centerId,
      farmName: _currentUser?.name ?? '양식장',
      centerName: centerName,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      selectedTanks: selectedTanks,
      totalFish: totalFish,
      serviceType: serviceType,
      status: 'pending',
      notes: notes,
      contractUrl: null,
      serviceAmount: serviceAmount,
      commissionRate: 0.10,
      commissionAmount: commissionAmount,
      createdAt: DateTime.now().toIso8601String().split('T')[0],
    );
    _reservations = [..._reservations, res];
    showToast('예약 신청이 완료되었습니다.');
    notifyListeners();
    return res;
  }

  /// API 연동 예약 생성 (서버 저장 후 fallback)
  Future<Reservation> createReservationApi({
    required String centerId,
    required String centerName,
    required String scheduledDate,
    required String scheduledTime,
    required List<String> selectedTanks,
    required String serviceType,
    required int totalFish,
    required String notes,
    required int serviceAmount,
    required int commissionAmount,
  }) async {
    final tempRes = Reservation(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      farmId: _currentUser?.id ?? 'farm_001',
      centerId: centerId,
      farmName: _currentUser?.name ?? '양식장',
      centerName: centerName,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      selectedTanks: selectedTanks,
      totalFish: totalFish,
      serviceType: serviceType,
      status: 'pending',
      notes: notes,
      contractUrl: null,
      serviceAmount: serviceAmount,
      commissionRate: 0.10,
      commissionAmount: commissionAmount,
      createdAt: DateTime.now().toIso8601String().split('T')[0],
    );

    try {
      final saved = await ApiService().createReservation(tempRes);
      _reservations = [..._reservations, saved];
      showToast('예약 신청이 완료되었습니다.');
      notifyListeners();
      return saved;
    } catch (_) {
      // 서버 실패 시 로컬에만 저장
      _reservations = [..._reservations, tempRes];
      showToast('예약 신청이 완료되었습니다. (오프라인)');
      notifyListeners();
      return tempRes;
    }
  }

  void updateReservationStatus(String id, String status, {String notes = ''}) {
    _reservations = _reservations.map((r) {
      if (r.id == id) {
        return r.copyWith(
          status: status,
          directorNotes: notes,
          contractUrl: status == 'approved' ? '/contracts/$id.pdf' : r.contractUrl,
        );
      }
      return r;
    }).toList();
    final msg = status == 'approved' ? '승인' : status == 'rejected' ? '거부' : '완료';
    showToast('예약이 $msg되었습니다.', type: status == 'approved' ? 'success' : 'info');
    notifyListeners();
  }

  /// API 연동 상태 변경
  Future<void> updateReservationStatusApi(String id, String status, {String notes = ''}) async {
    bool success = false;
    try {
      final updated = await ApiService().updateReservationStatus(id, status, directorNotes: notes);
      _reservations = _reservations.map((r) => r.id == id ? updated : r).toList();
      success = true;
    } catch (_) {
      // 서버 실패 시 로컬만 업데이트
      _reservations = _reservations.map((r) {
        if (r.id == id) {
          return r.copyWith(
            status: status,
            directorNotes: notes,
            contractUrl: status == 'approved' ? '/contracts/$id.pdf' : r.contractUrl,
          );
        }
        return r;
      }).toList();
    }
    final msg = status == 'approved' ? '승인' : status == 'rejected' ? '거부' : '완료';
    final suffix = success ? '' : ' (오프라인)';
    showToast('예약이 $msg되었습니다.$suffix', type: status == 'approved' ? 'success' : 'info');
    notifyListeners();
  }

  // ── 서버에서 예약 목록 로드 ────────────────────────────────────

  Future<void> loadReservationsForFarm(String farmId) async {
    _isLoadingReservations = true;
    notifyListeners();
    try {
      final res = await ApiService().getReservationsByFarm(farmId);
      if (res.isNotEmpty) _reservations = res;
    } catch (_) {
      // mock 데이터 유지
    } finally {
      _isLoadingReservations = false;
      notifyListeners();
    }
  }

  Future<void> loadReservationsForCenter(String centerId) async {
    _isLoadingReservations = true;
    notifyListeners();
    try {
      final res = await ApiService().getReservationsByCenter(centerId);
      // 서버 데이터가 있으면 교체, 없으면 기존 in-memory 데이터 유지
      // (같은 기기 테스트 시 farm이 만든 예약이 in-memory에 살아있음)
      if (res.isNotEmpty) _reservations = res;
    } catch (_) {
      // 서버 연결 실패 → 기존 _reservations 유지 (farm이 만든 예약 포함)
    } finally {
      _isLoadingReservations = false;
      notifyListeners();
    }
  }

  // ── 센터 목록 로드 ────────────────────────────────────────────

  Future<void> loadCenters() async {
    try {
      final list = await ApiService().listCenters();
      if (list.isNotEmpty) {
        _centers = list;
        notifyListeners();
      }
    } catch (_) {
      // mockCenters 유지
    }
  }

  // ── 양식장 프로필 ─────────────────────────────────────────────

  Future<void> loadFarmProfile(String farmId) async {
    try {
      final p = await ApiService().getFarmProfile(farmId);
      if (p != null) {
        _farmProfile = p;
        notifyListeners();
      }
    } catch (_) {
      // 서버 미연결 시 null 유지 (빈 폼 표시)
    }
  }

  Future<void> saveFarmProfileApi(FarmProfile profile) async {
    final saved = await ApiService().saveFarmProfile(profile.id, profile);
    _farmProfile = saved;
    showToast('프로필이 저장되었습니다.');
    notifyListeners();
  }

  // ── 수산질병관리원 프로필 ─────────────────────────────────────

  Future<void> loadCenterProfile(String centerId) async {
    try {
      final p = await ApiService().getCenterProfile(centerId);
      if (p != null) {
        _centerProfile = p;
        notifyListeners();
      }
    } catch (_) {
      // 서버 미연결 시 null 유지
    }
  }

  Future<void> saveCenterProfileApi(CenterProfile profile) async {
    final saved = await ApiService().saveCenterProfile(profile.id, profile);
    _centerProfile = saved;
    showToast('프로필이 저장되었습니다.');
    notifyListeners();
  }

  // ── Job operations ────────────────────────────────────────────

  void createJob(Job job) {
    final newJob = job.copyWith(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      centerId: _currentUser?.id ?? 'center_001',
      appliedCount: 0,
      status: 'open',
    );
    _jobs = [..._jobs, newJob];
    showToast('구인 공고가 등록되었습니다.');
    notifyListeners();
  }

  // ── Stats ─────────────────────────────────────────────────────

  TankStats getTankStats() {
    final userId = _currentUser?.id ?? 'farm_001';
    final ft = _tanks.where((t) => t.farmId == userId).toList();
    return TankStats(
      total: ft.length,
      healthy: ft.where((t) => t.status == 'healthy').length,
      warning: ft.where((t) => t.status == 'warning').length,
      danger: ft.where((t) => t.status == 'danger').length,
      totalFish: ft.fold(0, (sum, t) => sum + t.totalFish),
      totalInjured: ft.fold(0, (sum, t) => sum + t.injuredFish),
    );
  }

  ReservationStats getReservationStats() {
    final userId = _currentUser?.id ?? 'farm_001';
    final fr = _reservations.where((r) => r.farmId == userId).toList();
    return ReservationStats(
      total: fr.length,
      pending: fr.where((r) => r.status == 'pending').length,
      approved: fr.where((r) => r.status == 'approved').length,
      completed: fr.where((r) => r.status == 'completed').length,
      rejected: fr.where((r) => r.status == 'rejected').length,
    );
  }
}
