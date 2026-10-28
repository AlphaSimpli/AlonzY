import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/ride.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'chat_list_page.dart';
import 'driver_bookings_page.dart';
import 'edit_profile_page.dart';
import 'my_bookings_page.dart';
import 'post_ride_page.dart';
import 'search_rides_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  AppUser? _user;
  List<Ride> _myRides = [];
  int _reviewCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final profile = await _dbService.getUserProfile(userId);
      List<Ride> rides = const [];
      var reviewCount = 0;
      if (profile != null) {
        if (profile.isDriver) {
          rides = await _dbService.getMyRides(userId);
          reviewCount = (await _dbService.getReviewsForDriver(userId)).length;
        }
      }

      if (!mounted) return;
      setState(() {
        _user = profile;
        _myRides = rides;
        _reviewCount = reviewCount;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _toggleDriver(bool enabled) async {
    final userId = _authService.currentUser?.id;
    if (userId == null || _user == null) return;

    try {
      await _dbService.updateProfile(userId: userId, isDriver: enabled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? '✅ Driver mode enabled' : 'Driver mode disabled',
          ),
        ),
      );
      _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _cancelRide(Ride ride) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: Text(
          'The ride from ${ride.originAddress} to ${ride.destinationAddress} will '
          'no longer be listed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel ride'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _dbService.updateRideStatus(ride.id, 'cancelled');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Ride cancelled')),
      );
      _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _openEditProfile() async {
    final user = _user;
    if (user == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
    );
    if (changed == true) {
      _loadProfile();
    }
  }

  Future<void> _requestGovtIdVerification() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verify your ID?'),
        content: const Text(
          'Your request will be reviewed by our support team. '
          'This helps build trust in the community.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Request verification'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _dbService.requestGovtIdVerification(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Verification requested — pending review'),
        ),
      );
      _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: _loading ? null : _openEditProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _ProfileHeader(user: user, reviewCount: _reviewCount),
                  const SizedBox(height: 24),

                  // -----------------------------------------------------------------
                  // Verification
                  // -----------------------------------------------------------------
                  _VerificationSection(
                    user: user,
                    onRequestIdVerification: _requestGovtIdVerification,
                  ),
                  const SizedBox(height: 24),

                  // -----------------------------------------------------------------
                  // Account mode
                  // -----------------------------------------------------------------
                  Text('Account Mode',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Driver Mode'),
                      subtitle: Text(user?.isDriver ?? false
                          ? 'You can post and manage rides'
                          : 'Enable to post rides'),
                      value: user?.isDriver ?? false,
                      onChanged: _toggleDriver,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -----------------------------------------------------------------
                  // Quick actions
                  // -----------------------------------------------------------------
                  Text('Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.search),
                          title: const Text('Search Rides'),
                          subtitle: const Text(
                              'Find and book available rides'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchRidesPage(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.bookmark),
                          title: const Text('My Bookings'),
                          subtitle: const Text('View your ride bookings'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyBookingsPage(),
                            ),
                          ),
                        ),
const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: const Text('Messages'),
                          subtitle: const Text(
                              'Chat with drivers and passengers'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatListPage(),
                            ),
                          ),
                        ),
                        if (user?.isDriver ?? false) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.add_circle),
                            title: const Text('Post a Ride'),
                            subtitle: const Text(
                                'Create a new ride offer'),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PostRidePage(),
                                ),
                              );
                              _loadProfile();
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.people),
                            title: const Text('Manage Bookings'),
                            subtitle: const Text(
                                'Accept/reject passenger bookings'),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              final userId = _authService.currentUser?.id;
                              if (userId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DriverBookingsPage(
                                        driverId: userId),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -----------------------------------------------------------------
                  // My posted rides (driver only)
                  // -----------------------------------------------------------------
                  if (user?.isDriver ?? false) ...[
                    Text('My Posted Rides',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (_myRides.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text('No rides posted yet'),
                          ),
                        ),
                      )
                    else
                      for (final ride in _myRides) ...[
                        _DriverRideCard(
                          ride: ride,
                          onCancel: ride.status == 'available'
                              ? () => _cancelRide(ride)
                              : null,
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 24),
                  ],

                  ElevatedButton.icon(
                    onPressed: () async {
                      await _authService.signOut();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Logged out')),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection({
    required this.user,
    required this.onRequestIdVerification,
  });

  final AppUser? user;
  final VoidCallback onRequestIdVerification;

  @override
  Widget build(BuildContext context) {
    final safe = user ?? const AppUser(id: '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verification',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _VerificationRow(
                icon: Icons.alternate_email,
                label: 'Email',
                status: safe.emailVerified
                    ? 'Verified'
                    : safe.email == null
                        ? 'Not provided'
                        : 'Not verified',
                verified: safe.emailVerified,
              ),
              const Divider(height: 1),
              _VerificationRow(
                icon: Icons.phone,
                label: 'Phone',
                status: safe.phoneVerified
                    ? 'Verified'
                    : safe.phone == null
                        ? 'Not provided'
                        : 'Not verified',
                verified: safe.phoneVerified,
              ),
              const Divider(height: 1),
              _VerificationRow(
                icon: Icons.badge_outlined,
                label: 'Government ID',
                status: switch (safe.govtIdStatus) {
                  'verified' => 'Verified',
                  'pending' => 'Pending review',
                  _ => 'Not verified',
                },
                verified: safe.govtIdVerified,
                pending: safe.govtIdStatus == 'pending',
                trailing: safe.govtIdStatus == 'none'
                    ? TextButton(
                        onPressed: onRequestIdVerification,
                        child: const Text('Verify now'),
                      )
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          safe.verificationLevel == 3
              ? '🎉 Fully verified — you\'re one of our most trusted members.'
              : 'Verified members are trusted more by the community. '
                  'Verification is free.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({
    required this.icon,
    required this.label,
    required this.status,
    required this.verified,
    this.pending = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String status;
  final bool verified;
  final bool pending;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = verified
        ? AppColors.success
        : pending
            ? AppColors.warning
            : AppColors.textSecondary;

    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      trailing: verified
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : pending
              ? const Icon(Icons.hourglass_top, color: AppColors.warning)
              : trailing,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, this.reviewCount = 0});

  final AppUser? user;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final safe = user ?? const AppUser(id: '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Text(
                safe.initials,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              safe.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (safe.email != null || safe.phone != null) ...[
              const SizedBox(height: 4),
              Text(
                [safe.email, safe.phone].whereType<String>().join(' · '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${safe.rating.toStringAsFixed(1)} rating',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (safe.isDriver) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.directions_car,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Driver',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
            if (reviewCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$reviewCount review${reviewCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (safe.verifiedRides > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${safe.verifiedRides} trip'
                  '${safe.verifiedRides == 1 ? '' : 's'} completed',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (safe.bio?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                safe.bio!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (safe.isDriver && (safe.vehicleMake != null ||
                safe.vehicleModel != null ||
                safe.vehiclePlate != null)) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      [
                        safe.vehicleMake,
                        safe.vehicleModel,
                        safe.vehiclePlate,
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DriverRideCard extends StatelessWidget {
  const _DriverRideCard({required this.ride, this.onCancel});

  final Ride ride;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final departure = ride.departureTime;
    final statusColor = switch (ride.status) {
      'available' => Colors.green,
      'in_progress' => Colors.blue,
      'completed' => Colors.grey,
      _ => Colors.orange,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.originAddress,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text('↓', style: TextStyle(fontSize: 12)),
                      Text(
                        ride.destinationAddress,
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
                      label: Text(
                        ride.status,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: statusColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${departure.month}/${departure.day}/${departure.year}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${departure.hour.toString().padLeft(2, '0')}:'
                      '${departure.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_seat, size: 16),
                    const SizedBox(width: 4),
                    Text('${ride.availableSeats} seats available'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16),
                    Text('\$${ride.pricePerSeat.toStringAsFixed(2)}/seat'),
                  ],
                ),
              ],
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel ride'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}