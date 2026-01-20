import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../../services/supabase_config.dart';

class ReviewsScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String? providerImage;

  const ReviewsScreen({
    Key? key,
    required this.providerId,
    required this.providerName,
    this.providerImage,
  }) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  Map<String, dynamic>? _providerStats;
  String _sortBy = 'recent'; // recent, highest, lowest

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadProviderStats();
  }

  Future<void> _loadProviderStats() async {
    try {
      final response = await SupabaseConfig.client
          .from('provider_profiles')
          .select()
          .eq('provider_id', widget.providerId)
          .single();

      setState(() => _providerStats = response);
    } catch (e) {
      print('Error loading provider stats: $e');
    }
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoading = true);

      var query = SupabaseConfig.client
          .from('reviews')
          .select('*, customer_profiles!inner(first_name, last_name, profile_image)')
          .eq('provider_id', widget.providerId);

      final response = await query.order('created_at', ascending: false);

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reviews: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getSortedReviews() {
    final reviews = List<Map<String, dynamic>>.from(_reviews);

    switch (_sortBy) {
      case 'highest':
        reviews.sort((a, b) =>
            (b['overall_rating'] as num).compareTo(a['overall_rating'] as num));
        break;
      case 'lowest':
        reviews.sort((a, b) =>
            (a['overall_rating'] as num).compareTo(b['overall_rating'] as num));
        break;
      case 'recent':
      default:
        // Already sorted by created_at DESC from query
        break;
    }

    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    final sortedReviews = _getSortedReviews();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Provider Stats Card
                  if (_providerStats != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            children: [
                              if (widget.providerImage != null)
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(widget.providerImage!),
                                )
                              else
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.blue.shade700,
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 40),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.providerName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF181511),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RatingBar.builder(
                                      initialRating:
                                          (_providerStats!['average_rating'] as num?)
                                                  ?.toDouble() ??
                                              0,
                                      minRating: 0,
                                      direction: Axis.horizontal,
                                      allowHalfRating: true,
                                      itemCount: 5,
                                      itemSize: 20,
                                      ignoreGestures: true,
                                      itemBuilder: (context, _) => const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      onRatingUpdate: (rating) {},
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${_providerStats!['average_rating']?.toStringAsFixed(1) ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF181511),
                                    ),
                                  ),
                                  const Text(
                                    'Rating',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5F758C),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${_providerStats!['total_reviews'] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF181511),
                                    ),
                                  ),
                                  const Text(
                                    'Reviews',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5F758C),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${_providerStats!['total_bookings'] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF181511),
                                    ),
                                  ),
                                  const Text(
                                    'Bookings',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5F758C),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Sort Filter
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_reviews.length} Reviews',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF181511),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _sortBy,
                          items: [
                            DropdownMenuItem(
                              value: 'recent',
                              child: const Text('Most Recent'),
                            ),
                            DropdownMenuItem(
                              value: 'highest',
                              child: const Text('Highest Rated'),
                            ),
                            DropdownMenuItem(
                              value: 'lowest',
                              child: const Text('Lowest Rated'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sortBy = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Reviews List
                  if (sortedReviews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.rate_review,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'No Reviews Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5F758C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedReviews.length,
                      itemBuilder: (context, index) {
                        final review = sortedReviews[index];
                        final createdAt = DateTime.parse(review['created_at']);
                        final formattedDate =
                            DateFormat('MMM dd, yyyy').format(createdAt);
                        final customerName =
                            '${review['customer_profiles']['first_name']} ${review['customer_profiles']['last_name']}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    if (review['customer_profiles']
                                            ['profile_image'] !=
                                        null)
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage: NetworkImage(
                                          review['customer_profiles']
                                              ['profile_image'],
                                        ),
                                      )
                                    else
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.blue.shade700,
                                        child: const Icon(Icons.person,
                                            color: Colors.white),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF181511),
                                            ),
                                          ),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF5F758C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Rating
                                RatingBar.builder(
                                  initialRating: (review['overall_rating'] as num)
                                      .toDouble(),
                                  minRating: 0,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemSize: 20,
                                  ignoreGestures: true,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) {},
                                ),
                                const SizedBox(height: 8),

                                // Review Text
                                if (review['review_text'] != null &&
                                    (review['review_text'] as String).isNotEmpty)
                                  Text(
                                    review['review_text'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF181511),
                                      height: 1.5,
                                    ),
                                  ),
                                const SizedBox(height: 12),

                                // Aspect Ratings
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ratings:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildAspectRating(
                                            'Prof.',
                                            review['professionalism_rating'],
                                          ),
                                          _buildAspectRating(
                                            'Comm.',
                                            review['communication_rating'],
                                          ),
                                          _buildAspectRating(
                                            'Punct.',
                                            review['punctuality_rating'],
                                          ),
                                          _buildAspectRating(
                                            'Quality',
                                            review['quality_rating'],
                                          ),
                                          _buildAspectRating(
                                            'Value',
                                            review['value_rating'],
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
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildAspectRating(String label, dynamic rating) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${(rating as num).toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
