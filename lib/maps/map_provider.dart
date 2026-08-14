import 'map_types.dart';
import 'map_view.dart';

/// Factory that produces provider-specific [MapView]s.
///
/// Implementations live under `lib/maps/providers/` (e.g.
/// `MaplibreMapProvider` today, `GoogleMapProvider` in a future iteration).
abstract class MapProvider {
  const MapProvider();

  MapView createView(MapViewConfig config);
}