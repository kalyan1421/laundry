import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String? orderNumber; // Human-readable order number, can be same as id if not available
  final String serviceType; // e.g., 'Professional Ironing', 'Wash & Fold'
  final Timestamp orderTimestamp;
  final String status; // Current overall status
  final double totalAmount;
  final List<Map<String, dynamic>> items;
  final String pickupAddress;
  final String deliveryAddress;
  final Timestamp pickupDate;
  final String pickupTimeSlot;
  final Timestamp deliveryDate;
  final String deliveryTimeSlot;
  final String paymentMethod;
  final String? specialInstructions;
  final List<Map<String, dynamic>> statusHistory; // New field for status updates timeline

  OrderModel({
    required this.id,
    required this.userId,
    this.orderNumber,
    required this.serviceType,
    required this.orderTimestamp,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.pickupDate,
    required this.pickupTimeSlot,
    required this.deliveryDate,
    required this.deliveryTimeSlot,
    required this.paymentMethod,
    this.specialInstructions,
    required this.statusHistory,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Determine serviceType: For now, a simple placeholder or based on first item's category.
    // You might want more sophisticated logic here.
    String determinedServiceType = 'Laundry Service'; // Default
    if (data['items'] != null && (data['items'] as List).isNotEmpty) {
      final firstItem = (data['items'] as List).first;
      if (firstItem['category'] != null && firstItem['category'].toString().isNotEmpty) {
        determinedServiceType = firstItem['category'];
      } else if (firstItem['name'] != null && firstItem['name'].toString().isNotEmpty) {
        determinedServiceType = firstItem['name']; // Fallback to item name
      }
    }
    
    // Ensure statusHistory is parsed correctly, defaulting to an empty list
    List<Map<String, dynamic>> parsedStatusHistory = [];
    if (data['statusHistory'] is List) {
      for (var item in (data['statusHistory'] as List)) {
        if (item is Map<String, dynamic>) {
          // Ensure timestamp is a Timestamp object
          if (item['timestamp'] != null && !(item['timestamp'] is Timestamp)) {
            // Attempt to convert if it's not, e.g., from a map or int,
            // but this might need more specific handling based on how it's stored if not a Timestamp.
            // For now, we'll assume it should be a Timestamp or we skip this item's timestamp if invalid.
            // A robust solution might involve checking item['timestamp'].toDate() if it's a Firestore Timestamp from a different SDK version.
          }
          parsedStatusHistory.add(item);
        }
      }
    }

    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      orderNumber: data['orderNumber'] ?? doc.id, // Use doc.id if orderNumber field is missing
      serviceType: determinedServiceType, 
      orderTimestamp: data['orderTimestamp'] ?? Timestamp.now(), // Expecting 'orderTimestamp'
      status: data['status'] ?? 'Unknown', // Expecting 'status'
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      pickupAddress: data['pickupAddress'] ?? 'N/A',
      deliveryAddress: data['deliveryAddress'] ?? 'N/A',
      pickupDate: data['pickupDate'] ?? Timestamp.now(),
      pickupTimeSlot: data['pickupTimeSlot'] ?? 'N/A',
      deliveryDate: data['deliveryDate'] ?? Timestamp.now(),
      deliveryTimeSlot: data['deliveryTimeSlot'] ?? 'N/A',
      paymentMethod: data['paymentMethod'] ?? 'N/A',
      specialInstructions: data['specialInstructions'] ?? '',
      statusHistory: parsedStatusHistory, // Use parsed list
    );
  }
}
