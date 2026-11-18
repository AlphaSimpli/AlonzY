import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../maps/map_types.dart';
import '../models/ride.dart';
import '../services/database_service.dart';
import '../services/osrm_service.dart';
import '../services/ride_routing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_autocomplete_field.dart';
import 'ride_details_page.dart';

/// Ride search with a standard rideshare flow.
///
/// The user fills in Origin, Destination, Date and Seats using live location
/// autocomplete, then taps "Search rides" to query available rides. Results are
/// listed inline, sorted by departure time in normal mode, or additional road
/// distance in explicitly enabled OSRM mode. Tapping a ride opens its detail
/// page (route preview, driver profile, policies) for booking. The map is
/// never opened implicitly: it only appears on the detail page once a real
/// address has been selected.
class SearchRidesPage extends StatefulWidget {
  const SearchRidesPage({super.key, this.databaseService, this.routingService});

  final DatabaseService? databaseService;
  final RideRoutingService? routingService;

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
  bool _useRoadRouting = false;
  bool _routingInProgress = false;
  RoutedRideSearch? _routedResults;
  RideRoutingService? _ownedRoutingService;

  RideRoutingService get _router =>
      widget.routingService ?? (_ownedRoutingService ??= RideRoutingService());

  // Comparing the selected address with the current text also protects against
  // stale coordinates after swapping the fields and then editing their text.
  bool get _hasSelectedOrigin =>
      _startLocation != null && _selectedStartAddress == _startController.text;
  bool get _hasSelectedDestination =>
      _endLocation != null && _selectedEndAddress == _endController.text;

