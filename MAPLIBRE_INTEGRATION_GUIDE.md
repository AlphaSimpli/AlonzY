# MapLibre GL + OpenFreeMap Integration Guide

## Overview
This guide explains how to integrate MapLibre GL with OpenFreeMap into your Alonzy carpooling app.

**Stack:**
- **Map Engine:** MapLibre GL (GPU-accelerated, open-source)
- **Tile/Style Provider:** OpenFreeMap (100% free, no API keys required)
- **Real-time Updates:** Supabase listeners for driver positions

---

## 1. Dependencies Updated ✅

Added to `pubspec.yaml`:
```yaml
maplibre_gl: ^0.20.0
```

Run:
```bash
flutter pub get
```

---

## 2. Native Permissions Configured ✅

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show rides on the map</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to show real-time driver tracking and ride information</string>
```

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<!-- Already configured -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 3. Created Files

### A. `lib/widgets/maplibre_map_widget.dart`
**Reusable map widget** with the following features:
- Initializes MapLibre GL with OpenFreeMap styling
- Exposes `MaplibreMapController` for adding markers/polylines/listeners
- Supports light/dark themes
- Optional user location tracking
- Customizable initial position and zoom level

**Usage:**
```dart
MaplibreMapWidget(
  initialLatitude: 37.7749,
  initialLongitude: -122.4194,
  initialZoom: 13,
  onMapReady: (controller) {
    // Save controller to add markers, polylines, listen to events
  },
  theme: 'bright', // or 'dark'
  showUserLocation: true,
)
```

### B. `lib/screens/search_map_page.dart`
**Map-based ride search screen** with:
- Full-screen map showing available rides
- Collapsible search panel (top)
- Results panel showing matching rides (bottom)
- Map controller ready for marker placement

**Usage in Navigation:**
Add to your `HomePage` bottom navigation:
```dart
const SearchMapPage(), // Instead of SearchRidesPage
```

---

## 4. How to Extend: Adding Driver Markers

Once map is ready, add markers for driver locations:

```dart
void _onMapReady(MaplibreMapController controller) {
  _mapController = controller;
  
  // Add a driver marker at specific coordinates
  _mapController.addSymbol(
    SymbolOptions(
      geometry: LatLng(37.7749, -122.4194),
      iconImage: "driver-icon", // Or use emoji
      iconSize: 1.0,
      textField: "Driver", // Label
    ),
  );
}
```

---

## 5. How to Extend: Real-time Driver Tracking (Supabase)

Listen to driver location updates via Supabase:

```dart
@override
void initState() {
  super.initState();
  _subscribeToDriverUpdates();
}

void _subscribeToDriverUpdates() {
  final supabase = Supabase.instance.client;
  
  // Subscribe to rides table for updates
  supabase
    .from('rides')
    .stream(primaryKey: ['id'])
    .eq('driver_id', driverId)
    .listen((List<Map<String, dynamic>> data) {
      for (var ride in data) {
        double? lat = ride['driver_latitude'];
        double? lng = ride['driver_longitude'];
        
        if (lat != null && lng != null) {
          // Update marker position on map
          _updateDriverMarker(ride['id'], LatLng(lat, lng));
        }
      }
    });
}

void _updateDriverMarker(String driverId, LatLng newPosition) {
  // Remove old marker and add new one, or use animateCamera
  _mapController.animateCamera(
    CameraUpdate.newLatLng(newPosition),
    duration: const Duration(milliseconds: 500),
  );
}
```

---

## 6. How to Extend: Adding Route Polylines

Draw the route between pickup and dropoff:

```dart
void _addRoutePolyline(LatLng startPoint, LatLng endPoint) {
  _mapController.addLine(
    LineOptions(
      geometry: [startPoint, endPoint],
      lineColor: "#2196F3", // Blue
      lineWidth: 3.0,
      lineOpacity: 0.8,
    ),
  );
}
```

---

## 7. OpenFreeMap Style URLs

- **Bright (Light):** `https://tiles.openfreemap.org/styles/bright`
- **Dark:** `https://tiles.openfreemap.org/styles/dark`
- **Liberty (Alternative Light):** `https://tiles.openfreemap.org/styles/liberty`

