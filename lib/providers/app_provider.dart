import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class AppProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoggedIn = false;
  List<Tank> _tanks = List.from(mockTanks);
  List<Reservation> _reservations = List.from(mockReservations);
  final List<Product> _products = List.from(mockProducts);
  List<Job> _jobs = List.from(mockJobs);
  ToastMessage? _toast;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  List<Tank> get tanks => _tanks;
  List<Reservation> get reservations => _reservations;
  List<Product> get products => _products;
  List<Job> get jobs => _jobs;
  ToastMessage? get toast => _toast;

  void login(String role) {
    _currentUser = mockUsers[role];
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
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

  // Tank operations
  void addTank(Tank tank) {
    final newTank = tank.copyWith(
      id: 'tank_${DateTime.now().millisecondsSinceEpoch}',
      farmId: 'farm_001',
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

  // Reservation operations
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
      farmId: 'farm_001',
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

  // Job operations
  void createJob(Job job) {
    final newJob = job.copyWith(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      centerId: 'center_001',
      appliedCount: 0,
      status: 'open',
    );
    _jobs = [..._jobs, newJob];
    showToast('구인 공고가 등록되었습니다.');
    notifyListeners();
  }

  // Stats
  TankStats getTankStats() {
    final ft = _tanks.where((t) => t.farmId == 'farm_001').toList();
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
    final fr = _reservations.where((r) => r.farmId == 'farm_001').toList();
    return ReservationStats(
      total: fr.length,
      pending: fr.where((r) => r.status == 'pending').length,
      approved: fr.where((r) => r.status == 'approved').length,
      completed: fr.where((r) => r.status == 'completed').length,
      rejected: fr.where((r) => r.status == 'rejected').length,
    );
  }
}
