import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/review.dart';
import '../models/ride.dart';

/// Data access layer for Supabase.
///
/// Every query result is converted to a strongly-typed model (see
/// `lib/models/`) which parses raw rows defensively, so dynamic-keyed maps
/// from Supabase can never leak a runtime cast error into the UI.
///
/// Seat accounting (decrement on booking, restore on cancel, overbooking
/// protection) is enforced server-side by triggers from migration 002, so the
/// client performs no manual seat arithmetic.
class DatabaseService {
  DatabaseService({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  final SupabaseClient supabase;

  static const int _spatialCandidateLimit = 100;

  /// Stores the offers shown by the road matcher as pending feedback.
  Future<Map<String, String>> recordMatchFeedback(
    List<MatchFeedbackDraft> entries,
  ) async {
    if (entries.isEmpty) return const {};
    final passengerId = supabase.auth.currentUser?.id;
    if (passengerId == null) {
      throw StateError('Sign in before saving matching feedback.');
    }

    final response = await supabase
        .from('match_feedback')
        .insert(
          entries
              .map(
                (entry) => {
                  'ride_id': entry.rideId,
                  'passenger_id': passengerId,
                  'detour_min': entry.detourMinutes,
                  'time_gap_min': entry.timeGapMinutes,
                  'pref_score': entry.preferenceScore,
                  'price': entry.price,
                  'rule_score': entry.ruleScore,
                },
              )
              .toList(),
        )
        .select('id, ride_id');

    return {
      for (final row in response)
        row['ride_id'].toString(): row['id'].toString(),
    };
  }

  Future<void> updateMatchFeedback({
    required String feedbackId,
    required bool accepted,
  }) async {
    if (feedbackId.isEmpty) {
      throw ArgumentError.value(feedbackId, 'feedbackId', 'Must not be empty.');
    }
    await supabase
        .from('match_feedback')
        .update({'accepted': accepted})
        .eq('id', feedbackId)
        .select('id')
        .single();
  }

  // ============================================================================
  // PROFILES
  // ============================================================================

  /// Creates the user profile row (also auto-created by the DB trigger).
  Future<void> createUserProfile({
    required String email,
    String? firstName,
    String? lastName,
    bool isDriver = false,
    bool isPassenger = true,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await supabase.from('profiles').insert({
      'id': user.id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'is_driver': isDriver,
      'is_passenger': isPassenger,
    });
  }

  /// Fetches the current user's profile.
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return AppUser.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  /// Updates profile fields; only provided values are sent.
  Future<void> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    bool? isDriver,
    String? bio,
    String? contactPreference,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    String? vehiclePlate,
    int? vehicleYear,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (isDriver != null) updates['is_driver'] = isDriver;
    if (bio != null) updates['bio'] = bio;
    if (contactPreference != null) {
      updates['contact_preference'] = contactPreference;
    }
    if (vehicleMake != null) updates['vehicle_make'] = vehicleMake;
    if (vehicleModel != null) updates['vehicle_model'] = vehicleModel;
    if (vehicleColor != null) updates['vehicle_color'] = vehicleColor;
    if (vehiclePlate != null) updates['vehicle_plate'] = vehiclePlate;
    if (vehicleYear != null) updates['vehicle_year'] = vehicleYear;
    if (updates.isEmpty) return;

    await supabase.from('profiles').update(updates).eq('id', userId);
  }

  /// Requests government ID verification (flagged pending for manual review).
  Future<void> requestGovtIdVerification(String userId) async {
    await supabase
        .from('profiles')
        .update({'govt_id_status': 'pending'})
        .eq('id', userId);
  }

  // ============================================================================
  // RIDES
  // ============================================================================

  /// Creates a new ride; returns the generated ride id.
  Future<String> createRide({
    required String originCity,
    required String originAddress,
    required double startLat,
    required double startLng,
    required String destinationCity,
    required String destinationAddress,
    required double endLat,
    required double endLng,
    required DateTime departureTime,
    required int availableSeats,
    required double pricePerSeat,
    required String vehicleType,
    String? vehiclePlate,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    int? vehicleYear,
    bool petsAllowed = false,
    String luggagePolicy = 'moderate',
    bool instantBooking = false,
    String? notes,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final payload = <String, dynamic>{
      'driver_id': user.id,
      'origin_city': originCity,
      'origin_address': originAddress,
      'destination_city': destinationCity,
      'destination_address': destinationAddress,
      'origin_lat': startLat,
      'origin_lng': startLng,
      'destination_lat': endLat,
      'destination_lng': endLng,
      'departure_time': departureTime.toIso8601String(),
      'available_seats': availableSeats,
      'price_per_seat': pricePerSeat,
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_color': vehicleColor,
      'vehicle_year': vehicleYear,
      'pets_allowed': petsAllowed,
      'luggage_policy': luggagePolicy,
      'instant_booking': instantBooking,
      'status': 'available',
      'notes': notes,
    };

    try {
      final response = await supabase
          .from('rides')
          .insert(payload)
          .select('id')
          .single();
      return response['id'].toString();
    } on PostgrestException catch (error) {
      final isMissingInstantBooking =
          error.code == 'PGRST204' || error.message.contains('instant_booking');
      if (!isMissingInstantBooking) rethrow;

      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('instant_booking');
      final response = await supabase
          .from('rides')
          .insert(fallbackPayload)
          .select('id')
          .single();
      return response['id'].toString();
    }
  }

  /// Searches available rides, ordered by departure.
  ///
  /// A selected origin and date enable the PostGIS pre-filter. Otherwise the
  /// existing text search remains available. This does not compute road detours.
  Future<List<Ride>> searchRides({
    DateTime? afterDate,
    String? startLocation,
    String? endLocation,
    double? maxPrice,
    int? minSeats,
    double? originLatitude,
    double? originLongitude,
    double radiusMeters = 10000,
  }) async {
    try {
      if ((originLatitude == null) != (originLongitude == null)) {
        throw ArgumentError('Both origin coordinates must be supplied.');
      }
      if (originLatitude != null &&
          (!originLatitude.isFinite ||
              originLatitude < -90 ||
              originLatitude > 90 ||
              !originLongitude!.isFinite ||
              originLongitude < -180 ||
              originLongitude > 180)) {
        throw ArgumentError('Invalid origin coordinates.');
      }
      if (maxPrice != null && (!maxPrice.isFinite || maxPrice < 0)) {
        throw ArgumentError('Invalid maximum price.');
      }
      if (minSeats != null && minSeats < 1) {
        throw ArgumentError('At least one seat must be requested.');
      }
      if (!radiusMeters.isFinite ||
          radiusMeters <= 0 ||
          radiusMeters > 100000) {
        throw ArgumentError(
          'Radius must be greater than 0 and at most 100 km.',
        );
      }

      final useSpatialSearch = originLatitude != null && afterDate != null;
      debugPrint('searchRides mode: ${useSpatialSearch ? 'postgis' : 'text'}');

      if (useSpatialSearch) {
        return await _searchSpatialRides(
          date: afterDate,
          latitude: originLatitude,
          longitude: originLongitude!,
          radiusMeters: radiusMeters,
          endLocation: endLocation,
          maxPrice: maxPrice,
          minSeats: minSeats ?? 1,
        );
      }

      var query = supabase.from('rides').select('''
            id,
            driver_id,
            origin_city,
            origin_address,
            destination_city,
            destination_address,
            origin_lat,
            origin_lng,
            destination_lat,
            destination_lng,
            departure_time,
            available_seats,
            price_per_seat,
            vehicle_type,
            vehicle_plate,
            vehicle_make,
            vehicle_model,
            vehicle_color,
            status,
            notes,
            pets_allowed,
            luggage_policy,
            instant_booking,
            vehicle_year,
            profiles!driver_id(
              id, first_name, last_name, rating, avatar_url, bio,
              email_verified, phone_verified, govt_id_status, verified_rides
            )
          ''');

      // Development and release builds must obey the same availability rules.
      query = query.eq('status', 'available');
      query = query.gt('available_seats', 0);

      if (afterDate != null) {
        final dayStart = DateTime(
          afterDate.year,
          afterDate.month,
          afterDate.day,
        );
        // Calendar arithmetic also handles local days of 23 or 25 hours.
        final dayEnd = DateTime(
          afterDate.year,
          afterDate.month,
          afterDate.day + 1,
        );
        query = query
            .gte('departure_time', dayStart.toUtc().toIso8601String())
            .lt('departure_time', dayEnd.toUtc().toIso8601String());
      }
      if (startLocation != null && startLocation.isNotEmpty) {
        final originTerm = _sanitizeSearchTerm(startLocation);
        if (originTerm.isEmpty) {
          developer.log(
            'origin filter skipped after sanitization',
            name: 'DatabaseService.searchRides',
          );
        } else {
          developer.log(
            'origin filter: city/address/legacy ilike %$originTerm%',
            name: 'DatabaseService.searchRides',
          );
          query = query.or(
            'origin_city.ilike.%$originTerm%,origin_address.ilike.%$originTerm%',
          );
        }
      }
      if (endLocation != null && endLocation.isNotEmpty) {
        final destinationTerm = _sanitizeSearchTerm(endLocation);
        if (destinationTerm.isEmpty) {
          developer.log(
            'destination filter skipped after sanitization',
            name: 'DatabaseService.searchRides',
          );
        } else {
          developer.log(
            'destination filter: city/address/legacy ilike %$destinationTerm%',
            name: 'DatabaseService.searchRides',
          );
          query = query.or(
            'destination_city.ilike.%$destinationTerm%,destination_address.ilike.%$destinationTerm%',
          );
        }
      }
      if (maxPrice != null) {
        query = query.lte('price_per_seat', maxPrice);
      }
      if (minSeats != null && minSeats > 1) {
        query = query.gte('available_seats', minSeats);
      }

      final response = await query.order('departure_time', ascending: true);
      developer.log(
        'searchRides response count: ${response.length}',
        name: 'DatabaseService.searchRides',
      );
      debugPrint('searchRides response count: ${response.length}');
      return response
          .map((row) => Ride.fromJson(row))
          .where((ride) => ride.id.isNotEmpty)
          .toList();
    } catch (e) {
      developer.log(
        'searchRides error: $e',
        name: 'DatabaseService.searchRides',
        error: e,
        stackTrace: StackTrace.current,
      );
      debugPrint('Error searching rides: $e');
      rethrow;
    }
  }

  Future<List<Ride>> _searchSpatialRides({
    required DateTime date,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required int minSeats,
    String? endLocation,
    double? maxPrice,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day + 1);
    final response = await supabase
        .rpc<List<Map<String, dynamic>>>(
          'search_ride_candidates',
          params: {
            'p_origin_lat': latitude,
            'p_origin_lng': longitude,
            'p_departure_from': dayStart.toUtc().toIso8601String(),
            'p_departure_until': dayEnd.toUtc().toIso8601String(),
            'p_radius_m': radiusMeters,
            'p_min_seats': minSeats,
            'p_max_price': maxPrice,
            // One extra row detects truncation before the destination filter.
            'p_limit': _spatialCandidateLimit + 1,
          },
        )
        .select('''
          id, driver_id,
          origin_city, origin_address, destination_city, destination_address,
          origin_lat, origin_lng, destination_lat, destination_lng,
          departure_time, available_seats, price_per_seat,
          vehicle_type, vehicle_plate, vehicle_make, vehicle_model,
          vehicle_color, vehicle_year, status, notes,
          pets_allowed, luggage_policy, instant_booking,
          profiles!driver_id(
            id, first_name, last_name, rating, avatar_url, bio,
            email_verified, phone_verified, govt_id_status, verified_rides
          )
        ''');

    if (response.length > _spatialCandidateLimit) {
      // The current RPC has no destination argument or pagination cursor.
      // Never present a truncated shortlist as an exhaustive search result.
      throw StateError(
        'More than 100 nearby offers. Narrow the date, price or seat filters.',
      );
    }

    final destinationTerm = endLocation == null
        ? ''
        : _sanitizeSearchTerm(endLocation).toLowerCase();
    final rides = response
        .map((row) => Ride.fromJson(row))
        .where((ride) => ride.id.isNotEmpty)
        .where(
          (ride) =>
              destinationTerm.isEmpty ||
              ride.destinationCity.toLowerCase().contains(destinationTerm) ||
              ride.destinationAddress.toLowerCase().contains(destinationTerm),
        )
        .toList();
    // Keep the existing UI order. OSRM and hybrid ranking are separate work.
    rides.sort((a, b) {
      final byDeparture = a.departureTime.compareTo(b.departureTime);
      return byDeparture != 0 ? byDeparture : a.id.compareTo(b.id);
    });
    debugPrint(
      'searchRides postgis: ${response.length} candidates, ${rides.length} results',
    );
    return rides;
  }

  static String _sanitizeSearchTerm(String value) {
    final primaryTerm = value.split(',').first.trim();
    return primaryTerm.replaceAll(RegExp(r'''[(),"'`.%\\]'''), '').trim();
  }

  /// Fetches a single ride by id (with driver preview).
  Future<Ride?> getRide(String rideId) async {
    try {
      final response = await supabase
          .from('rides')
          .select('''
            id,
            driver_id,
            origin_city,
            origin_address,
            destination_city,
            destination_address,
            origin_lat,
            origin_lng,
            destination_lat,
            destination_lng,
            departure_time,
            available_seats,
            price_per_seat,
            vehicle_type,
            vehicle_plate,
            vehicle_make,
            vehicle_model,
            vehicle_color,
            status,
            notes,
            pets_allowed,
            luggage_policy,
            instant_booking,
            vehicle_year,
            profiles!driver_id(
              id, first_name, last_name, rating, avatar_url, bio, phone,
              email_verified, phone_verified, govt_id_status, verified_rides
            )
          ''')
          .eq('id', rideId)
          .maybeSingle();
      if (response == null) return null;
      final ride = Ride.fromJson(response);
      return ride.id.isEmpty ? null : ride;
    } catch (e) {
      debugPrint('Error fetching ride: $e');
      return null;
    }
  }

  /// The driver's rides, oldest departure first.
  Future<List<Ride>> getMyRides(String driverId) async {
    try {
      final response = await supabase
          .from('rides')
          .select()
          .eq('driver_id', driverId)
          .order('departure_time', ascending: true);
      return response
          .map((row) => Ride.fromJson(row))
          .where((ride) => ride.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching driver rides: $e');
      return [];
    }
  }

  /// Updates a ride's status (e.g. cancel, complete).
  Future<void> updateRideStatus(String rideId, String status) async {
    await supabase.from('rides').update({'status': status}).eq('id', rideId);
  }

  Future<void> completeRide(String rideId) async {
    await supabase.rpc('complete_ride', params: {'p_ride_id': rideId});
  }

  Future<void> cancelBookingAsDriver(String bookingId) async {
    await supabase.rpc(
      'cancel_booking_by_driver',
      params: {'p_booking_id': bookingId},
    );
  }

  // ============================================================================
  // BOOKINGS
  // ============================================================================

  /// Books [seatsBooked] seats on a ride.
  ///
  /// Seat availability is validated by the server (`prevent_overbooking`
  /// trigger); the client does not touch `available_seats`. On rides with
  /// instant booking the status is `confirmed`; otherwise it is `pending`
  /// until the driver approves it.
  Future<String> createBooking({
    required String rideId,
    required int seatsBooked,
    required double totalPrice,
    bool instantBooking = false,
    String? pickupLocation,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final bookingId = await supabase.rpc(
      'create_booking_request',
      params: {
        'p_ride_id': rideId,
        'p_seats_booked': seatsBooked,
        'p_total_price': totalPrice,
        'p_pickup_location': pickupLocation,
      },
    );
    return bookingId.toString();
  }

  /// The passenger's bookings, newest first, with ride + driver embedded.
  Future<List<Booking>> getMyBookings(String passengerId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select('''
            id,
            ride_id,
            passenger_id,
            seats_booked,
            total_price,
            pickup_location,
            status,
            created_at,
            rides(
              id,
              driver_id,
              origin_city,
              origin_address,
              destination_city,
              destination_address,
              origin_lat,
              origin_lng,
              destination_lat,
              destination_lng,
              departure_time,
              available_seats,
              price_per_seat,
              vehicle_type,
              vehicle_plate,
              vehicle_make,
              vehicle_model,
              vehicle_color,
              status,
              notes,
              pets_allowed,
              luggage_policy,
              instant_booking,
              vehicle_year,
              profiles!driver_id(
                id, first_name, last_name, rating, avatar_url, bio,
                email_verified, phone_verified, govt_id_status, verified_rides
              )
            )
          ''')
          .eq('passenger_id', passengerId)
          .order('created_at', ascending: false);

      return response
          .map((row) => Booking.fromJson(row))
          .where((booking) => booking.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      return [];
    }
  }

  /// Bookings for a ride the user drives, with passenger profiles embedded.
  Future<List<Booking>> getRideBookings(String rideId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select('''
            id,
            ride_id,
            passenger_id,
            seats_booked,
            total_price,
            pickup_location,
            status,
            created_at,
            profiles!passenger_id(
              id, first_name, last_name, phone, avatar_url, rating,
              email_verified, phone_verified, govt_id_status, verified_rides
            )
          ''')
          .eq('ride_id', rideId)
          .order('created_at', ascending: false);

      return response
          .map((row) => Booking.fromJson(row))
          .where((booking) => booking.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching ride bookings: $e');
      return [];
    }
  }

  Future<Booking?> getConversationBooking({
    required String rideId,
    required String passengerId,
  }) async {
    final response = await supabase
        .from('bookings')
        .select('''
          id, ride_id, passenger_id, seats_booked, total_price,
          pickup_location, status, created_at,
          profiles!passenger_id(id, first_name, last_name, rating, avatar_url)
        ''')
        .eq('ride_id', rideId)
        .eq('passenger_id', passengerId)
        .maybeSingle();
    return response == null ? null : Booking.fromJson(response);
  }

  /// Updates a booking's status (confirmed/cancelled/completed).
  ///
  /// Cancelling restores the ride's seats automatically via the database
  /// `restore_booking_seats_on_cancel` trigger.
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId);
  }

  Future<void> approveBooking(String bookingId) async {
    await supabase.rpc('approve_booking', params: {'p_booking_id': bookingId});
  }

  Future<void> rejectBooking(String bookingId) async {
    await supabase.rpc('reject_booking', params: {'p_booking_id': bookingId});
  }

  /// Cancels a booking (passenger or driver action).
  Future<void> cancelBooking(String bookingId) async {
    await supabase.rpc('cancel_booking', params: {'p_booking_id': bookingId});
  }

  // ============================================================================
  // REVIEWS
  // ============================================================================

  /// Reviews written about [driverId], newest first.
  Future<List<Review>> getReviewsForDriver(String driverId) async {
    try {
      final response = await supabase
          .from('reviews')
          .select()
          .eq('reviewee_id', driverId)
          .order('created_at', ascending: false);
      return response
          .map((row) => Review.fromJson(row))
          .where((review) => review.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  /// Whether the current user has already reviewed [rideId].
  Future<bool> hasReviewedRide(String rideId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return true;
      final response = await supabase
          .from('reviews')
          .select('id')
          .eq('ride_id', rideId)
          .eq('reviewer_id', user.id)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking review: $e');
      return true; // Failing closed avoids duplicate review prompts.
    }
  }

  /// Creates a review; the driver's rating is recomputed server-side.
  Future<void> createReview({
    required String rideId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await supabase.from('reviews').insert({
      'ride_id': rideId,
      'reviewer_id': user.id,
      'reviewee_id': revieweeId,
      'rating': rating,
      'comment': comment,
    });
  }

  // ============================================================================
  // REAL-TIME LISTENERS
  // ============================================================================

  /// Real-time stream of available rides (seat counts update live).
  Stream<List<Ride>> watchAvailableRides() {
    return supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .map(
          (records) => records
              .map((row) => Ride.fromJson(Map<String, dynamic>.from(row)))
              .where((ride) => ride.availableSeats > 0)
              .where((ride) => ride.id.isNotEmpty)
              .toList(),
        );
  }

  /// Real-time stream of a user's bookings (status changes update live).
  Stream<List<Booking>> watchMyBookings(String passengerId) {
    return supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .map(
          (records) => records
              .where((row) => row['passenger_id'] == passengerId)
              .map((row) => Booking.fromJson(row))
              .where((booking) => booking.id.isNotEmpty)
              .toList(),
        );
  }

  // ============================================================================
  // CHAT
  // ============================================================================

  static const String _conversationSelect = '''
    id,
    ride_id,
    passenger_id,
    driver_id,
    last_message,
    last_message_at,
    last_sender_id,
    created_at,
    passenger_last_read_at,
    driver_last_read_at,
    passenger:profiles!passenger_id(
      id, first_name, last_name, rating, avatar_url,
      email_verified, phone_verified, govt_id_status, verified_rides
    ),
    driver:profiles!driver_id(
      id, first_name, last_name, rating, avatar_url,
      email_verified, phone_verified, govt_id_status, verified_rides
    ),
    rides!ride_id(
      origin_city, origin_address, destination_city, destination_address,
      departure_time
    )
  ''';

  /// Finds (or creates) the conversation between [passengerId] and
  /// [driverId] for a ride. Only the two participants may call this.
  /// Returns the conversation id.
  Future<String> getOrCreateConversation({
    required String rideId,
    required String passengerId,
    required String driverId,
  }) async {
    if (rideId.trim().isEmpty ||
        passengerId.trim().isEmpty ||
        driverId.trim().isEmpty) {
      throw ArgumentError(
        'Conversation participant and ride IDs are required.',
      );
    }
    if (passengerId == driverId) {
      throw ArgumentError(
        'A conversation requires two different participants.',
      );
    }

    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    if (user.id != passengerId && user.id != driverId) {
      throw Exception('Not part of this trip');
    }

    Future<String?> findExistingId() async {
      final existing = await supabase
          .from('conversations')
          .select('id')
          .eq('ride_id', rideId)
          .eq('passenger_id', passengerId)
          .maybeSingle();
      final id = existing?['id']?.toString();
      return id == null || id.isEmpty ? null : id;
    }

    final existingId = await findExistingId();
    if (existingId != null) return existingId;

    try {
      final created = await supabase
          .from('conversations')
          .insert({
            'ride_id': rideId,
            'passenger_id': passengerId,
            'driver_id': driverId,
          })
          .select('id')
          .single();
      final id = created['id']?.toString();
      if (id == null || id.isEmpty) {
        throw StateError('Supabase created a conversation without an ID.');
      }
      return id;
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;

      // Another request may have created the unique ride/passenger row first.
      final racedId = await findExistingId();
      if (racedId != null) return racedId;
      rethrow;
    }
  }

  /// All conversations for [userId], newest activity first.
  Future<List<Conversation>> getConversations(String userId) async {
    try {
      final response = await supabase
          .from('conversations')
          .select(_conversationSelect)
          .or('passenger_id.eq.$userId,driver_id.eq.$userId')
          .order('last_message_at', ascending: false);
      return response
          .map((row) => Conversation.fromJson(row))
          .where((conversation) => conversation.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  /// Messages of a conversation, oldest first.
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final response = await supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return response
          .map((row) => ChatMessage.fromJson(row))
          .where((message) => message.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  /// Sends a message in a conversation.
  Future<void> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final text = message.trim();
    if (text.isEmpty) return;

    await supabase.from('chat_messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'message': text,
    });
  }

  /// Marks all incoming messages as read for [userId].
  Future<void> markConversationRead(
    String conversationId,
    String userId,
  ) async {
    final participant = await _conversationParticipant(conversationId, userId);
    if (participant == null) return;
    final column = participant == 'passenger'
        ? 'passenger_last_read_at'
        : 'driver_last_read_at';
    await supabase
        .from('conversations')
        .update({column: DateTime.now().toIso8601String()})
        .eq('id', conversationId);
  }

  Future<String?> _conversationParticipant(
    String conversationId,
    String userId,
  ) async {
    final row = await supabase
        .from('conversations')
        .select('passenger_id, driver_id')
        .eq('id', conversationId)
        .maybeSingle();
    if (row == null) return null;
    if (row['passenger_id']?.toString() == userId) return 'passenger';
    if (row['driver_id']?.toString() == userId) return 'driver';
    return null;
  }

  /// Real-time stream of a conversation's messages.
  Stream<List<ChatMessage>> watchConversation(String conversationId) {
    return supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .map(
          (records) => records
              .map((row) => ChatMessage.fromJson(row))
              .where((message) => message.id.isNotEmpty)
              .toList(),
        );
  }

  /// Real-time events on conversations involving [userId] (created or updated).
  RealtimeChannel watchConversationEvents(
    String userId, {
    required void Function(PostgresChangePayload payload) onEvent,
  }) {
    final channel = supabase
        .channel('conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'passenger_id',
            value: userId,
          ),
          callback: onEvent,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: userId,
          ),
          callback: onEvent,
        );
    return channel.subscribe();
  }
}

class MatchFeedbackDraft {
  const MatchFeedbackDraft({
    required this.rideId,
    required this.detourMinutes,
    required this.timeGapMinutes,
    required this.preferenceScore,
    required this.price,
    required this.ruleScore,
  });

  final String rideId;
  final double detourMinutes;
  final int timeGapMinutes;
  final double preferenceScore;
  final double price;
  final double ruleScore;
}
