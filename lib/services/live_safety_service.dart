import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_ride_location.dart';

/// Shares a participant's GPS fixes and listens to other participants.
///
/// The service is intended to be started only after a ride has begun. Backend
/// row-level security independently enforces that rule.
class LiveSafetyService {
  LiveSafetyService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  static const String _table = 'ride_live_locations';
  static const Duration _defaultInterval = Duration(seconds: 6);

  final SupabaseClient _supabase;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _publishTimer;
  Position? _latestPosition;
  DateTime? _lastUploadedAt;
  Completer<void>? _publishingCompleter;
  String? _sharingRideId;
  String? _sharingUserId;
  bool _isPublishing = false;
  void Function(Object error, StackTrace stackTrace)? _onSharingError;

  bool get isSharing => _sharingRideId != null;

  /// Starts sharing the signed-in user's location until [stopSharing] is
  /// called. Android displays an ongoing notification while tracking.
  Future<void> startSharing({
    required String rideId,
    Duration interval = _defaultInterval,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    if (rideId.trim().isEmpty) {
      throw ArgumentError.value(rideId, 'rideId', 'Must not be empty.');
    }
    if (interval < const Duration(seconds: 5) ||
        interval > const Duration(seconds: 10)) {
      throw ArgumentError.value(
        interval,
        'interval',
        'Must be between five and ten seconds.',
      );
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before sharing a live ride location.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Enable location services to share your live location.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw StateError(
        'Location permission is required to share a live ride location.',
      );
    }

    await stopSharing();
    _sharingRideId = rideId;
    _sharingUserId = userId;
    _onSharingError = onError;

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings(interval),
        ).listen(
          (position) {
            _latestPosition = position;
            unawaited(_publishLatestPosition());
          },
          onError: (Object error, StackTrace stackTrace) {
            _reportSharingError(error, stackTrace);
          },
        );

    _publishTimer = Timer.periodic(interval, (_) {
      unawaited(_publishLatestPosition());
    });
  }

  /// Stops GPS updates and removes the last shared fix from Supabase.
  Future<void> stopSharing() async {
    final rideId = _sharingRideId;
    final userId = _sharingUserId;

    _publishTimer?.cancel();
    _publishTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _publishingCompleter?.future;
    _latestPosition = null;
    _lastUploadedAt = null;
    _sharingRideId = null;
    _sharingUserId = null;
    _onSharingError = null;

    if (rideId != null && userId != null) {
      await _supabase
          .from(_table)
          .delete()
          .eq('ride_id', rideId)
          .eq('user_id', userId);
    }
  }

  /// Subscribes to the latest location of each ride participant.
  ///
  /// The current snapshot is fetched after the Realtime channel connects, so
  /// viewers joining mid-trip can place existing participant markers too.
  RealtimeChannel subscribeToRideLocations({
    required String rideId,
    required void Function(LiveRideLocation location) onLocation,
    required void Function(String userId) onLocationRemoved,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final channel = _supabase.channel('live-safety:$rideId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ride_id',
            value: rideId,
          ),
          callback: (payload) {
            try {
              if (payload.newRecord.isNotEmpty) {
                final location = LiveRideLocation.fromJson(payload.newRecord);
                if (location.rideId == rideId) onLocation(location);
              } else {
                final userId = payload.oldRecord['user_id']?.toString();
                if (userId != null && userId.isNotEmpty) {
                  onLocationRemoved(userId);
                }
              }
            } catch (error, stackTrace) {
              _reportError(error, stackTrace, onError);
            }
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(
              _loadCurrentLocations(
                rideId: rideId,
                onLocation: onLocation,
                onError: onError,
              ),
            );
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.closed ||
              status == RealtimeSubscribeStatus.timedOut) {
            _reportError(
              error ?? StateError('Realtime channel status: $status'),
              StackTrace.current,
              onError,
            );
          }
        });

    return channel;
  }

  Future<void> _loadCurrentLocations({
    required String rideId,
    required void Function(LiveRideLocation location) onLocation,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      final rows = await _supabase.from(_table).select().eq('ride_id', rideId);
      for (final row in rows) {
        final location = LiveRideLocation.fromJson(
          Map<String, dynamic>.from(row),
        );
        if (DateTime.now().difference(location.capturedAt) <=
            const Duration(minutes: 2)) {
          onLocation(location);
        }
      }
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, onError);
    }
  }

  Future<void> _publishLatestPosition() async {
    final rideId = _sharingRideId;
    final userId = _sharingUserId;
    final position = _latestPosition;
    if (rideId == null ||
        userId == null ||
        position == null ||
        _isPublishing ||
        position.timestamp == _lastUploadedAt ||
        DateTime.now().difference(position.timestamp) >
            const Duration(seconds: 30)) {
      return;
    }

    _isPublishing = true;
    _publishingCompleter = Completer<void>();
    try {
      final location = LiveRideLocation(
        rideId: rideId,
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        speedMetersPerSecond: position.speed >= 0 ? position.speed : null,
        headingDegrees: position.heading >= 0 ? position.heading : null,
        capturedAt: position.timestamp,
      );
      await _supabase
          .from(_table)
          .upsert(location.toJson(), onConflict: 'ride_id,user_id');
      _lastUploadedAt = position.timestamp;
    } catch (error, stackTrace) {
      _reportSharingError(error, stackTrace);
    } finally {
      _isPublishing = false;
      _publishingCompleter?.complete();
      _publishingCompleter = null;
    }
  }

  LocationSettings _locationSettings(Duration interval) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: interval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'AlonzY — trajet en cours',
          notificationText:
              'Votre position est partagée avec les participants.',
          notificationChannelName: 'Suivi de trajet',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
  }

  void _reportSharingError(Object error, StackTrace stackTrace) {
    _reportError(error, stackTrace, _onSharingError);
  }

  void _reportError(
    Object error,
    StackTrace stackTrace,
    void Function(Object error, StackTrace stackTrace)? onError,
  ) {
    debugPrint('Live safety tracking error: $error');
    onError?.call(error, stackTrace);
  }
}
