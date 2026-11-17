import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
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

  AppLocalizations get _strings => AppLocalizations.of(context);

  // Both decimal separators represent the same numeric CAD amount in storage.
  double? get _price =>
      double.tryParse(_priceController.text.trim().replaceAll(',', '.'));

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
          _showMessage(_strings.postInvalidLocations);
          return false;
        }
        return true;
      case 2:
        return true;
      case 3:
        final price = _price;
        if (price == null || price <= 0) {
          _showMessage(_strings.postInvalidPrice);
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
      helpText: _strings.searchPickDate,
    );
    if (picked != null) {
      setState(() => _departureDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
      helpText: _strings.postPickTime,
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
        pricePerSeat: _price!,
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
      debugPrint('Ride publication failed: $e');
      _showMessage(_strings.postFailed);
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
        title: Text(_strings.postPublished),
        content: Text(
          _strings.postPublishedMessage,
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_strings.postGreat),
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
      appBar: AppBar(title: Text(_strings.postTitle)),
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
                        child: Text(_strings.postBack),
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
                            ? _strings.postPublishing
                            : _step == _stepCount
                            ? _strings.postPublish
                            : _strings.postContinue,
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
      1: _strings.postRouteTitle,
      2: _strings.postScheduleTitle,
      3: _strings.postPriceTitle,
      4: _strings.postPoliciesTitle,
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
        title: _strings.postRoute,
        children: [
          LocationAutocompleteField(
            controller: _startController,
            label: _strings.postPickup,
            icon: Icons.trip_origin,
            placeholder: _strings.postPickupHint,
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
            label: _strings.postDropoff,
            icon: Icons.place,
            placeholder: _strings.postDropoffHint,
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
              startLabel: _strings.postPickup,
              endLabel: _strings.postDropoff,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _strings.postMapHint,
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
        title: _strings.postDeparture,
        children: [
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today,
                  label: _strings.searchDate,
                  value: _formatDate(_departureDate),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.access_time,
                  label: _strings.postTime,
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
        title: _strings.postSeatsPricing,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 400;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: narrow ? constraints.maxWidth : 190,
                    child: _SeatStepper(
                      value: _seats,
                      onChanged: (v) => setState(() => _seats = v),
                    ),
                  ),
                  SizedBox(
                    width: narrow
                        ? constraints.maxWidth
                        : constraints.maxWidth - 206,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,4}([.,]\d{0,2})?$'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: _strings.postPricePerSeat,
                        prefixIcon: const Icon(Icons.attach_money),
                        hintText: _strings.postPriceHint,
                      ),
                    ),
                  ),
                ],
              );
            },
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
        title: _strings.detailsVehicle,
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
          _ResponsiveFieldPair(
            first: TextField(
              controller: _makeController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _strings.postMake,
                hintText: _strings.postMakeHint,
              ),
            ),
            second: TextField(
              controller: _modelController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _strings.postModel,
                hintText: _strings.postModelHint,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ResponsiveFieldPair(
            first: TextField(
              controller: _colorController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _strings.postColor,
                hintText: _strings.postColorHint,
              ),
            ),
            second: TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: _strings.postYear,
                hintText: _strings.postYearHint,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: _strings.postPlate,
              hintText: _strings.postPlateHint,
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
        title: _strings.postRidePolicies,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_strings.postInstantBooking),
            subtitle: Text(_strings.postInstantExplanation),
            value: _instantBooking,
            onChanged: (v) => setState(() => _instantBooking = v),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_strings.postPetsAllowed),
            subtitle: Text(_strings.postPetsExplanation),
            value: _petsAllowed,
            onChanged: (v) => setState(() => _petsAllowed = v),
          ),
          const SizedBox(height: 8),
          Text(
            _strings.postLuggageSpace,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
            onChanged: (_) => setState(() {}),
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: _strings.postNotes,
              alignLabelWithHint: true,
              hintText: _strings.postNotesHint,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildPolicySummary() {
    final summary = [
      _strings.postSummaryBooking(
        _instantBooking
            ? _strings.postBookingInstant
            : _strings.postBookingApproval,
      ),
      _strings.postSummaryPets(
        _petsAllowed
            ? _strings.detailsPetsAllowed
            : _strings.detailsPetsNotAllowed,
      ),
      _strings.postSummaryLuggage(_luggagePolicyLabel(_luggagePolicy)),
      if (_notesController.text.trim().isNotEmpty)
        _strings.postSummaryNotes(_notesController.text.trim()),
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
            Row(
              children: [
                const Icon(Icons.verified, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _strings.postReady,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
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

  String _luggagePolicyLabel(String policy) {
    switch (policy) {
      case 'none':
        return _strings.postLuggageNone;
      case 'small':
        return _strings.postLuggageSmall;
      case 'large':
        return _strings.postLuggageLarge;
      default:
        return _strings.postLuggageStandard;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
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
              flex: 3,
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
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
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
                    _label(context, i),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: i == current
                          ? FontWeight.w700
                          : FontWeight.w500,
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

  static String _label(BuildContext context, int step) {
    final strings = AppLocalizations.of(context);
    switch (step) {
      case 1:
        return strings.postRoute;
      case 2:
        return strings.postSchedule;
      case 3:
        return strings.postPricing;
      default:
        return strings.postPolicies;
    }
  }
}

class _ResponsiveFieldPair extends StatelessWidget {
  const _ResponsiveFieldPair({required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 400;
      final width = narrow
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(width: width, child: first),
          SizedBox(width: width, child: second),
        ],
      );
    },
  );
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
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
  const _RoutePreviewMap({
    required this.start,
    required this.end,
    required this.startLabel,
    required this.endLabel,
  });

  final MapLocation start;
  final MapLocation end;
  final String startLabel;
  final String endLabel;

  @override
  State<_RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends State<_RoutePreviewMap> {
  AppMapController? _controller;

  @override
  void didUpdateWidget(_RoutePreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start ||
        oldWidget.end != widget.end ||
        oldWidget.startLabel != widget.startLabel ||
        oldWidget.endLabel != widget.endLabel) {
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
        label: widget.startLabel,
        colorHex: '#10B981',
      ),
    );
    await controller.addMarker(
      MapMarkerData(
        id: 'dropoff',
        location: widget.end,
        label: widget.endLabel,
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
      // This preview is only 220 px high: keep room between both margins.
      padding: 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child:
            AppMaps.createView(
              MapViewConfig(
                initialCenter: widget.start,
                initialZoom: 12,
                showUserLocation: false,
              ),
            ).build(
              onMapCreated: (controller) {
                _controller = controller;
                _draw();
              },
            ),
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
      tooltip: AppLocalizations.of(context).searchSwap,
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
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
          Text(switch (type) {
            'sedan' => AppLocalizations.of(context).detailsSedan,
            'suv' => AppLocalizations.of(context).detailsSuv,
            'van' => AppLocalizations.of(context).detailsVan,
            _ => type,
          }),
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
      label: Text(_label(context)),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }

  String _label(BuildContext context) {
    final strings = AppLocalizations.of(context);
    switch (policy) {
      case 'none':
        return strings.postLuggageNone;
      case 'small':
        return strings.postLuggageSmall;
      case 'large':
        return strings.postLuggageLarge;
      default:
        return strings.postLuggageStandard;
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
            tooltip: AppLocalizations.of(context).searchFewerSeats,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).searchSeats,
                  style: const TextStyle(
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
            tooltip: AppLocalizations.of(context).searchMoreSeats,
            onTap: value < 8 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
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
          label: Text(
            NumberFormat.simpleCurrency(
              locale: Localizations.localeOf(context).toLanguageTag(),
              name: 'CAD',
              decimalDigits: 0,
            ).format(int.parse(price)),
          ),
          avatar: const Icon(Icons.bolt, size: 16),
          onPressed: () => onSelected(price),
        );
      }).toList(),
    );
  }
}
