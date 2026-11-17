import 'package:flutter/material.dart';

import '../maps/map_types.dart';
import '../models/ride.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_autocomplete_field.dart';
import 'ride_details_page.dart';

/// Ride search with a standard rideshare flow.
///
/// The user fills in Origin, Destination, Date and Seats using live location
/// autocomplete, then taps "Search rides" to query available rides. Results are
/// listed inline, sorted by departure time. Tapping a ride opens its detail
/// page (route preview, driver profile, policies) for booking. The map is
/// never opened implicitly: it only appears on the detail page once a real
/// address has been selected.
class SearchRidesPage extends StatefulWidget {
  const SearchRidesPage({super.key, this.databaseService});

  final DatabaseService? databaseService;

  @override
  State<SearchRidesPage> createState() => _SearchRidesPageState();
}

class _SearchRidesPageState extends State<SearchRidesPage> {
  late final DatabaseService _dbService =
      widget.databaseService ?? DatabaseService();

  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _maxPriceController = TextEditingController();

  MapLocation? _startLocation;
  MapLocation? _endLocation;
  String? _selectedStartAddress;
  String? _selectedEndAddress;

  DateTime? _selectedDate;
  int _minSeats = 1;

  List<Ride> _searchResults = [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _searchError;

  // Comparing the selected address with the current text also protects against
  // stale coordinates after swapping the fields and then editing their text.
  bool get _hasSelectedOrigin =>
      _startLocation != null && _selectedStartAddress == _startController.text;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _swapRoute() {
    final fromText = _startController.text;
    final toText = _endController.text;
    final fromLocation = _startLocation;
    final toLocation = _endLocation;
    final fromSelectedAddress = _selectedStartAddress;
    final toSelectedAddress = _selectedEndAddress;

    setState(() {
      _startController.text = toText;
      _endController.text = fromText;
      _startLocation = toSelectedAddress == toText ? toLocation : null;
      _endLocation = fromSelectedAddress == fromText ? fromLocation : null;
      _selectedStartAddress = toSelectedAddress;
      _selectedEndAddress = fromSelectedAddress;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pick a departure date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _searchRides() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    final priceText = _maxPriceController.text.trim().replaceAll(',', '.');
    final maxPrice = priceText.isEmpty ? null : double.tryParse(priceText);
    if (priceText.isNotEmpty &&
        (maxPrice == null || !maxPrice.isFinite || maxPrice < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid, non-negative maximum price.'),
        ),
      );
      return;
    }
    final selectedOrigin = _hasSelectedOrigin ? _startLocation : null;
    setState(() {
      _loading = true;
      _hasSearched = true;
      _searchError = null;
      _searchResults = [];
    });

    try {
      final dateTime = _selectedDate == null
          ? null
          : DateTime(
              _selectedDate!.year,
              _selectedDate!.month,
              _selectedDate!.day,
            );

      final results = await _dbService.searchRides(
        afterDate: dateTime,
        startLocation: _startController.text.trim().isEmpty
            ? null
            : _startController.text.trim(),
        endLocation: _endController.text.trim().isEmpty
            ? null
            : _endController.text.trim(),
        maxPrice: maxPrice,
        minSeats: _minSeats,
        originLatitude: selectedOrigin?.latitude,
        originLongitude: selectedOrigin?.longitude,
      );

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _loading = false;
      });

      debugPrint('Found ${results.length} rides');
    } catch (e) {
      debugPrint('Error searching rides: $e');
      if (!mounted) return;
      final message = e is StateError
          ? e.message.toString()
          : 'Search failed. Check your connection and sign-in, then try again.';
      setState(() {
        _loading = false;
        _searchError = message;
        _searchResults = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openRideDetails(Ride ride) async {
    final booked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RideDetailsPage(ride: ride)),
    );
    if (booked == true && mounted) {
      _searchRides(); // Refresh seat availability after a booking.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Rides")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // -----------------------------------------------------------------
          // Search form
          // -----------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Where are you going?",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tell us your trip and we'll find a ride for you.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  LocationAutocompleteField(
                    controller: _startController,
                    label: 'From',
                    icon: Icons.trip_origin,
                    placeholder: 'Leaving from…',
                    onSelected: (location, address, city) => setState(() {
                      _startLocation = location;
                      _selectedStartAddress = address;
                    }),
                    onCleared: () => setState(() {
                      _startLocation = null;
                      _selectedStartAddress = null;
                    }),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      onPressed: _swapRoute,
                      tooltip: 'Swap pickup and drop-off',
                      icon: const Icon(Icons.swap_vert, size: 20),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  LocationAutocompleteField(
                    controller: _endController,
                    label: 'To',
                    icon: Icons.place,
                    placeholder: 'Going to…',
                    onSelected: (location, address, city) => setState(() {
                      _endLocation = location;
                      _selectedEndAddress = address;
                    }),
                    onCleared: () => setState(() {
                      _endLocation = null;
                      _selectedEndAddress = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: _selectedDate == null
                              ? 'Any date'
                              : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                          onTap: _selectDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SeatStepper(
                          value: _minSeats,
                          onChanged: (v) => setState(() => _minSeats = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _maxPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Max price per seat (optional)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hasSelectedOrigin && _selectedDate != null
                        ? 'Nearby search: departures within 10 km. '
                              'Destination is still matched by text.'
                        : 'Text search. Select a departure suggestion and a '
                              'date to search departures within 10 km.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _searchRides,
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
          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // Results
          // -----------------------------------------------------------------
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchError != null)
            _EmptyState(
              icon: Icons.error_outline,
              title: 'Search unavailable',
              message: _searchError!,
            )
          else if (!_hasSearched)
            const _EmptyState(
              icon: Icons.search,
              title: 'Search for a ride',
              message:
                  'Enter your trip details above and tap "Search rides" to see available trips.',
            )
          else if (_searchResults.isEmpty)
            const _EmptyState(
              icon: Icons.directions_car,
              title: 'No rides found',
              message: 'Try adjusting your search filters',
            )
          else
            for (final ride in _searchResults)
              _RideCard(ride: ride, onTap: () => _openRideDetails(ride)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private building blocks
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride, required this.onTap});

  final Ride ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final driver = ride.driver;
    final timeUntilDeparture = ride.departureTime.difference(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      driver?.initials ?? 'D',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${ride.originCity.isEmpty ? 'Unknown city' : ride.originCity}"
                          " → ${ride.destinationCity.isEmpty ? 'Unknown city' : ride.destinationCity}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${driver?.displayName ?? 'Driver'} · "
                          "${(driver?.rating ?? 5.0).toStringAsFixed(1)}⭐",
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\$${ride.pricePerSeat.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${ride.availableSeats} seats",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _LocationTag(
                    icon: Icons.trip_origin,
                    text: ride.originAddress,
                  ),
                  _LocationTag(
                    icon: Icons.place,
                    text: ride.destinationAddress,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: AppColors.divider.withValues(alpha: 0.6)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _departsLabel(timeUntilDeparture),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _departsLabel(Duration duration) {
    if (duration.isNegative) return "Departed";
    if (duration.inHours > 0) {
      return "Departs in ${duration.inHours}h ${duration.inMinutes % 60}m";
    }
    return "Departs in ${duration.inMinutes}m";
  }
}

class _LocationTag extends StatelessWidget {
  const _LocationTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 15),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatStepper extends StatelessWidget {
  const _SeatStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Ink(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seats',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: value < 8 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
    );
  }
}