  @override
  void dispose() {
    _ownedRoutingService?.close();
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
      helpText: AppLocalizations.of(context).searchPickDate,
    );
    if (picked != null && mounted) {
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
        SnackBar(
          content: Text(AppLocalizations.of(context).searchInvalidPrice),
        ),
      );
      return;
    }
    final selectedOrigin = _hasSelectedOrigin ? _startLocation : null;
    final selectedDestination = _hasSelectedDestination ? _endLocation : null;
    final useRoadRouting = _useRoadRouting;
    if (useRoadRouting &&
        (selectedOrigin == null ||
            selectedDestination == null ||
            _selectedDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).searchRoadRequired),
        ),
      );
      return;
    }
    // Snapshot inputs before the asynchronous database/routing work begins.
    final originText = _startController.text.trim();
    final destinationText = _endController.text.trim();
    final minSeats = _minSeats;
    final date = _selectedDate;
    setState(() {
      _loading = true;
      _hasSearched = true;
      _searchError = null;
      _searchResults = [];
      _routedResults = null;
      _routingInProgress = false;
    });

    try {
      final dateTime = date == null
          ? null
          : DateTime(date.year, date.month, date.day);

      final results = await _dbService.searchRides(
        afterDate: dateTime,
        startLocation: originText.isEmpty ? null : originText,
        // PostGIS supplies nearby origins. OSRM replaces the destination TEXT
        // filter only in road mode, allowing actual pickup/dropoff detours.
        endLocation: useRoadRouting || destinationText.isEmpty
            ? null
            : destinationText,
        maxPrice: maxPrice,
        minSeats: minSeats,
        originLatitude: selectedOrigin?.latitude,
        originLongitude: selectedOrigin?.longitude,
      );

      if (!mounted) return;
      RoutedRideSearch? routed;
      if (useRoadRouting) {
        setState(() => _routingInProgress = true);
        routed = await _router.rank(
          candidates: results,
          pickup: OsrmCoordinate(
            selectedOrigin!.latitude,
            selectedOrigin.longitude,
          ),
          dropoff: OsrmCoordinate(
            selectedDestination!.latitude,
            selectedDestination.longitude,
          ),
          isCancelled: () => !mounted,
        );
        if (!mounted) return;
      }
      setState(() {
        _searchResults = routed == null
            ? results
            : routed.rides.map((result) => result.ride).toList();
        _routedResults = routed;
        _loading = false;
        _routingInProgress = false;
      });

      debugPrint(
        'Found ${_searchResults.length} rides${useRoadRouting ? ' (OSRM)' : ''}',
      );
    } catch (e) {
      // No coordinates or request URLs in routing diagnostics.
      debugPrint(
        'Search failed (${e is OsrmException ? e.code : e.runtimeType})',
      );
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      // Keep the diagnostic in the log, not in a user-facing untranslated error.
      final message =
          e is StateError &&
              e.message ==
                  'More than 100 nearby offers. Narrow the date, price or seat filters.'
          ? strings.searchTooMany
          : e is OsrmException
          ? e.code == 'tooManyCandidates'
                ? strings.searchRoadTooMany(RideRoutingService.maxCandidates)
                : strings.searchRoadFailed
          : strings.searchFailed;
      setState(() {
        _loading = false;
        _searchError = message;
        _searchResults = [];
        _routedResults = null;
        _routingInProgress = false;
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
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.searchTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // -----------------------------------------------------------------
          // Search form
          // -----------------------------------------------------------------
          Card(
            child: AbsorbPointer(
              absorbing: _loading,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.searchHeading,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.searchIntroduction,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    LocationAutocompleteField(
                      controller: _startController,
                      label: strings.searchFrom,
                      icon: Icons.trip_origin,
                      placeholder: strings.searchFromHint,
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
                        tooltip: strings.searchSwap,
                        icon: const Icon(Icons.swap_vert, size: 20),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    LocationAutocompleteField(
                      controller: _endController,
                      label: strings.searchTo,
                      icon: Icons.place,
                      placeholder: strings.searchToHint,
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
                            label: strings.searchDate,
                            value: _selectedDate == null
                                ? strings.searchAnyDate
                                : MaterialLocalizations.of(
                                    context,
                                  ).formatMediumDate(_selectedDate!),
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
                      decoration: InputDecoration(
                        labelText: strings.searchMaxPrice,
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _useRoadRouting
                          ? strings.searchRoadNearbyHint
                          : _hasSelectedOrigin && _selectedDate != null
                          ? strings.searchNearbyHint
                          : strings.searchTextHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.searchRoadToggle),
                      value: _useRoadRouting,
                      onChanged: _loading
                          ? null
                          : (value) => setState(() {
                              _useRoadRouting = value;
                              // Do not leave badges/results from a different mode visible.
                              _hasSearched = false;
                              _searchResults = [];
                              _routedResults = null;
                              _searchError = null;
                            }),
                    ),
                    if (_useRoadRouting)
                      Text(
                        strings.searchRoadHelp(
                          RideRoutingService.maxCandidates,
                          RideRoutingService.maxExtraDistanceKm,
                        ),
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
                      label: Text(
                        _routingInProgress
                            ? strings.searchRoadLoading
                            : _loading
                            ? strings.searchLoading
                            : strings.searchSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // Results
          // -----------------------------------------------------------------
          if (!_loading && _routedResults != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                strings.searchRoadResults(
                  _routedResults!.rides.length,
                  _routedResults!.excludedCount,
                ),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchError != null)
            _EmptyState(
              icon: Icons.error_outline,
              title: strings.searchUnavailable,
              message: _searchError!,
            )
          else if (!_hasSearched)
            _EmptyState(
              icon: Icons.search,
              title: strings.searchInitialTitle,
              message: strings.searchInitialMessage,
            )
          else if (_searchResults.isEmpty)
            _EmptyState(
              icon: Icons.directions_car,
              title: strings.searchEmptyTitle,
              message: _routedResults == null
                  ? strings.searchEmptyMessage
                  : strings.searchRoadEmpty,
            )
          else
            for (final ride in _searchResults)
              _RideCard(
                ride: ride,
                detour: _routedResults?.rides
                    .where((result) => identical(result.ride, ride))
                    .firstOrNull
                    ?.detour,
                onTap: () => _openRideDetails(ride),
              ),
          if (_useRoadRouting || _routedResults != null) ...[
            const SizedBox(height: 16),
            SelectableText(
              strings.searchRoadAttribution,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
  const _RideCard({required this.ride, required this.onTap, this.detour});

  final Ride ride;
  final VoidCallback onTap;
  final OsrmDetourEstimate? detour;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final driver = ride.driver;
    final hasDriverName =
        (driver?.firstName?.trim().isNotEmpty ?? false) ||
        (driver?.lastName?.trim().isNotEmpty ?? false);
    final price = NumberFormat.currency(
      locale: strings.localeName == 'fr' ? 'fr_CA' : 'en_CA',
      name: 'CAD',
      symbol: '\$',
    ).format(ride.pricePerSeat);
    final rating = NumberFormat(
      '0.0',
      strings.localeName,
    ).format(driver?.rating ?? 5.0);
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
                      hasDriverName
                          ? driver!.initials
                          : strings.searchDriverInitial,
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
                          "${ride.originCity.isEmpty ? strings.searchUnknownCity : ride.originCity}"
                          " → ${ride.destinationCity.isEmpty ? strings.searchUnknownCity : ride.destinationCity}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${hasDriverName ? driver!.displayName : strings.searchDriver} · "
                          "$rating⭐",
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
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.searchAvailableSeats(ride.availableSeats),
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
              if (detour != null) ...[
                Text(
                  strings.searchRoadDetour(
                    NumberFormat(
                      '0.0',
                      strings.localeName,
                    ).format(detour!.extraDistanceKm),
                    detour!.extraDurationMinutes.ceil(),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
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
                      _departsLabel(strings, timeUntilDeparture),
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

  static String _departsLabel(AppLocalizations strings, Duration duration) {
    if (duration.isNegative) return strings.searchDeparted;
    if (duration.inHours > 0) {
      return strings.searchDepartsHours(
        duration.inHours,
        duration.inMinutes % 60,
      );
    }
    return strings.searchDepartsMinutes(duration.inMinutes);
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

class _SeatStepper extends StatelessWidget {
  const _SeatStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
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
            tooltip: strings.searchFewerSeats,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.searchSeats,
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
            tooltip: strings.searchMoreSeats,
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
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
    );
  }
}
