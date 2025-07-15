import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get orders for delivery person with enhanced customer information
  Stream<List<OrderModel>> getOrdersForDeliveryPartner(String deliveryPartnerId) {
    return _firestore
        .collection('orders')
        .where('assignedDeliveryPerson', isEqualTo: deliveryPartnerId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<OrderModel> orders = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          
          // Fetch customer information if customerId exists
          if (order.customerId != null) {
            UserModel? customer = await _fetchCustomerInfo(order.customerId!);
            order = order.copyWith(customerInfo: customer);
          }
          
          orders.add(order);
        } catch (e) {
          print('Error processing order ${doc.id}: $e');
        }
      }
      
      // Sort orders manually by timestamp (most recent first)
      orders.sort((a, b) {
        DateTime aTime = a.assignedAt?.toDate() ?? a.orderTimestamp.toDate();
        DateTime bTime = b.assignedAt?.toDate() ?? b.orderTimestamp.toDate();
        return bTime.compareTo(aTime);
      });
      
      return orders;
    });
  }

  // Get single order with customer information
  Future<OrderModel?> getOrderWithCustomerInfo(String orderId) async {
    try {
      DocumentSnapshot orderDoc = await _firestore.collection('orders').doc(orderId).get();
      
      if (!orderDoc.exists) {
        print('Order not found: $orderId');
        return null;
      }
      
      OrderModel order = OrderModel.fromFirestore(orderDoc as DocumentSnapshot<Map<String, dynamic>>);
      
      // Fetch customer information if customerId exists
      if (order.customerId != null) {
        UserModel? customer = await _fetchCustomerInfo(order.customerId!);
        order = order.copyWith(customerInfo: customer);
      }
      
      return order;
    } catch (e) {
      print('Error fetching order with customer info: $e');
      return null;
    }
  }

  // Fetch customer information
  Future<UserModel?> _fetchCustomerInfo(String customerId) async {
    try {
      DocumentSnapshot customerDoc = await _firestore.collection('customer').doc(customerId).get();
      
      if (customerDoc.exists) {
        Map<String, dynamic> customerData = customerDoc.data() as Map<String, dynamic>;
        
        return UserModel(
          uid: customerId,
          name: customerData['name'] ?? customerData['fullName'] ?? 'Customer',
          email: customerData['email'] ?? '',
          phoneNumber: customerData['phoneNumber'] ?? customerData['phone'] ?? '',
          role: 'customer',
        );
      }
    } catch (e) {
      print('Error fetching customer info for $customerId: $e');
    }
    return null;
  }

  // Get all orders with pagination and customer info
  Future<List<OrderModel>> getOrdersWithPagination({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? status,
    String? deliveryPartnerId,
  }) async {
    try {
      Query query = _firestore.collection('orders');
      
      // Apply filters
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      if (deliveryPartnerId != null) {
        query = query.where('assignedDeliveryPerson', isEqualTo: deliveryPartnerId);
      }
      
             // Order by creation time - try multiple field options
       try {
         query = query.orderBy('createdAt', descending: true);
       } catch (e) {
         try {
           query = query.orderBy('orderTimestamp', descending: true);
         } catch (e2) {
           // If both fail, don't order
           print('Warning: Could not order by timestamp fields: $e, $e2');
         }
       }
      
      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(limit);
      
      QuerySnapshot snapshot = await query.get();
      List<OrderModel> orders = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          
          // Fetch customer information if customerId exists
          if (order.customerId != null) {
            UserModel? customer = await _fetchCustomerInfo(order.customerId!);
            order = order.copyWith(customerInfo: customer);
          }
          
          orders.add(order);
        } catch (e) {
          print('Error processing order ${doc.id}: $e');
        }
      }
      
      return orders;
    } catch (e) {
      print('Error fetching orders with pagination: $e');
      return [];
    }
  }

  // Update order status and notify delivery person
  Future<bool> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('🔄 OrderService: Updating order $orderId to status: $newStatus');
      
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add status to history - use Timestamp.now() instead of FieldValue.serverTimestamp() in arrayUnion
      Map<String, dynamic> statusEntry = {
        'status': newStatus,
        'timestamp': Timestamp.now(), // Fixed: Use Timestamp.now() instead of FieldValue.serverTimestamp()
        'updatedBy': 'delivery_partner',
      };

      if (notes != null) {
        statusEntry['notes'] = notes;
        updateData['notes'] = notes;
      }

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      print('📝 OrderService: Update data: $updateData');
      print('📝 OrderService: Status entry: $statusEntry');

      // Update the order
      await _firestore.collection('orders').doc(orderId).update({
        ...updateData,
        'statusHistory': FieldValue.arrayUnion([statusEntry]),
      });

      print('✅ OrderService: Order $orderId status updated to: $newStatus');
      return true;
    } catch (e) {
      print('❌ OrderService: Error updating order status: $e');
      return false;
    }
  }

  // Accept order by delivery person
  Future<bool> acceptOrderByDeliveryPartner({
    required String orderId,
    required String deliveryPartnerId,
    String? notes,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'isAcceptedByDeliveryPerson': true,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptanceNotes': notes,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'accepted',
            'timestamp': Timestamp.now(), // Fixed: Use Timestamp.now() instead of FieldValue.serverTimestamp()
            'notes': 'Order accepted by delivery person',
            'deliveryPartnerId': deliveryPartnerId,
          }
        ]),
      });

      print('Order $orderId accepted by delivery person: $deliveryPartnerId');
      return true;
    } catch (e) {
      print('Error accepting order: $e');
      return false;
    }
  }

  // Reject order by delivery person
  Future<bool> rejectOrderByDeliveryPartner({
    required String orderId,
    required String deliveryPartnerId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'isAcceptedByDeliveryPerson': false,
        'status': 'rejected_by_delivery_partner',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'assignedDeliveryPerson': null, // Unassign from this delivery person
        'assignedDeliveryPersonName': null,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'rejected_by_delivery_partner',
            'timestamp': Timestamp.now(), // Fixed: Use Timestamp.now() instead of FieldValue.serverTimestamp()
            'reason': reason,
            'deliveryPartnerId': deliveryPartnerId,
          }
        ]),
      });

      print('Order $orderId rejected by delivery person: $deliveryPartnerId');
      return true;
    } catch (e) {
      print('Error rejecting order: $e');
      return false;
    }
  }

  // Get order statistics for delivery person
  Future<Map<String, int>> getDeliveryPartnerOrderStats(String deliveryPartnerId) async {
    try {
      // Get all orders for this delivery person
      QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('assignedDeliveryPerson', isEqualTo: deliveryPartnerId)
          .get();

      Map<String, int> stats = {
        'total': ordersSnapshot.docs.length,
        'pending': 0,
        'accepted': 0,
        'in_progress': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (QueryDocumentSnapshot doc in ordersSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'unknown';
        
        if (stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting delivery person stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'in_progress': 0,
        'completed': 0,
        'cancelled': 0,
      };
    }
  }
} 