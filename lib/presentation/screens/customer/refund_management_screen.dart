import 'package:flutter/material.dart';
import 'package:servyn/data/repositories/refund_repository.dart';
import 'package:servyn/domain/entities/refund.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/refund.dart';

class RefundManagementScreen extends StatefulWidget {
  final String bookingId;
  final double bookingAmount;
  final String bookingStatus;

  const RefundManagementScreen({
    required this.bookingId,
    required this.bookingAmount,
    required this.bookingStatus,
  });

  @override
  State<RefundManagementScreen> createState() => _RefundManagementScreenState();
}

class _RefundManagementScreenState extends State<RefundManagementScreen> {
  late RefundRepository _refundRepository;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedReason = 'cancellation';
  bool _isLoading = false;
  Refund? _existingRefund;

  final List<String> _refundReasons = [
    'cancellation',
    'dispute_resolved',
    'service_not_provided',
    'customer_request',
    'refund_error',
  ];

  final Map<String, String> _reasonDescriptions = {
    'cancellation': 'Booking cancelled before service',
    'dispute_resolved': 'Refund from resolved dispute',
    'service_not_provided': 'Provider did not provide service',
    'customer_request': 'Customer requested refund',
    'refund_error': 'Refund to correct payment error',
  };

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _refundRepository = RefundRepository(supabase);
    _checkExistingRefund();
  }

  Future<void> _checkExistingRefund() async {
    try {
      final customerId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final refunds = await _refundRepository.getRefundsByCustomer(customerId);
      
      for (final refund in refunds) {
        if (refund.bookingId == widget.bookingId) {
          setState(() => _existingRefund = refund);
          break;
        }
      }
    } catch (e) {
      print('Error checking existing refund: $e');
    }
  }

  Future<void> _requestRefund() async {
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customerId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final providerId = await _getProviderId();

      final refund = await _refundRepository.createRefund(
        bookingId: widget.bookingId,
        customerId: customerId,
        providerId: providerId,
        amount: widget.bookingAmount,
        reason: _selectedReason,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refund request submitted successfully')),
        );
        setState(() => _existingRefund = refund);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getProviderId() async {
    try {
      final booking = await Supabase.instance.client
          .from('bookings')
          .select('provider_id')
          .eq('id', widget.bookingId)
          .single();

      return booking['provider_id'] ?? '';
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    if (_existingRefund != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Refund Status')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(_existingRefund!.status)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Refund Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Chip(
                          label: Text(_existingRefund!.status.toUpperCase()),
                          backgroundColor:
                              _getStatusColor(_existingRefund!.status),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Amount: ৳${_existingRefund!.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text('Reason: ${_existingRefund!.reason}'),
                    if (_existingRefund!.notes != null) ...[
                      const SizedBox(height: 8),
                      Text('Notes: ${_existingRefund!.notes}'),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Requested: ${_formatTime(_existingRefund!.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (_existingRefund!.processedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Processed: ${_formatTime(_existingRefund!.processedAt!)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_existingRefund!.status == 'pending') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your refund request is being reviewed. Admin will approve or reject within 24 hours.',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Request Refund')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Amount',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '৳${widget.bookingAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Refund Reason',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _refundReasons.length,
              (index) {
                final reason = _refundReasons[index];
                return RadioListTile(
                  title: Text(reason.replaceAll('_', ' ').toUpperCase()),
                  subtitle: Text(
                    _reasonDescriptions[reason] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() => _selectedReason = value ?? 'cancellation');
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            Text(
              'Additional Notes (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Provide any additional details...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestRefund,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request Refund'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
