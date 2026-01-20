import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/session_service.dart';
import 'availability_screen.dart';
import 'earnings_screen.dart';
import 'provider_settings_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  bool _isOnline = true;
  bool _isLoading = true;
  String _greetingName = '';
  Map<String, dynamic> _stats = {
    'todayEarnings': 0.0,
    'completedJobs': 0,
    'averageRating': 0.0,
  };
  Map<String, dynamic>? _activeJob;
  List<Map<String, dynamic>> _upcomingJobs = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final providerId = await SessionService.getUserId();
      if (providerId != null) {
        final stats = await SupabaseService.getProviderDashboardStats(providerId);
        final active = await SupabaseService.getProviderActiveJob(providerId);
        final upcoming = await SupabaseService.getProviderUpcomingJobs(providerId);
        setState(() {
          _stats = stats;
          _activeJob = active;
          _upcomingJobs = List<Map<String, dynamic>>.from(upcoming);
          _greetingName = active?['provider_profiles']?['business_name'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F7F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Avatar
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFEAE8E4),
                        child: Icon(Icons.person, color: Color(0xFFEC9213)),
                      ),
                      // Notifications
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening notifications...')),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F7F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.notifications_none, color: Color(0xFF181511)),
                            ),
                            Positioned(
                              top: 6,
                              right: 8,
                              child: Container(
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_greetingText()}, ${_greetingName.isEmpty ? 'Provider' : _greetingName}',
                    style: const TextStyle(
                      color: Color(0xFF181511),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Availability Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6E1DB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 10,
                              width: 10,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: AnimatedOpacity(
                                      opacity: _isOnline ? 0.75 : 0.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEC9213).withOpacity(0.75),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEC9213),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'You are Online',
                              style: TextStyle(
                                color: Color(0xFF181511),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Receiving job requests',
                          style: TextStyle(color: Color(0xFF897961), fontSize: 13),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isOnline = !_isOnline),
                      child: Container(
                        height: 31,
                        width: 51,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isOnline ? const Color(0xFFEC9213) : const Color(0xFFF4F3F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: _isOnline ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          height: 23,
                          width: 27,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats Grid (horizontal scroll)
            SizedBox(
              height: 140,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatCard(
                    icon: Icons.payments,
                    title: 'Today',
                    value: '৳${_stats['todayEarnings']?.toStringAsFixed(2) ?? '0.00'}',
                    badge: '+5%',
                    badgeColor: const Color(0xFF078810),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.check_circle,
                    title: 'Completed',
                    value: '${_stats['completedJobs'] ?? 0} Jobs',
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.star,
                    title: 'Rating',
                    value: '${(_stats['averageRating'] ?? 0.0).toStringAsFixed(1)} ★',
                    badge: '+0.1',
                    badgeColor: const Color(0xFF078810),
                  ),
                ],
              ),
            ),

            // Active Job Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Active Job', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181511))),
                  SizedBox(
                    height: 8,
                    width: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFEC9213), borderRadius: BorderRadius.all(Radius.circular(4))),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildActiveJobCard(),
            ),

            // Upcoming Jobs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Upcoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181511))),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening all upcoming jobs...')),
                      );
                    },
                    child: const Text('See All', style: TextStyle(color: Color(0xFFEC9213), fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _upcomingJobs.isEmpty
                    ? [
                        _buildUpcomingTile(icon: Icons.electrical_services, title: 'Outlet Installation', subtitle: 'Today, 4:00 PM'),
                        const SizedBox(height: 8),
                        _buildUpcomingTile(icon: Icons.plumbing, title: 'Pipe Maintenance', subtitle: 'Tomorrow, 9:00 AM'),
                      ]
                    : _upcomingJobs.map((job) {
                        final title = job['service_name'] ?? 'Service';
                        final when = job['scheduled_date'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildUpcomingTile(icon: Icons.handyman, title: title, subtitle: when.toString()),
                        );
                      }).toList(),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: const Border(top: BorderSide(color: Color(0xFFE6E1DB))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', true, 0),
                _buildNavItem(Icons.calendar_today, 'Schedule', false, 1),
                _buildScanFab(),
                _buildNavItem(Icons.account_balance_wallet, 'Wallet', false, 3),
                _buildNavItem(Icons.person, 'Profile', false, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFFEC9213), size: 20),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? const Color(0xFF078810)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(badge, style: TextStyle(color: badgeColor ?? const Color(0xFF078810), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Color(0xFF897961), fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Color(0xFF181511), fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActiveJobCard() {
    final status = _activeJob?['status'] ?? 'en_route';
    final serviceName = _activeJob?['service_name'] ?? 'Leaking Faucet Repair';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1DB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: Image.network('https://placeholder.pics/svg/300', fit: BoxFit.cover),
                ),
                Positioned.fill(child: Container(color: Colors.black.withOpacity(0.08))),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                    child: Row(children: const [Icon(Icons.near_me, size: 16, color: Color(0xFFEC9213)), SizedBox(width: 4), Text('2.4 mi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEC9213)))]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEC9213).withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFEC9213).withOpacity(0.2))),
                    child: Text(status.toString().replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Color(0xFFEC9213), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Text(serviceName, style: const TextStyle(color: Color(0xFF181511), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: const [Icon(Icons.location_on, size: 16, color: Color(0xFF897961)), SizedBox(width: 4), Text('123 Main St, Downtown', style: TextStyle(color: Color(0xFF897961), fontSize: 13))]),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC9213), foregroundColor: Colors.white, elevation: 2, minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as arrived at job location')),
                    );
                  },
                  child: const Text('Arrived', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              _squareIconButton(Icons.call, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling customer...')),
                );
              }),
              const SizedBox(width: 8),
              _squareIconButton(Icons.chat, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening chat with customer...')),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _squareIconButton(IconData icon, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(color: const Color(0xFFF4F3F0), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF181511)),
      ),
    );
  }

  Widget _buildUpcomingTile({required IconData icon, required String title, required String subtitle}) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening details for $title')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE6E1DB))),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(color: const Color(0xFFF8F7F6), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFFEC9213)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF181511))), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Color(0xFF897961), fontSize: 12))]),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF897961)),
          ],
        ),
      ),
    );
  }

  Widget _buildScanFab() {
    return GestureDetector(
      onTap: _onScanTapped,
      child: Transform.translate(
        offset: const Offset(0, -28),
        child: Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(color: const Color(0xFF181511), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)]),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active, int index) {
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? const Color(0xFFEC9213) : const Color(0xFF897961)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? const Color(0xFFEC9213) : const Color(0xFF897961), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 0) return; // Already on home
    
    Widget? destination;
    switch (index) {
      case 1: // Schedule
        destination = const AvailabilityScreen();
        break;
      case 3: // Wallet
        destination = const EarningsScreen();
        break;
      case 4: // Profile
        destination = const ProviderSettingsScreen();
        break;
    }
    
    if (destination != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
    }
  }

  void _onScanTapped() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFFEC9213)),
            SizedBox(width: 8),
            Text('QR Scanner'),
          ],
        ),
        content: const Text('QR code scanning feature coming soon!\n\nThis will allow you to scan customer QR codes for quick job verification.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
