class Refund {
  final String id;
  final String bookingId;
  final String customerId;
  final String providerId;
  final double amount;
  final String reason; // cancellation, dispute_resolved, service_not_provided, etc.
  final String status; // pending, approved, rejected, completed
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? notes;
  final String? approvedBy;

  Refund({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.notes,
    this.approvedBy,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      providerId: json['provider_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      notes: json['notes'],
      approvedBy: json['approved_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'customer_id': customerId,
      'provider_id': providerId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'notes': notes,
      'approved_by': approvedBy,
    };
  }
}

class RefundPolicy {
  final String id;
  final String reason; // cancellation, dispute, service_failure
  final int refundWindowHours; // Hours from booking to refund deadline
  final double refundPercentage; // 0-100
  final String description;
  final bool requiresApproval;

  RefundPolicy({
    required this.id,
    required this.reason,
    required this.refundWindowHours,
    required this.refundPercentage,
    required this.description,
    required this.requiresApproval,
  });

  factory RefundPolicy.fromJson(Map<String, dynamic> json) {
    return RefundPolicy(
      id: json['id'] ?? '',
      reason: json['reason'] ?? '',
      refundWindowHours: json['refund_window_hours'] ?? 24,
      refundPercentage: (json['refund_percentage'] as num?)?.toDouble() ?? 100.0,
      description: json['description'] ?? '',
      requiresApproval: json['requires_approval'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': reason,
      'refund_window_hours': refundWindowHours,
      'refund_percentage': refundPercentage,
      'description': description,
      'requires_approval': requiresApproval,
    };
  }
}

class RefundTransaction {
  final String id;
  final String refundId;
  final String fromAccount; // Where money comes from
  final String toAccount; // Customer's account/bank
  final double amount;
  final String method; // wallet, bank_transfer, original_payment_method
  final String status; // pending, processing, completed, failed
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  RefundTransaction({
    required this.id,
    required this.refundId,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  factory RefundTransaction.fromJson(Map<String, dynamic> json) {
    return RefundTransaction(
      id: json['id'] ?? '',
      refundId: json['refund_id'] ?? '',
      fromAccount: json['from_account'] ?? '',
      toAccount: json['to_account'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method'] ?? 'wallet',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      failureReason: json['failure_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'refund_id': refundId,
      'from_account': fromAccount,
      'to_account': toAccount,
      'amount': amount,
      'method': method,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'failure_reason': failureReason,
    };
  }
}
