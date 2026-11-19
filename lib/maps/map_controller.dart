import 'package:flutter/foundation.dart';

import 'map_types.dart';

/// Abstraction over a map provider's controller.
///
/// Screens and services interact only with this interface, so the underlying
/// provider (MapLibre today, Google Maps tomorrow) can be swapped without
/// touching business logic.
abstract class AppMapController {
  /// Called whenever the map camera finishes moving.
  VoidCallback? onIdle;

  /// Adds (or replaces) a marker with [MapMarkerData.id].
  Future<void> addMarker(MapMarkerData marker);

  /// Adds a marker as a styled map circle when supported by the provider.
  Future<void> addCircleMarker(MapMarkerData marker) => addMarker(marker);

  /// Removes a marker by id. No-op when the id is unknown.
  Future<void> removeMarker(String id);

  /// Draws a polyline on the map.
  Future<void> addPolyline(MapPolylineData polyline);

  /// Draws a style-layer polyline when the provider supports line caps.
  Future<void> addStyledPolyline(MapPolylineData polyline) =>
      addPolyline(polyline);

  /// Removes every marker and overlay the controller has created.
  Future<void> clear();

  /// Smoothly moves the camera to [location].
  Future<void> animateTo(
    MapLocation location, {
    double zoom = 15,
    Duration duration = const Duration(milliseconds: 500),
  });

  /// Smoothly moves the camera to fit all [points] on screen.
  Future<void> animateToBounds(
    List<MapLocation> points, {
    double padding = 100,
    Duration duration = const Duration(milliseconds: 500),
  });

  /// Fits points while allowing extra room below the route for an overlay.
  Future<void> animateToBoundsWithPadding(
    List<MapLocation> points, {
    double left = 64,
    double top = 64,
    double right = 64,
    double bottom = 300,
    Duration duration = const Duration(milliseconds: 500),
  }) => animateToBounds(
    points,
    padding: [left, top, right, bottom].reduce((a, b) => a > b ? a : b),
    duration: duration,
  );

  /// The current camera centre, or `null` when the provider does not
  /// track camera position.
  MapLocation? get cameraCenter;

  /// Releases native resources held by this controller.
  ///
  /// Implementations must be safe to call even when the platform widget has
  /// already disposed its own resources.
  void dispose();
}
