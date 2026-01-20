import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import 'booking_submitted_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String providerId;

  const ProviderProfileScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  Map<String, dynamic>? _provider;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _portfolio = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  String _selectedDate = 'Tuesday, Oct 13';
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    setState(() => _isLoading = true);
    try {
      final provider = await SupabaseService.getPublicProviderProfile(widget.providerId);
      final reviews = await SupabaseService.getPublicProviderReviews(widget.providerId);
      final portfolio = await SupabaseService.getPublicProviderPortfolio(widget.providerId);

      setState(() {
        _provider = provider;
        _reviews = reviews;
        _portfolio = portfolio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading provider: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F7F6),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFEC9213))),
      );
    }

    if (_provider == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F7F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Provider not found')),
      );
    }

    final rating = _provider!['rating'] ?? _provider!['average_rating'] ?? 4.5;
    final reviewCount = _provider!['total_reviews'] ?? 0;
    final hourlyRate = _provider!['hourly_rate'] ?? 65;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Sticky Header
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Provider Profile',
                  style: TextStyle(
                    color: Color(0xFF181511),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : const Color(0xFF181511),
                    ),
                    onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFF181511)),
                    onPressed: () {},
                  ),
                ],
              ),

              // Profile Header
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: _provider!['profile_photo'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(_provider!['profile_photo']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: const Color(0xFFE6E1DB),
                            ),
                            child: _provider!['profile_photo'] == null
                                ? const Icon(Icons.person, size: 64, color: Color(0xFF897961))
                                : null,
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC9213),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: const Icon(Icons.verified_user, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _provider!['name'] ?? 'Provider',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _provider!['services']?.join(', ') ?? 'Service Provider',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF617589),
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F7F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE6E1DB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181511),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($reviewCount Reviews)',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF617589),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // About Section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _provider!['bio'] ?? 'Experienced service provider.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4E5D6D),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Portfolio Gallery
              if (_portfolio.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Work',
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _portfolio.length,
                            itemBuilder: (context, index) {
                              final item = _portfolio[index];
                              return Container(
                                width: 256,
                                margin: const EdgeInsets.only(right: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: item['image_url'] != null
                                            ? Image.network(
                                                item['image_url'],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              )
                                            : Container(
                                                color: const Color(0xFFE6E1DB),
                                                child: const Icon(Icons.image, size: 64),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['title'] ?? 'Work',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF181511),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Availability Calendar
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Week Strip
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F7F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDateButton('Mon', '12', false),
                            _buildDateButton('Tue', '13', true),
                            _buildDateButton('Wed', '14', false),
                            _buildDateButton('Thu', '15', false),
                            _buildDateButton('Fri', '16', false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Available slots for $_selectedDate',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF897961),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildTimeSlot('09:00 AM'),
                          _buildTimeSlot('11:00 AM'),
                          _buildTimeSlot('02:30 PM'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Reviews Section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 120),
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF181511),
                                ),
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < rating.floor() ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$reviewCount ratings',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF617589),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildRatingBar(5, 0.87),
                                _buildRatingBar(4, 0.10),
                                _buildRatingBar(3, 0.02),
                                _buildRatingBar(2, 0.01),
                                _buildRatingBar(1, 0.0),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_reviews.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        ..._reviews.take(3).map((review) => _buildReviewCard(review)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Footer CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Starting at',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF897961),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '৳$hourlyRate',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF181511),
                            ),
                          ),
                          const Text(
                            '/hr',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF897961),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingSubmittedScreen(
                              booking: {
                                'service_name': _provider!['services']?.first ?? 'Service',
                                'status': 'pending',
                                'provider_id': widget.providerId,
                                'provider_name': _provider!['name'] ?? 'Provider',
                                'price': hourlyRate.toDouble(),
                                'scheduled_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC9213),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String day, String date, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDate = '$day, Oct $date'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEC9213) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF897961),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF181511),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time) {
    final isSelected = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEC9213).withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFFEC9213) : const Color(0xFF181511),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$stars',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: const Color(0xFFE6E1DB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC9213)),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE6E1DB),
            child: Text(
              (review['customer_name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review['customer_name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181511),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (review['rating'] ?? 5) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  review['comment'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4E5D6D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
