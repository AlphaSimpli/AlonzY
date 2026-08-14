import 'package:flutter/material.dart';

import '../maps/map_types.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_autocomplete_field.dart';

/// Ride search with a standard rideshare flow.
///
/// The user fills in Origin, Destination, Date and Seats using live location
/// autocomplete, then taps "Search rides" to query available rides. Results are
/// listed inline below the search form. The map is never opened implicitly:
/// it only appears once a real address has been selected by the user.
class SearchRidesPage extends StatefulWidget {
  const SearchRidesPage({super.key});

  @override
  State<SearchRidesPage> createState() => _SearchRidesPageState();
}

class _SearchRidesPageState extends State<SearchRidesPage> {
  final DatabaseService _dbService = DatabaseService();

  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _maxPriceController = TextEditingController();

  MapLocation? _startLocation;
  MapLocation? _endLocation;

  DateTime? _selectedDate;
  int _minSeats = 1;

  List<Map<String, dynamic>> _searchResults = [];
  bool _loading = false;
  bool _hasSearched = false;

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

    setState(() {
      _startController.text = toText;
      _endController.text = fromText;
      _startLocation = toLocation;
      _endLocation = fromLocation;
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
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      // Use just the date part (at midnight) to include all rides from the
      // selected day onwards.
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
        minSeats: _minSeats,
      );

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _loading = false;
      });

      debugPrint("✅ Found ${results.length} rides");
    } catch (e) {
      debugPrint("❌ Error searching rides: $e");
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error searching: $e")),
      );
    }
  }

  void _showBookingDialog(BuildContext context, Map<String, dynamic> ride) {
    int seatsToBook = 1;
    final availableSeats = (ride['available_seats'] as num?)?.toInt() ?? 1;
    final pricePerSeat = (ride['price_per_seat'] as num?)?.toDouble() ?? 0;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Book Ride"),
        content: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${ride['start_location']} → ${ride['end_location']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Seats:"),
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
                        Text("$seatsToBook"),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (seatsToBook < availableSeats) {
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
                  "Total: \$${(pricePerSeat * seatsToBook).toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final totalPrice = pricePerSeat * seatsToBook;
                final bookingId = await _dbService.createBooking(
                  rideId: ride['id'],
                  seatsBooked: seatsToBook,
                  totalPrice: totalPrice,
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("✅ Booking confirmed! ID: $bookingId")),
                );
                _searchRides(); // Refresh search results
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Booking failed: $e")),
                );
              }
            },
            child: const Text("Book Now"),
          ),
        ],
      ),
    );
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
                    onSelected: (location, address) =>
                        setState(() => _startLocation = location),
                    onCleared: () => setState(() => _startLocation = null),
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
                    onSelected: (location, address) =>
                        setState(() => _endLocation = location),
                    onCleared: () => setState(() => _endLocation = null),
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
          else if (!_hasSearched)
            _EmptyState(
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
              _RideCard(
                ride: ride,
                onBook: () => _showBookingDialog(context, ride),
              ),
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
  const _RideCard({required this.ride, required this.onBook});

  final Map<String, dynamic> ride;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final driver = ride['profiles'] is Map
        ? Map<String, dynamic>.from(ride['profiles'] as Map)
        : <String, dynamic>{};
    final departureTime =
        DateTime.tryParse(ride['departure_time']?.toString() ?? '');
    final timeUntilDeparture =
        departureTime?.difference(DateTime.now());
    final price = (ride['price_per_seat'] as num?)?.toDouble() ?? 0;
    final seats = (ride['available_seats'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[300],
          child: const Icon(Icons.directions_car, color: Colors.white),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${ride['start_location']} → ${ride['end_location']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (timeUntilDeparture != null)
                    Text(
                      "Departs in ${_formatDuration(timeUntilDeparture)}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "\$${price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$seats seats",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "${driver['first_name'] ?? 'Driver'} "
                      "(${driver['rating'] ?? 5.0}⭐)",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text("Book"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    if (duration.isNegative) return "Departed";
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes % 60}m";
    }
    return "${duration.inMinutes}m";
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