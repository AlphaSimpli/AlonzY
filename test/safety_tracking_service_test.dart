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
    required String token,
    required DateTime consentGivenAt,
    required DateTime expiresAt,
  }) async {
    this.token = token;
    this.consentGivenAt = consentGivenAt;
    this.expiresAt = expiresAt;
    events.add('create:$bookingId');
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
