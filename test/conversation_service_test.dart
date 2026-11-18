import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/services/database_service.dart';

void main() {
  const passengerId = 'passenger-test';
  const driverId = 'driver-test';
  const rideId = 'ride-test';
  const conversationId = 'conversation-test';

  late SupabaseClient client;
  late List<http.Request> requests;
  late int conversationReads;

  Map<String, dynamic> session() {
    final claims = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'sub': passengerId,
              'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            }),
          ),
        )
        .replaceAll('=', '');
    return {
      'access_token': 'eyJhbGciOiJIUzI1NiJ9.$claims.test-signature',
      'refresh_token': 'simulated-refresh-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': passengerId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'passenger@example.com',
        'created_at': '2026-11-17T12:00:00Z',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
      },
    };
  }

  setUp(() async {
    requests = [];
    conversationReads = 0;
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/token')) {
          return http.Response(
            jsonEncode(session()),
            200,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path.endsWith('/conversations') &&
            request.method == 'GET') {
          conversationReads++;
          return http.Response(
            jsonEncode(
              conversationReads == 1
                  ? []
                  : [
                      {'id': conversationId},
                    ],
            ),
            200,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path.endsWith('/conversations') &&
            request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'code': '23505',
              'message': 'duplicate key value violates unique constraint',
            }),
            409,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path.endsWith('/bookings') && request.method == 'GET') {
          final select = request.url.queryParameters['select'] ?? '';
          final includesRideId = RegExp(
            r'rides\(\s*id\s*,\s*driver_id',
          ).hasMatch(select);
          return http.Response(
            jsonEncode([
              {
                'id': 'booking-test',
                'ride_id': rideId,
                'passenger_id': passengerId,
                'seats_booked': 1,
                'total_price': 10,
                'status': 'confirmed',
                'created_at': '2026-11-17T12:00:00Z',
                'rides': {
                  if (includesRideId) 'id': rideId,
                  'driver_id': driverId,
                  'origin_city': 'Ottawa',
                  'origin_address': 'Ottawa centre',
                  'destination_city': 'Gatineau',
                  'destination_address': 'Gatineau centre',
                  'origin_lat': 45.42,
                  'origin_lng': -75.69,
                  'destination_lat': 45.48,
                  'destination_lng': -75.7,
                  'departure_time': '2026-11-20T18:30:00Z',
                  'available_seats': 2,
                  'price_per_seat': 10,
                  'vehicle_type': 'sedan',
                },
              },
            ]),
            200,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        throw StateError('Unexpected HTTP request: ${request.url}');
      }),
    );
    await client.auth.signInWithPassword(
      email: 'passenger@example.com',
      password: 'simulated-password',
    );
  });

  tearDown(() async {
    await client.dispose();
  });

  test(
    'recovers the existing conversation after a concurrent insert',
    () async {
      final service = DatabaseService(client: client);

      final result = await service.getOrCreateConversation(
        rideId: rideId,
        passengerId: passengerId,
        driverId: driverId,
      );

      expect(result, conversationId);
      expect(conversationReads, 2);
      expect(
        requests.where(
          (request) =>
              request.url.path.endsWith('/conversations') &&
              request.method == 'POST',
        ),
        hasLength(1),
      );
    },
  );

  test('loads the nested ride ID required to open its conversation', () async {
    final service = DatabaseService(client: client);

    final bookings = await service.getMyBookings(passengerId);

    expect(bookings, hasLength(1));
    expect(bookings.single.ride?.id, rideId);
    final request = requests.singleWhere(
      (request) => request.url.path.endsWith('/bookings'),
    );
    expect(
      request.url.queryParameters['select'],
      matches(RegExp(r'rides\(\s*id\s*,\s*driver_id')),
    );
  });
}
