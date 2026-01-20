class CustomerProfile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? profileImageUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> savedAddresses; // Home, Work, etc.
  final List<String> preferredServiceCategories;
  final String? preferredLanguage;
  final bool receiveNotifications;
  final int totalBookings;
  final double averageSpent;
  final double averageRating;
  final DateTime createdAt;
  final DateTime? lastBookingDate;

  CustomerProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.profileImageUrl,
    this.address,
    this.latitude,
    this.longitude,
    required this.savedAddresses,
    required this.preferredServiceCategories,
    this.preferredLanguage,
    required this.receiveNotifications,
    required this.totalBookings,
    required this.averageSpent,
    required this.averageRating,
    required this.createdAt,
    this.lastBookingDate,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profileImageUrl: json['profile_image_url'],
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      savedAddresses: List<String>.from(json['saved_addresses'] ?? []),
      preferredServiceCategories:
          List<String>.from(json['preferred_service_categories'] ?? []),
      preferredLanguage: json['preferred_language'],
      receiveNotifications: json['receive_notifications'] ?? true,
      totalBookings: json['total_bookings'] ?? 0,
      averageSpent: (json['average_spent'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      lastBookingDate: json['last_booking_date'] != null
          ? DateTime.parse(json['last_booking_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'saved_addresses': savedAddresses,
      'preferred_service_categories': preferredServiceCategories,
      'preferred_language': preferredLanguage,
      'receive_notifications': receiveNotifications,
      'total_bookings': totalBookings,
      'average_spent': averageSpent,
      'average_rating': averageRating,
      'created_at': createdAt.toIso8601String(),
      'last_booking_date': lastBookingDate?.toIso8601String(),
    };
  }
}

class ProviderProfile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? profileImageUrl;
  final String serviceCategory;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String verificationStatus; // verified, pending, rejected
  final List<String>? certifications;
  final List<String> workingDays; // Mon, Tue, etc
  final String workingHoursStart; // HH:mm
  final String workingHoursEnd;
  final int maxConcurrentJobs;
  final int completedJobs;
  final double averageRating;
  final int totalReviews;
  final bool isOnline;
  final String? bankAccountInfo;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  ProviderProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.serviceCategory,
    this.description,
    this.latitude,
    this.longitude,
    required this.verificationStatus,
    this.certifications,
    required this.workingDays,
    required this.workingHoursStart,
    required this.workingHoursEnd,
    required this.maxConcurrentJobs,
    required this.completedJobs,
    required this.averageRating,
    required this.totalReviews,
    required this.isOnline,
    this.bankAccountInfo,
    required this.createdAt,
    this.verifiedAt,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profileImageUrl: json['profile_image_url'],
      serviceCategory: json['service_category'] ?? '',
      description: json['description'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      verificationStatus: json['verification_status'] ?? 'pending',
      certifications: List<String>.from(json['certifications'] ?? []),
      workingDays: List<String>.from(json['working_days'] ?? []),
      workingHoursStart: json['working_hours_start'] ?? '09:00',
      workingHoursEnd: json['working_hours_end'] ?? '17:00',
      maxConcurrentJobs: json['max_concurrent_jobs'] ?? 1,
      completedJobs: json['completed_jobs'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      isOnline: json['is_online'] ?? false,
      bankAccountInfo: json['bank_account_info'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'service_category': serviceCategory,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'verification_status': verificationStatus,
      'certifications': certifications,
      'working_days': workingDays,
      'working_hours_start': workingHoursStart,
      'working_hours_end': workingHoursEnd,
      'max_concurrent_jobs': maxConcurrentJobs,
      'completed_jobs': completedJobs,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'is_online': isOnline,
      'bank_account_info': bankAccountInfo,
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}
