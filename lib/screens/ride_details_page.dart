import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../maps/app_maps.dart';
import '../maps/map_controller.dart';
import '../maps/map_types.dart';
import '../models/conversation.dart';
import '../models/ride.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/verification_badges.dart';
import 'chat_page.dart';

/// Full ride detail view: route map preview, driver profile, vehicle info,
/// policies and seat booking.
///
/// The route preview is only rendered because a valid ride (with both
/// addresses and coordinates) was selected before navigating here.
class RideDetailsPage extends StatefulWidget {
  final Ride ride;

  const RideDetailsPage({super.key, required this.ride});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  late Ride _ride;
  AppMapController? _mapController;
  int _seatsToBook = 1;
  bool _booking = false;

  bool get _isOwnRide => _ride.driverId == _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
  }

  Future<void> _refreshRide() async {
    final fresh = await _dbService.getRide(_ride.id);
    if (!mounted || fresh == null) return;
    setState(() => _ride = fresh);
  }

  Future<void> _book() async {
    setState(() => _booking = true);
    try {
      await _dbService.createBooking(
        rideId: _ride.id,
        seatsBooked: _seatsToBook,
        totalPrice: _ride.pricePerSeat * _seatsToBook,
        instantBooking: _ride.instantBooking,
      );
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _ride.instantBooking
                ? strings.detailsBookingConfirmed
                : strings.detailsBookingRequested,
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Booking failed: $e');
      final strings = AppLocalizations.of(context);
      setState(() => _booking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('active booking')
                ? strings.detailsAlreadyBooked
                : e.toString().contains('Not enough seats')
                ? strings.detailsNotEnoughSeats
                : strings.detailsBookingFailed,
          ),
        ),
      );
      _refreshRide();
    }
  }

  Future<void> _openChat() async {
    final driverId = _ride.driverId;
    try {
      final conversationId = await _dbService.getOrCreateConversation(
        rideId: _ride.id,
        passengerId: _authService.currentUser?.id ?? '',
        driverId: driverId,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversation: Conversation(
              id: conversationId,
              rideId: _ride.id,
              passengerId: _authService.currentUser?.id ?? '',
              driverId: driverId,
              driver: _ride.driver,
              lastMessageAt: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          ),
        ),
      );
      _refreshRide();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).detailsChatFailed)),
      );
      debugPrint('Could not open chat: $e');
    }
  }

  Future<void> _drawRoute() async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.clear();
    await controller.addMarker(
      MapMarkerData(
        id: 'pickup',
        location: _ride.start,
        label: _ride.originAddress,
        colorHex: '#10B981',
      ),
    );
    await controller.addMarker(
      MapMarkerData(
        id: 'dropoff',
        location: _ride.end,
        label: _ride.destinationAddress,
        colorHex: '#EF4444',
      ),
    );
    await controller.addPolyline(
      MapPolylineData(points: [_ride.start, _ride.end]),
    );
    await controller.animateToBounds(
      [_ride.start, _ride.end],
      // This preview is only 200 px high: keep room between both margins.
      padding: 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final driver = _ride.driver;
    final hasDriverName =
        (driver?.firstName?.trim().isNotEmpty ?? false) ||
        (driver?.lastName?.trim().isNotEmpty ?? false);
    final departure = _ride.departureTime;
    final money = NumberFormat.currency(
      locale: strings.localeName == 'fr' ? 'fr_CA' : 'en_CA',
      name: 'CAD',
      symbol: '\$',
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.detailsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // -----------------------------------------------------------------
          // Route
          // -----------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteLine(
                    start: _ride.originAddress,
                    end: _ride.destinationAddress,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child:
                          AppMaps.createView(
                            MapViewConfig(
                              initialCenter: _ride.start,
                              initialZoom: 12,
                              showUserLocation: false,
                            ),
                          ).build(
                            onMapCreated: (controller) {
                              _mapController = controller;
                              _drawRoute();
                            },
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDateTime(context, departure),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // Driver
          // -----------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          hasDriverName
                              ? driver!.initials
                              : strings.searchDriverInitial,
                          style: const TextStyle(
                            color: Colors.white,
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
                              hasDriverName
                                  ? driver!.displayName
                                  : strings.searchDriver,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    strings.detailsRating(
                                      NumberFormat(
                                        '0.0',
                                        strings.localeName,
                                      ).format(driver?.rating ?? 5.0),
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            if (driver != null && driver.verifiedRides > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                strings.detailsCompletedTrips(
                                  driver.verifiedRides,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (driver != null && driver.verificationLevel > 0) ...[
                    const SizedBox(height: 10),
                    VerificationBadges(user: driver, compact: true),
                  ],
                  if (driver?.bio?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    Text(
                      driver!.bio!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // Vehicle & policies
          // -----------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.detailsVehicleHeading,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.directions_car,
                    label: strings.detailsVehicle,
                    value: _vehicleSummary(strings, _ride),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.pets,
                    label: strings.detailsPets,
                    value: _ride.petsAllowed
                        ? strings.detailsPetsAllowed
                        : strings.detailsPetsNotAllowed,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.luggage,
                    label: strings.detailsLuggage,
                    value: _luggageLabel(strings, _ride.luggagePolicy),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.bolt,
                    label: strings.detailsBooking,
                    value: _ride.instantBooking
                        ? strings.detailsInstantBooking
                        : strings.detailsApprovalRequired,
                  ),
                  if (_ride.notes?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.notes,
                      label: strings.detailsNotes,
                      value: _ride.notes!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // Booking
          // -----------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.detailsPrice,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Expanded(
                        child: Text(
                          strings.detailsPricePerSeat(
                            money.format(_ride.pricePerSeat),
                          ),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.detailsSeatsToBook,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: strings.searchFewerSeats,
                        onPressed: _seatsToBook > 1 && !_booking
                            ? () => setState(() => _seatsToBook--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_seatsToBook',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        tooltip: strings.searchMoreSeats,
                        onPressed:
                            _seatsToBook < _ride.availableSeats && !_booking
                            ? () => setState(() => _seatsToBook++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.detailsTotal,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Expanded(
                        child: Text(
                          money.format(_ride.pricePerSeat * _seatsToBook),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isOwnRide)
                    OutlinedButton.icon(
                      onPressed: _openChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(
                        strings.detailsMessageDriver,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (!_isOwnRide) const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _booking ? null : _book,
                    icon: _booking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.event_seat),
                    label: Text(
                      _booking
                          ? strings.detailsBookingLoading
                          : strings.detailsBookSeats(_seatsToBook),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_ride.availableSeats <= 3 && _ride.availableSeats > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        strings.detailsSeatsLeft(_ride.availableSeats),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(BuildContext context, DateTime dt) {
    final strings = AppLocalizations.of(context);
    return strings.detailsDateTime(
      DateFormat.yMMMd(strings.localeName).format(dt),
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(dt),
        alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
      ),
    );
  }

  static String _luggageLabel(AppLocalizations strings, String policy) {
    switch (policy) {
      case 'none':
        return strings.detailsLuggageNone;
      case 'small':
        return strings.detailsLuggageSmall;
      case 'large':
        return strings.detailsLuggageLarge;
      default:
        return strings.detailsLuggageStandard;
    }
  }

  static String _vehicleSummary(AppLocalizations strings, Ride ride) {
    final type = switch (ride.vehicleType.toLowerCase()) {
      'sedan' => strings.detailsSedan,
      'suv' => strings.detailsSuv,
      'van' => strings.detailsVan,
      _ => ride.vehicleType,
    };
    // Personal vehicle descriptions are not machine-translated.
    final parts = [
      if (ride.vehicleColor?.isNotEmpty ?? false) ride.vehicleColor!,
      if (ride.vehicleMake?.isNotEmpty ?? false) ride.vehicleMake!,
      if (ride.vehicleModel?.isNotEmpty ?? false) ride.vehicleModel!,
      type,
      if (ride.vehicleYear != null) '(${ride.vehicleYear})',
    ];
    final summary = parts.join(' ').trim();
    if (summary.isEmpty) return strings.detailsVehicleUnspecified;
    if (ride.vehiclePlate?.isNotEmpty ?? false) {
      return '$summary · ${ride.vehiclePlate}';
    }
    return summary;
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.start, required this.end});

  final String start;
  final String end;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.trip_origin, size: 20, color: AppColors.success),
            Container(width: 2, height: 32, color: AppColors.divider),
            const Icon(Icons.place, size: 20, color: AppColors.danger),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                start,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                end,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          '$label:  ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
