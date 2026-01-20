import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/session_service.dart';
import '../../../services/supabase_config.dart';
import 'provider_settings_screen.dart';
import '../auth/auth_choice_screen.dart';
import 'reviews_screen.dart';
import '../chat/chat_list_screen.dart';

class EnhancedProviderDashboardScreen extends StatefulWidget {
  const EnhancedProviderDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedProviderDashboardScreen> createState() => _EnhancedProviderDashboardScreenState();
}

class _EnhancedProviderDashboardScreenState extends State<EnhancedProviderDashboardScreen> {
  bool _isLoading = true;
  bool _isOnline = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _activeJob;
  List<Map<String, dynamic>> _upcomingJobs = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  String _providerName = 'Provider';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await SessionService.getUserId();
      if (userId != null) {
        final stats = await SupabaseService.getProviderDashboardStats(userId);
        final activeJob = await SupabaseService.getProviderActiveJob(userId);
        final upcomingJobs = await SupabaseService.getProviderUpcomingJobs(userId);
        
        // Load pending requests
        final pendingRequests = await SupabaseConfig.client
            .from('bookings')
            .select('''
              *,
              customer_profiles!inner(full_name, phone)
            ''')
            .eq('provider_id', userId)
            .eq('status', 'pending')
            .order('created_at', ascending: false)
            .limit(5);
        
        // Get provider name
        final profile = await SupabaseConfig.client
            .from('provider_profiles')
            .select('name')
            .eq('user_id', userId)
            .single();

        setState(() {
          _stats = stats;
          _activeJob = activeJob;
          _upcomingJobs = upcomingJobs;
          _pendingRequests = List<Map<String, dynamic>>.from(pendingRequests);
          _providerName = profile['name'] ?? 'Provider';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionService.clearSession();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthChoiceScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC9213)))
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: const Color(0xFFEC9213),
                child: _currentIndex == 0
                    ? _buildHomeContent()
                    : _buildOtherContent(),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEC9213).withOpacity(0.1),
                      child: const Icon(Icons.person, color: Color(0xFFEC9213)),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'logout') {
                          _logout();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Logout', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatListScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.notifications_outlined),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Good Morning, $_providerName',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF181511),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Availability Toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _isOnline ? const Color(0xFFEC9213) : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? 'You are Online' : 'You are Offline',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181511),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isOnline ? 'Receiving job requests' : 'Not receiving requests',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF897961),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: (value) => setState(() => _isOnline = value),
                    activeColor: const Color(0xFFEC9213),
                  ),
                ],
              ),
            ),
          ),

          // Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.payments,
                    label: 'Today',
                    value: '৳${(_stats['todayEarnings'] ?? 0).toStringAsFixed(2)}',
                    badge: '+5%',
                    badgeColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: '${_stats['completedJobs'] ?? 0} Jobs',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final userId = await SessionService.getUserId();
                      if (userId != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewsScreen(
                              providerId: userId,
                              providerName: _providerName,
                            ),
                          ),
                        );
                      }
                    },
                    child: _buildStatCard(
                      icon: Icons.star,
                      label: 'Rating',
                      value: '${(_stats['averageRating'] ?? 0).toStringAsFixed(1)} ★',
                      badge: '+0.1',
                      badgeColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Pending Requests Section
          if (_pendingRequests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'New Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_pendingRequests.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ..._pendingRequests.map((request) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildPendingRequestCard(request),
                )),
            const SizedBox(height: 24),
          ],

          // Active Job Section
          if (_activeJob != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Job',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF181511),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEC9213),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildActiveJobCard(_activeJob!),
            ),
            const SizedBox(height: 24),
          ],

          // Upcoming Jobs
          if (_upcomingJobs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF181511),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFFEC9213),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ..._upcomingJobs.take(3).map((job) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildUpcomingJobCard(job),
                )),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
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
                    color: badgeColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF897961),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181511),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(Map<String, dynamic> job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E1DB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.map, size: 48, color: Color(0xFF897961)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC9213).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFEC9213).withOpacity(0.2),
                  ),
                ),
                child: const Text(
                  'En Route',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEC9213),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job['service_name'] ?? 'Service',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181511),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF897961)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job['customer_address'] ?? 'Address',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF897961),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC9213),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Arrived',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.call),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F3F0),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chat),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F3F0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingJobCard(Map<String, dynamic> job) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1DB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.home_repair_service, color: Color(0xFFEC9213)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['service_name'] ?? 'Service',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181511),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${job['scheduled_date']} at ${job['scheduled_time']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF897961),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF897961)),
        ],
      ),
    );
  }

  Widget _buildPendingRequestCard(Map<String, dynamic> request) {
    final customerName = request['customer_profiles']?['full_name'] ?? 'Customer';
    final serviceCategory = request['service_category'] ?? 'Service';
    final scheduledDate = request['scheduled_date'] ?? '';
    final scheduledTime = request['scheduled_time'] ?? '';
    final location = request['service_location'] ?? 'Location not specified';
    final price = request['estimated_price'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEC9213), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC9213).withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
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
                      serviceCategory,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF181511),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF897961),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '৳${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEC9213),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF897961)),
              const SizedBox(width: 6),
              Text(
                '$scheduledDate at $scheduledTime',
                style: const TextStyle(fontSize: 12, color: Color(0xFF897961)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF897961)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF897961)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleRejectBooking(request['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAcceptBooking(request['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC9213),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptBooking(String bookingId) async {
    try {
      await SupabaseConfig.client
          .from('bookings')
          .update({
            'status': 'confirmed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDashboardData(); // Reload dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Booking'),
        content: const Text('Are you sure you want to decline this booking request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseConfig.client
            .from('bookings')
            .update({
              'status': 'cancelled',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking declined'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadDashboardData(); // Reload dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error declining booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildOtherContent() {
    return Center(
      child: Text(
        _currentIndex == 1
            ? 'Schedule'
            : _currentIndex == 2
                ? 'Scan'
                : _currentIndex == 3
                    ? 'Wallet'
                    : 'Profile',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 'Home', 0),
                  _buildNavItem(Icons.calendar_today, 'Schedule', 1),
                  const SizedBox(width: 64), // Space for FAB
                  _buildNavItem(Icons.account_balance_wallet, 'Wallet', 3),
                  _buildNavItem(Icons.person, 'Profile', 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProviderSettingsScreen(),
            ),
          );
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFEC9213) : const Color(0xFF897961),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFFEC9213) : const Color(0xFF897961),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
