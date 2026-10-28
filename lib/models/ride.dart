import '../maps/map_types.dart';
import 'app_user.dart';

/// Strongly-typed ride offer with a driver profile preview.
///
/// All numeric/date fields are parsed defensively so raw Supabase rows can
/// never throw a runtime cast exception.
class Ride {
  final String id;
  final String driverId;
  final String originCity;
  final String originAddress;
  final String destinationCity;
  final String destinationAddress;
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final DateTime departureTime;
  final int availableSeats;
  final double pricePerSeat;
  final String vehicleType;
  final String? vehiclePlate;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final int? vehicleYear;
  final bool instantBooking;
  final String status;
  final String? notes;
  final bool petsAllowed;
  final String luggagePolicy;
  final AppUser? driver;

  const Ride({
    required this.id,
    required this.driverId,
    this.originCity = '',
    this.originAddress = '',
    this.destinationCity = '',
    this.destinationAddress = '',
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.departureTime,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.vehicleType,
    this.vehiclePlate,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleYear,
    this.instantBooking = false,
    this.status = 'available',
    this.notes,
    this.petsAllowed = false,
    this.luggagePolicy = 'moderate',
    this.driver,
  });

  MapLocation get start => MapLocation(originLat, originLng);
  MapLocation get end => MapLocation(destinationLat, destinationLng);

  String get vehicleSummary {
    final parts = <String>[
      if (vehicleColor?.isNotEmpty ?? false) vehicleColor!,
      if (vehicleMake?.isNotEmpty ?? false) vehicleMake!,
      if (vehicleModel?.isNotEmpty ?? false) vehicleModel!,
      vehicleType,
      if (vehicleYear != null) '($vehicleYear)',
    ];
    final joined = parts.join(' ').trim();
    if (joined.isEmpty) return 'Vehicle not specified';
    if (vehiclePlate?.isNotEmpty ?? false) return '$joined · ${vehiclePlate!}';
    return joined;
  }

  factory Ride.fromJson(Map<String, dynamic>? json) {
    final data = json == null ? <String, dynamic>{} : Map<String, dynamic>.from(json);
    final rawDriver = data['profiles'] is Map
        ? Map<String, dynamic>.from(data['profiles'] as Map)
        : null;
    return Ride(
      id: data['id']?.toString() ?? '',
      driverId: data['driver_id']?.toString() ?? '',
          originCity: _safeCity(data['origin_city']),
          originAddress: data['origin_address']?.toString() ?? '',
          destinationCity: _safeCity(data['destination_city']),
          destinationAddress: data['destination_address']?.toString() ?? '',
          originLat: _asDouble(data['origin_lat']) ?? 0,
          originLng: _asDouble(data['origin_lng']) ?? 0,
          destinationLat: _asDouble(data['destination_lat']) ?? 0,
          destinationLng: _asDouble(data['destination_lng']) ?? 0,
      departureTime: DateTime.tryParse(data['departure_time']?.toString() ?? '') ??
          DateTime.now(),
      availableSeats: _asInt(data['available_seats']) ?? 0,
      pricePerSeat: _asDouble(data['price_per_seat']) ?? 0,
      vehicleType: data['vehicle_type']?.toString() ?? 'sedan',
      vehiclePlate: data['vehicle_plate']?.toString(),
      vehicleMake: data['vehicle_make']?.toString(),
      vehicleModel: data['vehicle_model']?.toString(),
      vehicleColor: data['vehicle_color']?.toString(),
      vehicleYear: _asInt(data['vehicle_year']),
      instantBooking: data['instant_booking'] == true,
      status: data['status']?.toString() ?? 'available',
      notes: data['notes']?.toString(),
      petsAllowed: data['pets_allowed'] == true,
      luggagePolicy: data['luggage_policy']?.toString() ?? 'moderate',
      driver: rawDriver == null ? null : AppUser.fromJson(rawDriver),
    );
  }

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String _safeCity(Object? value) {
    final city = value?.toString().trim() ?? '';
    if (city.isEmpty || RegExp(r'^-?\d+(?:[., ]|$)').hasMatch(city)) {
      return '';
    }
    if (RegExp(
      r'\b(street|st\.?|road|rd\.?|avenue|ave\.?|boulevard|blvd\.?)\b',
      caseSensitive: false,
    ).hasMatch(city)) {
      return '';
    }
    return city;
  }
}