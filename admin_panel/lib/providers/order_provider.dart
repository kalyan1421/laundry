// providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrderService _orderService = OrderService();
  
  List<OrderModel> _allOrders = [];
  List<OrderModel> _deliveryOrders = [];
  List<Map<String, dynamic>> _quickOrderNotifications = [];
  bool _isLoading = false;
  String? _error;
  
  List<OrderModel> get allOrders => _allOrders;
  List<OrderModel> get deliveryOrders => _deliveryOrders;
  List<Map<String, dynamic>> get quickOrderNotifications => _quickOrderNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Stream<List<OrderModel>> getAllOrdersStream() {
    // Try ordering by different timestamp fields, fallback to no ordering
    Query query = _firestore.collection('orders');
    
    // Try to order by available timestamp fields
    try {
      query = query.orderBy('orderTimestamp', descending: true);
    } catch (e) {
      print('Warning: Could not order by orderTimestamp, trying createdAt: $e');
      try {
        query = query.orderBy('createdAt', descending: true);
      } catch (e2) {
        print('Warning: Could not order by any timestamp field: $e2');
      }
    }
    
    return query.snapshots().asyncMap((snapshot) async {
      List<OrderModel> orders = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          
          // Fetch customer information if customerId exists
          if (order.customerId != null) {
            OrderModel? orderWithCustomer = await _orderService.getOrderWithCustomerInfo(doc.id);
            if (orderWithCustomer != null) {
              order = orderWithCustomer;
            }
          }
          
          orders.add(order);
        } catch (e) {
          print('Error processing order ${doc.id}: $e');
        }
             }
       
       // Sort orders manually by timestamp (most recent first)
       orders.sort((a, b) {
         DateTime aTime = a.createdAt?.toDate() ?? a.orderTimestamp.toDate();
         DateTime bTime = b.createdAt?.toDate() ?? b.orderTimestamp.toDate();
         return bTime.compareTo(aTime);
       });
       
       _allOrders = orders;
       return _allOrders;
    });
  }
  
  // Enhanced delivery orders stream with customer information
  Stream<List<OrderModel>> getDeliveryOrdersStream(String deliveryId) {
    return _orderService.getOrdersForDeliveryPartner(deliveryId);
  }
  
  // Get single order with customer information
  Future<OrderModel?> getOrderWithCustomerInfo(String orderId) async {
    return await _orderService.getOrderWithCustomerInfo(orderId);
  }
  
  Stream<List<Map<String, dynamic>>> getQuickOrderNotificationsStream() {
    return _firestore
        .collection('quickOrderNotifications')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      _quickOrderNotifications = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
      return _quickOrderNotifications;
    });
  }
  
  Future<void> updateOrderStatus(String orderId, String status, {String? notes}) async {
    try {
      await _orderService.updateOrderStatus(
        orderId: orderId,
        newStatus: status,
        notes: notes,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> assignOrder(String orderId, String deliveryPersonId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'assignedDeliveryPerson': deliveryPersonId, // Fixed field name
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'assigned',
            'timestamp': Timestamp.now(), // Fixed: Use Timestamp.now() instead of FieldValue.serverTimestamp()
            'assignedTo': deliveryPersonId,
          }
        ]),
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Accept order by delivery partner
  Future<bool> acceptOrder(String orderId, String deliveryPartnerId, {String? notes}) async {
    try {
      return await _orderService.acceptOrderByDeliveryPartner(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        notes: notes,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Reject order by delivery partner
  Future<bool> rejectOrder(String orderId, String deliveryPartnerId, String reason) async {
    try {
      return await _orderService.rejectOrderByDeliveryPartner(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        reason: reason,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Get delivery partner statistics
  Future<Map<String, int>> getDeliveryPartnerStats(String deliveryPartnerId) async {
    try {
      return await _orderService.getDeliveryPartnerOrderStats(deliveryPartnerId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
  
  Future<void> updateQuickOrderStatus(String notificationId, String status) async {
    try {
      await _firestore.collection('quickOrderNotifications').doc(notificationId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
