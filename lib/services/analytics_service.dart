import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _supabase;

  AnalyticsService(this._supabase);

  // Admin Dashboard Analytics
  Future<Map<String, dynamic>> getAdminDashboardMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
        // Total bookings
        final bookingsResp = await _supabase
          .from('bookings')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final bookingsCount = (bookingsResp as List).length;

        // Completed bookings
        final completedBookingsResp = await _supabase
          .from('bookings')
          .select()
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final completedBookingsCount = (completedBookingsResp as List).length;

        // Total revenue
      final revenueResp = await _supabase.from('bookings').select('amount')
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String());
      final revenueData = revenueResp as List;
      double totalRevenue = 0;
      for (final booking in revenueData) {
        totalRevenue += (booking['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Average rating
        final ratingsResp = await _supabase
          .from('reviews')
          .select('rating')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final ratingsData = ratingsResp as List;
      double averageRating = 0;
      if (ratingsData.isNotEmpty) {
        double totalRating = 0;
        for (final review in ratingsData) {
          totalRating += (review['rating'] as num?)?.toDouble() ?? 0.0;
        }
        averageRating = totalRating / ratingsData.length;
      }

        // Disputed bookings
        final disputedResp = await _supabase
          .from('disputes')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final disputedCount = (disputedResp as List).length;

      return {
        'total_bookings': bookingsCount,
        'completed_bookings': completedBookingsCount,
        'completion_rate': completedBookingsCount / (bookingsCount > 0 ? bookingsCount : 1),
        'total_revenue': totalRevenue,
        'average_rating': averageRating,
        'disputed_bookings': disputedCount,
        'date_range': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Failed to fetch admin metrics: $e');
    }
  }

  // Provider Analytics
  Future<Map<String, dynamic>> getProviderAnalytics({
    required String providerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
        // Total bookings
        final bookingsResp = await _supabase
          .from('bookings')
          .select()
          .eq('provider_id', providerId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final bookingsCount = (bookingsResp as List).length;

        // Completed bookings
        final completedResp = await _supabase
          .from('bookings')
          .select()
          .eq('provider_id', providerId)
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final completedCount = (completedResp as List).length;

        // Declined bookings
        final declinedResp = await _supabase
          .from('bookings')
          .select()
          .eq('provider_id', providerId)
          .eq('status', 'declined')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final declinedCount = (declinedResp as List).length;

      // Revenue
        final revenueResp = await _supabase
          .from('bookings')
          .select('amount')
          .eq('provider_id', providerId)
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final revenueData = revenueResp as List;
      double totalEarnings = 0;
      for (final booking in revenueData) {
        totalEarnings += (booking['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Average rating from reviews
        final reviewsResp = await _supabase
          .from('reviews')
          .select('rating')
          .eq('provider_id', providerId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final reviewsData = reviewsResp as List;
      double averageRating = 0;
      if (reviewsData.isNotEmpty) {
        double totalRating = 0;
        for (final review in reviewsData) {
          totalRating += (review['rating'] as num?)?.toDouble() ?? 0.0;
        }
        averageRating = totalRating / reviewsData.length;
      }

      return {
        'total_bookings': bookingsCount,
        'completed_bookings': completedCount,
        'declined_bookings': declinedCount,
        'acceptance_rate': (bookingsCount - declinedCount) / (bookingsCount > 0 ? bookingsCount : 1),
        'completion_rate': completedCount / (bookingsCount > 0 ? bookingsCount : 1),
        'total_earnings': totalEarnings,
        'average_rating': averageRating,
        'total_reviews': reviewsData.length,
      };
    } catch (e) {
      throw Exception('Failed to fetch provider analytics: $e');
    }
  }

  // Customer Analytics
  Future<Map<String, dynamic>> getCustomerAnalytics({
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
        // Total bookings
        final bookingsResp = await _supabase
          .from('bookings')
          .select()
          .eq('customer_id', customerId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final bookingsCount = (bookingsResp as List).length;

        // Completed bookings
        final completedResp = await _supabase
          .from('bookings')
          .select()
          .eq('customer_id', customerId)
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final completedCount = (completedResp as List).length;

      // Total spent
        final spendingResp = await _supabase
          .from('bookings')
          .select('amount')
          .eq('customer_id', customerId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final spendingData = spendingResp as List;
      double totalSpent = 0;
      for (final booking in spendingData) {
        totalSpent += (booking['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Average rating given
        final ratingsResp = await _supabase
          .from('reviews')
          .select('rating')
          .eq('customer_id', customerId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final ratingsData = ratingsResp as List;
      double averageRatingGiven = 0;
      if (ratingsData.isNotEmpty) {
        double totalRating = 0;
        for (final rating in ratingsData) {
          totalRating += (rating['rating'] as num?)?.toDouble() ?? 0.0;
        }
        averageRatingGiven = totalRating / ratingsData.length;
      }

        // Disputes filed
        final disputesResp = await _supabase
          .from('disputes')
          .select()
          .eq('customer_id', customerId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final disputesCount = (disputesResp as List).length;

      return {
        'total_bookings': bookingsCount,
        'completed_bookings': completedCount,
        'completion_rate': completedCount / (bookingsCount > 0 ? bookingsCount : 1),
        'total_spent': totalSpent,
        'average_spent_per_booking': bookingsCount > 0 ? totalSpent / bookingsCount : 0,
        'average_rating_given': averageRatingGiven,
        'total_reviews': ratingsData.length,
        'disputes_filed': disputesCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch customer analytics: $e');
    }
  }

  // Revenue breakdown by service category
  Future<List<Map<String, dynamic>>> getRevenueByCategory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
        final revenueResp = await _supabase
          .from('bookings')
          .select('service_category, amount')
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final revenueData = revenueResp as List;
      final categoryRevenue = <String, double>{};
      for (final booking in revenueData) {
        final category = booking['service_category'] ?? 'Unknown';
        final amount = (booking['amount'] as num?)?.toDouble() ?? 0.0;
        categoryRevenue[category] = (categoryRevenue[category] ?? 0) + amount;
      }

      return categoryRevenue.entries
          .map((e) => {'category': e.key, 'revenue': e.value})
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch revenue by category: $e');
    }
  }

  // Booking trends over time
  Future<List<Map<String, dynamic>>> getBookingTrends({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final bookingsResp = await _supabase
          .from('bookings')
          .select('created_at, status')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: true);
      final bookingsData = bookingsResp as List;
      final dailyTrends = <String, Map<String, int>>{};
      for (final booking in bookingsData) {
        final date = DateTime.parse(booking['created_at']).toString().split(' ')[0];
        final status = booking['status'] ?? 'unknown';
        if (!dailyTrends.containsKey(date)) {
          dailyTrends[date] = {'total': 0, 'completed': 0, 'pending': 0};
        }
        dailyTrends[date]!['total'] = (dailyTrends[date]!['total'] ?? 0) + 1;
        if (status == 'completed') {
          dailyTrends[date]!['completed'] = (dailyTrends[date]!['completed'] ?? 0) + 1;
        } else if (status == 'pending') {
          dailyTrends[date]!['pending'] = (dailyTrends[date]!['pending'] ?? 0) + 1;
        }
      }
      return dailyTrends.entries
          .map((e) => {
                'date': e.key,
                ...e.value,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch booking trends: $e');
    }
  }

  // Top performing providers
  Future<List<Map<String, dynamic>>> getTopProviders({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
  }) async {
    try {
      final providersResp = await _supabase
          .from('provider_profiles')
          .select('id, full_name, average_rating, completed_jobs, total_reviews');
      final providersData = providersResp as List;
      final providers = <Map<String, dynamic>>[];
      for (final provider in providersData) {
        final completedBookingsResp = await _supabase
          .from('bookings')
          .select()
          .eq('provider_id', provider['id'])
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final completedBookingsCount = (completedBookingsResp as List).length;
        providers.add({
          'id': provider['id'],
          'name': provider['full_name'],
          'rating': provider['average_rating'],
          'completed_jobs': completedBookingsCount,
          'total_reviews': provider['total_reviews'],
        });
      }
      providers.sort((a, b) {
        final jobsCompare =
            (b['completed_jobs'] as int).compareTo(a['completed_jobs'] as int);
        if (jobsCompare != 0) return jobsCompare;
        return (b['rating'] as num).compareTo(a['rating'] as num);
      });
      return providers.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch top providers: $e');
    }
  }

  // User growth metrics
  Future<Map<String, dynamic>> getUserGrowthMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
        final newCustomersResp = await _supabase
          .from('customer_profiles')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final newCustomers = (newCustomersResp as List).length;

        final newProvidersResp = await _supabase
          .from('provider_profiles')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
        final newProviders = (newProvidersResp as List).length;

        final totalCustomersResp = await _supabase
          .from('customer_profiles')
          .select();
        final totalCustomers = (totalCustomersResp as List).length;

        final totalProvidersResp = await _supabase
          .from('provider_profiles')
          .select();
        final totalProviders = (totalProvidersResp as List).length;

        return {
        'new_customers': newCustomers,
        'new_providers': newProviders,
        'total_customers': totalCustomers,
        'total_providers': totalProviders,
        'customer_growth_rate': newCustomers / (totalCustomers > 0 ? totalCustomers : 1),
        'provider_growth_rate': newProviders / (totalProviders > 0 ? totalProviders : 1),
        };
    } catch (e) {
      throw Exception('Failed to fetch user growth metrics: $e');
    }
  }
}
