import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/services/safety_tracking_service.dart';

class _FakeSafetyBackend implements SafetyTrackingBackend {
  final List<String> events = [];
  String? token;
  DateTime? consentGivenAt;
  DateTime? expiresAt;

  @override
  Future<String> createShare({
    required String bookingId,
    required String rideId,
    required String token,
    required DateTime consentGivenAt,
    required DateTime expiresAt,
  }) async {
    this.token = token;
    this.consentGivenAt = consentGivenAt;
    this.expiresAt = expiresAt;
    events.add('create:$bookingId:$rideId');
    return 'share-id';
  }

  @override
  Future<void> addPosition({
    required String rideId,
    required SafetyCoordinate position,
  }) async {
    events.add('position:$rideId:${position.latitude}');
  }

  @override
  Future<void> deactivateShare(String shareId) async {
    events.add('deactivate:$shareId');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('allows shares for confirmed bookings before and during a ride', () {
    expect(
      canShareSafetyForRide(
        bookingStatus: 'confirmed',
        rideStatus: 'available',
      ),
      isTrue,
    );
    expect(
      canShareSafetyForRide(
        bookingStatus: 'in_progress',
        rideStatus: 'in_progress',
      ),
      isTrue,
    );
    expect(
      canShareSafetyForRide(bookingStatus: 'pending', rideStatus: 'available'),
      isFalse,
    );
    expect(
      canShareSafetyForRide(
        bookingStatus: 'confirmed',
        rideStatus: 'completed',
      ),
      isFalse,
    );
  });

  test(
    'uses the deployed tracker URL when no override is configured',
    () async {
      final backend = _FakeSafetyBackend();
      final sharedUrls = <Uri>[];
      final service = SafetyTrackingService(
        backend: backend,
        positionProvider: () async => const SafetyCoordinate(45, -73),
        shareHandler: (url) async => sharedUrls.add(url),
      );

      await service.startSharing(
        bookingId: 'booking-1',
        rideId: 'ride-1',
        consentGiven: true,
      );

      expect(
        sharedUrls.single.origin + sharedUrls.single.path,
        defaultSafetyTrackerUrl,
      );
      await service.stopSharing();
    },
  );

  test(
    'returns a public link without opening the system share sheet',
    () async {
      final backend = _FakeSafetyBackend();
      var openedShareSheet = false;
      final service = SafetyTrackingService(
        backend: backend,
        trackerBaseUrl: 'https://example.test/track.html',
        positionProvider: () async => const SafetyCoordinate(45, -73),
        shareHandler: (_) async => openedShareSheet = true,
      );

      final link = await service.startSharing(
        bookingId: 'booking-1',
        rideId: 'ride-1',
        consentGiven: true,
        invokeShareSheet: false,
      );

      expect(link.origin + link.path, 'https://example.test/track.html');
      expect(link.queryParameters['token'], backend.token);
      expect(openedShareSheet, isFalse);
      await service.stopSharing();
    },
  );

  test('requires explicit consent before creating a share token', () async {
    final backend = _FakeSafetyBackend();
    final service = SafetyTrackingService(
      backend: backend,
      trackerBaseUrl: 'https://example.test/track.html',
      positionProvider: () async => const SafetyCoordinate(45, -73),
      shareHandler: (_) async {},
    );
    await expectLater(
      service.startSharing(
        bookingId: 'booking-1',
        rideId: 'ride-1',
        consentGiven: false,
      ),
      throwsStateError,
    );
    expect(backend.events, isEmpty);
    expect(service.isSharing, isFalse);
  });

  test(
    'creates an expiring token, uploads fixes and revokes on stop',
    () async {
      final backend = _FakeSafetyBackend();
      final sharedUrls = <Uri>[];
      var fixes = 0;
      final service = SafetyTrackingService(
        backend: backend,
        trackerBaseUrl: 'https://example.test/track.html',
        interval: const Duration(milliseconds: 15),
        clock: () => DateTime.utc(2026, 11, 20),
        positionProvider: () async {
          fixes++;
          return SafetyCoordinate(45 + fixes / 1000, -73);
        },
        shareHandler: (url) async => sharedUrls.add(url),
      );

      await service.startSharing(
        bookingId: 'booking-1',
        rideId: 'ride-1',
        consentGiven: true,
      );
      expect(service.isSharing, isTrue);
      expect(backend.token, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(backend.consentGivenAt, DateTime.utc(2026, 11, 20));
      expect(backend.expiresAt, DateTime.utc(2026, 11, 20, 3));
      expect(sharedUrls.single.queryParameters['token'], backend.token);
      expect(
        backend.events.where((event) => event.startsWith('position:')),
        isNotEmpty,
      );

      await Future<void>.delayed(const Duration(milliseconds: 40));
      await service.stopSharing();
      expect(service.isSharing, isFalse);
      expect(backend.events.last, 'deactivate:share-id');
      expect(
        backend.events.where((event) => event.startsWith('position:')).length,
        greaterThan(1),
      );
    },
  );

  test('a failed share sheet deactivates the newly created token', () async {
    final backend = _FakeSafetyBackend();
    final service = SafetyTrackingService(
      backend: backend,
      trackerBaseUrl: 'https://example.test/track.html',
      positionProvider: () async => const SafetyCoordinate(45, -73),
      shareHandler: (_) async => throw StateError('share failed'),
    );

    await expectLater(
      service.startSharing(
        bookingId: 'booking-1',
        rideId: 'ride-1',
        consentGiven: true,
      ),
      throwsStateError,
    );
    expect(backend.events.last, 'deactivate:share-id');
    expect(service.isSharing, isFalse);
  });
}
