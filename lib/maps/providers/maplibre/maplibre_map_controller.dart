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
  final Map<String, ({String sourceId, String layerId})> _circleMarkers = {};
  final List<Line> _lines = <Line>[];
  final List<({String sourceId, String layerId})> _styledLines = [];
  int _overlayIndex = 0;

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
  Future<void> addCircleMarker(MapMarkerData marker) async {
    if (marker.circleRadius == null) {
      await addMarker(marker);
      return;
    }
    await _removeCircleMarker(marker.id);
    final sourceId = 'alonzy-circle-source-${_overlayIndex++}';
    final layerId = 'alonzy-circle-layer-${_overlayIndex++}';
    await _controller.addGeoJsonSource(
      sourceId,
      _pointFeature(marker.location),
    );
    await _controller.addCircleLayer(
      sourceId,
      layerId,
      CircleLayerProperties(
        circleColor: marker.colorHex,
        circleRadius: marker.circleRadius,
        circleStrokeColor: marker.circleStrokeColor,
        circleStrokeWidth: marker.circleStrokeWidth,
      ),
    );
    _circleMarkers[marker.id] = (sourceId: sourceId, layerId: layerId);
    await addMarker(marker);
  }

  @override
  Future<void> removeMarker(String id) async {
    final symbol = _markers.remove(id);
    if (symbol != null) {
      await _controller.removeSymbol(symbol);
    }
    await _removeCircleMarker(id);
  }

  Future<void> _removeCircleMarker(String id) async {
    final overlay = _circleMarkers.remove(id);
    if (overlay == null) return;
    await _controller.removeLayer(overlay.layerId);
    await _controller.removeSource(overlay.sourceId);
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
        lineJoin: polyline.lineJoin,
      ),
    );
    _lines.add(line);
  }

  @override
  Future<void> addStyledPolyline(MapPolylineData polyline) async {
    if (polyline.points.length < 2) return;
    final sourceId = 'alonzy-route-source-${_overlayIndex++}';
    final layerId = 'alonzy-route-layer-${_overlayIndex++}';
    await _controller.addGeoJsonSource(sourceId, _lineFeature(polyline.points));
    await _controller.addLineLayer(
      sourceId,
      layerId,
      LineLayerProperties(
        lineColor: polyline.colorHex,
        lineWidth: polyline.width,
        lineOpacity: polyline.opacity,
        lineCap: polyline.lineCap,
        lineJoin: polyline.lineJoin,
      ),
    );
    _styledLines.add((sourceId: sourceId, layerId: layerId));
  }

  Map<String, dynamic> _pointFeature(MapLocation point) => {
    'type': 'Feature',
    'geometry': {
      'type': 'Point',
      'coordinates': [point.longitude, point.latitude],
    },
    'properties': <String, dynamic>{},
  };

  Map<String, dynamic> _lineFeature(List<MapLocation> points) => {
    'type': 'Feature',
    'geometry': {
      'type': 'LineString',
      'coordinates': [
        for (final point in points) [point.longitude, point.latitude],
      ],
    },
    'properties': <String, dynamic>{},
  };

  @override
  Future<void> clear() async {
    for (final id in _markers.keys.toList()) {
      await removeMarker(id);
    }
    for (final line in _lines) {
      await _controller.removeLine(line);
    }
    _lines.clear();
    for (final overlay in _styledLines) {
      await _controller.removeLayer(overlay.layerId);
      await _controller.removeSource(overlay.sourceId);
    }
    _styledLines.clear();
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
  Future<void> animateToBoundsWithPadding(
    List<MapLocation> points, {
    double left = 64,
    double top = 64,
    double right = 64,
    double bottom = 300,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    if (points.length < 2) return;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    await _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        left: left,
        top: top,
        right: right,
        bottom: bottom,
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
    _circleMarkers.clear();
    _lines.clear();
    _styledLines.clear();
  }
}
