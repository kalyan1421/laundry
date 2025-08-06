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
  
  // Fast loading stream without customer data for better performance
  Stream<List<OrderModel>> getFastOrdersStream({String? statusFilter, int limit = 50}) {
    Query query = _firestore.collection('orders');
    
    // Apply different query strategies based on filter
    if (statusFilter != null && statusFilter != 'all') {
      try {
        query = query.where('status', isEqualTo: statusFilter);
        try {
          query = query.orderBy('orderTimestamp', descending: true).limit(limit);
        } catch (e) {
          query = query.limit(limit);
        }
      } catch (e) {
        print('Status filter failed, using basic query: $e');
        query = _firestore.collection('orders').limit(limit);
      }
    } else {
      try {
        query = query.orderBy('orderTimestamp', descending: true).limit(limit);
      } catch (e) {
        try {
          query = query.orderBy('createdAt', descending: true).limit(limit);
        } catch (e2) {
          query = query.limit(limit);
        }
      }
    }
    
    return query.snapshots().map((snapshot) {
      List<OrderModel> orders = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          
          // Apply status filter in code if database query failed
          if (statusFilter != null && statusFilter != 'all' && order.status != statusFilter) {
            continue;
          }
          
          orders.add(order);
        } catch (e) {
          print('Error parsing order ${doc.id}: $e');
        }
      }
      
      return orders;
    });
  }

  // Original method with customer data (kept for compatibility)
  Stream<List<OrderModel>> getAllOrdersStream({String? statusFilter, int limit = 50}) {
    Query query = _firestore.collection('orders');
    
    // Apply different query strategies based on filter
    if (statusFilter != null && statusFilter != 'all') {
      try {
        // Try optimized query with index
        query = query.where('status', isEqualTo: statusFilter);
        
        // Try to order by timestamp with limit
        try {
          query = query.orderBy('orderTimestamp', descending: true).limit(limit);
        } catch (e) {
          print('Info: Using basic query without ordering for status filter');
          query = query.limit(limit);
        }
      } catch (e) {
        print('Info: Falling back to basic query: $e');
        // Fallback to basic query without status filter
        query = _firestore.collection('orders').limit(limit);
      }
    } else {
      // For 'all' orders, use basic query
      try {
        query = query.orderBy('orderTimestamp', descending: true).limit(limit);
      } catch (e) {
        try {
          query = query.orderBy('createdAt', descending: true).limit(limit);
        } catch (e2) {
          print('Using basic query without ordering');
          query = query.limit(limit);
        }
      }
    }
    
    return query.snapshots().asyncMap((snapshot) async {
      List<OrderModel> orders = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          
          // Apply status filter in code if database query failed
          if (statusFilter != null && statusFilter != 'all' && order.status != statusFilter) {
            continue;
          }
          
          // Fetch customer information if customerId exists
          if (order.customerId != null) {
            try {
              OrderModel? orderWithCustomer = await _orderService.getOrderWithCustomerInfo(doc.id);
              if (orderWithCustomer != null) {
                order = orderWithCustomer;
              }
            } catch (e) {
              print('Error fetching customer info for order ${doc.id}: $e');
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
      
      // Apply limit in code if needed
      if (orders.length > limit) {
        orders = orders.take(limit).toList();
      }
      
      _allOrders = orders;
      return _allOrders;
    });
  }

  // Separate method for getting full order details when needed
  Future<OrderModel?> getOrderWithFullDetails(String orderId) async {
    try {
      DocumentSnapshot orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return null;
      
      OrderModel order = OrderModel.fromFirestore(orderDoc as DocumentSnapshot<Map<String, dynamic>>);
      
      // Fetch customer information if needed
      if (order.customerId != null) {
        OrderModel? orderWithCustomer = await _orderService.getOrderWithCustomerInfo(orderId);
        if (orderWithCustomer != null) {
          return orderWithCustomer;
        }
      }
      
      return order;
    } catch (e) {
      print('Error getting order with full details: $e');
      return null;
    }
  }
  
  // Search orders by customer ID
  Future<List<OrderModel>> searchOrdersByCustomerId(String customerId) async {
    List<OrderModel> orders = [];
    
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('orderTimestamp', descending: true)
          .get();
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          
          // Fetch customer information
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
    } catch (e) {
      print('Error searching orders by customer ID: $e');
    }
    
    return orders;
  }
  
  // Search orders by order ID (partial match)
  Future<List<OrderModel>> searchOrdersByOrderId(String orderId) async {
    List<OrderModel> orders = [];
    
    try {
      // First try exact match
      DocumentSnapshot exactDoc = await _firestore.collection('orders').doc(orderId).get();
      if (exactDoc.exists) {
        OrderModel order = OrderModel.fromFirestore(exactDoc as DocumentSnapshot<Map<String, dynamic>>);
        
        // Fetch customer information
        if (order.customerId != null) {
          OrderModel? orderWithCustomer = await _orderService.getOrderWithCustomerInfo(exactDoc.id);
          if (orderWithCustomer != null) {
            order = orderWithCustomer;
          }
        }
        
        orders.add(order);
        return orders;
      }
      
      // If no exact match, search by orderNumber field
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('orderNumber', isGreaterThanOrEqualTo: orderId)
          .where('orderNumber', isLessThan: orderId + '\uf8ff')
          .get();
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          
          // Fetch customer information
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
    } catch (e) {
      print('Error searching orders by order ID: $e');
    }
    
    return orders;
  }
  
  // Get orders for a specific customer
  Stream<List<OrderModel>> getOrdersForCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderTimestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<OrderModel> orders = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          
          // Fetch customer information
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
      
      return orders;
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
      // Clear any cached error after successful update
      _error = null;
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
  
  // Refresh orders by notifying listeners
  void refreshOrders() {
    notifyListeners();
  }
}
