import '../../map_provider.dart';
import '../../map_types.dart';
import '../../map_view.dart';
import 'maplibre_map_view.dart';

/// MapLibre implementation of [MapProvider].
///
/// This is the default provider for the initial phase. Swapping to Google
/// Maps later only requires a new `GoogleMapProvider` and a single call to
/// [AppMaps.configure].
class MaplibreMapProvider extends MapProvider {
  const MaplibreMapProvider();

  @override
  MapView createView(MapViewConfig config) {
    return MaplibreMapView(config: config);
  }
}
