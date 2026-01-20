import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';

class BookingDeclineHandler {
  final SupabaseClient _supabase;
  late StreamSubscription _bookingStream;

  BookingDeclineHandler(this._supabase);

  /// Initialize listening to booking decline events
  void initializeDeclineListener() {
    _bookingStream = _supabase
        .from('bookings')
        .on(RealtimeListenTypes.postgresChanges,
            ChannelFilter(event: '*', schema: 'public', table: 'bookings'))
        .listen((payload) {
      final data = payload.newRecord;
      
      // Check if status changed to declined
      if (data['status'] == 'provider_declined') {
        _handleProviderDecline(
          bookingId: data['id'],
          providerId: data['provider_id'],
          customerId: data['customer_id'],
          customerLat: data['customer_latitude'],
          customerLng: data['customer_longitude'],
          serviceCategory: data['service_category'],
        );
      }
    });
  }

  /// Handle when provider declines booking
  Future<void> _handleProviderDecline({
    required String bookingId,
    required String providerId,
    required String customerId,
    required double customerLat,
    required double customerLng,
    required String serviceCategory,
  }) async {
    try {
      // Immediately update to declined status
      await _supabase
          .from('bookings')
          .update({
            'status': 'declined',
            'declined_by': providerId,
            'declined_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      // Notify customer about decline
      await _notifyCustomerOfDecline(customerId, bookingId);

      // Attempt auto-assign to next provider
      // Delayed to give customer time to see notification
      Future.delayed(const Duration(seconds: 2), () {
        _attemptAutoReassign(
          bookingId: bookingId,
          rejectedProviderId: providerId,
          customerLat: customerLat,
          customerLng: customerLng,
          serviceCategory: serviceCategory,
        );
      });
    } catch (e) {
      print('Error handling provider decline: $e');
    }
  }

  /// Attempt to auto-reassign booking
  Future<void> _attemptAutoReassign({
    required String bookingId,
    required String rejectedProviderId,
    required double customerLat,
    required double customerLng,
    required String serviceCategory,
  }) async {
    try {
      // Get nearest available provider excluding the one who declined
      final nearbyProviders = await _getNearbyProviders(
        customerLat: customerLat,
        customerLng: customerLng,
        serviceCategory: serviceCategory,
        excludeProviderId: rejectedProviderId,
      );

      if (nearbyProviders.isNotEmpty) {
        final nextProviderId = nearbyProviders.first['id'];

        // Assign to next provider
        await _supabase.from('bookings').update({
          'provider_id': nextProviderId,
          'status': 'provider_assigned',
        }).eq('id', bookingId);

        // Notify new provider
        await _notifyProviderOfAssignment(nextProviderId, bookingId);
      } else {
        // No providers available - notify customer to wait or reschedule
        await _notifyCustomerNoProvidersAvailable(bookingId);
      }
    } catch (e) {
      print('Error attempting auto-reassign: $e');
    }
  }

  /// Get nearby available providers
  Future<List<Map<String, dynamic>>> _getNearbyProviders({
    required double customerLat,
    required double customerLng,
    required String serviceCategory,
    required String excludeProviderId,
  }) async {
    try {
      final response = await _supabase
          .from('provider_profiles')
          .select()
          .eq('service_category', serviceCategory)
          .eq('verification_status', 'verified')
          .eq('is_active', true);

      // Filter by distance and availability
      final providers = <Map<String, dynamic>>[];

      for (final provider in response as List) {
        if (provider['id'] == excludeProviderId) continue;

        // Check if within reasonable distance (15km default)
        final distance = _calculateDistance(
          customerLat,
          customerLng,
          provider['latitude'] ?? 0.0,
          provider['longitude'] ?? 0.0,
        );

        if (distance <= 15) {
          providers.add(provider);
        }
      }

      // Sort by rating (highest first) then by distance
      providers.sort((a, b) {
        final ratingCompare = (b['average_rating'] ?? 0)
            .compareTo(a['average_rating'] ?? 0);
        if (ratingCompare != 0) return ratingCompare;
        return _calculateDistance(
          customerLat,
          customerLng,
          a['latitude'] ?? 0.0,
          a['longitude'] ?? 0.0,
        ).compareTo(_calculateDistance(
          customerLat,
          customerLng,
          b['latitude'] ?? 0.0,
          b['longitude'] ?? 0.0,
        ));
      });

      return providers;
    } catch (e) {
      print('Error getting nearby providers: $e');
      return [];
    }
  }

  /// Simple distance calculation (Haversine formula approximation)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Notify customer about provider decline
  Future<void> _notifyCustomerOfDecline(String customerId, String bookingId) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': customerId,
        'type': 'provider_declined',
        'title': 'Provider Declined',
        'body': 'We are finding another provider for your booking...',
        'booking_id': bookingId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error notifying customer: $e');
    }
  }

  /// Notify new provider of assignment
  Future<void> _notifyProviderOfAssignment(String providerId, String bookingId) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': providerId,
        'type': 'booking_assigned',
        'title': 'New Booking Assigned',
        'body': 'You have been assigned a new service request.',
        'booking_id': bookingId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error notifying provider: $e');
    }
  }

  /// Notify customer no providers available
  Future<void> _notifyCustomerNoProvidersAvailable(String bookingId) async {
    try {
      final booking = await _supabase
          .from('bookings')
          .select('customer_id')
          .eq('id', bookingId)
          .single();

      await _supabase.from('notifications').insert({
        'user_id': booking['customer_id'],
        'type': 'no_providers_available',
        'title': 'No Providers Available',
        'body': 'We could not find providers in your area right now. Please try again later.',
        'booking_id': bookingId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error notifying customer of no availability: $e');
    }
  }

  /// Cleanup listener
  void dispose() {
    _bookingStream.cancel();
  }
}
