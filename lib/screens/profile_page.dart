import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'post_ride_page.dart';
import 'driver_bookings_page.dart';
import 'my_bookings_page.dart';
import 'search_rides_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  final dbService = DatabaseService();

  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> myRides = [];
  bool loading = true;
  bool isDriver = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = authService.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      final profile = await dbService.getUserProfile(userId);
      final isUserDriver = profile?['is_driver'] ?? false;

      // Load driver's rides if in driver mode
      List<Map<String, dynamic>> rides = [];
      if (isUserDriver) {
        rides = await dbService.getMyRides(userId);
      }

      setState(() {
        userProfile = profile;
        isDriver = isUserDriver;
        myRides = rides;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading profile: $e");
      setState(() => loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
    }
  }

  Future<void> _toggleDriver() async {
    try {
      final userId = authService.currentUser?.id;
      if (userId == null) return;

      await dbService.updateProfile(
        userId: userId,
        isDriver: !isDriver,
      );

      setState(() => isDriver = !isDriver);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ ${isDriver ? 'Driver mode enabled' : 'Driver mode disabled'}"),
          ),
        );
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
      appBar: AppBar(title: const Text("Profile & Settings")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue[300],
                            child: Text(
                              (userProfile?['first_name'] ?? 'U')
                                  .toString()
                                  .toUpperCase()
                                  .characters
                                  .first,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${userProfile?['first_name'] ?? 'User'} ${userProfile?['last_name'] ?? ''}",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authService.currentUser?.email ?? "",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                "${userProfile?['rating'] ?? 5.0} rating",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mode Selection
                  Text("Account Mode", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Card(
                    child: SwitchListTile(
                      title: const Text("Driver Mode"),
                      subtitle: Text(isDriver
                          ? "You can post and manage rides"
                          : "Enable to post rides"),
                      value: isDriver,
                      onChanged: (_) => _toggleDriver(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text("Quick Actions", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text("Search Rides"),
                    subtitle: const Text("Find and book available rides"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchRidesPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bookmark),
                    title: const Text("My Bookings"),
                    subtitle: const Text("View your ride bookings"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyBookingsPage(),
                        ),
                      );
                    },
                  ),
                  if (isDriver) ...[
                    ListTile(
                      leading: const Icon(Icons.add_circle),
                      title: const Text("Post a Ride"),
                      subtitle: const Text("Create a new ride offer"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PostRidePage(),
                          ),
                        );
                        // Refresh if ride was posted
                        if (result == true) {
                          _loadProfile();
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text("Manage Bookings"),
                      subtitle: const Text("Accept/reject passenger bookings"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        final userId = authService.currentUser?.id;
                        if (userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DriverBookingsPage(driverId: userId),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // My Posted Rides Section (Driver Only)
                  if (isDriver) ...[
                    Text("My Posted Rides", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (myRides.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              "No rides posted yet",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      )
                    else
                      ...myRides.map((ride) {
                        final departureTime = DateTime.parse(ride['departure_time'] as String);
                        final timeStr = "${departureTime.hour}:${departureTime.minute.toString().padLeft(2, '0')}";
                        final dateStr = "${departureTime.month}/${departureTime.day}/${departureTime.year}";
                        final statusColor = ride['status'] == 'available' ? Colors.green : Colors.orange;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Route
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ride['start_location'] ?? "Start",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text("↓", style: TextStyle(fontSize: 12)),
                                          Text(
                                            ride['end_location'] ?? "End",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Chip(
                                          label: Text(ride['status'] ?? 'unknown',
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 12)),
                                          backgroundColor: statusColor,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Details row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event_seat, size: 16),
                                        const SizedBox(width: 4),
                                        Text("${ride['available_seats']} seats available"),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_money, size: 16),
                                        Text("${ride['price_per_seat']}/seat"),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authService.signOut();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ Logged out")),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
