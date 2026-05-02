import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SearchRidesPage extends StatefulWidget {
  const SearchRidesPage({super.key});

  @override
  State<SearchRidesPage> createState() => _SearchRidesPageState();
}

class _SearchRidesPageState extends State<SearchRidesPage> {
  final dbService = DatabaseService();
  
  final startLocationController = TextEditingController();
  final endLocationController = TextEditingController();
  final maxPriceController = TextEditingController();

  DateTime? selectedDate;
  List<Map<String, dynamic>> searchResults = [];
  bool loading = false;
  bool hasSearched = false;

  @override
  void dispose() {
    startLocationController.dispose();
    endLocationController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _searchRides() async {
    setState(() {
      loading = true;
      hasSearched = true;
    });

    try {
      // Prepare search parameters
      final dateTime = selectedDate != null
          ? DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day)
          : DateTime.now();

      final double? maxPrice = maxPriceController.text.isNotEmpty
          ? double.tryParse(maxPriceController.text)
          : null;

      final results = await dbService.searchRides(
        afterDate: dateTime,
        startLocation: startLocationController.text.isEmpty
            ? null
            : startLocationController.text,
        endLocation: endLocationController.text.isEmpty
            ? null
            : endLocationController.text,
        maxPrice: maxPrice,
      );

      setState(() {
        searchResults = results;
        loading = false;
      });

      print("✅ Found ${results.length} rides");
    } catch (e) {
      print("❌ Error searching rides: $e");
      setState(() => loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error searching: $e")),
        );
      }
    }
  }

  void _showBookingDialog(BuildContext context, Map<String, dynamic> ride) {
    int seatsToBook = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Book Ride"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${ride['start_location']} → ${ride['end_location']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Seats:"),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (seatsToBook > 1) {
                              setState(() => seatsToBook--);
                            }
                          },
                        ),
                        Text("$seatsToBook"),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (seatsToBook < ride['available_seats']) {
                              setState(() => seatsToBook++);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Total: \$${(ride['price_per_seat'] * seatsToBook).toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final totalPrice = ride['price_per_seat'] * seatsToBook;
                final bookingId = await dbService.createBooking(
                  rideId: ride['id'],
                  seatsBooked: seatsToBook,
                  totalPrice: totalPrice,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "✅ Booking confirmed! ID: $bookingId",
                      ),
                    ),
                  );
                  _searchRides(); // Refresh search results
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Booking failed: $e")),
                  );
                }
              }
            },
            child: const Text("Book Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Rides")),
      body: Column(
        children: [
          // Search Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Search Filters", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: startLocationController,
                    decoration: const InputDecoration(
                      labelText: "From",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: endLocationController,
                    decoration: const InputDecoration(
                      labelText: "To",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: maxPriceController,
                          decoration: const InputDecoration(
                            labelText: "Max Price",
                            border: OutlineInputBorder(),
                            prefixText: "\$",
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _searchRides,
                      icon: const Icon(Icons.search),
                      label: const Text("Search Rides"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Search Results
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : !hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "No search performed yet",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      )
                    : searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  "No rides found",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Try adjusting your search filters",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final ride = searchResults[index];
                              final driver =
                                  ride['profiles'] as Map<String, dynamic>? ?? {};
                              final departureTime =
                                  DateTime.parse(ride['departure_time']);
                              final timeUntilDeparture =
                                  departureTime.difference(DateTime.now());

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[300],
                                    child: Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${ride['start_location']} → ${ride['end_location']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Departs in ${_formatDuration(timeUntilDeparture)}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "\$${ride['price_per_seat']}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${ride['available_seats']} seats",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 16),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                "${driver['first_name'] ?? 'Driver'} (${driver['rating'] ?? 5.0}⭐)",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _showBookingDialog(context, ride);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text("Book"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "Departed";
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes % 60}m";
    }
    return "${duration.inMinutes}m";
  }
}
