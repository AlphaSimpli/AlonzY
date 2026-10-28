/// Strongly-typed application user profile.
///
/// Every field is read through safe accessors so raw Supabase rows (which are
/// decoded with dynamic keys) can never throw a cast error at runtime.
class AppUser {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;
  final bool isDriver;
  final bool isPassenger;
  final double rating;
  final String? bio;
  final String contactPreference;
  final bool emailVerified;
  final bool phoneVerified;
  final String govtIdStatus;
  final DateTime? govtIdVerifiedAt;
  final int verifiedRides;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehiclePlate;
  final int? vehicleYear;

  const AppUser({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    this.isDriver = false,
    this.isPassenger = true,
    this.rating = 5.0,
    this.bio,
    this.contactPreference = 'email',
    this.emailVerified = false,
    this.phoneVerified = false,
    this.govtIdStatus = 'none',
    this.govtIdVerifiedAt,
    this.verifiedRides = 0,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.vehiclePlate,
    this.vehicleYear,
  });

  String get displayName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return 'Rider';
    return '$first $last'.trim();
  }

  String get initials {
    final first = firstName?.trim();
    final last = lastName?.trim();
    if ((first?.isNotEmpty ?? false) && (last?.isNotEmpty ?? false)) {
      return '${first![0]}${last![0]}'.toUpperCase();
    }
    final name = (first?.isNotEmpty ?? false) ? first! : email ?? 'R';
    return name.substring(0, 1).toUpperCase();
  }

  /// Whether the government ID has been verified.
  bool get govtIdVerified => govtIdStatus == 'verified';

  /// Number of verification levels completed (email, phone, govt ID).
  int get verificationLevel {
    var level = 0;
    if (emailVerified) level++;
    if (phoneVerified) level++;
    if (govtIdVerified) level++;
    return level;
  }

  /// Parses a raw database row, tolerating dynamic-keyed maps from Supabase.
  factory AppUser.fromJson(Map<String, dynamic>? json) {
    final data = json == null ? <String, dynamic>{} : _sanitize(json);
    return AppUser(
      id: data['id']?.toString() ?? '',
      email: data['email']?.toString(),
      firstName: data['first_name']?.toString(),
      lastName: data['last_name']?.toString(),
      phone: data['phone']?.toString(),
      avatarUrl: data['avatar_url']?.toString(),
      isDriver: data['is_driver'] == true,
      isPassenger: data['is_passenger'] != false,
      rating: _asDouble(data['rating']) ?? 5.0,
      bio: data['bio']?.toString(),
      contactPreference: data['contact_preference']?.toString() ?? 'email',
      emailVerified: data['email_verified'] == true,
      phoneVerified: data['phone_verified'] == true,
      govtIdStatus: data['govt_id_status']?.toString() ?? 'none',
      govtIdVerifiedAt:
          DateTime.tryParse(data['govt_id_verified_at']?.toString() ?? ''),
      verifiedRides: _asInt(data['verified_rides']) ?? 0,
      vehicleMake: data['vehicle_make']?.toString(),
      vehicleModel: data['vehicle_model']?.toString(),
      vehicleColor: data['vehicle_color']?.toString(),
      vehiclePlate: data['vehicle_plate']?.toString(),
      vehicleYear: _asInt(data['vehicle_year']),
    );
  }

  /// Builds a column map for insert/update queries (nulls omitted).
  Map<String, dynamic> toJson() => {
        if (email != null) 'email': email,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'is_driver': isDriver,
        'is_passenger': isPassenger,
        if (bio != null) 'bio': bio,
        'contact_preference': contactPreference,
        if (vehicleMake != null) 'vehicle_make': vehicleMake,
        if (vehicleModel != null) 'vehicle_model': vehicleModel,
        if (vehicleColor != null) 'vehicle_color': vehicleColor,
        if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
        if (vehicleYear != null) 'vehicle_year': vehicleYear,
      };

  static Map<String, dynamic> _sanitize(Map<String, dynamic> json) =>
      Map<String, dynamic>.from(json);

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
