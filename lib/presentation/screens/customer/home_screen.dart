import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/session_service.dart';
import '../../../services/supabase_config.dart';
import '../auth/auth_choice_screen.dart';
import 'provider_search_screen.dart';
import 'all_categories_screen.dart';
import 'profile_edit_screen.dart';
import 'customer_settings_screen.dart';
import 'service_booking_flow_screen.dart';
import '../tracking/live_tracking_screen.dart';
import 'sos_alert_screen.dart';
import 'complaints_list_screen.dart';
import '../chat/chat_list_screen.dart';
import 'booking_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _userName;
  String? _profilePhoto;
  bool _isLoading = true;
  bool _hasNotifications = false;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _featuredProviders = [];
  bool _loadingProviders = true;
  
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.electrical_services, 'name': 'Electrician'},
    {'icon': Icons.plumbing, 'name': 'Plumber'},
    {'icon': Icons.cleaning_services, 'name': 'Cleaning'},
    {'icon': Icons.yard, 'name': 'Gardening'},
    {'icon': Icons.construction, 'name': 'Carpentry'},
    {'icon': Icons.format_paint, 'name': 'Painting'},
    {'icon': Icons.school, 'name': 'Tutor'},
    {'icon': Icons.grid_view, 'name': 'More'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFeaturedProviders();
    _checkNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    print('📋 Loading user data for HomeScreen...');
    setState(() => _isLoading = true);
    
    try {
      // Try to get user ID from session service first (since we manage session manually)
      String? userId = await SessionService.getUserId();
      // Fallback to Supabase auth user if session is empty (legacy/backup)
      if (userId == null) {
        userId = SupabaseConfig.client.auth.currentUser?.id;
      }
      
      print('🔍 Current user ID: $userId');
      
      if (userId != null) {
        try {
          final profile = await SupabaseConfig.client
              .from('customer_profiles')
              .select('full_name, email, profile_photo_base64')
              .eq('user_id', userId)
              .maybeSingle();
          
          if (profile != null) {
            print('✅ Profile loaded successfully: ${profile['full_name']}');
            setState(() {
              _userName = profile['full_name'];
              _profilePhoto = profile['profile_photo_base64'];
              _isLoading = false;
            });
          } else {
             print('⚠️ Profile not found for userId: $userId');
             setState(() {
              _userName = 'User';
              _isLoading = false;
             });
          }
        } catch (profileError) {
          print('❌ Profile query error: $profileError');
          // If profile query fails, still show the home screen with default values
          setState(() {
            _userName = 'User';
            _isLoading = false;
          });
        }
      } else {
        print('❌ No authenticated user found in SessionService or SupabaseAuth');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadFeaturedProviders() async {
    setState(() => _loadingProviders = true);
    try {
      final response = await SupabaseConfig.client
          .from('provider_profiles')
          .select('''
            *,
            users!inner(phone)
          ''')
          .eq('verification_status', 'verified')
          .limit(5);
      
      setState(() {
        _featuredProviders = List<Map<String, dynamic>>.from(response);
        _loadingProviders = false;
      });
    } catch (e) {
      print('Error loading providers: $e');
      setState(() => _loadingProviders = false);
    }
  }

  Future<void> _checkNotifications() async {
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) return;
      
      // Check for unread notifications or bookings
      final notificationsResponse = await SupabaseConfig.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false);
      
      final bookingsResponse = await SupabaseConfig.client
          .from('bookings')
          .select('id')
          .eq('customer_id', userId)
          .inFilter('status', ['confirmed', 'in_progress']);
      
      final unreadNotifications = notificationsResponse.length;
      final activeBookings = bookingsResponse.length;
      final totalCount = unreadNotifications + activeBookings;
      
      setState(() {
        _hasNotifications = totalCount > 0;
        _unreadCount = totalCount;
      });
    } catch (e) {
      debugPrint('Error checking notifications: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await SupabaseService.logout();
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthChoiceScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Profile Avatar - tap to go to profile
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileEditScreen(),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _profilePhoto != null
                                    ? MemoryImage(base64Decode(_profilePhoto!))
                                    : null,
                                child: _profilePhoto == null
                                    ? Text(
                                        _userName?.substring(0, 1).toUpperCase() ?? 'U',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()},',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5F758C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _userName ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111418),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Notification Button
                        Stack(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7F8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Notifications feature coming soon!'),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_hasNotifications)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.search,
                              color: Color(0xFF5F758C),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'What service do you need?',
                                hintStyle: TextStyle(
                                  color: Color(0xFF5F758C),
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProviderSearchScreen(
                                        initialQuery: value.trim(),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.mic,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Voice Search'),
                                  content: const Text('Voice search feature coming soon!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Book Service Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ServiceBookingFlowScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC9213),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.calendar_today, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Book a Service',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Quick Actions Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(
                    icon: Icons.warning,
                    label: 'SOS',
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SosAlertScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.report_problem_outlined,
                    label: 'Complaints',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ComplaintsListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Categories Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111418),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AllCategoriesScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Categories Horizontal List
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                if (category['name'] != 'More') {
                                  // Navigate to new booking flow
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ServiceBookingFlowScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AllCategoriesScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFF0F0F0),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      category['icon'],
                                      size: 32,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category['name'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF111418),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Active Booking Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Booking',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111418),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildActiveBookingCard(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Bookings Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Bookings',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111418),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BookingHistoryScreen(),
                                    ),
                                  );
                                },
                                child: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildRecentBookingsList(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recommended Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recommended for You',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111418),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Based on your previous bookings',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5F758C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRecommendationsList(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0, true),
                _buildNavItem(Icons.calendar_month_outlined, 'Bookings', 1, false),
                _buildNavItem(Icons.chat_bubble_outline, 'Messages', 2, false),
                _buildNavItem(Icons.settings_outlined, 'Settings', 3, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (index == 3) {
          // Navigate to customer settings
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerSettingsScreen(),
            ),
          ).then((result) {
            if (result == true) {
              // Reload profile data if updated
              _loadUserData();
            }
          });
        } else if (index == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking history screen coming soon!')),
          );
        } else if (index == 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Messages screen coming soon!')),
          );
        }
      },
      onLongPress: index == 3 ? () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      } : null,
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryBlue : const Color(0xFF5F758C),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.primaryBlue : const Color(0xFF5F758C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBookingCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadActiveBooking(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: const Center(
              child: Text(
                'No active bookings',
                style: TextStyle(color: Color(0xFF5F758C)),
              ),
            ),
          );
        }
        
        final booking = snapshot.data!;
        return _buildBookingCard(booking);
      },
    );
  }
  
  Future<Map<String, dynamic>?> _loadActiveBooking() async {
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) return null;
      
      final response = await SupabaseConfig.client
          .from('bookings')
          .select('*,service_categories(*)')
          .eq('customer_id', userId)
          .inFilter('status', ['confirmed', 'provider_assigned', 'en_route', 'in_progress'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error loading active booking: $e');
      return null;
    }
  }
  
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'confirmed';
    final serviceName = booking['service_name'] ?? 'Service';
    final scheduledDate = DateTime.tryParse(booking['scheduled_date'] ?? '');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'in_progress' ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: status == 'in_progress' ? Colors.orange : Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status == 'in_progress' ? Colors.orange.shade700 : Colors.green.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      serviceName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF5F758C),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          scheduledDate != null
                              ? '${_formatDate(scheduledDate)}'
                              : 'Not scheduled',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5F758C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.person, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sarah J.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5F758C),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to live tracking
                    final bookingId = booking['id'] ?? '';
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveTrackingScreen(
                          bookingId: bookingId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('Track Provider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat, color: AppColors.primaryBlue),
                  iconSize: 20,
                  onPressed: () {
                    // TODO: Open chat
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadRecentBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: const Center(
              child: Text(
                'No recent bookings',
                style: TextStyle(color: Color(0xFF5F758C)),
              ),
            ),
          );
        }
        
        final bookings = snapshot.data!;
        return Column(
          children: bookings.map((booking) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRecentBookingCard(booking),
          )).toList(),
        );
      },
    );
  }
  
  Future<List<Map<String, dynamic>>> _loadRecentBookings() async {
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) return [];
      
      final response = await SupabaseConfig.client
          .from('bookings')
          .select('''
            id,
            service_category,
            service_location,
            scheduled_date,
            scheduled_time,
            estimated_price,
            status,
            payment_status,
            created_at,
            service_categories(*)
          ''')
          .eq('customer_id', userId)
          .order('created_at', ascending: false)
          .limit(3);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading recent bookings: $e');
      return [];
    }
  }
  
  Widget _buildRecentBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    final serviceName = booking['service_categories']?['name'] ?? 'Service';
    final scheduledDate = DateTime.tryParse(booking['scheduled_date'] ?? '');
    final scheduledTime = booking['scheduled_time'] ?? '';
    final price = booking['estimated_price'] ?? 0;
    
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    
    switch (status) {
      case 'confirmed':
        statusColor = Colors.blue.shade700;
        statusBgColor = Colors.blue.shade50;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.shade50;
        statusIcon = Icons.sync;
        break;
      case 'completed':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.shade50;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        statusColor = Colors.red.shade700;
        statusBgColor = Colors.red.shade50;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey.shade700;
        statusBgColor = Colors.grey.shade50;
        statusIcon = Icons.schedule;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
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
                      serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F758C),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                scheduledDate != null
                    ? '${_formatDate(scheduledDate)} at $scheduledTime'
                    : 'Not scheduled',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5F758C)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.payments, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '৳${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              if (status == 'completed')
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to review screen
                  },
                  child: const Text('Rate Service', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    if (_loadingProviders) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_featuredProviders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No providers available yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: _featuredProviders.map((provider) {
        final hourlyRate = provider['hourly_rate'] ?? 50;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRecommendationCard(
            name: provider['full_name'] ?? 'Unknown',
            specialty: (provider['services'] as List?)?.first ?? 'Service Provider',
            rating: (provider['rating'] ?? provider['average_rating'] ?? 4.5).toDouble(),
            reviews: provider['total_reviews'] ?? 0,
            price: '৳$hourlyRate/hr',
            profilePhoto: provider['profile_photo_base64'],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationCard({
    required String name,
    required String specialty,
    required double rating,
    required int reviews,
    required String price,
    String? profilePhoto,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Provider Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: profilePhoto != null
                  ? DecorationImage(
                      image: MemoryImage(base64Decode(profilePhoto)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profilePhoto == null
                ? const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.primaryBlue,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          
          // Provider Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111418),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5F758C),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111418),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '($reviews reviews)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F758C),
                      ),
                    ),
                    Text(
                      'Starting at $price',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == DateTime(now.year, now.month, now.day)) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
