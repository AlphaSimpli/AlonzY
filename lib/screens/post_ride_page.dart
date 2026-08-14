import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../maps/app_maps.dart';
import '../maps/map_controller.dart';
import '../maps/map_types.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_autocomplete_field.dart';

/// Post a ride offer.
///
/// Designed for frictionless data entry:
/// - Route locations are typed in with live autocomplete; the map only shows
///   a route preview once both addresses have been selected.
/// - Sensible defaults pre-filled (departure tomorrow, 3 seats, sedan).
/// - Structured sections with clear grouping and inline validation.
class PostRidePage extends StatefulWidget {
  const PostRidePage({super.key});

  @override
  State<PostRidePage> createState() => _PostRidePageState();
}

class _PostRidePageState extends State<PostRidePage> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _priceController = TextEditingController();
  final _plateController = TextEditingController();
  final _notesController = TextEditingController();

  MapLocation? _startLocation;
  MapLocation? _endLocation;

  DateTime _departureDate = _defaultDate();
  TimeOfDay _departureTime = _defaultTime();
  String _vehicleType = 'sedan';
  int _seats = 3;

  bool _loading = false;

  static DateTime _defaultDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  static TimeOfDay _defaultTime() {
    final now = DateTime.now().add(const Duration(hours: 1));
    return TimeOfDay(hour: now.hour, minute: 0);
  }

  static const List<String> _vehicleTypes = ['sedan', 'suv', 'van'];

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _priceController.dispose();
    _plateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Route picking
  // ---------------------------------------------------------------------------

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

  String? _validateLocation(MapLocation? location, String label) {
    if (location == null) {
      return 'Select a $label location from the suggestions';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Schedule
  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pick a departure date',
    );
    if (picked != null) {
      setState(() => _departureDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
      helpText: 'Pick a departure time',
    );
    if (picked != null) {
      setState(() => _departureTime = picked);
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final start = _startLocation;
    final end = _endLocation;
    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a pickup and drop-off location first'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final departure = DateTime(
        _departureDate.year,
        _departureDate.month,
        _departureDate.day,
        _departureTime.hour,
        _departureTime.minute,
      );

      await _dbService.createRide(
        startLocation: _startController.text.trim(),
        startLat: start.latitude,
        startLng: start.longitude,
        endLocation: _endController.text.trim(),
        endLat: end.latitude,
        endLng: end.longitude,
        departureTime: departure,
        availableSeats: _seats,
        pricePerSeat: double.parse(_priceController.text),
        vehicleType: _vehicleType,
        vehiclePlate: _plateController.text.trim().isEmpty
            ? null
            : _plateController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride posted successfully')),
      );
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post ride: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _startController.clear();
    _endController.clear();
    _priceController.clear();
    _plateController.clear();
    _notesController.clear();
    setState(() {
      _startLocation = null;
      _endLocation = null;
      _departureDate = _defaultDate();
      _departureTime = _defaultTime();
      _vehicleType = 'sedan';
      _seats = 3;
    });
    _formKey.currentState?.reset();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a ride')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SectionCard(
                icon: Icons.alt_route,
                title: 'Route',
                children: [
                  LocationAutocompleteField(
                    controller: _startController,
                    label: 'Pickup',
                    icon: Icons.trip_origin,
                    placeholder: 'Where are you leaving from?',
                    onSelected: (location, address) =>
                        setState(() => _startLocation = location),
                    onCleared: () => setState(() => _startLocation = null),
                    validator: (_) => _validateLocation(_startLocation, 'pickup'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        _SwapButton(onTap: _swapRoute),
                      ],
                    ),
                  ),
                  LocationAutocompleteField(
                    controller: _endController,
                    label: 'Drop-off',
                    icon: Icons.place,
                    placeholder: 'Where are you going?',
                    onSelected: (location, address) =>
                        setState(() => _endLocation = location),
                    onCleared: () => setState(() => _endLocation = null),
                    validator: (_) =>
                        _validateLocation(_endLocation, 'drop-off'),
                  ),
                  if (_startLocation != null && _endLocation != null) ...[
                    const SizedBox(height: 12),
                    _RoutePreviewMap(
                      start: _startLocation!,
                      end: _endLocation!,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.schedule,
                title: 'Departure',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: _formatDate(_departureDate),
                          onTap: _loading ? null : _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: _departureTime.format(context),
                          onTap: _loading ? null : _pickTime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.directions_car,
                title: 'Vehicle',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _vehicleTypes.map((type) {
                      return _VehicleChip(
                        type: type,
                        selected: _vehicleType == type,
                        onSelected: _loading
                            ? null
                            : () => setState(() => _vehicleType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _plateController,
                    enabled: !_loading,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle plate (optional)',
                      prefixIcon: Icon(Icons.confirmation_number),
                      hintText: 'e.g. ABC 123',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.event_seat,
                title: 'Ride details',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SeatStepper(
                          value: _seats,
                          onChanged: _loading
                              ? null
                              : (v) => setState(() => _seats = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _priceController,
                          enabled: !_loading,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,4}(\.\d{0,2})?'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Price per seat',
                            prefixIcon: Icon(Icons.attach_money),
                            hintText: '0.00',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return 'Enter a price';
                            final price = double.tryParse(text);
                            if (price == null || price <= 0) {
                              return 'Enter a valid price';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PriceSuggestions(
                    onSelected: (price) {
                      if (_loading) return;
                      _priceController.text = price;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    enabled: !_loading,
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      alignLabelWithHint: true,
                      hintText: 'e.g. music, luggage, stops along the way',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.rocket_launch),
                label: Text(_loading ? 'Posting…' : 'Post ride'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Private building blocks
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Map preview of the selected route. Only rendered once both the pickup and
/// drop-off addresses have been picked from the autocomplete suggestions.
class _RoutePreviewMap extends StatefulWidget {
  const _RoutePreviewMap({required this.start, required this.end});

  final MapLocation start;
  final MapLocation end;

  @override
  State<_RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends State<_RoutePreviewMap> {
  AppMapController? _controller;

  @override
  void didUpdateWidget(_RoutePreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _draw();
    }
  }

  Future<void> _draw() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.clear();
    await controller.addMarker(
      MapMarkerData(
        id: 'pickup',
        location: widget.start,
        label: 'Pickup',
        colorHex: '#10B981',
      ),
    );
    await controller.addMarker(
      MapMarkerData(
        id: 'dropoff',
        location: widget.end,
        label: 'Drop-off',
        colorHex: '#EF4444',
      ),
    );
    await controller.addPolyline(
      MapPolylineData(
        points: [widget.start, widget.end],
        colorHex: '#4F46E5',
        width: 4,
      ),
    );
    await controller.animateToBounds(
      [widget.start, widget.end],
      padding: 120,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: AppMaps.createView(
          MapViewConfig(
            initialCenter: widget.start,
            initialZoom: 12,
            showUserLocation: false,
          ),
        ).build(onMapCreated: (controller) {
          _controller = controller;
          _draw();
        }),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      tooltip: 'Swap pickup and drop-off',
      icon: const Icon(Icons.swap_vert, size: 20),
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
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
  final VoidCallback? onTap;

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

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  final String type;
  final bool selected;
  final VoidCallback? onSelected;

  static const Map<String, IconData> _icons = {
    'sedan': Icons.directions_car,
    'suv': Icons.directions_car_filled,
    'van': Icons.airport_shuttle,
  };

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[type], size: 18),
          const SizedBox(width: 6),
          Text(type[0].toUpperCase() + type.substring(1)),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected?.call(),
    );
  }
}

class _SeatStepper extends StatelessWidget {
  const _SeatStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            onTap: (value > 1 && onChanged != null)
                ? () => onChanged!(value - 1)
                : null,
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
            onTap: (value < 8 && onChanged != null)
                ? () => onChanged!(value + 1)
                : null,
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

class _PriceSuggestions extends StatelessWidget {
  const _PriceSuggestions({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: ['5', '10', '15', '20'].map((price) {
        return ActionChip(
          label: Text('\$$price'),
          avatar: const Icon(Icons.bolt, size: 16),
          onPressed: () => onSelected(price),
        );
      }).toList(),
    );
  }
}