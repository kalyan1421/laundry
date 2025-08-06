import 'package:intl/intl.dart';

/// Transaction model for UPI payments
class TransactionModel {
  final String id;
  final String orderId;
  final String customerId;
  final double amount;
  final String description;
  final String upiId;
  final String payerName;
  final String payeeVpa; // Virtual Payment Address
  final TransactionStatus status;
  final String? transactionRefId;
  final String? responseCode;
  final String? errorMessage;
  final String? upiApp; // Which UPI app was used
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.description,
    required this.upiId,
    required this.payerName,
    required this.payeeVpa,
    required this.status,
    this.transactionRefId,
    this.responseCode,
    this.errorMessage,
    this.upiApp,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  /// Create a copy of this transaction with updated fields
  TransactionModel copyWith({
    String? id,
    String? orderId,
    String? customerId,
    double? amount,
    String? description,
    String? upiId,
    String? payerName,
    String? payeeVpa,
    TransactionStatus? status,
    String? transactionRefId,
    String? responseCode,
    String? errorMessage,
    String? upiApp,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      upiId: upiId ?? this.upiId,
      payerName: payerName ?? this.payerName,
      payeeVpa: payeeVpa ?? this.payeeVpa,
      status: status ?? this.status,
      transactionRefId: transactionRefId ?? this.transactionRefId,
      responseCode: responseCode ?? this.responseCode,
      errorMessage: errorMessage ?? this.errorMessage,
      upiApp: upiApp ?? this.upiApp,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert transaction to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'customerId': customerId,
      'amount': amount,
      'description': description,
      'upiId': upiId,
      'payerName': payerName,
      'payeeVpa': payeeVpa,
      'status': status.name,
      'transactionRefId': transactionRefId,
      'responseCode': responseCode,
      'errorMessage': errorMessage,
      'upiApp': upiApp,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create transaction from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      customerId: json['customerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      upiId: json['upiId'] as String,
      payerName: json['payerName'] as String,
      payeeVpa: json['payeeVpa'] as String,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      transactionRefId: json['transactionRefId'] as String?,
      responseCode: json['responseCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
      upiApp: json['upiApp'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Get formatted amount with currency symbol
  String get formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Get formatted date and time
  String get formattedDateTime {
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
  }

  /// Get formatted completion date and time
  String? get formattedCompletionDateTime {
    if (completedAt == null) return null;
    return DateFormat('dd MMM yyyy, hh:mm a').format(completedAt!);
  }

  /// Check if transaction is successful
  bool get isSuccessful => status == TransactionStatus.success;

  /// Check if transaction is failed
  bool get isFailed => status == TransactionStatus.failed;

  /// Check if transaction is pending
  bool get isPending => status == TransactionStatus.pending;

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.success:
        return 'Success';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.timeout:
        return 'Timeout';
    }
  }

  /// Get short transaction ID for display
  String get shortTransactionId {
    return id.length > 8 ? '${id.substring(0, 8)}...' : id;
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Transaction status enumeration
enum TransactionStatus {
  pending,   // Transaction initiated
  success,   // Transaction completed successfully
  failed,    // Transaction failed
  cancelled, // Transaction cancelled by user
  timeout,   // Transaction timed out
}

/// Extension for TransactionStatus
extension TransactionStatusExtension on TransactionStatus {
  /// Get display color for the status
  String get colorCode {
    switch (this) {
      case TransactionStatus.pending:
        return '#FF9800'; // Orange
      case TransactionStatus.success:
        return '#4CAF50'; // Green
      case TransactionStatus.failed:
        return '#F44336'; // Red
      case TransactionStatus.cancelled:
        return '#9E9E9E'; // Grey
      case TransactionStatus.timeout:
        return '#FF5722'; // Deep Orange
    }
  }

  /// Get icon for the status
  String get iconName {
    switch (this) {
      case TransactionStatus.pending:
        return 'access_time';
      case TransactionStatus.success:
        return 'check_circle';
      case TransactionStatus.failed:
        return 'error';
      case TransactionStatus.cancelled:
        return 'cancel';
      case TransactionStatus.timeout:
        return 'timer_off';
    }
  }
} 