import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:supabase_flutter_app/maps/map_controller.dart';
import 'package:supabase_flutter_app/maps/map_types.dart';
import 'package:supabase_flutter_app/maps/providers/maplibre/maplibre_map_view.dart';

// No live tiles, JavaScript or native plugin. These tests isolate the ordering
// contract between the app map wrapper and MapLibre's two readiness callbacks.
class _FakeMapPlatform extends MapLibrePlatform {
  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) => const SizedBox();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MapLibrePlatform Function() originalFactory;
  late _FakeMapPlatform platform;
  late MapLibreMapController nativeController;
  late List<AppMapController> readyControllers;

  setUp(() {
    originalFactory = MapLibrePlatform.createInstance;
    platform = _FakeMapPlatform();
    MapLibrePlatform.createInstance = () => platform;
    nativeController = MapLibreMapController(
      maplibrePlatform: platform,
      initialCameraPosition: const CameraPosition(target: LatLng(45, -75)),
      annotationOrder: const [],
      annotationConsumeTapEvents: const [],
    );
    readyControllers = [];
  });

  tearDown(() {
    nativeController.dispose();
    MapLibrePlatform.createInstance = originalFactory;
  });

  Future<MapLibreMap> openMap(WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const MaplibreMapView(
          config: MapViewConfig(showUserLocation: false),
        ).build(onMapCreated: readyControllers.add),
      ),
    );
    return tester.widget<MapLibreMap>(find.byType(MapLibreMap));
  }

  testWidgets('does not expose the controller before style load', (
    tester,
  ) async {
    final map = await openMap(tester);
    map.onMapCreated!(nativeController);
    expect(readyControllers, isEmpty);
    map.onStyleLoadedCallback!();
    expect(readyControllers, hasLength(1));
  });

  testWidgets('also handles style load arriving before map creation', (
    tester,
  ) async {
    final map = await openMap(tester);
    map.onStyleLoadedCallback!();
    expect(readyControllers, isEmpty);
    map.onMapCreated!(nativeController);
    expect(readyControllers, hasLength(1));
  });

  testWidgets('notifies readiness only once', (tester) async {
    final map = await openMap(tester);
    map.onMapCreated!(nativeController);
    map.onStyleLoadedCallback!();
    map.onStyleLoadedCallback!();
    expect(readyControllers, hasLength(1));
  });

  testWidgets('ignores a style callback after the map is removed', (
    tester,
  ) async {
    final map = await openMap(tester);
    map.onMapCreated!(nativeController);
    await tester.pumpWidget(const SizedBox());
    map.onStyleLoadedCallback!();
    expect(readyControllers, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
