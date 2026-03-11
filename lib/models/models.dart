class AppUser {
  final String id;
  final String role;
  final String name;
  final String email;

  // Farm fields
  final String? ownerName;
  final int? totalTanks;
  final int? totalFish;

  // Center fields
  final String? directorName;
  final int? staffCount;
  final double? rating;
  final int? reviewCount;

  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.ownerName,
    this.totalTanks,
    this.totalFish,
    this.directorName,
    this.staffCount,
    this.rating,
    this.reviewCount,
  });
}

class Tank {
  final String id;
  final String farmId;
  final String name;
  final int totalFish;
  final int injuredFish;
  final double waterTemp;
  final String status; // healthy, warning, danger
  final String lastInjectionDate;
  final String nextInjectionDate;
  final String notes;
  final String createdAt;

  const Tank({
    required this.id,
    required this.farmId,
    required this.name,
    required this.totalFish,
    required this.injuredFish,
    required this.waterTemp,
    required this.status,
    required this.lastInjectionDate,
    required this.nextInjectionDate,
    required this.notes,
    this.createdAt = '',
  });

  Tank copyWith({
    String? id,
    String? farmId,
    String? name,
    int? totalFish,
    int? injuredFish,
    double? waterTemp,
    String? status,
    String? lastInjectionDate,
    String? nextInjectionDate,
    String? notes,
    String? createdAt,
  }) {
    return Tank(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      name: name ?? this.name,
      totalFish: totalFish ?? this.totalFish,
      injuredFish: injuredFish ?? this.injuredFish,
      waterTemp: waterTemp ?? this.waterTemp,
      status: status ?? this.status,
      lastInjectionDate: lastInjectionDate ?? this.lastInjectionDate,
      nextInjectionDate: nextInjectionDate ?? this.nextInjectionDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AquaCenter {
  final String id;
  final String name;
  final String directorName;
  final String phone;
  final String location;
  final List<String> specialties;
  final double rating;
  final int reviewCount;
  final double distance;
  final bool isAvailable;
  final String nextAvailable;

  const AquaCenter({
    required this.id,
    required this.name,
    required this.directorName,
    required this.phone,
    required this.location,
    required this.specialties,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.isAvailable,
    required this.nextAvailable,
  });
}

class Reservation {
  final String id;
  final String farmId;
  final String centerId;
  final String farmName;
  final String centerName;
  final String scheduledDate;
  final String scheduledTime;
  final List<String> selectedTanks;
  final int totalFish;
  final String serviceType;
  final String status; // pending, approved, rejected, completed
  final String notes;
  final String? contractUrl;
  final int serviceAmount;
  final double commissionRate;
  final int commissionAmount;
  final String createdAt;
  final String? directorNotes;

  const Reservation({
    required this.id,
    required this.farmId,
    required this.centerId,
    required this.farmName,
    required this.centerName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.selectedTanks,
    required this.totalFish,
    required this.serviceType,
    required this.status,
    required this.notes,
    this.contractUrl,
    required this.serviceAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.createdAt,
    this.directorNotes,
  });

  Reservation copyWith({
    String? id,
    String? farmId,
    String? centerId,
    String? farmName,
    String? centerName,
    String? scheduledDate,
    String? scheduledTime,
    List<String>? selectedTanks,
    int? totalFish,
    String? serviceType,
    String? status,
    String? notes,
    String? contractUrl,
    int? serviceAmount,
    double? commissionRate,
    int? commissionAmount,
    String? createdAt,
    String? directorNotes,
  }) {
    return Reservation(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      centerId: centerId ?? this.centerId,
      farmName: farmName ?? this.farmName,
      centerName: centerName ?? this.centerName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      selectedTanks: selectedTanks ?? this.selectedTanks,
      totalFish: totalFish ?? this.totalFish,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      contractUrl: contractUrl ?? this.contractUrl,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      createdAt: createdAt ?? this.createdAt,
      directorNotes: directorNotes ?? this.directorNotes,
    );
  }
}

class Product {
  final String id;
  final String centerId;
  final String category;
  final String name;
  final String description;
  final int price;
  final int stock;
  final bool available;

  const Product({
    required this.id,
    required this.centerId,
    required this.category,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.available,
  });
}

class Job {
  final String id;
  final String centerId;
  final String centerName;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final String location;
  final int appliedCount;
  final int wage;
  final String status; // open, closed
  final List<String> skills;
  final String createdAt;

  const Job({
    required this.id,
    required this.centerId,
    required this.centerName,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.appliedCount,
    required this.wage,
    required this.status,
    required this.skills,
    required this.createdAt,
  });

  Job copyWith({
    String? id,
    String? centerId,
    String? centerName,
    String? title,
    String? description,
    String? startDate,
    String? endDate,
    String? location,
    int? appliedCount,
    int? wage,
    String? status,
    List<String>? skills,
    String? createdAt,
  }) {
    return Job(
      id: id ?? this.id,
      centerId: centerId ?? this.centerId,
      centerName: centerName ?? this.centerName,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      appliedCount: appliedCount ?? this.appliedCount,
      wage: wage ?? this.wage,
      status: status ?? this.status,
      skills: skills ?? this.skills,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ToastMessage {
  final String message;
  final String type; // success, info, error
  final int id;

  const ToastMessage({
    required this.message,
    required this.type,
    required this.id,
  });
}

class TankStats {
  final int total;
  final int healthy;
  final int warning;
  final int danger;
  final int totalFish;
  final int totalInjured;

  const TankStats({
    required this.total,
    required this.healthy,
    required this.warning,
    required this.danger,
    required this.totalFish,
    required this.totalInjured,
  });
}

class ReservationStats {
  final int total;
  final int pending;
  final int approved;
  final int completed;
  final int rejected;

  const ReservationStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.completed,
    required this.rejected,
  });
}
