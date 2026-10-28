import 'dart:async';

import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/conversation.dart';
import '../models/ride.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'chat_page.dart';

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
    } catch (e) {
      debugPrint('Error loading rides and bookings: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
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
        const SnackBar(content: Text('✅ Booking accepted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    try {
      await _dbService.rejectBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Booking rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _dbService.cancelBookingAsDriver(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel booking: $e')),
      );
    }
  }

  Future<void> _markCompleted(Ride ride) async {
    try {
      await _dbService.completeRide(ride.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Ride marked as completed')),
      );
      _loadRidesAndBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Could not open chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No rides posted yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Post a ride to start receiving booking requests.',
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
    this.onComplete,
  });

  final Ride ride;
  final List<Booking> bookings;
  final ValueChanged<Booking> onAccept;
  final ValueChanged<Booking> onReject;
  final ValueChanged<Booking> onCancel;
  final ValueChanged<Booking> onMessage;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final departure = ride.departureTime;

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
                  label: Text(ride.status),
                  backgroundColor: _statusColor(ride.status),
                ),
                const SizedBox(width: 8),
                Text(
                  '${ride.availableSeats} seats | '
                  '\$${ride.pricePerSeat.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(
          'Departs: ${departure.month}/${departure.day} at '
          '${departure.hour.toString().padLeft(2, '0')}:'
          '${departure.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          const Divider(),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No bookings yet',
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
          if (onComplete != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark ride as completed'),
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
                      passenger?.displayName ?? 'Passenger',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.seatsBooked} seats - '
                      '\$${booking.totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (passenger?.phone != null)
                      Text(
                        'Phone: ${passenger!.phone}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (booking.pickupLocation != null)
                      Text(
                        'Pickup: ${booking.pickupLocation}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(booking.status),
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
                    label: const Text('Message'),
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
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
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
                      label: const Text('Cancel'),
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