import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:customer_app/core/constants/firebase_constants.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define active order statuses
  final List<String> _activeOrderStatuses = [
    'Pending',
    'Confirmed',
    'Picked Up',
    'Processing',
    'In Process',
    'Ready for Delivery',
    'Out for Delivery',
    'New Orders', // From admin panel statuses
    'Pending Ironing', // From admin panel statuses
    'In Delivery' // From admin panel statuses
  ];

  Future<OrderModel?> getLastActiveOrder(String userId) async {
    if (userId.isEmpty) {
      print('[OrderService] User ID is empty, cannot fetch last active order.');
      return null;
    }
    try {
      print('[OrderService] Fetching last active order for userId: $userId');
      print('[OrderService] Active statuses being queried: $_activeOrderStatuses');
      
      final QuerySnapshot snapshot = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: _activeOrderStatuses)
          .orderBy('orderTimestamp', descending: true) // Assuming this field exists and is a Timestamp
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        print('[OrderService] Last active order found. Doc ID: ${doc.id}, Data: ${doc.data()}');
        return OrderModel.fromFirestore(doc);
      } else {
        print('[OrderService] No active orders found for userId: $userId');
        return null;
      }
    } catch (e) {
      print('[OrderService] Error fetching last active order: $e');
      return null;
    }
  }

  // You can add other order-related methods here, e.g.:
  // Stream<List<OrderModel>> getUserOrdersStream(String userId) { ... }
  // Future<void> createOrder(OrderModel order) { ... }
  // Future<void> cancelOrder(String orderId) { ... }
} 