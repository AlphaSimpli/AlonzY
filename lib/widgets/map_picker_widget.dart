import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerWidget extends StatefulWidget {
  final Function(LatLng, String) onLocationPicked;
  final String title;

  const MapPickerWidget({
    required this.onLocationPicked,
    required this.title,
  });

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  late GoogleMapController mapController;
  LatLng? selectedLocation;
  Set<Marker> markers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });
      _addMarker(selectedLocation!);
    } catch (e) {
      print("Error getting location: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error getting location: $e")),
        );
      }
    }
  }

  Future<void> _addMarker(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      String address = 'Unknown Location';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }

      setState(() {
        markers.clear();
        markers.add(
          Marker(
            markerId: const MarkerId('selected'),
            position: location,
            infoWindow: InfoWindow(title: address),
            draggable: true,
            onDragEnd: (newLocation) {
              setState(() => selectedLocation = newLocation);
              _addMarker(newLocation);
            },
          ),
        );
      });
    } catch (e) {
      print("Error adding marker: $e");
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() => selectedLocation = location);
    _addMarker(location);
  }

  Future<String> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return '${location.latitude}, ${location.longitude}';
    } catch (e) {
      print("Error getting address: $e");
      return '${location.latitude}, ${location.longitude}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (selectedLocation != null)
            TextButton(
              onPressed: () async {
                final address =
                    await _getAddressFromCoordinates(selectedLocation!);
                widget.onLocationPicked(selectedLocation!, address);
                Navigator.pop(context);
              },
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : selectedLocation == null
              ? const Center(
                  child: Text('Unable to get your location'),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: selectedLocation!,
                        zoom: 15,
                      ),
                      onTap: _onMapTapped,
                      markers: markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                    // Crosshair in center
                    Center(
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    // Info panel at bottom
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tap map to select location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lat: ${selectedLocation!.latitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Lng: ${selectedLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
