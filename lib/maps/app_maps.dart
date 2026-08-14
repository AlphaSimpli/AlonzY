import 'map_provider.dart';
import 'map_types.dart';
import 'map_view.dart';
import 'providers/maplibre/maplibre_map_provider.dart';

/// Holds the currently configured map provider for the whole app.
///
/// Screens request maps through [AppMaps.createView] instead of constructing
/// provider widgets directly, which is what makes the map layer swappable.
class AppMaps {
  AppMaps._();

  static MapProvider _provider = const MaplibreMapProvider();

  /// The active provider (MapLibre by default).
  static MapProvider get provider => _provider;

  /// Swap the map provider at runtime, e.g. from MapLibre to Google Maps.
  static void configure(MapProvider provider) {
    _provider = provider;
  }

  /// Convenience factory so screens don't need to reference the provider.
  static MapView createView(MapViewConfig config) =>
      _provider.createView(config);
}
