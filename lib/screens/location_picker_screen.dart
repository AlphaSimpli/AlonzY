import 'package:flutter/material.dart';

import '../maps/map_controller.dart';
import '../maps/app_maps.dart';
import '../maps/map_types.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';

/// Full-screen map picker for selecting a ride location.
///
/// Renders the configured map provider (MapLibre by default), drops a pin in
/// the centre of the screen, and returns the tapped coordinates plus a
/// human-readable address when confirmed.
class LocationPickerScreen extends StatefulWidget {
  /// Screen title (e.g. "Select pickup location").
  final String title;

  /// Optional starting point; falls back to the device location.
  final MapLocation? initialLocation;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initialLocation,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final GeocodingService _geocoding = GeocodingService();

  AppMapController? _mapController;
  MapLocation? _selected;
  String? _address;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final initial = widget.initialLocation;
    if (initial != null) {
      setState(() => _selected = initial);
      await _refreshAddress();
      return;
    }

    final position = await _geocoding.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _selected = position != null
          ? MapLocation(position.latitude, position.longitude)
          : const MapLocation(37.7749, -122.4194);
    });
    await _refreshAddress();
  }

  Future<void> _refreshAddress() async {
    final location = _selected;
    if (location == null) return;

    setState(() => _isLoadingAddress = true);
    final address = await _geocoding.addressFor(location);
    if (!mounted) return;

    setState(() {
      _address = address;
      _isLoadingAddress = false;
    });
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    controller.onIdle = _onCameraIdle;
    _animateToSelected();
  }

  void _onCameraIdle() {
    final center = _mapController?.cameraCenter;
    if (center == null) return;
    setState(() => _selected = center);
    _refreshAddress();
  }

  Future<void> _animateToSelected() async {
    final controller = _mapController;
    final location = _selected;
    if (controller == null || location == null) return;
    await controller.animateTo(location, zoom: 16);
  }

  void _confirm() {
    final location = _selected;
    final address = _address;
    if (location == null || address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the address to load')),
      );
      return;
    }

    Navigator.pop(context, {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'address': address,
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = _selected;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: location == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: AppMaps.createView(
                    MapViewConfig(
                      initialCenter: location,
                      initialZoom: 16,
                      showUserLocation: true,
                      trackCameraPosition: true,
                    ),
                  ).build(
                    onMapCreated: _onMapCreated,
                    onMapIdle: _onCameraIdle,
                  ),
                ),

                // Animated centre pin.
                IgnorePointer(
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.9, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: const _CenterPin(),
                    ),
                  ),
                ),

                // Address card.
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _AddressCard(
                        address: _address,
                        location: location,
                        isLoading: _isLoadingAddress,
                      ),
                    ),
                  ),
                ),

                // Confirm button.
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingAddress ? null : _confirm,
                          icon: const Icon(Icons.check),
                          label: Text(
                            _isLoadingAddress
                                ? 'Loading address…'
                                : 'Confirm location',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Recenter FAB.
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 88, right: 16),
                      child: FloatingActionButton(
                        heroTag: 'recenter',
                        onPressed: _animateToSelected,
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: AppColors.primary, size: 30),
        ),
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.location,
    required this.isLoading,
  });

  final String? address;
  final MapLocation location;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected location',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const SizedBox(
              height: 20,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            Text(
              address ?? 'Loading…',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${location.latitude.toStringAsFixed(5)}, '
              '${location.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}