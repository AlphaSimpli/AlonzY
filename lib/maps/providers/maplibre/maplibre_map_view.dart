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
      onStyleLoadedCallback: () {},
      onCameraIdle: _handleCameraIdle,
      compassEnabled: config.compassEnabled,
      cameraTargetBounds: CameraTargetBounds.unbounded,
      minMaxZoomPreference:
          MinMaxZoomPreference(config.minZoom, config.maxZoom),
      myLocationEnabled: config.showUserLocation,
      myLocationTrackingMode: MyLocationTrackingMode.none,
      trackCameraPosition: config.trackCameraPosition,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
      },
    );
  }

  void _handleMapCreated(MapLibreMapController controller) {
    _controller = MaplibreAppMapController(controller);
    widget.onMapCreated(_controller!);
  }

  void _handleCameraIdle() {
    widget.onMapIdle?.call();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
