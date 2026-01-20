import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'time_slot_selection_screen.dart';
import 'service_booking_flow_screen.dart';
import 'no_providers_screen.dart';
import '../../../services/supabase_config.dart';

class ProviderInfo {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String specialization;
  final double pricePerHour;
  final bool isAvailable;
  final List<String> skills;
  final int completedJobs;
  final int yearsExperience;

  ProviderInfo({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.specialization,
    required this.pricePerHour,
    required this.isAvailable,
    required this.skills,
    required this.completedJobs,
    required this.yearsExperience,
  });
}

class ProviderListScreen extends StatefulWidget {
  final ServiceCategory serviceCategory;
  final String location;
  final Map<String, double>? coordinates;
  final String? landmark;

  const ProviderListScreen({
    super.key,
    required this.serviceCategory,
    required this.location,
    this.coordinates,
    this.landmark,
  });

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  String _sortBy = 'distance'; // distance, rating, price
  bool _availableOnly = true;
  double _maxDistance = 10.0; // km
  List<ProviderInfo> _providers = [];
  List<ProviderInfo> _filteredProviders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);

    try {
      // Fetch providers from Supabase database
      final response = await SupabaseConfig.client
          .from('provider_profiles')
          .select('''
            *,
            users!provider_profiles_user_id_fkey (
              id,
              phone
            )
          ''')
          .eq('service_category', widget.serviceCategory.name)
          .eq('status', 'active')
          .eq('verification_status', 'verified');

      final providers = (response as List).map((providerData) {
        
        return ProviderInfo(
          id: providerData['id'] as String,
          name: providerData['full_name'] ?? 'Provider',
          imageUrl: 'https://via.placeholder.com/150',
          rating: (providerData['rating'] ?? 5.0).toDouble(),
          reviewCount: providerData['total_reviews'] ?? 0,
          distanceKm: 2.5, // TODO: Calculate actual distance from coordinates
          specialization: providerData['service_category'] ?? widget.serviceCategory.name,
          pricePerHour: (providerData['hourly_rate'] ?? 500.0).toDouble(),
          isAvailable: providerData['availability_status'] == 'available',
          skills: (providerData['skills'] as List?)?.map((s) => s.toString()).toList() ?? ['Licensed', 'Experienced'],
          completedJobs: providerData['total_jobs_completed'] ?? 0,
          yearsExperience: providerData['years_of_experience'] ?? 1,
        );
      }).toList();

      setState(() {
        _providers = providers;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading providers: $e');
      
      // Fallback to mock data if database query fails
      setState(() {
        _providers = _generateMockProviders();
        _applyFilters();
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using demo data: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  List<ProviderInfo> _generateMockProviders() {
    final random = math.Random();
    final names = ['Ahmed Khan', 'Rahim Uddin', 'Karim Hassan', 'Farhan Ali', 'Sabbir Rahman'];
    
    return List.generate(5, (index) {
      final isAvailable = random.nextBool();
      return ProviderInfo(
        id: 'provider_$index',
        name: names[index],
        imageUrl: 'https://via.placeholder.com/150',
        rating: 4.0 + random.nextDouble(),
        reviewCount: 20 + random.nextInt(100),
        distanceKm: 1 + random.nextDouble() * 15,
        specialization: widget.serviceCategory.name,
        pricePerHour: 500 + random.nextInt(1000).toDouble(),
        isAvailable: isAvailable,
        skills: ['Licensed', 'Experienced', '24/7 Available'],
        completedJobs: 50 + random.nextInt(200),
        yearsExperience: 2 + random.nextInt(8),
      );
    });
  }

  void _applyFilters() {
    var filtered = List<ProviderInfo>.from(_providers);

    // Filter by availability
    if (_availableOnly) {
      filtered = filtered.where((p) => p.isAvailable).toList();
    }

    // Filter by distance
    filtered = filtered.where((p) => p.distanceKm <= _maxDistance).toList();

    // Sort
    if (_sortBy == 'distance') {
      filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (_sortBy == 'rating') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'price') {
      filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    }

    setState(() {
      _filteredProviders = filtered;
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF181511)),
                ),
                const SizedBox(height: 20),

                const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF181511))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('Distance', 'distance', setModalState),
                    _buildFilterChip('Rating', 'rating', setModalState),
                    _buildFilterChip('Price', 'price', setModalState),
                  ],
                ),

                const SizedBox(height: 20),
                const Text('Maximum Distance', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF181511))),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _maxDistance,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        activeColor: const Color(0xFFEC9213),
                        label: '${_maxDistance.toInt()} km',
                        onChanged: (value) {
                          setModalState(() => _maxDistance = value);
                          setState(() => _maxDistance = value);
                        },
                      ),
                    ),
                    Text('${_maxDistance.toInt()} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Available Only', style: TextStyle(color: Color(0xFF181511))),
                  value: _availableOnly,
                  activeColor: const Color(0xFFEC9213),
                  onChanged: (value) {
                    setModalState(() => _availableOnly = value);
                    setState(() => _availableOnly = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC9213),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, StateSetter setModalState) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() => _sortBy = value);
        setState(() => _sortBy = value);
      },
      selectedColor: const Color(0xFFEC9213).withOpacity(0.2),
      checkmarkColor: const Color(0xFFEC9213),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFEC9213) : const Color(0xFF897961),
      ),
    );
  }

  void _selectProvider(ProviderInfo provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimeSlotSelectionScreen(
          serviceCategory: widget.serviceCategory,
          location: widget.location,
          provider: provider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Available Providers',
          style: TextStyle(color: Color(0xFF181511), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFFEC9213)),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: Colors.white,
            child: Row(
              children: [
                _buildProgressStep(1, 'Category', false),
                _buildProgressLine(),
                _buildProgressStep(2, 'Location', false),
                _buildProgressLine(),
                _buildProgressStep(3, 'Provider', true),
                _buildProgressLine(),
                _buildProgressStep(4, 'Time', false),
              ],
            ),
          ),

          // Location Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E1DB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFEC9213)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.location,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF181511)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.landmark != null && widget.landmark!.isNotEmpty)
                        Text(
                          'Near: ${widget.landmark}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF897961)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Provider List
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: Color(0xFFEC9213))),
            )
          else if (_filteredProviders.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'No providers found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181511)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try adjusting your filters',
                      style: TextStyle(color: Color(0xFF897961)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoProvidersScreen(
                              serviceCategory: widget.serviceCategory,
                              location: widget.location,
                              currentRadius: _maxDistance,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC9213),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Expand Search Area', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredProviders.length,
                itemBuilder: (context, index) {
                  final provider = _filteredProviders[index];
                  return _buildProviderCard(provider);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(ProviderInfo provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _selectProvider(provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: widget.serviceCategory.color.withOpacity(0.2),
                    child: Icon(widget.serviceCategory.icon, color: widget.serviceCategory.color, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF181511),
                                ),
                              ),
                            ),
                            if (provider.isAvailable)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Available',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF897961)),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on, color: Color(0xFFEC9213), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF897961)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.work, '${provider.completedJobs} jobs'),
                  _buildInfoChip(Icons.schedule, '${provider.yearsExperience} years'),
                  _buildInfoChip(Icons.payments, '৳${provider.pricePerHour.toInt()}/hr'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: provider.skills.map((skill) => _buildSkillBadge(skill)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF897961)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF181511))),
        ],
      ),
    );
  }

  Widget _buildSkillBadge(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEC9213).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        skill,
        style: const TextStyle(fontSize: 11, color: Color(0xFFEC9213)),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF897961),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFFEC9213) : const Color(0xFF897961),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: const Color(0xFFE6E1DB),
      ),
    );
  }
}
