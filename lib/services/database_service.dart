import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final supabase = Supabase.instance.client;

  // ============================================================================
  // PROFILES
  // ============================================================================

  /// Create user profile after signup
  Future<void> createUserProfile({
    required String email,
    String? firstName,
    String? lastName,
    bool isDriver = false,
    bool isPassenger = true,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      await supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'is_driver': isDriver,
        'is_passenger': isPassenger,
      });

      debugPrint("✅ Profile created for $email");
    } catch (e) {
      debugPrint("❌ Error creating profile: $e");
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint("❌ Error fetching profile: $e");
      return null;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    bool? isDriver,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (isDriver != null) updates['is_driver'] = isDriver;

      await supabase.from('profiles').update(updates).eq('id', userId);

      debugPrint("✅ Profile updated");
    } catch (e) {
      debugPrint("❌ Error updating profile: $e");
      rethrow;
    }
  }

  // ============================================================================
  // RIDES
  // ============================================================================

  /// Create a new ride
  Future<String> createRide({
    required String startLocation,
    required double startLat,
    required double startLng,
    required String endLocation,
    required double endLat,
    required double endLng,
    required DateTime departureTime,
    required int availableSeats,
    required double pricePerSeat,
    required String vehicleType,
    String? vehiclePlate,
    String? notes,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final response = await supabase.from('rides').insert({
        'driver_id': user.id,
        'start_location': startLocation,
        'start_lat': startLat,
        'start_lng': startLng,
        'end_location': endLocation,
        'end_lat': endLat,
        'end_lng': endLng,
        'departure_time': departureTime.toIso8601String(),
        'available_seats': availableSeats,
        'price_per_seat': pricePerSeat,
        'vehicle_type': vehicleType,
        'vehicle_plate': vehiclePlate,
        'notes': notes,
      }).select('id').single();

      debugPrint("✅ Ride created: ${response['id']}");
      return response['id'];
    } catch (e) {
      debugPrint("❌ Error creating ride: $e");
      rethrow;
    }
  }

  /// Get available rides with advanced filtering
  Future<List<Map<String, dynamic>>> searchRides({
    DateTime? afterDate,
    String? startLocation,
    String? endLocation,
    double? maxPrice,
    int? minSeats,
  }) async {
    try {
      // Debug logging
      debugPrint("🔍 Searching rides with filters:");
      debugPrint("   - afterDate: ${afterDate?.toIso8601String()}");
      debugPrint("   - startLocation: $startLocation");
      debugPrint("   - endLocation: $endLocation");
      debugPrint("   - maxPrice: $maxPrice");
      debugPrint("   - minSeats: $minSeats");

      var query = supabase
          .from('rides')
          .select(
            '''
            id,
            driver_id,
            start_location,
            start_lat,
            start_lng,
            end_location,
            end_lat,
            end_lng,
            departure_time,
            available_seats,
            price_per_seat,
            vehicle_type,
            vehicle_plate,
            status,
            notes
          '''
          )
          .eq('status', 'available')
          .gt('available_seats', 0); // Only rides with available seats

      // Filter by date
      if (afterDate != null) {
        query = query.gte('departure_time', afterDate.toIso8601String());
      }

      // Filter by start location (case-insensitive partial match)
      if (startLocation != null && startLocation.isNotEmpty) {
        query = query.ilike('start_location', '%$startLocation%');
      }

      // Filter by end location
      if (endLocation != null && endLocation.isNotEmpty) {
        query = query.ilike('end_location', '%$endLocation%');
      }

      // Filter by max price
      if (maxPrice != null) {
        query = query.lte('price_per_seat', maxPrice);
      }

      // Filter by minimum available seats
      if (minSeats != null && minSeats > 1) {
        query = query.gte('available_seats', minSeats);
      }

      final response = await query.order('departure_time', ascending: true);
      debugPrint("✅ Search returned ${response.length} rides");

      // Fetch driver profiles for each ride. Supabase decodes nested/embedded
      // rows as dynamic-keyed maps, so every record is re-typed explicitly to
      // guarantee a `Map<String, dynamic>` for callers.
      final ridesWithProfiles = <Map<String, dynamic>>[];
      for (final rawRide in response) {
        final ride = Map<String, dynamic>.from(rawRide);
        try {
          final driverId = ride['driver_id'];
          final driverProfile = await supabase
              .from('profiles')
              .select('first_name, last_name, rating, avatar_url')
              .eq('id', driverId)
              .maybeSingle();

          ride['profiles'] = driverProfile == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(driverProfile);
        } catch (e) {
          debugPrint("⚠️ Could not fetch driver profile for ride ${ride['id']}: $e");
          ride['profiles'] = <String, dynamic>{};
        }
        ridesWithProfiles.add(ride);
      }

      return ridesWithProfiles;
    } catch (e) {
      debugPrint("❌ Error searching rides: $e");
      return [];
    }
  }

  /// Get available rides after a specific date (wrapper around searchRides)
  Future<List<Map<String, dynamic>>> getAvailableRides({
    DateTime? afterDate,
  }) async {
    return searchRides(afterDate: afterDate);
  }

  /// Get driver's rides
  Future<List<Map<String, dynamic>>> getMyRides(String driverId) async {
    try {
      final response = await supabase
          .from('rides')
          .select()
          .eq('driver_id', driverId)
          .order('departure_time', ascending: true);

      return response
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (e) {
      debugPrint("❌ Error fetching driver rides: $e");
      return [];
    }
  }

  /// Update ride status
  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await supabase.from('rides').update({'status': status}).eq('id', rideId);

      debugPrint("✅ Ride status updated to $status");
    } catch (e) {
      debugPrint("❌ Error updating ride status: $e");
      rethrow;
    }
  }

  // ============================================================================
  // BOOKINGS
  // ============================================================================

  /// Create a booking
  Future<String> createBooking({
    required String rideId,
    required int seatsBooked,
    required double totalPrice,
    String? pickupLocation,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final response = await supabase.from('bookings').insert({
        'ride_id': rideId,
        'passenger_id': user.id,
        'seats_booked': seatsBooked,
        'total_price': totalPrice,
        'pickup_location': pickupLocation,
      }).select('id').single();

      // Update ride available seats
      final ride =
          await supabase.from('rides').select('available_seats').eq('id', rideId).single();
      final newAvailableSeats = (ride['available_seats'] as int) - seatsBooked;

      await supabase
          .from('rides')
          .update({'available_seats': newAvailableSeats}).eq('id', rideId);

      debugPrint("✅ Booking created: ${response['id']}");
      return response['id'];
    } catch (e) {
      debugPrint("❌ Error creating booking: $e");
      rethrow;
    }
  }

  /// Get passenger bookings
  Future<List<Map<String, dynamic>>> getMyBookings(String passengerId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select(
            '''
            id,
            ride_id,
            seats_booked,
            total_price,
            pickup_location,
            status,
            created_at,
            rides(
              driver_id,
              start_location,
              end_location,
              departure_time,
              vehicle_type,
              price_per_seat,
              profiles(first_name, last_name, avatar_url)
            )
          '''
          )
          .eq('passenger_id', passengerId)
          .order('created_at', ascending: false);

      return response
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (e) {
      debugPrint("❌ Error fetching bookings: $e");
      return [];
    }
  }

  /// Get bookings for a ride (driver only)
  Future<List<Map<String, dynamic>>> getRideBookings(String rideId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select(
            '''
            id,
            passenger_id,
            seats_booked,
            total_price,
            pickup_location,
            status,
            created_at,
            profiles(first_name, last_name, phone, avatar_url, rating)
          '''
          )
          .eq('ride_id', rideId)
          .order('created_at', ascending: false);

      return response
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (e) {
      debugPrint("❌ Error fetching ride bookings: $e");
      return [];
    }
  }

  /// Cancel booking (passenger action)
  Future<void> cancelBooking(String bookingId, String rideId) async {
    try {
      // Get booking details to restore seats
      final booking =
          await supabase.from('bookings').select('seats_booked').eq('id', bookingId).single();

      // Update booking status
      await supabase.from('bookings').update({'status': 'cancelled'}).eq('id', bookingId);

      // Restore available seats in ride
      final ride =
          await supabase.from('rides').select('available_seats').eq('id', rideId).single();
      final restoredSeats = (ride['available_seats'] as int) + (booking['seats_booked'] as int);

      await supabase
          .from('rides')
          .update({'available_seats': restoredSeats}).eq('id', rideId);

      debugPrint("✅ Booking cancelled");
    } catch (e) {
      debugPrint("❌ Error cancelling booking: $e");
      rethrow;
    }
  }

  // ============================================================================
  // REAL-TIME LISTENERS
  // ============================================================================

  /// Listen to available rides in real-time
  Stream<List<Map<String, dynamic>>> watchAvailableRides() {
    return supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .map((records) => records
            .where((row) => ((row['available_seats'] as int?) ?? 0) > 0)
            .map((row) => Map<String, dynamic>.from(row))
            .toList());
  }

  /// Listen to user's bookings in real-time
  Stream<List<Map<String, dynamic>>> watchMyBookings(String passengerId) {
    return supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .map((records) => records
            .where((row) => row['passenger_id'] == passengerId)
            .map((row) => Map<String, dynamic>.from(row))
            .toList());
  }
}