Change in `MaplibreMapWidget`:
```dart
String get _styleUrl {
  return 'https://tiles.openfreemap.org/styles/dark'; // or 'bright'
}
```

---

## 8. MinSDK Version Check

Your current Android config is compatible:
```gradle
minSdk = flutter.minSdkVersion  // Usually 21
```

MapLibre GL supports API 21+, so no changes needed.

---

## 9. Integration with Existing Screens

### Option 1: Replace SearchRidesPage with SearchMapPage
In `home_page.dart`:
```dart
import 'search_map_page.dart';

_pages = [
  const _HomeTab(),
  const SearchMapPage(),  // ← Changed from SearchRidesPage
  const PostRidePage(),
  const MyBookingsPage(),
  const ProfilePage(),
];
```

### Option 2: Keep Both & Let Users Choose
Create a choice screen that lets users pick between text search and map search.

### Option 3: Embed Map in PostRidePage
```dart
// In post_ride_page.dart
MaplibreMapWidget(
  onMapReady: (controller) {
    // Let drivers set route on map
  },
)
```

---

## 10. Next Steps

1. **Run the app:**
   ```bash
   flutter pub get
   flutter run
   ```

2. **Test the map widget:**
   - Launch the app
   - Navigate to Search tab (should show map)
   - Verify map loads with OpenFreeMap tiles
   - Check user location displays

3. **Add real-time driver tracking:**
   - Implement Supabase listeners for driver location updates
   - Add markers dynamically when rides are found
   - Test marker updates in real-time

4. **Add polyline routes:**
   - Calculate route between pickup/dropoff
   - Draw polyline on map
   - Update when ride is booked

5. **Optimize performance:**
   - Use symbol clustering for many markers
   - Implement marker recycling
   - Cache style/tiles locally (if needed)

---

## 11. Troubleshooting

**Map not showing tiles:**
- Check internet connection
- Verify OpenFreeMap URL is reachable
- Check that permissions are granted in app

**Markers not appearing:**
- Ensure `_mapController` is initialized (call happens in `onMapReady`)
- Verify LatLng coordinates are valid

**User location not showing:**
- Verify location permissions granted
- Check `showUserLocation: true` in MaplibreMapWidget
- Ensure `myLocationEnabled` is true

**Performance issues:**
- Reduce number of markers rendered
- Use clustering for > 100 markers
- Disable `myLocationTrackingMode` if not needed

---

## 12. API Reference

### MaplibreMapWidget
```dart
MaplibreMapWidget(
  initialLatitude: double,        // Default: 37.7749
  initialLongitude: double,       // Default: -122.4194
  initialZoom: double,            // Default: 13
  onMapReady: Function(MaplibreMapController), // Required
  theme: String,                  // 'bright' or 'dark'
  showUserLocation: bool,         // Default: true
)
```

### MaplibreMapController Methods
```dart
// Add marker
controller.addSymbol(SymbolOptions(...))

// Add line/polyline
controller.addLine(LineOptions(...))

// Add circle
controller.addCircle(CircleOptions(...))

// Animate camera
controller.animateCamera(CameraUpdate...)

// Get current position
controller.animateCamera(CameraUpdate.newCameraPosition(...))

// Remove all symbols
controller.removeSymbols(symbolIds)

// Dispose when done
controller.dispose()
```

---

## 13. Cost Analysis

✅ **100% Free Setup:**
- MapLibre GL: Open-source (no cost)
- OpenFreeMap tiles: No API key required, no usage limits
- Supabase: Already in your stack (free tier available)
- Total cost for mapping: **$0**

---

Good luck with your Alonzy app! 🚗✨
