import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../maps/app_maps.dart';
import '../maps/map_controller.dart';
import '../maps/map_types.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_autocomplete_field.dart';

/// Step-by-step ride publishing flow.
///
///   1. Route        — pickup/drop-off via location autocomplete; the map
///                     preview only appears once both addresses are selected.
///   2. Schedule     — departure date and time.
///   3. Seats & cost — available seats, price per seat, vehicle details.
///   4. Policies     — pets, luggage, notes, then publish.
///
/// Publishing persists the ride directly to Supabase under the signed-in
/// user's ownership.
class PostRidePage extends StatefulWidget {
  const PostRidePage({super.key});

  @override
  State<PostRidePage> createState() => _PostRidePageState();
}

class _PostRidePageState extends State<PostRidePage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _priceController = TextEditingController();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();
  final _yearController = TextEditingController();

  MapLocation? _startLocation;
  MapLocation? _endLocation;
  String _originCity = '';
  String _destinationCity = '';

  DateTime _departureDate = _defaultDate();
  TimeOfDay _departureTime = _defaultTime();
  String _vehicleType = 'sedan';
  int _seats = 3;
  bool _petsAllowed = false;
  bool _instantBooking = false;
  String _luggagePolicy = 'moderate';

  int _step = 1;
  bool _publishing = false;

  static const int _stepCount = 4;

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
  void initState() {
    super.initState();
    _prefillVehicleDetails();
  }

  /// Pre-fills the vehicle section from the driver's saved profile so repeat
  /// postings are fast.
  Future<void> _prefillVehicleDetails() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final profile = await _dbService.getUserProfile(userId);
    if (profile == null || !mounted) return;

    _makeController.text = profile.vehicleMake ?? '';
    _modelController.text = profile.vehicleModel ?? '';
    _colorController.text = profile.vehicleColor ?? '';
    _plateController.text = profile.vehiclePlate ?? '';
    _yearController.text = profile.vehicleYear?.toString() ?? '';
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _priceController.dispose();
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation between steps
  // ---------------------------------------------------------------------------

  bool _validateStep(int step) {
    switch (step) {
      case 1:
        if (_startLocation == null ||
            _endLocation == null ||
            _originCity.isEmpty ||
            _destinationCity.isEmpty) {
          _showMessage(
            'Select locations with a recognized municipality from the suggestions',
          );
          return false;
        }
        return true;
      case 2:
        return true;
      case 3:
        final price = double.tryParse(_priceController.text.trim());
        if (price == null || price <= 0) {
          _showMessage('Enter a valid price per seat');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep(_step)) return;
    FocusScope.of(context).unfocus();
    setState(() => _step++);
  }

  void _previousStep() {
    setState(() => _step = _step > 1 ? _step - 1 : _step);
  }

  void _swapRoute() {
    final fromText = _startController.text;
    final toText = _endController.text;
    final fromLocation = _startLocation;
    final toLocation = _endLocation;
    final fromCity = _originCity;
    final toCity = _destinationCity;

    setState(() {
      _startController.text = toText;
      _endController.text = fromText;
      _startLocation = toLocation;
      _endLocation = fromLocation;
      _originCity = toCity;
      _destinationCity = fromCity;
    });
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
  // Publish
  // ---------------------------------------------------------------------------

  Future<void> _publish() async {
    if (!_validateStep(3)) return;
    FocusScope.of(context).unfocus();
    setState(() => _publishing = true);

    try {
      final departure = DateTime(
        _departureDate.year,
        _departureDate.month,
        _departureDate.day,
        _departureTime.hour,
        _departureTime.minute,
      );

      await _dbService.createRide(
        originCity: _originCity,
        originAddress: _startController.text.trim(),
        startLat: _startLocation!.latitude,
        startLng: _startLocation!.longitude,
        destinationCity: _destinationCity,
        destinationAddress: _endController.text.trim(),
        endLat: _endLocation!.latitude,
        endLng: _endLocation!.longitude,
        departureTime: departure,
        availableSeats: _seats,
        pricePerSeat: double.parse(_priceController.text.trim()),
        vehicleType: _vehicleType,
        vehiclePlate: _plateController.text.trim().isEmpty
            ? null
            : _plateController.text.trim(),
        vehicleMake: _makeController.text.trim().isEmpty
            ? null
            : _makeController.text.trim(),
        vehicleModel: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        vehicleColor: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        vehicleYear: int.tryParse(_yearController.text.trim()),
        petsAllowed: _petsAllowed,
        luggagePolicy: _luggagePolicy,
        instantBooking: _instantBooking,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      await _showPublishedConfirmation();
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not post ride: $e');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _showPublishedConfirmation() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 56,
        ),
        title: const Text('Ride published!'),
        content: const Text(
          'Your ride is now live. Passengers can find it in search and book '
          'a seat right away.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Great'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _startController.clear();
    _endController.clear();
    _priceController.clear();
    _plateController.clear();
    _makeController.clear();
    _modelController.clear();
    _colorController.clear();
    _notesController.clear();
    _yearController.clear();
    setState(() {
      _step = 1;
      _startLocation = null;
      _endLocation = null;
      _originCity = '';
      _destinationCity = '';
      _departureDate = _defaultDate();
      _departureTime = _defaultTime();
      _vehicleType = 'sedan';
      _seats = 3;
      _petsAllowed = false;
      _instantBooking = false;
      _luggagePolicy = 'moderate';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a ride')),
      body: SafeArea(
        child: Column(
          children: [
            _StepIndicator(current: _step, count: _stepCount),
            const Divider(height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: ListView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _stepTitle(context),
                    const SizedBox(height: 16),
                    ..._buildStepContent(),
                    const SizedBox(height: 16),
                    if (_step == _stepCount) _buildPolicySummary(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _publishing ? null : _previousStep,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _publishing
                          ? null
                          : _step == _stepCount
                              ? _publish
                              : _nextStep,
                      icon: _publishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _step == _stepCount
                                  ? Icons.rocket_launch
                                  : Icons.arrow_forward,
                            ),
                      label: Text(
                        _publishing
                            ? 'Publishing…'
                            : _step == _stepCount
                                ? 'Publish ride'
                                : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTitle(BuildContext context) {
    final titles = {
      1: 'Where is your route?',
      2: 'When are you departing?',
      3: 'Seats, price & vehicle',
      4: 'Trip policies',
    };
    return Text(
      titles[_step] ?? '',
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  List<Widget> _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildRouteStep();
      case 2:
        return _buildScheduleStep();
      case 3:
        return _buildSeatsPriceStep();
      case 4:
        return _buildPoliciesStep();
      default:
        return const [SizedBox.shrink()];
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Route
  // ---------------------------------------------------------------------------

  List<Widget> _buildRouteStep() {
    return [
      _SectionCard(
        icon: Icons.alt_route,
        title: 'Route',
        children: [
          LocationAutocompleteField(
            controller: _startController,
            label: 'Pickup',
            icon: Icons.trip_origin,
            placeholder: 'Where are you leaving from?',
            onSelected: (location, address, city) => setState(() {
              _startLocation = location;
              _originCity = city ?? '';
            }),
            onCleared: () => setState(() {
              _startLocation = null;
              _originCity = '';
            }),
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
            onSelected: (location, address, city) => setState(() {
              _endLocation = location;
              _destinationCity = city ?? '';
            }),
            onCleared: () => setState(() {
              _endLocation = null;
              _destinationCity = '';
            }),
          ),
          if (_startLocation != null && _endLocation != null) ...[
            const SizedBox(height: 12),
            _RoutePreviewMap(
              start: _startLocation!,
              end: _endLocation!,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select both locations to preview the route on the map.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Schedule
  // ---------------------------------------------------------------------------

  List<Widget> _buildScheduleStep() {
    return [
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
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: _departureTime.format(context),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Step 3 — Seats, price & vehicle
  // ---------------------------------------------------------------------------

  List<Widget> _buildSeatsPriceStep() {
    return [
      _SectionCard(
        icon: Icons.event_seat,
        title: 'Seats & pricing',
        children: [
          Row(
            children: [
              Expanded(
                child: _SeatStepper(
                  value: _seats,
                  onChanged: (v) => setState(() => _seats = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _priceController,
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PriceSuggestions(
            onSelected: (price) => _priceController.text = price,
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
                onSelected: () => setState(() => _vehicleType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _makeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Make (optional)',
                    hintText: 'e.g. Toyota',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _modelController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Model (optional)',
                    hintText: 'e.g. Corolla',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _colorController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Color (optional)',
                    hintText: 'e.g. White',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Year (optional)',
                    hintText: 'e.g. 2022',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Plate (optional)',
              hintText: 'e.g. ABC 123',
            ),
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Step 4 — Policies
  // ---------------------------------------------------------------------------

  List<Widget> _buildPoliciesStep() {
    return [
      _SectionCard(
        icon: Icons.rule,
        title: 'Ride policies',
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Instant booking'),
            subtitle: const Text(
              'Passengers book immediately. Turn off to review and approve '
              'each booking request first.',
            ),
            value: _instantBooking,
            onChanged: (v) => setState(() => _instantBooking = v),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pets allowed'),
            subtitle: const Text(
              'Allow passengers to bring well-behaved pets',
            ),
            value: _petsAllowed,
            onChanged: (v) => setState(() => _petsAllowed = v),
          ),
          const SizedBox(height: 8),
          Text('Luggage space',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const ['none', 'small', 'moderate', 'large'].map((p) {
              return _LuggageChip(
                policy: p,
                selected: _luggagePolicy == p,
                onSelected: () => setState(() => _luggagePolicy = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Notes for passengers (optional)',
              alignLabelWithHint: true,
              hintText: 'e.g. music, luggage, stops along the way',
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildPolicySummary() {
    final summary = [
      'Booking: ${_instantBooking ? 'instant' : 'driver approval'}',
      'Pets: ${_petsAllowed ? 'allowed' : 'not allowed'}',
      'Luggage: ${_luggagePolicyLabel(_luggagePolicy)}',
      if (_notesController.text.trim().isNotEmpty)
        'Notes: ${_notesController.text.trim()}',
    ].join('\n');

    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Ready to publish',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(summary, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  static String _luggagePolicyLabel(String policy) {
    switch (policy) {
      case 'none':
        return 'no luggage';
      case 'small':
        return 'small bags';
      case 'large':
        return 'large items';
      default:
        return 'standard';
    }
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
// Shared building blocks
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          for (var i = 1; i <= count; i++) ...[
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= current
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                    child: Center(
                      child: i < current
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : Text(
                              '$i',
                              style: TextStyle(
                                color: i <= current
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _label(i),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                      color: i <= current
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (i < count)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 22),
                  color: i < current ? AppColors.primary : AppColors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _label(int step) {
    switch (step) {
      case 1:
        return 'Route';
      case 2:
        return 'Schedule';
      case 3:
        return 'Seats & price';
      default:
        return 'Policies';
    }
  }
}

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

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  final String type;
  final bool selected;
  final VoidCallback onSelected;

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
      onSelected: (_) => onSelected(),
    );
  }
}

class _LuggageChip extends StatelessWidget {
  const _LuggageChip({
    required this.policy,
    required this.selected,
    required this.onSelected,
  });

  final String policy;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(_label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }

  String get _label {
    switch (policy) {
      case 'none':
        return 'None';
      case 'small':
        return 'Small';
      case 'large':
        return 'Large';
      default:
        return 'Standard';
    }
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seats',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
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
