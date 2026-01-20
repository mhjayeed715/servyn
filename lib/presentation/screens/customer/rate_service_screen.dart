import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../services/supabase_config.dart';
import '../../../core/services/session_service.dart';

class RateServiceScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String providerName;
  final String serviceCategory;
  final String? providerImage;

  const RateServiceScreen({
    Key? key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.serviceCategory,
    this.providerImage,
  }) : super(key: key);

  @override
  State<RateServiceScreen> createState() => _RateServiceScreenState();
}

class _RateServiceScreenState extends State<RateServiceScreen> {
  double _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  final List<String> _aspects = [
    'Professionalism',
    'Communication',
    'Punctuality',
    'Quality of Work',
    'Value for Money',
  ];
  final Map<String, double> _aspectRatings = {
    'Professionalism': 0,
    'Communication': 0,
    'Punctuality': 0,
    'Quality of Work': 0,
    'Value for Money': 0,
  };

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an overall rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = await SessionService.getUserId();
      if (userId == null) throw 'User not authenticated';

      // Calculate average aspect rating
      final avgAspectRating = _aspectRatings.values.fold(0.0, (a, b) => a + b) / _aspectRatings.length;

      // Insert review
      await SupabaseConfig.client.from('reviews').insert({
        'booking_id': widget.bookingId,
        'provider_id': widget.providerId,
        'customer_id': userId,
        'overall_rating': _rating,
        'professionalism_rating': _aspectRatings['Professionalism'],
        'communication_rating': _aspectRatings['Communication'],
        'punctuality_rating': _aspectRatings['Punctuality'],
        'quality_rating': _aspectRatings['Quality of Work'],
        'value_rating': _aspectRatings['Value for Money'],
        'average_aspect_rating': avgAspectRating,
        'review_text': _reviewController.text,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update provider rating in provider_profiles
      await _updateProviderRating();

      // Update booking status to 'reviewed'
      await SupabaseConfig.client
          .from('bookings')
          .update({'review_status': 'reviewed'})
          .eq('id', widget.bookingId);

      setState(() => _isSubmitting = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Review Submitted'),
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
            content: const Text('Thank you for your feedback!'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close review screen
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProviderRating() async {
    try {
      // Get all reviews for this provider
      final reviews = await SupabaseConfig.client
          .from('reviews')
          .select('overall_rating')
          .eq('provider_id', widget.providerId);

      if (reviews.isNotEmpty) {
        final avgRating = (reviews as List<dynamic>)
                .map((r) => (r['overall_rating'] as num).toDouble())
                .reduce((a, b) => a + b) /
            reviews.length;

        final totalReviews = reviews.length;

        // Update provider profile
        await SupabaseConfig.client
            .from('provider_profiles')
            .update({
              'average_rating': avgRating,
              'total_reviews': totalReviews,
            })
            .eq('provider_id', widget.providerId);
      }
    } catch (e) {
      print('Error updating provider rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Service'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  if (widget.providerImage != null)
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(widget.providerImage!),
                    )
                  else
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blue.shade700,
                      child: const Icon(Icons.person, color: Colors.white, size: 32),
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
                        Text(
                          widget.serviceCategory,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5F758C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Overall Rating
            const Text(
              'Overall Rating',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: RatingBar.builder(
                initialRating: _rating,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 48,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() => _rating = rating);
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _rating > 0 ? '$_rating / 5.0 stars' : 'Tap to rate',
                style: TextStyle(
                  fontSize: 14,
                  color: _rating > 0 ? Colors.green : Color(0xFF5F758C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Aspect Ratings
            const Text(
              'Rate Different Aspects',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
            const SizedBox(height: 12),
            ..._aspects.map((aspect) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          aspect,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF181511),
                          ),
                        ),
                        Text(
                          _aspectRatings[aspect]! > 0
                              ? '${_aspectRatings[aspect]?.toStringAsFixed(1)} / 5'
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RatingBar.builder(
                      initialRating: _aspectRatings[aspect] ?? 0,
                      minRating: 0,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 28,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.blue,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _aspectRatings[aspect] = rating;
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),

            // Review Text
            const Text(
              'Your Review (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your experience with this service...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
