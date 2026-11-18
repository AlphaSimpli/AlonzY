import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SafetyCoordinate {
  const SafetyCoordinate(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

abstract interface class SafetyTrackingBackend {
  Future<String> createShare({
    required String bookingId,
    required String token,
    required DateTime consentGivenAt,
    required DateTime expiresAt,
  });

  Future<void> addPosition({
    required String rideId,
    required SafetyCoordinate position,
  });

  Future<void> deactivateShare(String shareId);
}

typedef SafetyPositionProvider = Future<SafetyCoordinate> Function();
typedef SafetyShareHandler = Future<void> Function(Uri shareUrl);

/// Foreground-only live location sharing, started only after explicit consent.
class SafetyTrackingService with WidgetsBindingObserver {
  SafetyTrackingService({
    SafetyTrackingBackend? backend,
    SafetyPositionProvider? positionProvider,
    SafetyShareHandler? shareHandler,
    String? trackerBaseUrl,
    this.interval = const Duration(seconds: 12),
    DateTime Function()? clock,
    Random? random,
  }) : _backend = backend ?? _SupabaseSafetyTrackingBackend(),
       _positionProvider = positionProvider ?? _currentDevicePosition,
       _shareHandler = shareHandler ?? _share,
       _trackerBaseUrl =
           trackerBaseUrl ??
           (dotenv.isInitialized ? dotenv.env['SAFETY_TRACKER_URL'] ?? '' : ''),
       _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure() {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval');
    }
  }

  final SafetyTrackingBackend _backend;
  final SafetyPositionProvider _positionProvider;
  final SafetyShareHandler _shareHandler;
  final String _trackerBaseUrl;
  final DateTime Function() _clock;
  final Random _random;
  final Duration interval;

  Timer? _timer;
  String? _shareId;
  String? _rideId;
  bool _uploading = false;
  bool _stopping = false;

  bool get isSharing => _shareId != null;

  Future<void> startSharing({
    required String bookingId,
    required String rideId,
    required bool consentGiven,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    if (!consentGiven) {
      throw StateError('Explicit consent is required before sharing location.');
    }
    if (bookingId.trim().isEmpty || rideId.trim().isEmpty) {
      throw ArgumentError('A booking and ride are required.');
    }
    if (isSharing) throw StateError('Location sharing is already active.');
    final trackerBase = Uri.tryParse(_trackerBaseUrl);
    if (trackerBase == null ||
        trackerBase.scheme != 'https' ||
        trackerBase.host.isEmpty ||
        trackerBase.hasQuery ||
        trackerBase.hasFragment) {
      throw StateError(
        'Configure SAFETY_TRACKER_URL as an HTTPS tracker page URL.',
      );
    }

    final token = _newToken();
    final consentGivenAt = _clock().toUtc();
    final expiresAt = consentGivenAt.add(const Duration(hours: 3));
    final shareId = await _backend.createShare(
      bookingId: bookingId,
      token: token,
      consentGivenAt: consentGivenAt,
      expiresAt: expiresAt,
    );
    _shareId = shareId;
    _rideId = rideId;
    WidgetsBinding.instance.addObserver(this);

    try {
      await _publishPosition();
      _startTimer(onError);
      final shareUrl = trackerBase.replace(
        queryParameters: {...trackerBase.queryParameters, 'token': token},
      );
      await _shareHandler(shareUrl);
    } catch (error, stackTrace) {
      _timer?.cancel();
      _timer = null;
      WidgetsBinding.instance.removeObserver(this);
      _shareId = null;
      _rideId = null;
      try {
        await _backend.deactivateShare(shareId);
      } catch (cleanupError, cleanupStack) {
        Error.throwWithStackTrace(cleanupError, cleanupStack);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> stopSharing() async {
    final shareId = _shareId;
    if (shareId == null || _stopping) return;
    _stopping = true;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    while (_uploading) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    try {
      await _backend.deactivateShare(shareId);
    } finally {
      _shareId = null;
      _rideId = null;
      _stopping = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isSharing) return;
    if (state == AppLifecycleState.resumed) {
      _startTimer(null);
      unawaited(_publishPosition(throwOnError: false));
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer(
    void Function(Object error, StackTrace stackTrace)? onError,
  ) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      unawaited(_publishPosition(onError: onError, throwOnError: false));
    });
  }

  Future<void> _publishPosition({
    void Function(Object error, StackTrace stackTrace)? onError,
    bool throwOnError = true,
  }) async {
    final rideId = _rideId;
    if (rideId == null || _uploading || _stopping) return;
    _uploading = true;
    try {
      final position = await _positionProvider();
      if (!position.latitude.isFinite ||
          !position.longitude.isFinite ||
          position.latitude.abs() > 90 ||
          position.longitude.abs() > 180) {
        throw StateError('The device returned invalid GPS coordinates.');
      }
      await _backend.addPosition(rideId: rideId, position: position);
    } catch (error, stackTrace) {
      debugPrint('Safety location update failed (${error.runtimeType}).');
      onError?.call(error, stackTrace);
      if (throwOnError) rethrow;
    } finally {
      _uploading = false;
    }
  }

  String _newToken() => base64Url
      .encode(List<int>.generate(32, (_) => _random.nextInt(256)))
      .replaceAll('=', '');

  static Future<SafetyCoordinate> _currentDevicePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw StateError('Foreground location permission is required.');
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return SafetyCoordinate(position.latitude, position.longitude);
  }

  static Future<void> _share(Uri shareUrl) async {
    await SharePlus.instance.share(ShareParams(uri: shareUrl));
  }
}

class _SupabaseSafetyTrackingBackend implements SafetyTrackingBackend {
  _SupabaseSafetyTrackingBackend({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<String> createShare({
    required String bookingId,
    required String token,
    required DateTime consentGivenAt,
    required DateTime expiresAt,
  }) async {
    final row = await _client
        .from('safety_shares')
        .insert({
          'booking_id': bookingId,
          'token': token,
          'is_active': true,
          'consent_given_at': consentGivenAt.toIso8601String(),
          'expires_at': expiresAt.toIso8601String(),
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  @override
  Future<void> addPosition({
    required String rideId,
    required SafetyCoordinate position,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before publishing a safety position.');
    }
    await _client.from('ride_positions').insert({
      'ride_id': rideId,
      'user_id': userId,
      'lat': position.latitude,
      'lng': position.longitude,
    });
  }

  @override
  Future<void> deactivateShare(String shareId) async {
    await _client
        .from('safety_shares')
        .update({'is_active': false})
        .eq('id', shareId);
  }
}
