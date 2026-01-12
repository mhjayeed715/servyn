import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../../services/supabase_config.dart';

class ServiceCategoryScreen extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;

  const ServiceCategoryScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
  });

  @override
  State<ServiceCategoryScreen> createState() => _ServiceCategoryScreenState();
}

class _ServiceCategoryScreenState extends State<ServiceCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  String _sortBy = 'rating'; // rating, price, reviews

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Fetch providers from Supabase filtered by category
      final response = await SupabaseConfig.client
          .from('provider_profiles')
          .select('*, users!inner(phone)')
          .eq('verification_status', 'approved')
          .order('created_at', ascending: false);
      
      setState(() {
        _providers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading providers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sortProviders(String sortType) {
    setState(() {
      _sortBy = sortType;
      // TODO: Implement sorting logic based on sortType
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Top Bar with Back Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.categoryName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111418),
                                ),
                              ),
                              Text(
                                '${_providers.length} providers available',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5F758C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.categoryIcon,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
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
                              decoration: InputDecoration(
                                hintText: 'Search ${widget.categoryName.toLowerCase()}...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF5F758C),
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                // TODO: Implement search filter
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.tune,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: () {
                              _showFilterBottomSheet();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Sort Options
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Sort by:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5F758C),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSortChip('Rating', 'rating'),
                  const SizedBox(width: 8),
                  _buildSortChip('Price', 'price'),
                  const SizedBox(width: 8),
                  _buildSortChip('Reviews', 'reviews'),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Provider List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _providers.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadProviders,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _providers.length,
                            itemBuilder: (context, index) {
                              final provider = _providers[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildProviderCard(provider),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => _sortProviders(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF5F758C),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final fullName = provider['full_name'] ?? 'Unknown';
    final specialty = widget.categoryName;
    final photoBase64 = provider['profile_photo_base64'];
    
    // TODO: Get actual rating and reviews from database
    final rating = 4.5 + (provider.hashCode % 10) / 10;
    final reviews = 50 + (provider.hashCode % 100);
    final price = '\$${40 + (provider.hashCode % 60)}/hr';
    
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to provider detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('View details for $fullName'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
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
              child: photoBase64 != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(photoBase64),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      widget.categoryIcon,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111418),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              rating.toStringAsFixed(1),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '($reviews reviews)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5F758C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Starting at $price',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.categoryIcon,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No providers available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for ${widget.categoryName.toLowerCase()} services',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111418),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Price Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111418),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterChip('Under \$50'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip('\$50 - \$100'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip('Over \$100'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111418),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterChip('4+ ⭐'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip('4.5+ ⭐'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Apply filters
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111418),
        ),
      ),
    );
  }
}
