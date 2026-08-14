import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../maps/map_controller.dart';
import '../maps/app_maps.dart';
import '../maps/map_types.dart';
import '../services/map_service.dart';
import '../theme/app_theme.dart';

/// EXAMPLE: complete implementation pattern for ride tracking.
///
/// This screen demonstrates how to combine the map abstraction
/// (`AppMaps.createView`) with [MapService] for a real-world ride tracking
/// scenario with real-time driver updates from Supabase.
class RideTrackingExample extends StatefulWidget {
  const RideTrackingExample({super.key});

  @override
  State<RideTrackingExample> createState() => _RideTrackingExampleState();
}

class _RideTrackingExampleState extends State<RideTrackingExample> {
  MapService? _mapService;
  RealtimeChannel? _driverUpdates;

  // Mock data — replace with real data from Supabase.
  static const String rideId = 'ride-123';
  static const MapLocation pickup = MapLocation(37.7749, -122.4194);
  static const MapLocation dropoff = MapLocation(37.8049, -122.3894);

  void _onMapReady(AppMapController controller) {
    _mapService = MapService(mapController: controller);

    _setupTracking();
  }

  Future<void> _setupTracking() async {
    final service = _mapService;
    if (service == null) return;

    await service.addRideLocationMarker(
      markerId: 'pickup-$rideId',
      latitude: pickup.latitude,
      longitude: pickup.longitude,
      label: 'Pickup',
      color: '#10B981',
    );
    await service.addRideLocationMarker(
      markerId: 'dropoff-$rideId',
      latitude: dropoff.latitude,
      longitude: dropoff.longitude,
      label: 'Dropoff',
      color: '#EF4444',
    );
    await service.addRoutePolyline(
      waypoints: const [pickup, dropoff],
      color: '#4F46E5',
    );
    await service.animateCameraToFitBounds(
      points: const [pickup, dropoff],
      padding: 150,
    );

    _driverUpdates = service.subscribeToDriverUpdates(
      rideId: rideId,
      onUpdate: (latitude, longitude, updatedDriverId) {
        service.updateDriverMarker(
          driverId: updatedDriverId,
          latitude: latitude,
          longitude: longitude,
        );
      },
    );
  }

  @override
  void dispose() {
    _driverUpdates?.unsubscribe();
    _mapService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking your ride')),
      body: Stack(
        children: [
          Positioned.fill(
            child: AppMaps.createView(
              const MapViewConfig(
                initialCenter: pickup,
                initialZoom: 14,
              ),
            ).build(onMapCreated: _onMapReady),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(child: Icon(Icons.person)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'John',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Toyota Prius · ABC 123',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('4.8', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.message),
                          label: const Text('Message'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
