import 'package:flutter/widgets.dart';

import 'map_controller.dart';
import 'map_types.dart';

/// A provider-agnostic map view.
///
/// Create a view through [MapProvider.createView], then call [build] inside a
/// widget tree. The concrete widget returned is owned by the active provider.
abstract class MapView {
  const MapView({required this.config});

  final MapViewConfig config;

  /// Builds the provider-specific map widget.
  ///
  /// [onMapCreated] is invoked once the underlying map is ready and exposes an
  /// [AppMapController] for adding markers, polylines, and camera work.
  /// [onMapIdle] is invoked whenever the camera stops moving.
  Widget build({
    required void Function(AppMapController controller) onMapCreated,
    VoidCallback? onMapIdle,
  });
}
