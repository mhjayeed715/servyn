import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

class MatchingService {
  final SupabaseClient _supabase;

  MatchingService(this._supabase);

  /// Auto-assign booking to next available provider
  Future<String?> autoAssignProvider({
    required String bookingId,
    required double customerLat,
    required double customerLng,
    required String serviceCategory,
    required String rejectedProviderId,
  }) async {
    try {
      // Get available providers near customer location
      final providers = await _getNearbyAvailableProviders(
        customerLat: customerLat,
        customerLng: customerLng,
        serviceCategory: serviceCategory,
        excludeProviderId: rejectedProviderId,
      );

      if (providers.isEmpty) {
        // No providers available - set booking to unassigned_waiting
        await _supabase
            .from('bookings')
            .update({
              'status': 'unassigned_waiting',
              'reassignment_count': _getReassignmentCount(bookingId) + 1,
            })
            .eq('id', bookingId);
        
        return null;
      }

      // Assign to first available provider
      final assignedProviderId = providers.first['id'];
      
      await _supabase.from('bookings').update({
        'provider_id': assignedProviderId,
        'status': 'provider_assigned',
        'assigned_at': DateTime.now().toIso8601String(),
        'reassignment_count': _getReassignmentCount(bookingId) + 1,
      }).eq('id', bookingId);

      // Send notification to provider
      await _sendProviderNotification(
        providerId: assignedProviderId,
        bookingId: bookingId,
        reason: 'auto_assigned',
      );

      // Log reassignment
      await _logReassignment(
        bookingId: bookingId,
        fromProviderId: rejectedProviderId,
        toProviderId: assignedProviderId,
        reason: 'provider_declined',
      );

      return assignedProviderId;
    } catch (e) {
      throw Exception('Auto-assignment failed: $e');
    }
  }

  /// Get nearby available providers
  Future<List<Map<String, dynamic>>> _getNearbyAvailableProviders({
    required double customerLat,
    required double customerLng,
    required String serviceCategory,
    required String excludeProviderId,
    double radiusKm = 15,
  }) async {
    try {
      // Get all verified providers in service category
      final response = await _supabase.from('provider_profiles').select().match({
        'verification_status': 'verified',
        'service_category': serviceCategory,
        'is_active': true,
      });

      if (response.isEmpty) return [];

      final providers = (response as List)
          .where((p) => p['id'] != excludeProviderId)
          .toList();

      // Calculate distance and sort
      final providerDistances = <Map<String, dynamic>>[];

      for (final provider in providers) {
        final distance = Geolocator.distanceBetween(
          customerLat,
          customerLng,
          provider['latitude'] ?? 0.0,
          provider['longitude'] ?? 0.0,
        );

        if (distance / 1000 <= radiusKm) {
          // Check provider availability
          if (await _isProviderAvailable(provider['id'])) {
            providerDistances.add({
              'id': provider['id'],
              'distance': distance,
              'rating': provider['average_rating'] ?? 0.0,
              'completed_jobs': provider['completed_jobs'] ?? 0,
            });
          }
        }
      }

      // Sort by: distance, then rating, then completed jobs
      providerDistances.sort((a, b) {
        // Prefer closer providers
        final distanceCompare = (a['distance'] as num)
            .compareTo(b['distance'] as num);
        if (distanceCompare != 0) return distanceCompare;

        // Then prefer higher-rated providers
        final ratingCompare = (b['rating'] as num)
            .compareTo(a['rating'] as num);
        if (ratingCompare != 0) return ratingCompare;

        // Then prefer more experienced providers
        return (b['completed_jobs'] as num)
            .compareTo(a['completed_jobs'] as num);
      });

      return providerDistances.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error fetching nearby providers: $e');
    }
  }

  /// Check if provider is currently available
  Future<bool> _isProviderAvailable(String providerId) async {
    try {
      // Check if provider has active/ongoing bookings
      final ongoingBookings = await _supabase
          .from('bookings')
          .select()
          .eq('provider_id', providerId)
          .inFilter('status', ['confirmed', 'en_route', 'in_progress']);

      // Check provider's max concurrent bookings
      final providerProfile = await _supabase
          .from('provider_profiles')
          .select('max_concurrent_jobs')
          .eq('id', providerId)
          .single();

      final maxJobs = providerProfile['max_concurrent_jobs'] ?? 1;
      
      return ongoingBookings.length < maxJobs;
    } catch (e) {
      return false;
    }
  }

  /// Send notification to provider about booking
  Future<void> _sendProviderNotification({
    required String providerId,
    required String bookingId,
    required String reason,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': providerId,
        'type': reason == 'auto_assigned' ? 'booking_assigned' : 'booking_reassigned',
        'title': reason == 'auto_assigned' 
            ? 'New Booking Available' 
            : 'You have been reassigned a booking',
        'body': 'A new service request is waiting for your acceptance.',
        'booking_id': bookingId,
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Here you would also send push notification via Firebase
      // await _notificationService.sendPushNotification(providerId, ...)
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  /// Log reassignment event for analytics
  Future<void> _logReassignment({
    required String bookingId,
    required String fromProviderId,
    required String toProviderId,
    required String reason,
  }) async {
    try {
      await _supabase.from('booking_reassignments').insert({
        'id': const Uuid().v4(),
        'booking_id': bookingId,
        'from_provider_id': fromProviderId,
        'to_provider_id': toProviderId,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log reassignment: $e');
    }
  }

  /// Get current reassignment count for booking
  int _getReassignmentCount(String bookingId) {
    // This should be fetched from database
    // For now, returning 0 as placeholder
    return 0;
  }

  /// Get waiting bookings and try to assign them
  Future<void> assignWaitingBookings() async {
    try {
      final waitingBookings = await _supabase
          .from('bookings')
          .select()
          .eq('status', 'unassigned_waiting')
          .filter('reassignment_count', 'lt', 3) // Max 3 reassignments
          .order('created_at', ascending: true);

      for (final booking in waitingBookings as List) {
        await autoAssignProvider(
          bookingId: booking['id'],
          customerLat: booking['customer_latitude'] ?? 0.0,
          customerLng: booking['customer_longitude'] ?? 0.0,
          serviceCategory: booking['service_category'] ?? '',
          rejectedProviderId: '', // Try all providers
        );
      }
    } catch (e) {
      print('Error assigning waiting bookings: $e');
    }
  }
}
