class FarmProfile {
  final String id;
  final String farmName;
  final String ownerName;
  final String location;
  final String address;
  final List<String> fishSpecies;
  final String phone;
  final String description;

  const FarmProfile({
    required this.id,
    required this.farmName,
    this.ownerName = '',
    this.location = '',
    this.address = '',
    this.fishSpecies = const [],
    this.phone = '',
    this.description = '',
  });

  factory FarmProfile.fromJson(Map<String, dynamic> j) => FarmProfile(
    id: j['id'] as String,
    farmName: j['farm_name'] as String,
    ownerName: j['owner_name'] as String? ?? '',
    location: j['location'] as String? ?? '',
    address: j['address'] as String? ?? '',
    fishSpecies: List<String>.from(j['fish_species'] ?? []),
    phone: j['phone'] as String? ?? '',
    description: j['description'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'farm_name': farmName,
    'owner_name': ownerName,
    'location': location,
    'address': address,
    'fish_species': fishSpecies,
    'phone': phone,
    'description': description,
  };

  FarmProfile copyWith({
    String? id,
    String? farmName,
    String? ownerName,
    String? location,
    String? address,
    List<String>? fishSpecies,
    String? phone,
    String? description,
  }) => FarmProfile(
    id: id ?? this.id,
    farmName: farmName ?? this.farmName,
    ownerName: ownerName ?? this.ownerName,
    location: location ?? this.location,
    address: address ?? this.address,
    fishSpecies: fishSpecies ?? this.fishSpecies,
    phone: phone ?? this.phone,
    description: description ?? this.description,
  );
}

class CenterProfile {
  final String id;
  final String centerName;
  final String directorName;
  final String location;
  final String phone;
  final List<String> specialties;
  final String businessHours;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final String description;

  const CenterProfile({
    required this.id,
    required this.centerName,
    this.directorName = '',
    this.location = '',
    this.phone = '',
    this.specialties = const [],
    this.businessHours = '',
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.description = '',
  });

  factory CenterProfile.fromJson(Map<String, dynamic> j) => CenterProfile(
    id: j['id'] as String,
    centerName: j['center_name'] as String,
    directorName: j['director_name'] as String? ?? '',
    location: j['location'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    specialties: List<String>.from(j['specialties'] ?? []),
    businessHours: j['business_hours'] as String? ?? '',
    isAvailable: j['is_available'] == true || j['is_available'] == 1,
    rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
    reviewCount: j['review_count'] as int? ?? 0,
    description: j['description'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'center_name': centerName,
    'director_name': directorName,
    'location': location,
    'phone': phone,
    'specialties': specialties,
    'business_hours': businessHours,
    'is_available': isAvailable,
    'rating': rating,
    'review_count': reviewCount,
    'description': description,
  };

  CenterProfile copyWith({
    String? id,
    String? centerName,
    String? directorName,
    String? location,
    String? phone,
    List<String>? specialties,
    String? businessHours,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    String? description,
  }) => CenterProfile(
    id: id ?? this.id,
    centerName: centerName ?? this.centerName,
    directorName: directorName ?? this.directorName,
    location: location ?? this.location,
    phone: phone ?? this.phone,
    specialties: specialties ?? this.specialties,
    businessHours: businessHours ?? this.businessHours,
    isAvailable: isAvailable ?? this.isAvailable,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    description: description ?? this.description,
  );
}
