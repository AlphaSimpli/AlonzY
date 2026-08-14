import 'package:flutter/material.dart';

import '../maps/map_controller.dart';
import '../maps/app_maps.dart';
import '../maps/map_types.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Map-based ride search.
///
/// Search rides by route/date/price, then browse results as markers on the map
/// and in the bottom sheet.
class SearchMapPage extends StatefulWidget {
  const SearchMapPage({super.key});

  @override
  State<SearchMapPage> createState() => _SearchMapPageState();
}

class _SearchMapPageState extends State<SearchMapPage> {
  final DatabaseService _dbService = DatabaseService();

  AppMapController? _mapController;

  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _maxPriceController = TextEditingController();

  DateTime? _selectedDate;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _showSearchPanel = true;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onMapReady(AppMapController controller) {
    _mapController = controller;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _search() async {
    setState(() => _loading = true);

    try {
      final now = DateTime.now();
      final dateTime = _selectedDate != null
          ? DateTime(
              _selectedDate!.year,
              _selectedDate!.month,
              _selectedDate!.day,
            )
          : DateTime(now.year, now.month, now.day);

      final double? maxPrice = _maxPriceController.text.isNotEmpty
          ? double.tryParse(_maxPriceController.text)
          : null;

      final results = await _dbService.searchRides(
        afterDate: dateTime,
        startLocation: _startController.text.trim().isEmpty
            ? null
            : _startController.text.trim(),
        endLocation: _endController.text.trim().isEmpty
            ? null
            : _endController.text.trim(),
        maxPrice: maxPrice,
      );

      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
      _plotResults(results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not search rides: $e')),
      );
    }
  }

  Future<void> _plotResults(List<Map<String, dynamic>> rides) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.clear();
    final points = <MapLocation>[];

    for (final ride in rides) {
      final lat = (ride['start_lat'] as num?)?.toDouble();
      final lng = (ride['start_lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final location = MapLocation(lat, lng);
      points.add(location);
      await controller.addMarker(
        MapMarkerData(
          id: 'ride-${ride['id']}',
          location: location,
          label: '\$${ride['price_per_seat']}',
          colorHex: '#4F46E5',
        ),
      );
    }

    if (points.length > 1) {
      await controller.animateToBounds(points, padding: 120);
    } else if (points.length == 1) {
      await controller.animateTo(points.first, zoom: 14);
    }
  }

  void _showBookingDialog(BuildContext context, Map<String, dynamic> ride) {
    var seatsToBook = 1;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Book ride'),
        content: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ride['start_location']}  →  ${ride['end_location']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text('Price: \$${ride['price_per_seat']} / seat'),
                Text('Available: ${ride['available_seats']} seats'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Seats to book'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (seatsToBook > 1) {
                              setDialogState(() => seatsToBook--);
                            }
                          },
                        ),
                        Text('$seatsToBook'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final available = (ride['available_seats'] as num?)
                                    ?.toInt() ??
                                0;
                            if (seatsToBook < available) {
                              setDialogState(() => seatsToBook++);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: \$${(ride['price_per_seat'] * seatsToBook).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _dbService.createBooking(
                  rideId: ride['id'],
                  seatsBooked: seatsToBook,
                  totalPrice: ride['price_per_seat'] * seatsToBook,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking confirmed')),
                );
                _search();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Booking failed: $e')),
                );
              }
            },
            child: const Text('Book now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find rides on map'),
        actions: [
          IconButton(
            icon: Icon(
              _showSearchPanel ? Icons.expand_more : Icons.expand_less,
            ),
            onPressed: () =>
                setState(() => _showSearchPanel = !_showSearchPanel),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AppMaps.createView(
              const MapViewConfig(initialZoom: 12, trackCameraPosition: true),
            ).build(onMapCreated: _onMapReady),
          ),

          if (_showSearchPanel)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _startController,
                        decoration: const InputDecoration(
                          labelText: 'Pickup',
                          prefixIcon: Icon(Icons.trip_origin),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _endController,
                        decoration: const InputDecoration(
                          labelText: 'Drop-off',
                          prefixIcon: Icon(Icons.place),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              borderRadius: BorderRadius.circular(14),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _selectedDate == null
                                      ? 'Any date'
                                      : '${_selectedDate!.month}/${_selectedDate!.day}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max price',
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _search,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_loading ? 'Searching…' : 'Search rides'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_results.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 210,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final ride = _results[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.directions_car, size: 20),
                        ),
                        title: Text(
                          '${ride['start_location']} → ${ride['end_location']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '\$${ride['price_per_seat']}/seat · '
                          '${ride['available_seats']} seats',
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () =>
                              _showBookingDialog(context, ride),
                          child: const Text('Book'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}