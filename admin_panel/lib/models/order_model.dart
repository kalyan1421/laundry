
// models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String paymentMode;
  final GeoPoint pickupLocation;
  final GeoPoint deliveryLocation;
  final String orderType; // 'normal', 'quick_delivery', 'quick_call'
  final String? assignedTo;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMode,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.orderType,
    this.assignedTo,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'paymentMode': paymentMode,
      'pickupLocation': pickupLocation,
      'deliveryLocation': deliveryLocation,
      'orderType': orderType,
      'assignedTo': assignedTo,
      'createdAt': createdAt,
    };
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item))
          .toList() ?? [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentMode: map['paymentMode'] ?? 'cash',
      pickupLocation: map['pickupLocation'] ?? const GeoPoint(0, 0),
      deliveryLocation: map['deliveryLocation'] ?? const GeoPoint(0, 0),
      orderType: map['orderType'] ?? 'normal',
      assignedTo: map['assignedTo'],
      createdAt: (map['createdAt']?.toDate()) ?? DateTime.now(),
    );
  }
}

class OrderItem {
  final String itemId;
  final String itemName;
  final int quantity;
  final double price;

  OrderItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }
}
