import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../map_controller.dart';
import '../../map_types.dart';
import '../../map_view.dart';
import 'maplibre_map_controller.dart';

/// MapLibre-backed [MapView].
///
/// Renders a [MapLibreMap] using the free OpenFreeMap tile service (no API
/// keys required) and exposes a [MaplibreAppMapController] through the
/// provider-agnostic [AppMapController] interface.
class MaplibreMapView extends MapView {
  const MaplibreMapView({required super.config});

  @override
  Widget build({
    required void Function(AppMapController controller) onMapCreated,
    VoidCallback? onMapIdle,
  }) {
    return _MaplibreMapViewWidget(
      config: config,
      onMapCreated: onMapCreated,
      onMapIdle: onMapIdle,
    );
  }
}

/// Default MapLibre style URL. Swapped for `dark` when the app runs dark mode.
const String _brightStyleUrl = 'https://tiles.openfreemap.org/styles/bright';

class _MaplibreMapViewWidget extends StatefulWidget {
  const _MaplibreMapViewWidget({
    required this.config,
    required this.onMapCreated,
    this.onMapIdle,
  });

  final MapViewConfig config;
  final void Function(AppMapController controller) onMapCreated;
  final VoidCallback? onMapIdle;

  @override
  State<_MaplibreMapViewWidget> createState() => _MaplibreMapViewWidgetState();
}

class _MaplibreMapViewWidgetState extends State<_MaplibreMapViewWidget> {
  MaplibreAppMapController? _controller;
  bool _styleLoaded = false;
  bool _readyNotified = false;

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return MapLibreMap(
      styleString: _brightStyleUrl,
      initialCameraPosition: CameraPosition(
        target: LatLng(
          config.initialCenter.latitude,
          config.initialCenter.longitude,
        ),
        zoom: config.initialZoom,
      ),
      onMapCreated: _handleMapCreated,
      onStyleLoadedCallback: _handleStyleLoaded,
      onCameraIdle: _handleCameraIdle,
      compassEnabled: config.compassEnabled,
      cameraTargetBounds: CameraTargetBounds.unbounded,
      minMaxZoomPreference: MinMaxZoomPreference(
        config.minZoom,
        config.maxZoom,
      ),
      myLocationEnabled: config.showUserLocation,
      myLocationTrackingMode: MyLocationTrackingMode.none,
      trackCameraPosition: config.trackCameraPosition,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
      },
    );
  }

  void _handleMapCreated(MapLibreMapController controller) {
    if (!mounted) return;
    _controller = MaplibreAppMapController(controller);
    _notifyWhenReady();
  }

  void _handleStyleLoaded() {
    _styleLoaded = true;
    _notifyWhenReady();
  }

  void _notifyWhenReady() {
    final controller = _controller;
    if (!mounted || !_styleLoaded || _readyNotified || controller == null) {
      return;
    }
    // MapLibre's annotation managers are only initialized after style load.
    // AppMapController promises a map ready for markers and polylines, not
    // merely a platform view that has been created.
    _readyNotified = true;
    widget.onMapCreated(controller);
  }

  void _handleCameraIdle() {
    widget.onMapIdle?.call();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
