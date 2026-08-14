import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DriverBookingsPage extends StatefulWidget {
  final String driverId;

  const DriverBookingsPage({super.key, required this.driverId});

  @override
  State<DriverBookingsPage> createState() => _DriverBookingsPageState();
}

class _DriverBookingsPageState extends State<DriverBookingsPage> {
  final dbService = DatabaseService();
  
  List<Map<String, dynamic>> driverRides = [];
  Map<String, List<Map<String, dynamic>>> rideBookings = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRidesAndBookings();
  }

  Future<void> _loadRidesAndBookings() async {
    try {
      setState(() => loading = true);

      // Get driver's rides
      final rides = await dbService.getMyRides(widget.driverId);
      
      // For each ride, get bookings
      final bookingsMap = <String, List<Map<String, dynamic>>>{};
      for (final ride in rides) {
        final bookings = await dbService.getRideBookings(ride['id']);
        bookingsMap[ride['id']] = bookings;
      }

      setState(() {
        driverRides = rides;
        rideBookings = bookingsMap;
        loading = false;
      });

      debugPrint("✅ Loaded ${rides.length} rides with bookings");
    } catch (e) {
      debugPrint("❌ Error loading rides and bookings: $e");
      setState(() => loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading bookings: $e")),
        );
      }
    }
  }

  Future<void> _acceptBooking(String bookingId) async {
    try {
      await dbService.supabase
          .from('bookings')
          .update({'status': 'confirmed'})
          .eq('id', bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Booking accepted")),
        );
        _loadRidesAndBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e")),
        );
      }
    }
  }

  Future<void> _rejectBooking(String bookingId, String rideId) async {
    try {
      // Get booking to restore seats
      final booking = await dbService.supabase
          .from('bookings')
          .select('seats_booked')
          .eq('id', bookingId)
          .single();

      // Mark as cancelled
      await dbService.supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      // Restore seats to ride
      final ride = await dbService.supabase
          .from('rides')
          .select('available_seats')
          .eq('id', rideId)
          .single();

      final restoredSeats =
          (ride['available_seats'] as int) + (booking['seats_booked'] as int);

      await dbService.supabase
          .from('rides')
          .update({'available_seats': restoredSeats})
          .eq('id', rideId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Booking rejected")),
        );
        _loadRidesAndBookings();
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
        title: const Text("Manage Bookings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRidesAndBookings,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : driverRides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "No rides posted yet",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: driverRides.length,
                  itemBuilder: (context, index) {
                    final ride = driverRides[index];
                    final bookings = rideBookings[ride['id']] ?? [];
                    final departureTime = DateTime.parse(ride['departure_time']);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${ride['start_location']} → ${ride['end_location']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(ride['status']),
                                  backgroundColor: _getStatusColor(ride['status']),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${ride['available_seats']} seats | \$${ride['price_per_seat']}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Text(
                          "Departs: ${departureTime.month}/${departureTime.day} at ${departureTime.hour}:${departureTime.minute.toString().padLeft(2, '0')}",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        children: [
                          const Divider(),
                          if (bookings.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                "No bookings yet",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: bookings.length,
                              itemBuilder: (context, bookingIndex) {
                                final booking = bookings[bookingIndex];
                                final passenger =
                                    booking['profiles'] as Map<String, dynamic>? ?? {};

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${passenger['first_name'] ?? 'Passenger'} (${passenger['rating'] ?? 5.0}⭐)",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${booking['seats_booked']} seats - \$${booking['total_price']}",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              if (booking['pickup_location'] !=
                                                  null)
                                                Text(
                                                  "Pickup: ${booking['pickup_location']}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                            ],
                                          ),
                                          Chip(
                                            label: Text(booking['status']),
                                            backgroundColor:
                                                _getBookingStatusColor(
                                                    booking['status']),
                                          ),
                                        ],
                                      ),
                                      if (booking['status'] == 'confirmed')
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _rejectBooking(
                                                    booking['id'],
                                                    ride['id'],
                                                  ),
                                                  icon: const Icon(Icons.close),
                                                  label: const Text("Reject"),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _acceptBooking(
                                                    booking['id'],
                                                  ),
                                                  icon: const Icon(Icons.check),
                                                  label: const Text("Accept"),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (bookingIndex <
                                          bookings.length -
                                              1)
                                        const Divider(
                                            height: 24),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
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

  Color _getBookingStatusColor(String status) {
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
