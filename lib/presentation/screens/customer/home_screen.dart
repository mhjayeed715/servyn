import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../services/supabase_config.dart';
import '../auth/auth_choice_screen.dart';
import 'service_category_screen.dart';

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
  final bool _hasNotifications = true;
  
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.electrical_services, 'name': 'Electrician'},
    {'icon': Icons.plumbing, 'name': 'Plumber'},
    {'icon': Icons.cleaning_services, 'name': 'Cleaning'},
    {'icon': Icons.yard, 'name': 'Gardening'},
    {'icon': Icons.construction, 'name': 'Carpentry'},
    {'icon': Icons.format_paint, 'name': 'Painting'},
    {'icon': Icons.grid_view, 'name': 'More'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        final profile = await SupabaseConfig.client
            .from('customer_profiles')
            .select('full_name, email, profile_photo_base64')
            .eq('user_id', user.id)
            .single();
        
        setState(() {
          _userName = profile['full_name'];
          _profilePhoto = profile['profile_photo_base64'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
                            // Profile Avatar
                            CircleAvatar(
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
                                  // TODO: Navigate to notifications
                                },
                              ),
                            ),
                            if (_hasNotifications)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 10,
                                  height: 10,
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
                                // TODO: Implement search
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.mic,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: () {
                              // TODO: Implement voice search
                            },
                          ),
                        ],
                      ),
                    ),
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
                              // TODO: Navigate to all categories
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ServiceCategoryScreen(
                                        categoryName: category['name'],
                                        categoryIcon: category['icon'],
                                      ),
                                    ),
                                  );
                                } else {
                                  // TODO: Navigate to all categories
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
                _buildNavItem(Icons.person_outline, 'Profile', 3, false),
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
          // TODO: Navigate to profile
        } else if (index == 1) {
          // TODO: Navigate to bookings
        } else if (index == 2) {
          // TODO: Navigate to messages
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
                child: const Text('Logout'),
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
    // TODO: Fetch from Supabase bookings table
    // For now showing placeholder
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
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CONFIRMED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Home Cleaning',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF5F758C),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tomorrow, 10:00 AM',
                          style: TextStyle(
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
                    // TODO: Track provider location
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

  Widget _buildRecommendationsList() {
    // TODO: Fetch from Supabase provider_profiles table
    // For now showing placeholder data
    return Column(
      children: [
        _buildRecommendationCard(
          name: 'John Doe',
          specialty: 'Master Electrician',
          rating: 4.9,
          reviews: 120,
          price: '\$50/hr',
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          name: 'Elite Gardens',
          specialty: 'Landscaping',
          rating: 4.8,
          reviews: 85,
          price: '\$80/visit',
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required String name,
    required String specialty,
    required double rating,
    required int reviews,
    required String price,
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
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: AppColors.primaryBlue,
            ),
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
}
