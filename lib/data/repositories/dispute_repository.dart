import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/dispute.dart';

class DisputeRepository {
  final SupabaseClient _supabase;

  DisputeRepository(this._supabase);

  // Create a new dispute
  Future<Dispute> createDispute({
    required String bookingId,
    required String customerId,
    required String providerId,
    required String reason,
    required String description,
    required List<String> evidenceUrls,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();

      final dispute = {
        'id': id,
        'booking_id': bookingId,
        'customer_id': customerId,
        'provider_id': providerId,
        'reason': reason,
        'description': description,
        'evidence_urls': evidenceUrls,
        'status': 'open',
        'priority': _calculatePriority(reason),
        'created_at': now.toIso8601String(),
      };

      await _supabase.from('disputes').insert(dispute);

      // Update booking status to disputed
      await _supabase
          .from('bookings')
          .update({'status': 'disputed'}).eq('id', bookingId);

      return Dispute.fromJson(dispute);
    } catch (e) {
      throw Exception('Failed to create dispute: $e');
    }
  }

  // Get dispute by ID
  Future<Dispute> getDisputeById(String disputeId) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select()
          .eq('id', disputeId)
          .single();

      return Dispute.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch dispute: $e');
    }
  }

  // Get disputes by customer
  Future<List<Dispute>> getDisputesByCustomer(String customerId) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List).map((d) => Dispute.fromJson(d)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer disputes: $e');
    }
  }

  // Get disputes by provider
  Future<List<Dispute>> getDisputesByProvider(String providerId) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      return (response as List).map((d) => Dispute.fromJson(d)).toList();
    } catch (e) {
      throw Exception('Failed to fetch provider disputes: $e');
    }
  }

  // Get all open disputes (for admin)
  Future<List<Dispute>> getAllOpenDisputes() async {
    try {
      final response = await _supabase
          .from('disputes')
          .select()
          .eq('status', 'open')
          .order('priority', ascending: false)
          .order('created_at', ascending: true);

      return (response as List).map((d) => Dispute.fromJson(d)).toList();
    } catch (e) {
      throw Exception('Failed to fetch open disputes: $e');
    }
  }

  // Add comment to dispute
  Future<DisputeComment> addComment({
    required String disputeId,
    required String userId,
    required String userType,
    required String message,
    required List<String> attachments,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();

      final comment = {
        'id': id,
        'dispute_id': disputeId,
        'user_id': userId,
        'user_type': userType,
        'message': message,
        'attachments': attachments,
        'created_at': now.toIso8601String(),
      };

      await _supabase.from('dispute_comments').insert(comment);

      return DisputeComment.fromJson(comment);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Get dispute comments
  Future<List<DisputeComment>> getDisputeComments(String disputeId) async {
    try {
      final response = await _supabase
          .from('dispute_comments')
          .select()
          .eq('dispute_id', disputeId)
          .order('created_at', ascending: true);

      return (response as List).map((c) => DisputeComment.fromJson(c)).toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  // Resolve dispute (admin action)
  Future<void> resolveDispute({
    required String disputeId,
    required String resolution, // 'customer_win', 'provider_win', 'partial_refund'
    required double refundAmount,
    required String adminId,
  }) async {
    try {
      await _supabase.from('disputes').update({
        'status': 'resolved',
        'resolution': resolution,
        'refund_amount': refundAmount,
        'admin_id': adminId,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', disputeId);

      // Get dispute to update booking
      final dispute = await getDisputeById(disputeId);

      // Update booking status
      await _supabase
          .from('bookings')
          .update({'status': 'dispute_resolved'}).eq('id', dispute.bookingId);
    } catch (e) {
      throw Exception('Failed to resolve dispute: $e');
    }
  }

  // Reject dispute
  Future<void> rejectDispute(String disputeId, String adminId) async {
    try {
      await _supabase.from('disputes').update({
        'status': 'rejected',
        'admin_id': adminId,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', disputeId);
    } catch (e) {
      throw Exception('Failed to reject dispute: $e');
    }
  }

  // Calculate priority based on reason
  String _calculatePriority(String reason) {
    final lowerReason = reason.toLowerCase();
    if (lowerReason.contains('safety') ||
        lowerReason.contains('danger') ||
        lowerReason.contains('harassment')) {
      return 'urgent';
    } else if (lowerReason.contains('quality') ||
        lowerReason.contains('damage')) {
      return 'high';
    } else if (lowerReason.contains('partial') ||
        lowerReason.contains('incomplete')) {
      return 'medium';
    }
    return 'low';
  }
}
