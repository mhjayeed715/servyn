import 'package:flutter/material.dart';
import 'package:servyn/data/repositories/dispute_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class Dispute {
  final String status;
  final String priority;
  final String reason;
  final String description;
  final List<String> evidenceUrls;
  final String? resolution;
  final double? refundAmount;
  final DateTime? resolvedAt;
  final String customerId;
  final String providerId;

  Dispute({
    required this.status,
    required this.priority,
    required this.reason,
    required this.description,
    required this.evidenceUrls,
    this.resolution,
    this.refundAmount,
    this.resolvedAt,
    required this.customerId,
    required this.providerId,
  });
}

class DisputeComment {
  final String userId;
  final String userType;
  final String message;
  final DateTime createdAt;

  DisputeComment({
    required this.userId,
    required this.userType,
    required this.message,
    required this.createdAt,
  });
}

class DisputeRepository {
  final dynamic supabase;
  DisputeRepository(this.supabase);

  Future<Dispute> getDisputeById(String id) async {
    // Dummy implementation
    return Dispute(
      status: 'open',
      priority: 'high',
      reason: 'Sample Reason',
      description: 'Sample Description',
      evidenceUrls: [],
      customerId: 'customer_id',
      providerId: 'provider_id',
    );
  }

  Future<List<DisputeComment>> getDisputeComments(String id) async {
    // Dummy implementation
    return [
      DisputeComment(
        userId: 'customer_id',
        userType: 'customer',
        message: 'Sample comment',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  Future<void> addComment({
    required String disputeId,
    required String userId,
    required String userType,
    required String message,
    required List attachments,
  }) async {
    // Dummy implementation
    return;
  }
}

class DisputeDetailScreen extends StatefulWidget {
  final String disputeId;

  const DisputeDetailScreen({required this.disputeId});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  late DisputeRepository _disputeRepository;
  final _commentController = TextEditingController();
  
  Dispute? _dispute;
  List<DisputeComment> _comments = [];
  bool _isLoading = true;
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _disputeRepository = DisputeRepository(supabase);
    _loadDispute();
  }

  Future<void> _loadDispute() async {
    try {
      final dispute = await _disputeRepository.getDisputeById(widget.disputeId);
      final comments = await _disputeRepository.getDisputeComments(widget.disputeId);
      
      setState(() {
        _dispute = dispute;
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dispute: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isSendingComment = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final userType = _getUserType(userId);

      await _disputeRepository.addComment(
        disputeId: widget.disputeId,
        userId: userId,
        userType: userType,
        message: _commentController.text,
        attachments: [],
      );

      _commentController.clear();
      await _loadDispute();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    } finally {
      setState(() => _isSendingComment = false);
    }
  }

  String _getUserType(String userId) {
    // Determine user type from dispute
    if (_dispute?.customerId == userId) return 'customer';
    if (_dispute?.providerId == userId) return 'provider';
    return 'admin';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_dispute == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute Details')),
        body: const Center(child: Text('Dispute not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Details'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Priority badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(
                          _dispute!.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getStatusColor(_dispute!.status),
                      ),
                      Chip(
                        label: Text(
                          _dispute!.priority.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getPriorityColor(_dispute!.priority),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dispute reason
                  Text(
                    'Reason',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_dispute!.reason),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_dispute!.description),
                  const SizedBox(height: 16),

                  // Evidence
                  if (_dispute!.evidenceUrls.isNotEmpty) ...[
                    Text(
                      'Evidence',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _dispute!.evidenceUrls.map((url) {
                        return GestureDetector(
                          onTap: () {
                            // Open in full screen or browser
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.attachment),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Timeline
                  if (_dispute!.resolvedAt != null) ...[
                    Text(
                      'Resolution',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resolution: ${_dispute!.resolution}'),
                          if (_dispute!.refundAmount != null)
                            Text('Refund: ৳${_dispute!.refundAmount?.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Comments section header
                  Text(
                    'Conversation (${_comments.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Comments list
                  ..._comments.map((comment) {
                    final isCurrentUser =
                        comment.userId == Supabase.instance.client.auth.currentUser?.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.blue.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  comment.userType.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatTime(comment.createdAt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comment.message),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          // Comment input
          if (_dispute!.status == 'open' || _dispute!.status == 'under_review')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSendingComment ? null : _addComment,
                    icon: _isSendingComment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
