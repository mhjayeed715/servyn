import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/refund_repository.dart';
import '../../domain/entities/refund.dart';

class AdminRefundManagementScreen extends StatefulWidget {
  const AdminRefundManagementScreen();

  @override
  State<AdminRefundManagementScreen> createState() =>
      _AdminRefundManagementScreenState();
}

class _AdminRefundManagementScreenState
    extends State<AdminRefundManagementScreen> {
  late RefundRepository _refundRepository;
  late Stream<List<Map<String, dynamic>>> _pendingRefundsStream;
  bool _isLoading = true;
  List<Refund> _pendingRefunds = [];

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _refundRepository = RefundRepository(supabase);
    _loadPendingRefunds();
  }

  Future<void> _loadPendingRefunds() async {
    try {
      final refunds = await _refundRepository.getPendingRefunds();
      setState(() {
        _pendingRefunds = refunds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading refunds: $e')),
        );
      }
    }
  }

  Future<void> _approveRefund(String refundId) async {
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id ?? '';
      await _refundRepository.approveRefund(
        refundId: refundId,
        adminId: adminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refund approved')),
        );
        await _loadPendingRefunds();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving refund: $e')),
        );
      }
    }
  }

  Future<void> _rejectRefund(String refundId, String reason) async {
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id ?? '';
      await _refundRepository.rejectRefund(
        refundId: refundId,
        adminId: adminId,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refund rejected')),
        );
        await _loadPendingRefunds();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting refund: $e')),
        );
      }
    }
  }

  void _showRejectDialog(Refund refund) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Refund'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRefund(refund.id, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRefunds,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRefunds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text('No pending refunds'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _pendingRefunds.length,
                  itemBuilder: (context, index) {
                    final refund = _pendingRefunds[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          'Refund Request - ৳${refund.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${refund.reason.replaceAll('_', ' ').toUpperCase()} • ${refund.createdAt.toString().split(' ')[0]}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  'Booking ID',
                                  refund.bookingId,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Customer ID',
                                  refund.customerId,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Provider ID',
                                  refund.providerId,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Amount',
                                  '৳${refund.amount.toStringAsFixed(2)}',
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Reason',
                                  refund.reason.replaceAll('_', ' ').toUpperCase(),
                                ),
                                if (refund.notes != null) ...[
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Notes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(refund.notes!),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _showRejectDialog(refund),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _approveRefund(refund.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(value),
        ),
      ],
    );
  }
}
