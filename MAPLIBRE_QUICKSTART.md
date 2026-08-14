# MapLibre GL Integration - Quick Start Checklist

## ✅ Completed Steps

- [x] Added `maplibre_gl: ^0.20.0` to `pubspec.yaml`
- [x] Updated iOS `Info.plist` with location permissions
- [x] Android permissions already configured in `AndroidManifest.xml`
- [x] Created `lib/widgets/maplibre_map_widget.dart` (reusable map widget)
- [x] Created `lib/screens/search_map_page.dart` (map-based ride search)
- [x] Created `lib/services/map_service.dart` (helper service for map operations)
- [x] Created `MAPLIBRE_INTEGRATION_GUIDE.md` (comprehensive guide)

---

## 📋 Next Steps to Run Your App

### 1. Install Dependencies
```bash
cd /Users/ousmanediallo/dev_App/AlonzY
flutter pub get
```

### 2. Update Navigation (OPTIONAL - Choose One)

#### Option A: Replace SearchRidesPage with SearchMapPage
Edit `lib/screens/home_page.dart`:
```dart
// Change this:
import 'search_rides_page.dart';

_pages = [
  const _HomeTab(),
  const SearchRidesPage(),  // ← OLD
  const PostRidePage(),
  const MyBookingsPage(),
  const ProfilePage(),
];

// To this:
import 'search_map_page.dart';

_pages = [
  const _HomeTab(),
  const SearchMapPage(),  // ← NEW (map-based search)
  const PostRidePage(),
  const MyBookingsPage(),
  const ProfilePage(),
];
```

#### Option B: Keep Both (Advanced)
Create a choice screen that lets users pick between text search and map search.

### 3. Run the App
```bash
flutter run
```

### 4. Test the Map
1. Launch the app
2. Navigate to the "Search" tab
3. Verify the map displays with OpenFreeMap tiles (bright theme)
4. Check that your location shows on the map
5. Test the search functionality

---

## 🗺️ How to Use Each Component

### MaplibreMapWidget (Reusable Widget)
```dart
import 'package:flutter/material.dart';
import '../widgets/maplibre_map_widget.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late MaplibreMapController _mapController;

  void _onMapReady(MaplibreMapController controller) {
    _mapController = controller;
    // Now you can add markers, polylines, etc.
  }

  @override
  Widget build(BuildContext context) {
    return MaplibreMapWidget(
      initialLatitude: 37.7749,
      initialLongitude: -122.4194,
      initialZoom: 13,
      onMapReady: _onMapReady,
      theme: 'bright', // or 'dark'
      showUserLocation: true,
    );
  }
}
```

### MapService (Helper Service)
```dart
import '../services/map_service.dart';

void _setupMapService() {
  final mapService = MapService(mapController: _mapController);
  
  // Add driver marker
  await mapService.addDriverMarker(
    driverId: 'driver-123',
    latitude: 37.7749,
    longitude: -122.4194,
    driverName: 'John',
  );
  
  // Add pickup location
  await mapService.addRideLocationMarker(
    markerId: 'pickup-1',
    latitude: 37.7749,
    longitude: -122.4194,
    label: 'Pickup',
    color: '#00FF00',
  );
  
  // Add route polyline
  await mapService.addRoutePolyline(
    waypoints: [
      LatLng(37.7749, -122.4194),
      LatLng(37.7849, -122.4094),
    ],
    color: '#2196F3',
    width: 3.0,
  );
  
  // Listen to real-time driver updates
  final subscription = mapService.subscribeToDriverUpdates(
    rideId: 'ride-123',
    onUpdate: (latitude, longitude, driverId) {
      mapService.updateDriverMarker(
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
      );
    },
  );
  
  // Later: unsubscribe
  // subscription.unsubscribe();
}
```

---

## 🎯 Implementation Roadmap

### Phase 1: Map Display (DONE ✅)
- [x] Display map with OpenFreeMap tiles
- [x] Show user location
- [x] Allow zoom/pan interactions

### Phase 2: Search Functionality (DONE ✅)
- [x] Create map-based search screen
- [x] Search for available rides
- [x] Display results

### Phase 3: Real-time Driver Tracking (TODO)
- [ ] Subscribe to Supabase driver location updates
- [ ] Add driver markers dynamically
- [ ] Update marker positions in real-time
- [ ] Animate camera to follow driver

### Phase 4: Route Display (TODO)
- [ ] Calculate route between pickup and dropoff
- [ ] Draw polyline on map
- [ ] Show estimated time/distance
- [ ] Update route in real-time

### Phase 5: Advanced Features (TODO)
- [ ] Cluster markers for performance
- [ ] Add custom marker icons
- [ ] Support dark theme
- [ ] Offline map support (advanced)
- [ ] Voice navigation (optional)

---

## 🐛 Troubleshooting

### Issue: Map doesn't display
**Solution:**
- Verify `flutter pub get` was run
- Check internet connection (OpenFreeMap needs to fetch tiles)
- Verify device/simulator permissions
- Check console for errors

### Issue: Map shows blank white screen
**Solution:**
- Wait 5-10 seconds for map style to load
- Check OpenFreeMap endpoint is reachable: https://tiles.openfreemap.org/styles/bright
- Try switching theme (dark/bright)

### Issue: User location doesn't show
**Solution:**
- Grant location permissions in app settings
- Ensure `showUserLocation: true` in MaplibreMapWidget
- On simulator, set a custom location in Xcode/Android Studio

### Issue: Markers don't appear
**Solution:**
- Verify `_mapController` is not null (check `onMapReady` callback fires)
- Ensure LatLng coordinates are valid
- Wait for style to load before adding markers

### Issue: Search not working
**Solution:**
- Check Supabase connection in `DatabaseService`
- Verify ride data exists in Supabase
- Check search parameters (dates, locations, price)

---

## 📚 File Structure

```
lib/
├── widgets/
│   └── maplibre_map_widget.dart     ← Reusable map widget
├── screens/
│   ├── home_page.dart               ← Update navigation here
│   ├── search_map_page.dart         ← NEW: Map-based search
│   ├── search_rides_page.dart       ← Keep for text search (optional)
│   ├── post_ride_page.dart
│   ├── my_bookings_page.dart
│   └── profile_page.dart
└── services/
    ├── map_service.dart             ← NEW: Map operations helper
    ├── auth_service.dart
    ├── database_service.dart
    └── ...

pubspec.yaml                           ← Updated with maplibre_gl
ios/Runner/Info.plist                  ← Updated with permissions
```

---

## 🔗 Useful Links

- **MapLibre GL Docs:** https://maplibre.org/maplibre-gl-js-docs/
- **OpenFreeMap:** https://openfreemap.org/
- **Flutter MapLibre Package:** https://pub.dev/packages/maplibre_gl
- **Supabase Realtime:** https://supabase.com/docs/guides/realtime

---

## 💡 Pro Tips

1. **Use MapService for consistency:** All map operations should go through `MapService` for easier management and debugging.

2. **Cache markers:** Store marker IDs in `MapService` to update them later instead of removing/readding.

3. **Optimize for performance:** With > 100 markers, use clustering to avoid lag.

4. **Test on real device:** Simulators may have slower rendering. Test on real device for best performance.

5. **Monitor tile loading:** OpenFreeMap is fast but can be slow on poor connections. Consider adding a loading indicator.

---

## ❓ Questions?

Refer to `MAPLIBRE_INTEGRATION_GUIDE.md` for detailed documentation and API reference.

Good luck with your Alonzy carpooling app! 🚗✨
