class Dispute {
  final String id;
  final String bookingId;
  final String customerId;
  final String providerId;
  final String reason;
  final String description;
  final List<String> evidenceUrls; // Photos/files
  final String status; // open, under_review, resolved, closed
  final String? resolution; // Admin decision
  final String? adminId;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final double? refundAmount;
  final String priority; // low, medium, high, urgent

  Dispute({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.reason,
    required this.description,
    required this.evidenceUrls,
    required this.status,
    this.resolution,
    this.adminId,
    required this.createdAt,
    this.resolvedAt,
    this.refundAmount,
    required this.priority,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      providerId: json['provider_id'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      evidenceUrls: List<String>.from(json['evidence_urls'] ?? []),
      status: json['status'] ?? 'open',
      resolution: json['resolution'],
      adminId: json['admin_id'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      refundAmount: (json['refund_amount'] as num?)?.toDouble(),
      priority: json['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'customer_id': customerId,
      'provider_id': providerId,
      'reason': reason,
      'description': description,
      'evidence_urls': evidenceUrls,
      'status': status,
      'resolution': resolution,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'refund_amount': refundAmount,
      'priority': priority,
    };
  }
}

class DisputeComment {
  final String id;
  final String disputeId;
  final String userId;
  final String userType; // customer, provider, admin
  final String message;
  final List<String> attachments;
  final DateTime createdAt;

  DisputeComment({
    required this.id,
    required this.disputeId,
    required this.userId,
    required this.userType,
    required this.message,
    required this.attachments,
    required this.createdAt,
  });

  factory DisputeComment.fromJson(Map<String, dynamic> json) {
    return DisputeComment(
      id: json['id'] ?? '',
      disputeId: json['dispute_id'] ?? '',
      userId: json['user_id'] ?? '',
      userType: json['user_type'] ?? 'customer',
      message: json['message'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispute_id': disputeId,
      'user_id': userId,
      'user_type': userType,
      'message': message,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
