import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String? specialInstructions;
  final String status; // 'pending', 'processing', 'completed'
  final String? assignedTo; // workshop member ID
  final DateTime? startedAt;
  final DateTime? completedAt;

  OrderItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.specialInstructions,
    required this.status,
    this.assignedTo,
    this.startedAt,
    this.completedAt,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      specialInstructions: data['specialInstructions'],
      status: data['status'] ?? 'pending',
      assignedTo: data['assignedTo'],
      startedAt: data['startedAt'] != null ? (data['startedAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'specialInstructions': specialInstructions,
      'status': status,
      'assignedTo': assignedTo,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  OrderItem copyWith({
    String? name,
    String? category,
    int? quantity,
    double? price,
    String? imageUrl,
    String? specialInstructions,
    String? status,
    String? assignedTo,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return OrderItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  double get totalPrice => price * quantity;
}

class WorkshopOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String? customerQrCode;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'processing', 'completed', 'delivered'
  final String? workshopId;
  final String? assignedTo; // workshop member ID who scanned the QR
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? deliveredAt;
  final String? specialInstructions;
  final Map<String, dynamic> address;
  final List<Map<String, dynamic>> statusHistory;
  final Map<String, dynamic>? payment;
  final double? workshopEarnings;
  final Map<String, double>? memberEarnings; // member ID -> earnings

  WorkshopOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.customerQrCode,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.workshopId,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.deliveredAt,
    this.specialInstructions,
    required this.address,
    required this.statusHistory,
    this.payment,
    this.workshopEarnings,
    this.memberEarnings,
  });

  factory WorkshopOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkshopOrder(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerQrCode: data['customerQrCode'],
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      workshopId: data['workshopId'],
      assignedTo: data['assignedTo'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      startedAt: data['startedAt'] != null ? (data['startedAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      deliveredAt: data['deliveredAt'] != null ? (data['deliveredAt'] as Timestamp).toDate() : null,
      specialInstructions: data['specialInstructions'],
      address: Map<String, dynamic>.from(data['address'] ?? {}),
      statusHistory: List<Map<String, dynamic>>.from(data['statusHistory'] ?? []),
      payment: data['payment'] != null ? Map<String, dynamic>.from(data['payment']) : null,
      workshopEarnings: data['workshopEarnings']?.toDouble(),
      memberEarnings: data['memberEarnings'] != null 
          ? Map<String, double>.from(data['memberEarnings'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'customerQrCode': customerQrCode,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'workshopId': workshopId,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'specialInstructions': specialInstructions,
      'address': address,
      'statusHistory': statusHistory,
      'payment': payment,
      'workshopEarnings': workshopEarnings,
      'memberEarnings': memberEarnings,
    };
  }

  WorkshopOrder copyWith({
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerQrCode,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    String? workshopId,
    String? assignedTo,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? deliveredAt,
    String? specialInstructions,
    Map<String, dynamic>? address,
    List<Map<String, dynamic>>? statusHistory,
    Map<String, dynamic>? payment,
    double? workshopEarnings,
    Map<String, double>? memberEarnings,
  }) {
    return WorkshopOrder(
      id: id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      customerQrCode: customerQrCode ?? this.customerQrCode,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      workshopId: workshopId ?? this.workshopId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      address: address ?? this.address,
      statusHistory: statusHistory ?? this.statusHistory,
      payment: payment ?? this.payment,
      workshopEarnings: workshopEarnings ?? this.workshopEarnings,
      memberEarnings: memberEarnings ?? this.memberEarnings,
    );
  }

  // Get order ID in display format
  String get displayId {
    return '#ORD-${id.substring(0, 8).toUpperCase()}';
  }

  // Get total items count
  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get pending items count
  int get pendingItems {
    return items.where((item) => item.status == 'pending').fold(0, (sum, item) => sum + item.quantity);
  }

  // Get processing items count
  int get processingItems {
    return items.where((item) => item.status == 'processing').fold(0, (sum, item) => sum + item.quantity);
  }

  // Get completed items count
  int get completedItems {
    return items.where((item) => item.status == 'completed').fold(0, (sum, item) => sum + item.quantity);
  }

  // Get progress percentage
  double get progressPercentage {
    if (totalItems == 0) return 0.0;
    return (completedItems / totalItems) * 100;
  }

  // Check if order is ready for completion
  bool get isReadyForCompletion {
    return items.every((item) => item.status == 'completed');
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'processing':
        return 'blue';
      case 'completed':
        return 'green';
      case 'delivered':
        return 'purple';
      default:
        return 'grey';
    }
  }

  // Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }

  // Get formatted address
  String get formattedAddress {
    final addressLine1 = address['addressLine1'] ?? '';
    final addressLine2 = address['addressLine2'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final zipCode = address['zipCode'] ?? '';
    
    final parts = [addressLine1, addressLine2, city, state, zipCode]
        .where((part) => part.isNotEmpty)
        .toList();
    
    return parts.join(', ');
  }

  // Get time since created
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Get estimated completion time
  Duration get estimatedCompletionTime {
    // Base time: 30 minutes per item
    final baseTime = Duration(minutes: 30 * totalItems);
    
    // Adjust based on item categories
    int complexityMultiplier = 1;
    for (final item in items) {
      switch (item.category.toLowerCase()) {
        case 'dry_cleaning':
          complexityMultiplier = 2;
          break;
        case 'ironing':
          complexityMultiplier = 1;
          break;
        case 'washing':
          complexityMultiplier = 1;
          break;
        default:
          complexityMultiplier = 1;
      }
    }
    
    return Duration(minutes: baseTime.inMinutes * complexityMultiplier);
  }

  @override
  String toString() {
    return 'Order(id: $id, customerId: $customerId, status: $status, totalAmount: $totalAmount, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkshopOrder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 