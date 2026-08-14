import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../map_controller.dart';
import '../../map_types.dart';

/// [AppMapController] backed by the MapLibre GL native controller.
///
/// Owns the mapping between app-level marker ids and the native [Symbol]
/// objects MapLibre uses, hiding those details from the rest of the app.
class MaplibreAppMapController extends AppMapController {
  MaplibreAppMapController(this._controller);

  final MapLibreMapController _controller;

  final Map<String, Symbol> _markers = <String, Symbol>{};
  final List<Line> _lines = <Line>[];

  @override
  MapLocation? get cameraCenter {
    final position = _controller.cameraPosition;
    if (position == null) return null;
    return MapLocation(position.target.latitude, position.target.longitude);
  }

  @override
  Future<void> addMarker(MapMarkerData marker) async {
    final existing = _markers.remove(marker.id);
    if (existing != null) {
      await _controller.removeSymbol(existing);
    }

    final symbol = await _controller.addSymbol(
      SymbolOptions(
        geometry: LatLng(marker.location.latitude, marker.location.longitude),
        textField: marker.label ?? '',
        textSize: 13,
        textColor: '#FFFFFF',
        textHaloColor: marker.colorHex,
        textHaloWidth: 2,
      ),
    );
    _markers[marker.id] = symbol;
  }

  @override
  Future<void> removeMarker(String id) async {
    final symbol = _markers.remove(id);
    if (symbol != null) {
      await _controller.removeSymbol(symbol);
    }
  }

  @override
  Future<void> addPolyline(MapPolylineData polyline) async {
    if (polyline.points.length < 2) return;
    final line = await _controller.addLine(
      LineOptions(
        geometry: polyline.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        lineColor: polyline.colorHex,
        lineWidth: polyline.width,
        lineOpacity: polyline.opacity,
      ),
    );
    _lines.add(line);
  }

  @override
  Future<void> clear() async {
    for (final id in _markers.keys.toList()) {
      final symbol = _markers.remove(id);
      if (symbol != null) {
        await _controller.removeSymbol(symbol);
      }
    }
    for (final line in _lines) {
      await _controller.removeLine(line);
    }
    _lines.clear();
  }

  @override
  Future<void> animateTo(
    MapLocation location, {
    double zoom = 15,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    await _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: zoom,
        ),
      ),
      duration: duration,
    );
  }

  @override
  Future<void> animateToBounds(
    List<MapLocation> points, {
    double padding = 100,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    if (points.length < 2) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    await _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        left: padding,
        top: padding,
        right: padding,
        bottom: padding,
      ),
      duration: duration,
    );
  }

  @override
  void dispose() {
    // The MapLibre platform view disposes its own controller in maplibre_gl
    // 0.20.0+, so we only release references held here. Calling dispose()
    // directly would trigger "used after being disposed" errors.
    _markers.clear();
    _lines.clear();
    debugPrint('MaplibreAppMapController disposed');
  }
}
