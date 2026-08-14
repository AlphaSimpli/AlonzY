import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final authService = AuthService();
  final dbService = DatabaseService();
  
  List<Map<String, dynamic>> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() => loading = true);

      final userId = authService.currentUser?.id;
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      final userBookings = await dbService.getMyBookings(userId);

      setState(() {
        bookings = userBookings;
        loading = false;
      });

      debugPrint("✅ Loaded ${bookings.length} bookings");
    } catch (e) {
      debugPrint("❌ Error loading bookings: $e");
      setState(() => loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading bookings: $e")),
        );
      }
    }
  }

  Future<void> _cancelBooking(String bookingId, String rideId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking?"),
        content: const Text("Are you sure you want to cancel this booking?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep it"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Cancel Booking"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await dbService.cancelBooking(bookingId, rideId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Booking cancelled")),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "No bookings yet",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Browse available rides and book one!",
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final ride = booking['rides'] as Map<String, dynamic>? ?? {};
                    final driver =
                        ride['profiles'] as Map<String, dynamic>? ?? {};
                    final departureTime =
                        ride['departure_time'] != null
                            ? DateTime.parse(ride['departure_time'])
                            : DateTime.now();

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${ride['start_location'] ?? 'Start'} → ${ride['end_location'] ?? 'End'}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Departs: ${departureTime.month}/${departureTime.day} at ${departureTime.hour}:${departureTime.minute.toString().padLeft(2, '0')}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(booking['status']),
                                  backgroundColor: _getStatusColor(booking['status']),
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
                                      "Driver",
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      "${driver['first_name'] ?? 'Driver'} (${driver['rating'] ?? 5.0}⭐)",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Your Booking",
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      "${booking['seats_booked']} seat(s) - \$${booking['total_price']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (booking['pickup_location'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Pickup: ${booking['pickup_location']}",
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (booking['status'] == 'confirmed')
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _cancelBooking(
                                      booking['id'],
                                      ride['id'],
                                    ),
                                    icon: const Icon(Icons.close),
                                    label: const Text("Cancel Booking"),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green[100]!;
      case 'completed':
        return Colors.blue[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}
