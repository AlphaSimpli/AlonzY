import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supabase_flutter_app/maps/map_types.dart';
import 'package:supabase_flutter_app/models/app_user.dart';
import 'package:supabase_flutter_app/models/booking.dart';
import 'package:supabase_flutter_app/models/chat_message.dart';
import 'package:supabase_flutter_app/models/conversation.dart';
import 'package:supabase_flutter_app/models/review.dart';
import 'package:supabase_flutter_app/models/ride.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';
import 'package:supabase_flutter_app/widgets/auth_layout.dart';

void main() {
  group('MapLocation', () {
    test('stores coordinates', () {
      const location = MapLocation(40.7128, -74.0060);
      expect(location.latitude, 40.7128);
      expect(location.longitude, -74.0060);
    });

    test('value equality works', () {
      const a = MapLocation(1.0, 2.0);
      const b = MapLocation(1.0, 2.0);
      const c = MapLocation(1.0, 3.0);
      expect(a, b);
      expect(a == c, isFalse);
    });

    test('serializes to json', () {
      const location = MapLocation(37.7749, -122.4194);
      expect(location.toJson(), {
        'latitude': 37.7749,
        'longitude': -122.4194,
      });
    });
  });

  group('MapViewConfig', () {
    test('uses sensible defaults', () {
      const config = MapViewConfig();
      expect(config.initialCenter.latitude, 37.7749);
      expect(config.initialZoom, 13);
      expect(config.showUserLocation, isTrue);
      expect(config.trackCameraPosition, isFalse);
    });

    test('copyWith overrides only provided fields', () {
      const config = MapViewConfig(initialZoom: 10);
      final updated = config.copyWith(initialZoom: 15, trackCameraPosition: true);
      expect(updated.initialZoom, 15);
      expect(updated.trackCameraPosition, isTrue);
      expect(updated.initialCenter, config.initialCenter);
    });
  });

  group('AppTheme', () {
    test('is Material 3 with the brand primary colour', () {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
    });
  });

  testWidgets('AuthLayout renders title, subtitle and children',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AuthLayout(
          title: 'Welcome back',
          subtitle: 'Sign in to continue.',
          showBackButton: false,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue.'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  group('AppUser.fromJson', () {
    test('parses a normal row', () {
      final user = AppUser.fromJson({
        'id': 'u1',
        'email': 'a@b.c',
        'first_name': 'Alice',
        'last_name': 'Smith',
        'phone': '+15145550123',
        'rating': 4.8,
        'bio': 'Hi',
        'contact_preference': 'phone',
        'email_verified': true,
        'phone_verified': true,
        'govt_id_status': 'verified',
        'verified_rides': 12,
        'vehicle_make': 'Toyota',
        'vehicle_model': 'Corolla',
        'vehicle_color': 'White',
        'vehicle_plate': 'ABC 123',
        'vehicle_year': 2022,
      });
      expect(user.id, 'u1');
      expect(user.displayName, 'Alice Smith');
      expect(user.initials, 'AS');
      expect(user.rating, 4.8);
      expect(user.contactPreference, 'phone');
      expect(user.vehicleMake, 'Toyota');
      expect(user.emailVerified, isTrue);
      expect(user.phoneVerified, isTrue);
      expect(user.govtIdVerified, isTrue);
      expect(user.verificationLevel, 3);
      expect(user.verifiedRides, 12);
      expect(user.vehicleYear, 2022);
    });

    test('parses a dynamic-keyed map without throwing', () {
      final raw = <dynamic, dynamic>{
        'id': 'u2',
        'first_name': 'Bob',
        'rating': 5,
      };
      final user = AppUser.fromJson(raw.cast<String, dynamic>());
      expect(user.id, 'u2');
      expect(user.displayName, 'Bob');
      expect(user.rating, 5.0);
    });

    test('is resilient to missing fields', () {
      final user = AppUser.fromJson(const {});
      expect(user.id, '');
      expect(user.displayName, 'Rider');
      expect(user.rating, 5.0);
      expect(user.isDriver, isFalse);
    });

    test('null row becomes a safe empty user', () {
      final user = AppUser.fromJson(null);
      expect(user.id, '');
      expect(user.isPassenger, isTrue);
    });
  });

  group('Ride.fromJson', () {
    test('parses a full ride with nested driver profile', () {
      final ride = Ride.fromJson({
        'id': 'r1',
        'driver_id': 'u1',
        'origin_city': 'Montreal',
        'origin_address': 'Montreal',
        'origin_lat': 45.5019,
        'origin_lng': -73.5674,
        'destination_city': 'Quebec City',
        'destination_address': 'Quebec City',
        'destination_lat': 46.8139,
        'destination_lng': -71.2080,
        'departure_time': '2026-09-01T08:30:00',
        'available_seats': 3,
        'price_per_seat': 25.5,
        'vehicle_type': 'suv',
        'vehicle_plate': 'XYZ 999',
        'vehicle_year': 2021,
        'instant_booking': true,
        'pets_allowed': true,
        'luggage_policy': 'large',
        'status': 'available',
        'profiles': {
          'first_name': 'Alice',
          'last_name': 'Smith',
          'rating': 4.9,
        },
      });

      expect(ride.id, 'r1');
      expect(ride.originAddress, 'Montreal');
      expect(ride.start.latitude, 45.5019);
      expect(ride.pricePerSeat, 25.5);
      expect(ride.availableSeats, 3);
      expect(ride.petsAllowed, isTrue);
      expect(ride.luggagePolicy, 'large');
      expect(ride.instantBooking, isTrue);
      expect(ride.vehicleYear, 2021);
      expect(ride.driver, isNotNull);
      expect(ride.driver!.displayName, 'Alice Smith');
      expect(ride.driver!.rating, 4.9);
      expect(ride.vehicleSummary, contains('XYZ 999'));
      expect(ride.vehicleSummary, contains('(2021)'));
    });

    test('nested profile is a dynamic-keyed map and still parses', () {
      final rawProfiles = <dynamic, dynamic>{
        'first_name': 'Carol',
        'rating': 4.2,
      };
      final rawRide = <dynamic, dynamic>{
        'id': 'r2',
        'driver_id': 'u9',
        'start_location': 'A',
        'end_location': 'B',
        'start_lat': 1.0,
        'start_lng': 2.0,
        'end_lat': 3.0,
        'end_lng': 4.0,
        'departure_time': '2026-10-01T10:00:00',
        'available_seats': 2,
        'price_per_seat': 10,
        'vehicle_type': 'sedan',
        'profiles': rawProfiles,
      };

      final ride = Ride.fromJson(rawRide.cast<String, dynamic>());
      expect(ride.driver!.displayName, 'Carol');
      expect(ride.driver!.rating, 4.2);
      expect(ride.pricePerSeat, 10.0);
    });

    test('missing or malformed values degrade safely', () {
      final ride = Ride.fromJson(const {});
      expect(ride.id, '');
      expect(ride.pricePerSeat, 0);
      expect(ride.availableSeats, 0);
      expect(ride.driver, isNull);
    });
  });

  group('Booking.fromJson', () {
    test('parses embedded ride and passenger', () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'ride_id': 'r1',
        'passenger_id': 'p1',
        'seats_booked': 2,
        'total_price': 51.0,
        'status': 'confirmed',
        'created_at': '2026-08-01T12:00:00',
        'rides': {
          'id': 'r1',
          'driver_id': 'u1',
          'start_location': 'A',
          'end_location': 'B',
          'start_lat': 1.0,
          'start_lng': 2.0,
          'end_lat': 3.0,
          'end_lng': 4.0,
          'departure_time': '2026-09-01T08:30:00',
          'available_seats': 3,
          'price_per_seat': 25.5,
          'vehicle_type': 'sedan',
          'profiles': {'first_name': 'Alice', 'rating': 4.9},
        },
        'profiles': {'first_name': 'Bob'},
      });

      expect(booking.id, 'b1');
      expect(booking.seatsBooked, 2);
      expect(booking.totalPrice, 51.0);
      expect(booking.ride, isNotNull);
      expect(booking.ride!.driver!.displayName, 'Alice');
      expect(booking.passenger!.displayName, 'Bob');
    });

    test('is resilient to missing fields', () {
      final booking = Booking.fromJson(const {});
      expect(booking.id, '');
      expect(booking.seatsBooked, 0);
      expect(booking.totalPrice, 0);
      expect(booking.ride, isNull);
    });
  });

  group('Review.fromJson', () {
    test('parses a review row', () {
      final review = Review.fromJson({
        'id': 'rv1',
        'ride_id': 'r1',
        'reviewer_id': 'p1',
        'reviewee_id': 'u1',
        'rating': 5,
        'comment': 'Great trip',
        'created_at': '2026-08-01T12:00:00',
      });
      expect(review.rating, 5);
      expect(review.comment, 'Great trip');
      expect(review.revieweeId, 'u1');
    });

    test('is resilient to missing fields', () {
      final review = Review.fromJson(const {});
      expect(review.rating, 5);
      expect(review.comment, isNull);
    });
  });

  group('Conversation.fromJson', () {
    test('parses embedded passenger, driver and ride', () {
      final conversation = Conversation.fromJson({
        'id': 'c1',
        'ride_id': 'r1',
        'passenger_id': 'p1',
        'driver_id': 'd1',
        'last_message': 'See you at 8!',
        'last_message_at': '2026-08-15T09:00:00',
        'last_sender_id': 'd1',
        'created_at': '2026-08-14T10:00:00',
        'passenger_last_read_at': '2026-08-15T08:00:00',
        'driver_last_read_at': null,
        'passenger': {'first_name': 'Bob'},
        'driver': {'first_name': 'Alice', 'email_verified': true},
        'rides': {
          'origin_city': 'A',
          'origin_address': 'A',
          'origin_lat': 1,
          'origin_lng': 2,
          'destination_city': 'B',
          'destination_address': 'B',
          'destination_lat': 3,
          'destination_lng': 4,
        },
      });

      expect(conversation.id, 'c1');
      expect(conversation.passenger!.displayName, 'Bob');
      expect(conversation.driver!.displayName, 'Alice');
      expect(conversation.ride!.originAddress, 'A');
      expect(conversation.otherParty('d1')!.displayName, 'Bob');
      expect(conversation.otherParty('p1')!.displayName, 'Alice');
      expect(conversation.hasUnread('p1'), isTrue);
      expect(conversation.hasUnread('d1'), isFalse);
    });

    test('hasUnread treats own message as read', () {
      final conversation = Conversation.fromJson({
        'id': 'c2',
        'ride_id': 'r1',
        'passenger_id': 'p1',
        'driver_id': 'd1',
        'last_message_at': '2026-08-15T09:00:00',
        'last_sender_id': 'p1',
        'created_at': '2026-08-14T10:00:00',
      });
      expect(conversation.hasUnread('p1'), isFalse);
      expect(conversation.hasUnread('d1'), isTrue);
    });

    test('is resilient to missing fields', () {
      final conversation = Conversation.fromJson(const {});
      expect(conversation.id, '');
      expect(conversation.passenger, isNull);
      expect(conversation.driver, isNull);
      expect(conversation.ride, isNull);
    });
  });

  group('ChatMessage.fromJson', () {
    test('parses a message row', () {
      final message = ChatMessage.fromJson({
        'id': 'm1',
        'conversation_id': 'c1',
        'sender_id': 'd1',
        'message': 'Hello!',
        'created_at': '2026-08-15T09:00:00',
      });
      expect(message.id, 'm1');
      expect(message.conversationId, 'c1');
      expect(message.senderId, 'd1');
      expect(message.message, 'Hello!');
      expect(message.createdAt.year, 2026);
    });

    test('is resilient to missing fields', () {
      final message = ChatMessage.fromJson(const {});
      expect(message.id, '');
      expect(message.message, '');
    });
  });
}