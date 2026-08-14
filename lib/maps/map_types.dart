import 'package:flutter/foundation.dart';

/// A geographic coordinate used across the whole app.
///
/// This is intentionally provider-agnostic so that map code never has to
/// import a vendor-specific type (e.g. `LatLng` from MapLibre or Google Maps).
@immutable
class MapLocation {
  final double latitude;
  final double longitude;

  const MapLocation(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  bool operator ==(Object other) =>
      other is MapLocation &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'MapLocation($latitude, $longitude)';
}

/// Describes a single marker (pin) shown on the map.
@immutable
class MapMarkerData {
  final String id;
  final MapLocation location;

  /// Optional short label rendered next to the marker.
  final String? label;

  /// Accent colour of the marker, as a hex string (e.g. `#10B981`).
  final String colorHex;

  const MapMarkerData({
    required this.id,
    required this.location,
    this.label,
    this.colorHex = '#4F46E5',
  });
}

/// Describes a polyline (route) drawn on the map.
@immutable
class MapPolylineData {
  final List<MapLocation> points;
  final String colorHex;
  final double width;
  final double opacity;

  const MapPolylineData({
    required this.points,
    this.colorHex = '#4F46E5',
    this.width = 4,
    this.opacity = 0.85,
  });
}

/// Configuration used when a map view is created.
@immutable
class MapViewConfig {
  final MapLocation initialCenter;
  final double initialZoom;
  final bool showUserLocation;
  final bool compassEnabled;
  final bool trackCameraPosition;
  final double minZoom;
  final double maxZoom;

  const MapViewConfig({
    this.initialCenter = const MapLocation(37.7749, -122.4194),
    this.initialZoom = 13,
    this.showUserLocation = true,
    this.compassEnabled = true,
    this.trackCameraPosition = false,
    this.minZoom = 0,
    this.maxZoom = 20,
  });

  MapViewConfig copyWith({
    MapLocation? initialCenter,
    double? initialZoom,
    bool? showUserLocation,
    bool? compassEnabled,
    bool? trackCameraPosition,
    double? minZoom,
    double? maxZoom,
  }) {
    return MapViewConfig(
      initialCenter: initialCenter ?? this.initialCenter,
      initialZoom: initialZoom ?? this.initialZoom,
      showUserLocation: showUserLocation ?? this.showUserLocation,
      compassEnabled: compassEnabled ?? this.compassEnabled,
      trackCameraPosition: trackCameraPosition ?? this.trackCameraPosition,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
    );
  }
}
