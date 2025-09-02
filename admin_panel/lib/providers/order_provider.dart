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
      // Get current order to check for previous assignment
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data()!;
      final previousDeliveryPartner = orderData['assignedDeliveryPerson'];
      final batch = _firestore.batch();

      // Update order with assignment
      batch.update(
        _firestore.collection('orders').doc(orderId),
        {
          'assignedDeliveryPerson': deliveryPersonId, // Primary field
          'assignedTo': deliveryPersonId, // Keep for backward compatibility
          'status': 'assigned',
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isAcceptedByDeliveryPerson': false, // Reset acceptance status
          'statusHistory': FieldValue.arrayUnion([
            {
              'status': 'assigned',
              'timestamp': Timestamp.now(),
              'assignedTo': deliveryPersonId,
              'updatedBy': 'admin',
            }
          ]),
        },
      );

      // Clean up previous delivery partner's records (if reassignment)
      if (previousDeliveryPartner != null && 
          previousDeliveryPartner.toString().isNotEmpty &&
          previousDeliveryPartner != deliveryPersonId) {
        
        print('🚚 🧹 Cleaning up previous delivery partner records: $previousDeliveryPartner');
        
        // Remove order from previous partner's currentOrders array
        batch.update(
          _firestore.collection('delivery').doc(previousDeliveryPartner),
          {
            'currentOrders': FieldValue.arrayRemove([orderId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Delete the assigned_orders subcollection document
        batch.delete(
          _firestore
              .collection('delivery')
              .doc(previousDeliveryPartner)
              .collection('assigned_orders')
              .doc(orderId),
        );
      }

      // Add order to new delivery partner's records
      // Add order to new partner's currentOrders array
      batch.update(
        _firestore.collection('delivery').doc(deliveryPersonId),
        {
          'currentOrders': FieldValue.arrayUnion([orderId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Create detailed order assignment record for new delivery partner
      batch.set(
        _firestore
            .collection('delivery')
            .doc(deliveryPersonId)
            .collection('assigned_orders')
            .doc(orderId),
        {
          'orderId': orderId,
          'assignedAt': FieldValue.serverTimestamp(),
          'status': 'assigned',
          'orderDetails': {
            'customerName': orderData['customerName'] ?? 'Unknown',
            'customerPhone': orderData['customerPhone'] ?? '',
            'pickupAddress': _getPickupAddressString(orderData),
            'deliveryAddress': _getDeliveryAddressString(orderData),
            'totalAmount': orderData['totalAmount'] ?? 0.0,
            'items': orderData['items'] ?? [],
            'specialInstructions': orderData['specialInstructions'] ?? '',
            'orderType': orderData['orderType'] ?? 'pickup_delivery',
            'serviceType': orderData['serviceType'] ?? 'laundry',
            'priority': orderData['priority'] ?? 'normal',
            'orderNumber': orderData['orderNumber'] ?? orderId,
            'createdAt': orderData['createdAt'],
            'pickupDate': orderData['pickupDate'],
            'deliveryDate': orderData['deliveryDate'],
            'paymentMethod': orderData['paymentMethod'] ?? 'cod',
          },
        },
      );

      await batch.commit();
      print('✅ Order $orderId assigned to delivery partner $deliveryPersonId');

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print('❌ Error assigning order: $e');
    }
  }
  
  // Helper method to get pickup address string from order data
  String _getPickupAddressString(Map<String, dynamic> orderData) {
    try {
      // Check if pickupAddress is a map (new structure)
      if (orderData['pickupAddress'] is Map<String, dynamic>) {
        final pickupAddressMap = orderData['pickupAddress'] as Map<String, dynamic>;
        return pickupAddressMap['formatted'] ?? 
               _formatAddressFromDetails(pickupAddressMap['details']) ??
               'Pickup address not available';
      }
      // Check if it's a string (legacy structure)
      else if (orderData['pickupAddress'] is String) {
        return orderData['pickupAddress'] as String;
      }
      // Default fallback
      else {
        return 'Pickup address not available';
      }
    } catch (e) {
      print('Error getting pickup address: $e');
      return 'Pickup address not available';
    }
  }

  // Helper method to get delivery address string from order data
  String _getDeliveryAddressString(Map<String, dynamic> orderData) {
    try {
      // Check if deliveryAddress is a map (new structure)
      if (orderData['deliveryAddress'] is Map<String, dynamic>) {
        final deliveryAddressMap = orderData['deliveryAddress'] as Map<String, dynamic>;
        return deliveryAddressMap['formatted'] ?? 
               _formatAddressFromDetails(deliveryAddressMap['details']) ??
               'Delivery address not available';
      }
      // Check if it's a string (legacy structure)
      else if (orderData['deliveryAddress'] is String) {
        return orderData['deliveryAddress'] as String;
      }
      // Default fallback
      else {
        return 'Delivery address not available';
      }
    } catch (e) {
      print('Error getting delivery address: $e');
      return 'Delivery address not available';
    }
  }

  // Helper method to format address from details
  String? _formatAddressFromDetails(Map<String, dynamic>? details) {
    if (details == null) return null;
    
    List<String> parts = [];
    if (details['doorNumber'] != null) parts.add('Door: ${details['doorNumber']}');
    if (details['floorNumber'] != null) parts.add('Floor: ${details['floorNumber']}');
    if (details['apartmentName'] != null) parts.add(details['apartmentName']);
    if (details['addressLine1'] != null) parts.add(details['addressLine1']);
    if (details['addressLine2'] != null && details['addressLine2'].toString().isNotEmpty) {
      parts.add(details['addressLine2']);
    }
    if (details['landmark'] != null) parts.add('Near ${details['landmark']}');
    if (details['city'] != null) parts.add(details['city']);
    if (details['state'] != null) parts.add(details['state']);
    if (details['pincode'] != null) parts.add(details['pincode']);
    
    return parts.isNotEmpty ? parts.join(', ') : null;
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
