import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_formatters.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/booking.dart';
import '../models/conversation.dart';
import '../models/ride.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'chat_page.dart';
import 'live_safety_track_screen.dart';

/// Driver-side booking management for all posted rides.
///
/// Accepts/rejects passenger bookings, marks rides as completed and refreshes
/// automatically whenever a booking row changes in real time.
class DriverBookingsPage extends StatefulWidget {
  final String driverId;

  const DriverBookingsPage({super.key, required this.driverId});

  @override
  State<DriverBookingsPage> createState() => _DriverBookingsPageState();
}

class _DriverBookingsPageState extends State<DriverBookingsPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  List<Ride> _rides = [];
  Map<String, List<Booking>> _rideBookings = {};
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    _loadRidesAndBookings();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadRidesAndBookings() async {
    setState(() => _loading = true);

    try {
      final rides = await _dbService.getMyRides(widget.driverId);

      final bookingsMap = <String, List<Booking>>{};
      for (final ride in rides) {
        bookingsMap[ride.id] = await _dbService.getRideBookings(ride.id);
      }

      if (!mounted) return;
      setState(() {
        _rides = rides;
        _rideBookings = bookingsMap;
        _loading = false;
      });

      _subscribeToBookingUpdates(rides.map((r) => r.id).toSet());
    } catch (error) {
      debugPrint('Error loading rides and bookings: $error');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).driverBookingsLoadFailed),
        ),
      );
    }
  }

  /// Live-updates the booking list whenever a booking on one of the driver's
  /// rides changes (new request, cancellation, …).
  void _subscribeToBookingUpdates(Set<String> rideIds) {
    if (rideIds.isEmpty) return;

    _bookingsSub?.cancel();
    _bookingsSub = _dbService.supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .listen(
      (records) {
        final changed = records.any(
          (row) => rideIds.contains(row['ride_id']?.toString()),
        );
        if (changed && mounted) {
          _loadRidesAndBookings();
        }
      },
      onError: (Object e) => debugPrint('Booking stream error: $e'),
    );
  }

  Future<void> _acceptBooking(String bookingId) async {
    try {
      await _dbService.approveBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).driverBookingsAccepted),
        ),
      );
    } catch (error) {
      debugPrint('Could not accept booking: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).driverBookingsActionFailed),
        ),
      );
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    try {
      await _dbService.rejectBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).driverBookingsRejected),
        ),
      );
    } catch (error) {
      debugPrint('Could not reject booking: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).driverBookingsActionFailed),
        ),
      );
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _dbService.cancelBookingAsDriver(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).driverBookingsCancelled),
        ),
      );
    } catch (error) {
      debugPrint('Could not cancel booking: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).driverBookingsActionFailed),
        ),
      );
    }
  }

  Future<void> _markCompleted(Ride ride) async {
    try {
      await _dbService.completeRide(ride.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).driverBookingsRideCompleted,
          ),
        ),
      );
      _loadRidesAndBookings();
    } catch (error) {
      debugPrint('Could not complete ride: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).driverBookingsActionFailed),
        ),
      );
    }
  }

  Future<void> _openLiveSafetyTrack(Ride ride) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveSafetyTrackScreen(
          rideId: ride.id,
          initialCenter: ride.start,
        ),
      ),
    );
  }

  Future<void> _openChat(Booking booking) async {
    final userId = _authService.currentUser?.id;
    final passenger = booking.passenger;
    if (userId == null || passenger == null) return;

    try {
      final conversationId = await _dbService.getOrCreateConversation(
        rideId: booking.rideId,
        passengerId: booking.passengerId,
        driverId: userId,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversation: Conversation(
              id: conversationId,
              rideId: booking.rideId,
              passengerId: booking.passengerId,
              driverId: userId,
              passenger: passenger,
              lastMessageAt: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          ),
        ),
      );
    } catch (error) {
      debugPrint('Could not open booking chat: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).myBookingsChatFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.driverBookingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRidesAndBookings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rides.length,
                  itemBuilder: (context, index) => _RideBookingsCard(
                    ride: _rides[index],
                    bookings: _rideBookings[_rides[index].id] ?? const [],
                    onAccept: (booking) => _acceptBooking(booking.id),
                    onReject: (booking) => _rejectBooking(booking.id),
                    onCancel: (booking) => _cancelBooking(booking.id),
                    onMessage: (booking) => _openChat(booking),
                    onTrack: _rides[index].status == 'in_progress'
                        ? () => _openLiveSafetyTrack(_rides[index])
                        : null,
                    onComplete: _rides[index].status == 'available' ||
                            _rides[index].status == 'in_progress'
                        ? () => _markCompleted(_rides[index])
                        : null,
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            strings.driverBookingsNoRidesTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            strings.driverBookingsNoRidesMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RideBookingsCard extends StatelessWidget {
  const _RideBookingsCard({
    required this.ride,
    required this.bookings,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
    required this.onMessage,
    this.onTrack,
    this.onComplete,
  });

  final Ride ride;
  final List<Booking> bookings;
  final ValueChanged<Booking> onAccept;
  final ValueChanged<Booking> onReject;
  final ValueChanged<Booking> onCancel;
  final ValueChanged<Booking> onMessage;
  final VoidCallback? onTrack;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final departure = ride.departureTime;
    final locale = Localizations.localeOf(context).toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ride.originAddress} → ${ride.destinationAddress}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(_localizedRideStatus(strings, ride.status)),
                  backgroundColor: _statusColor(ride.status),
                ),
                const SizedBox(width: 8),
                Text(
                  strings.driverBookingsSeatsPrice(
                    ride.availableSeats,
                    formatCadMoney(context, ride.pricePerSeat),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(
          strings.driverBookingsDeparture(
            DateFormat.yMMMd(locale).format(departure),
            DateFormat.jm(locale).format(departure),
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          const Divider(),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.driverBookingsNoBookings,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            for (var i = 0; i < bookings.length; i++) ...[
              _BookingTile(
                booking: bookings[i],
                onAccept: () => onAccept(bookings[i]),
                onReject: () => onReject(bookings[i]),
                onCancel: () => onCancel(bookings[i]),
                onMessage: () => onMessage(bookings[i]),
              ),
              if (i < bookings.length - 1) const Divider(height: 1),
            ],
          if (onTrack != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTrack,
                  icon: const Icon(Icons.my_location),
                  label: Text(strings.driverBookingsLiveTrack),
                ),
              ),
            ),
          ],
          if (onComplete != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(strings.driverBookingsCompleteRide),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green[100]!;
      case 'in_progress':
        return Colors.blue[100]!;
      case 'completed':
        return Colors.grey[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }

  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
    required this.onMessage,
  });

  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCancel;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final passenger = booking.passenger;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger?.displayName ??
                          strings.driverBookingsPassenger,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.driverBookingsSeatsPrice(
                        booking.seatsBooked,
                        formatCadMoney(context, booking.totalPrice),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (passenger?.phone?.isNotEmpty == true)
                      Text(
                        strings.driverBookingsPhone(passenger!.phone!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (booking.pickupLocation != null)
                      Text(
                        strings.driverBookingsPickup(booking.pickupLocation!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(_localizedBookingStatus(strings, booking.status)),
                backgroundColor: _statusColor(booking.status),
              ),
            ],
          ),
          if (booking.status == 'pending' || booking.status == 'confirmed') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(strings.driverBookingsMessage),
                  ),
                ),
                const SizedBox(width: 8),
                if (booking.status == 'pending') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      icon: const Icon(Icons.close),
                      label: Text(strings.driverBookingsReject),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check),
                      label: Text(strings.driverBookingsAccept),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      icon: const Icon(Icons.close),
                      label: Text(strings.driverBookingsCancel),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green[100]!;
      case 'pending':
        return Colors.amber[100]!;
      case 'completed':
        return Colors.blue[100]!;
      case 'cancelled':
      case 'rejected':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }

  }
}

String _localizedRideStatus(AppLocalizations strings, String status) =>
    switch (status.toLowerCase()) {
      'available' => strings.profileDriverRideStatusAvailable,
      'in_progress' => strings.profileDriverRideStatusInProgress,
      'completed' => strings.profileDriverRideStatusCompleted,
      _ => strings.profileDriverRideStatusOther,
    };

String _localizedBookingStatus(AppLocalizations strings, String status) =>
    switch (status.toLowerCase()) {
      'confirmed' || 'accepted' => strings.myBookingsConfirmedStatus,
      'pending' => strings.myBookingsPendingStatus,
      'completed' => strings.myBookingsCompletedStatus,
      'cancelled' => strings.myBookingsCancelledStatus,
      'rejected' => strings.myBookingsRejectedStatus,
      _ => strings.myBookingsOtherStatus,
    };