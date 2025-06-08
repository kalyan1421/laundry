// models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import './user_model.dart'; // Assuming UserModel is in the same directory

class OrderModel {
  final String id;
  final String userId;
  final String? orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String? paymentMethod;
  final String? deliveryAddress;
  final String? pickupAddress;
  final Timestamp orderTimestamp;
  final String? serviceType;
  final String? assignedTo;
  final UserModel? customer; // Added customer details

  OrderModel({
    required this.id,
    required this.userId,
    this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.deliveryAddress,
    this.pickupAddress,
    required this.orderTimestamp,
    this.serviceType,
    this.assignedTo,
    this.customer, // Added to constructor
  });

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      orderNumber: data['orderNumber'] as String?,
      items: (data['items'] as List<dynamic>?)
              ?.map((itemData) => OrderItem.fromMap(itemData as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'Unknown',
      paymentMethod: data['paymentMethod'] as String?,
      deliveryAddress: data['deliveryAddress'] as String?,
      pickupAddress: data['pickupAddress'] as String?,
      orderTimestamp: data['orderTimestamp'] as Timestamp? ?? Timestamp.now(),
      serviceType: data['serviceType'] as String?,
      assignedTo: data['assignedTo'] as String?,
      customer: null, // Customer will be populated by the service layer
    );
  }

  OrderModel copyWith({UserModel? customerInfo}) {
    return OrderModel(
      id: id,
      userId: userId,
      orderNumber: orderNumber,
      items: items,
      totalAmount: totalAmount,
      status: status,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      pickupAddress: pickupAddress,
      orderTimestamp: orderTimestamp,
      serviceType: serviceType,
      assignedTo: assignedTo,
      customer: customerInfo ?? customer, // Use new customerInfo or keep existing
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
      'pickupAddress': pickupAddress,
      'orderTimestamp': orderTimestamp,
      'serviceType': serviceType,
      if (assignedTo != null) 'assignedTo': assignedTo,
    };
  }
}

class OrderItem {
  final String itemId;
  final String name;
  final int quantity;
  final double pricePerPiece;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.pricePerPiece,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'pricePerPiece': pricePerPiece,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemId: map['itemId'] as String? ?? map['garmentId'] as String? ?? map['productId'] as String? ?? '',
      name: map['name'] as String? ?? map['itemName'] as String? ?? 'Unknown Item',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      pricePerPiece: (map['pricePerPiece'] as num?)?.toDouble() ?? (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
