import 'package:flutter/material.dart';
import 'dart:async';

import '../models/booking.dart';
import '../models/conversation.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'chat_page.dart';
import 'live_safety_track_screen.dart';

/// The passenger's booking history, split into Upcoming and Past rides.
///
/// Completed trips can be reviewed (driver rating). Cancellations restore the
/// ride's seats automatically on the server.
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  List<Booking> _bookings = [];
  final Set<String> _reviewedRideIds = {};
  bool _loading = true;
  int _tab = 0;
  StreamSubscription<List<Booking>>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      _bookingsSub = _dbService.watchMyBookings(userId).listen((_) {
        if (mounted) _loadBookings();
      });
    }
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final bookings = await _dbService.getMyBookings(userId);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
      for (final booking in bookings) {
        final ride = booking.ride;
        if (booking.status == 'completed' && ride != null) {
          final reviewed = await _dbService.hasReviewedRide(ride.id);
          if (!mounted) return;
          setState(() {
            if (reviewed) _reviewedRideIds.add(ride.id);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
      );
    }
  }

  List<Booking> get _visibleBookings {
    final now = DateTime.now();
    return _bookings.where((booking) {
      final departure = booking.ride?.departureTime;
      final isUpcoming = departure != null && departure.isAfter(now);
      return _tab == 0 ? isUpcoming : !isUpcoming;
    }).toList();
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _dbService.cancelBooking(booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Booking cancelled')),
      );
      _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _rateDriver(Booking booking) async {
    final ride = booking.ride;
    final driver = ride?.driver;
    if (ride == null || driver == null) return;

    var rating = 5;
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Rate ${driver.displayName}'),
        content: StatefulBuilder(
          builder: (dialogContext, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () =>
                          setDialogState(() => rating = i),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  alignLabelWithHint: true,
                  hintText: 'How was the trip?',
                ),
              ),
            ],
          ),
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
                await _dbService.createReview(
                  rideId: ride.id,
                  revieweeId: driver.id,
                  rating: rating,
                  comment: commentController.text.trim().isEmpty
                      ? null
                      : commentController.text.trim(),
                );
                if (!mounted) return;
                setState(() => _reviewedRideIds.add(ride.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Thank you for your review')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not submit review: $e')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    commentController.dispose();
  }

  Future<void> _openChat(Booking booking) async {
    final ride = booking.ride;
    final userId = _authService.currentUser?.id;
    if (ride == null || userId == null) return;

    try {
      final conversationId = await _dbService.getOrCreateConversation(
        rideId: ride.id,
        passengerId: userId,
        driverId: ride.driverId,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversation: Conversation(
              id: conversationId,
              rideId: ride.id,
              passengerId: userId,
              driverId: ride.driverId,
              driver: ride.driver,
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

  Future<void> _openLiveSafetyTrack(Booking booking) {
    final ride = booking.ride;
    if (ride == null) return Future<void>.value();

    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LiveSafetyTrackScreen(rideId: ride.id, initialCenter: ride.start),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleBookings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Upcoming'),
                  icon: Icon(Icons.schedule, size: 18),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Past'),
                  icon: Icon(Icons.history, size: 18),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) =>
                  setState(() => _tab = selection.first),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : visible.isEmpty
              ? _EmptyState(
                  isUpcoming: _tab == 0,
                  hasAnyBookings: _bookings.isNotEmpty,
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (context, index) =>
                        _BookingCard(
                          booking: visible[index],
                          onCancel:
                              visible[index].status == 'confirmed' ||
                                  visible[index].status == 'pending'
                              ? () => _cancelBooking(visible[index])
                              : null,
                          onRate: visible[index].status == 'completed' &&
                                  (visible[index].ride?.driver != null) &&
                                  !_reviewedRideIds
                                      .contains(visible[index].ride?.id)
                              ? () => _rateDriver(visible[index])
                              : null,
                          onMessage:
                              (visible[index].ride?.driver != null) &&
                                  (visible[index].status == 'confirmed' ||
                                      visible[index].status == 'pending')
                              ? () => _openChat(visible[index])
                              : null,
                          onTrack: visible[index].status == 'confirmed' &&
                                  visible[index].ride?.status == 'in_progress'
                              ? () => _openLiveSafetyTrack(visible[index])
                              : null,
                        ),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isUpcoming,
    required this.hasAnyBookings,
  });

  final bool isUpcoming;
  final bool hasAnyBookings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUpcoming ? Icons.event_available : Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isUpcoming ? 'No upcoming bookings' : 'No past bookings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isUpcoming && !hasAnyBookings
                ? 'Browse available rides and book one!'
                : 'Your ride history will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    this.onCancel,
    this.onRate,
    this.onMessage,
    this.onTrack,
  });

  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;
  final VoidCallback? onMessage;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final ride = booking.ride;
    final driver = ride?.driver;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        '${ride?.originAddress ?? 'Start'} → '
                        '${ride?.destinationAddress ?? 'End'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (ride != null)
                        Text(
                          _formatDeparture(ride.departureTime),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${driver?.displayName ?? 'Driver'} '
                      '(${(driver?.rating ?? 5.0).toStringAsFixed(1)}⭐)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Your Booking',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${booking.seatsBooked} seat(s) - '
                      '\$${booking.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (booking.pickupLocation != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pickup: ${booking.pickupLocation}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (booking.status == 'pending') ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Waiting for the driver to approve your booking',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onTrack != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTrack,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Live Safety Track'),
                ),
              ),
            ],
            if (onRate != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onMessage != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMessage,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onRate,
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Rate driver'),
                    ),
                  ),
                ],
              ),
            ] else if (onCancel != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onMessage != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMessage,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel Booking'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDeparture(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return 'Departs: ${months[dt.month - 1]} ${dt.day} at $hh:$mm';
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
