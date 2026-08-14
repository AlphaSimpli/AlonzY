import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../maps/map_controller.dart';
import '../maps/map_types.dart';

/// High-level map operations built on top of the provider-agnostic
/// [AppMapController].
///
/// Responsibilities:
/// - Add/remove markers for drivers and ride locations
/// - Draw polylines for routes
/// - Listen to Supabase real-time events for driver location updates
/// - Animate the camera to a location or a set of bounds
class MapService {
  MapService({required this.mapController, SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final AppMapController mapController;
  final SupabaseClient _supabase;

  /// Driver ids whose markers this service manages, so updates can be
  /// distinguished from brand-new markers.
  final Set<String> _driverMarkerIds = <String>{};

  /// Add a marker for a specific driver.
  Future<void> addDriverMarker({
    required String driverId,
    required double latitude,
    required double longitude,
    String? driverName,
  }) async {
    await mapController.addMarker(
      MapMarkerData(
        id: driverId,
        location: MapLocation(latitude, longitude),
        label: driverName ?? 'Driver',
        colorHex: '#4F46E5',
      ),
    );
    _driverMarkerIds.add(driverId);
    debugPrint('Added marker for driver $driverId');
  }

  /// Update an existing driver marker position (for real-time tracking).
  Future<void> updateDriverMarker({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    if (!_driverMarkerIds.contains(driverId)) {
      await addDriverMarker(
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
      );
      return;
    }

    // MapLibre doesn't support moving symbols in-place, so the marker is
    // replaced with a fresh one at the new position.
    await mapController.removeMarker(driverId);
    await mapController.addMarker(
      MapMarkerData(
        id: driverId,
        location: MapLocation(latitude, longitude),
        label: 'Driver',
        colorHex: '#4F46E5',
      ),
    );
    debugPrint('Updated marker for driver $driverId');
  }

  /// Remove the marker for a specific driver.
  Future<void> removeDriverMarker(String driverId) async {
    await mapController.removeMarker(driverId);
    _driverMarkerIds.remove(driverId);
    debugPrint('Removed marker for driver $driverId');
  }

  /// Add a marker for a ride location (pickup/drop-off).
  Future<void> addRideLocationMarker({
    required String markerId,
    required double latitude,
    required double longitude,
    required String label,
    String color = '#10B981',
  }) async {
    await mapController.addMarker(
      MapMarkerData(
        id: markerId,
        location: MapLocation(latitude, longitude),
        label: label,
        colorHex: color,
      ),
    );
    debugPrint('Added $label marker at ($latitude, $longitude)');
  }

  /// Draw a polyline (route) through [waypoints].
  Future<void> addRoutePolyline({
    required List<MapLocation> waypoints,
    String color = '#4F46E5',
    double width = 4,
  }) async {
    await mapController.addPolyline(
      MapPolylineData(points: waypoints, colorHex: color, width: width),
    );
    debugPrint('Added route polyline with ${waypoints.length} waypoints');
  }

  /// Listen to real-time driver position updates from Supabase.
  ///
  /// Returns a [RealtimeChannel] that can be cancelled via `unsubscribe()`.
  ///
  /// Example:
  /// ```dart
  /// final subscription = mapService.subscribeToDriverUpdates(
  ///   rideId: rideId,
  ///   onUpdate: (lat, lng, driverId) {
  ///     mapService.updateDriverMarker(driverId: driverId, latitude: lat, longitude: lng);
  ///   },
  /// );
  /// // Later:
  /// subscription.unsubscribe();
  /// ```
  RealtimeChannel subscribeToDriverUpdates({
    required String rideId,
    required void Function(double latitude, double longitude, String driverId)
        onUpdate,
  }) {
    final channel = _supabase.channel('driver-updates:$rideId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rides',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: rideId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final driverId = newRecord['driver_id'] as String?;
            final latitude = (newRecord['driver_latitude'] as num?)?.toDouble();
            final longitude =
                (newRecord['driver_longitude'] as num?)?.toDouble();

            if (driverId != null && latitude != null && longitude != null) {
              onUpdate(latitude, longitude, driverId);
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('Subscribed to driver updates for ride $rideId');
          } else if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint('Channel error: $error');
          }
        });

    return channel;
  }

  /// Animate the camera to a specific location.
  Future<void> animateCameraToLocation({
    required double latitude,
    required double longitude,
    double zoom = 15,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return mapController.animateTo(
      MapLocation(latitude, longitude),
      zoom: zoom,
      duration: duration,
    );
  }

  /// Animate the camera to fit a set of locations (bounds).
  Future<void> animateCameraToFitBounds({
    required List<MapLocation> points,
    double padding = 100,
  }) {
    return mapController.animateToBounds(points, padding: padding);
  }

  /// Remove every marker and overlay managed by this service.
  Future<void> clearAll() => mapController.clear();

  /// Dispose of the service and its controller.
  void dispose() => mapController.dispose();
}
