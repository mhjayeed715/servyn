import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/refund.dart';

class RefundRepository {
  final SupabaseClient _supabase;

  RefundRepository(this._supabase);

  // Create refund request
  Future<Refund> createRefund({
    required String bookingId,
    required String customerId,
    required String providerId,
    required double amount,
    required String reason,
    String? notes,
  }) async {
    try {
      // Get refund policy
      final policy = await _getRefundPolicy(reason);

      // Check if within refund window
      final booking = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      final bookingTime = DateTime.parse(booking['created_at']);
      final now = DateTime.now();
      final hoursDifference = now.difference(bookingTime).inHours;

      if (hoursDifference > policy.refundWindowHours) {
        throw Exception('Refund window has expired');
      }

      // Calculate refundable amount
      final refundAmount = amount * (policy.refundPercentage / 100);

      final id = const Uuid().v4();
      final refund = {
        'id': id,
        'booking_id': bookingId,
        'customer_id': customerId,
        'provider_id': providerId,
        'amount': refundAmount,
        'reason': reason,
        'status': policy.requiresApproval ? 'pending' : 'approved',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('refunds').insert(refund);

      // If doesn't require approval, process immediately
      if (!policy.requiresApproval) {
        await _processRefund(id);
      }

      return Refund.fromJson(refund);
    } catch (e) {
      throw Exception('Failed to create refund: $e');
    }
  }

  // Get refund by ID
  Future<Refund> getRefundById(String refundId) async {
    try {
      final response = await _supabase
          .from('refunds')
          .select()
          .eq('id', refundId)
          .single();

      return Refund.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch refund: $e');
    }
  }

  // Get refunds for customer
  Future<List<Refund>> getRefundsByCustomer(String customerId) async {
    try {
      final response = await _supabase
          .from('refunds')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List).map((r) => Refund.fromJson(r)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer refunds: $e');
    }
  }

  // Get pending refunds (admin)
  Future<List<Refund>> getPendingRefunds() async {
    try {
      final response = await _supabase
          .from('refunds')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return (response as List).map((r) => Refund.fromJson(r)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending refunds: $e');
    }
  }

  // Approve refund (admin)
  Future<void> approveRefund({
    required String refundId,
    required String adminId,
  }) async {
    try {
      await _supabase.from('refunds').update({
        'status': 'approved',
        'approved_by': adminId,
      }).eq('id', refundId);

      await _processRefund(refundId);
    } catch (e) {
      throw Exception('Failed to approve refund: $e');
    }
  }

  // Reject refund (admin)
  Future<void> rejectRefund({
    required String refundId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _supabase.from('refunds').update({
        'status': 'rejected',
        'approved_by': adminId,
        'notes': reason,
      }).eq('id', refundId);
    } catch (e) {
      throw Exception('Failed to reject refund: $e');
    }
  }

  // Process refund (internal - execute the actual transaction)
  Future<void> _processRefund(String refundId) async {
    try {
      final refund = await getRefundById(refundId);

      // Create transaction
      final transactionId = const Uuid().v4();
      final transaction = {
        'id': transactionId,
        'refund_id': refundId,
        'from_account': 'escrow',
        'to_account': refund.customerId,
        'amount': refund.amount,
        'method': 'wallet', // Default method
        'status': 'processing',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('refund_transactions').insert(transaction);

      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 5));

      // Update transaction status to completed
      await _supabase
          .from('refund_transactions')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      // Update refund status
      await _supabase.from('refunds').update({
        'status': 'completed',
        'processed_at': DateTime.now().toIso8601String(),
      }).eq('id', refundId);

      // Add funds to customer wallet
      await _addToCustomerWallet(refund.customerId, refund.amount);

      // Remove from escrow
      await _removeFromEscrow(refund.bookingId, refund.amount);

      // Log refund event
      await _supabase.from('refund_audit_log').insert({
        'id': const Uuid().v4(),
        'refund_id': refundId,
        'action': 'refund_processed',
        'details': 'Refund successfully processed and added to customer wallet',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error processing refund: $e');
      // Update transaction status to failed
      await _supabase.from('refund_transactions').update({
        'status': 'failed',
        'failure_reason': e.toString(),
      }).eq('refund_id', refundId);
    }
  }

  // Add funds to customer wallet
  Future<void> _addToCustomerWallet(String customerId, double amount) async {
    try {
      // This would integrate with your wallet system
      // For now, just a placeholder
      print('Adding ৳$amount to wallet for customer $customerId');
    } catch (e) {
      throw Exception('Failed to add funds to wallet: $e');
    }
  }

  // Remove from escrow
  Future<void> _removeFromEscrow(String bookingId, double amount) async {
    try {
      // Update escrow balance for booking
      final booking = await _supabase
          .from('bookings')
          .select('escrow_amount')
          .eq('id', bookingId)
          .single();

      final currentEscrow = (booking['escrow_amount'] as num?)?.toDouble() ?? 0.0;
      final newEscrow = currentEscrow - amount;

      await _supabase.from('bookings').update({
        'escrow_amount': newEscrow,
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to update escrow: $e');
    }
  }

  // Get refund policy
  Future<RefundPolicy> _getRefundPolicy(String reason) async {
    try {
      final response = await _supabase
          .from('refund_policies')
          .select()
          .eq('reason', reason)
          .single();

      return RefundPolicy.fromJson(response);
    } catch (e) {
      // Return default policy if not found
      return RefundPolicy(
        id: 'default',
        reason: reason,
        refundWindowHours: 24,
        refundPercentage: 100.0,
        description: 'Default refund policy',
        requiresApproval: true,
      );
    }
  }

  // Get refund statistics
  Future<Map<String, dynamic>> getRefundStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final refunds = await _supabase
          .from('refunds')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      double totalRefunded = 0;
      int totalRefunds = 0;
      int approvedCount = 0;
      int rejectedCount = 0;
      int pendingCount = 0;

      for (final refund in refunds as List) {
        totalRefunded += (refund['amount'] as num?)?.toDouble() ?? 0.0;
        totalRefunds++;

        final status = refund['status'];
        if (status == 'completed') approvedCount++;
        if (status == 'rejected') rejectedCount++;
        if (status == 'pending') pendingCount++;
      }

      return {
        'total_refunded': totalRefunded,
        'total_refunds': totalRefunds,
        'approved_count': approvedCount,
        'rejected_count': rejectedCount,
        'pending_count': pendingCount,
        'approval_rate': totalRefunds > 0 ? approvedCount / totalRefunds : 0,
        'average_refund_amount': totalRefunds > 0 ? totalRefunded / totalRefunds : 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch refund statistics: $e');
    }
  }
}
