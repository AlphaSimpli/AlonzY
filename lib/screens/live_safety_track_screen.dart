import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../maps/app_maps.dart';
import '../maps/map_controller.dart';
import '../maps/map_types.dart';
import '../models/live_ride_location.dart';
import '../services/live_safety_service.dart';

/// Map view for sharing or viewing participant locations during an active ride.
class LiveSafetyTrackScreen extends StatefulWidget {
  const LiveSafetyTrackScreen({
    required this.rideId,
    required this.initialCenter,
    super.key,
  });

  final String rideId;
  final MapLocation initialCenter;

  @override
  State<LiveSafetyTrackScreen> createState() => _LiveSafetyTrackScreenState();
}

class _LiveSafetyTrackScreenState extends State<LiveSafetyTrackScreen> {
  final LiveSafetyService _safetyService = LiveSafetyService();
  final Map<String, LiveRideLocation> _locations = {};
  AppMapController? _mapController;
  RealtimeChannel? _locationChannel;
  bool _isSharing = false;
  bool _isStartingShare = false;
  String? _errorMessage;

  @override
  void dispose() {
    _locationChannel?.unsubscribe();
    unawaited(_stopSharingOnDispose());
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _stopSharingOnDispose() async {
    try {
      await _safetyService.stopSharing();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Live Safety Track',
          context: ErrorDescription('while stopping location sharing'),
        ),
      );
    }
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    _locationChannel = _safetyService.subscribeToRideLocations(
      rideId: widget.rideId,
      onLocation: _showLocation,
      onLocationRemoved: _removeLocation,
      onError: _showError,
    );
  }

  void _showLocation(LiveRideLocation location) {
    if (!mounted) return;
    final previous = _locations[location.userId];
    if (previous != null && !location.capturedAt.isAfter(previous.capturedAt)) {
      return;
    }
    setState(() {
      _locations[location.userId] = location;
      _errorMessage = null;
    });
    unawaited(_updateMarker(location));
  }

  Future<void> _updateMarker(LiveRideLocation location) async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      await controller.addMarker(
        MapMarkerData(
          id: location.userId,
          location: MapLocation(location.latitude, location.longitude),
          label:
              location.userId == Supabase.instance.client.auth.currentUser?.id
              ? 'Moi'
              : 'Participant',
          colorHex:
              location.userId == Supabase.instance.client.auth.currentUser?.id
              ? '#4F46E5'
              : '#10B981',
        ),
      );
    } catch (error, stackTrace) {
      _showError(error, stackTrace);
    }
  }

  void _removeLocation(String userId) {
    if (!mounted) return;
    setState(() => _locations.remove(userId));
    unawaited(_mapController?.removeMarker(userId));
  }

  void _showError(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    setState(() => _errorMessage = error.toString());
  }

  Future<void> _toggleSharing() async {
    if (_isStartingShare) return;
    setState(() {
      _isStartingShare = true;
      _errorMessage = null;
    });

    try {
      if (_isSharing) {
        await _safetyService.stopSharing();
        if (mounted) setState(() => _isSharing = false);
      } else {
        await _safetyService.startSharing(
          rideId: widget.rideId,
          onError: _showError,
        );
        if (mounted) setState(() => _isSharing = true);
      }
    } catch (error, stackTrace) {
      _showError(error, stackTrace);
      if (mounted) {
        setState(() => _isSharing = _safetyService.isSharing);
      }
    } finally {
      if (mounted) setState(() => _isStartingShare = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Safety Track')),
      body: Stack(
        children: [
          Positioned.fill(
            child: AppMaps.createView(
              MapViewConfig(
                initialCenter: widget.initialCenter,
                initialZoom: 14,
                showUserLocation: false,
              ),
            ).build(onMapCreated: _onMapCreated),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_locations.length} participant(s) sur la carte',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSharing
                          ? 'Votre position est partagée pendant ce trajet.'
                          : 'Le partage de votre position est désactivé.',
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isStartingShare ? null : _toggleSharing,
                      icon: _isStartingShare
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isSharing
                                  ? Icons.location_off
                                  : Icons.my_location,
                            ),
                      label: Text(
                        _isSharing
                            ? 'Arrêter le partage'
                            : 'Partager ma position',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
