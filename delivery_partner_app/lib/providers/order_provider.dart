// providers/order_provider.dart - Delivery Partner Order Management
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<OrderModel> _pendingPickups = [];
  List<OrderModel> _pendingDeliveries = [];
  List<OrderModel> _completedTasks = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastNotificationTime;
  
  // Getters
  List<OrderModel> get pendingPickups => _pendingPickups;
  List<OrderModel> get pendingDeliveries => _pendingDeliveries;
  List<OrderModel> get completedTasks => _completedTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastNotificationTime => _lastNotificationTime;
  
  // Method to handle new order assignment notifications
  void handleOrderAssignmentNotification(Map<String, dynamic> notificationData) {
    print('🚚 📦 OrderProvider: Handling new order assignment notification');
    print('🚚 Order ID: ${notificationData['orderId']}');
    print('🚚 Order Number: ${notificationData['orderNumber']}');
    
    _lastNotificationTime = DateTime.now();
    
    // Clear any previous errors
    _error = null;
    
    // Trigger a refresh of the UI
    notifyListeners();
    
    print('🚚 ✅ OrderProvider: Notification handled, UI will refresh automatically via streams');
  }
  
  // Method to manually refresh order data
  Future<void> refreshOrderData(String deliveryPartnerId) async {
    print('🚚 🔄 OrderProvider: Manually refreshing order data');
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // The streams will automatically refresh the data
      // This method just triggers loading state and clears errors
      await Future.delayed(Duration(milliseconds: 500)); // Small delay for UX
      
      _isLoading = false;
      notifyListeners();
      
      print('🚚 ✅ OrderProvider: Manual refresh completed');
    } catch (e) {
      _error = 'Failed to refresh order data: $e';
      _isLoading = false;
      notifyListeners();
      
      print('🚚 ❌ OrderProvider: Manual refresh failed - $e');
    }
  }
  
  // Get pickup tasks for delivery partner (including newly assigned orders)
  Stream<List<OrderModel>> getPickupTasksStream(String deliveryPartnerId) {
    print('🚚 📦 OrderProvider: Getting pickup tasks for delivery partner: $deliveryPartnerId');
    
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['assigned', 'confirmed', 'ready_for_pickup'])
        .where('assignedDeliveryPartner', isEqualTo: deliveryPartnerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('🚚 📦 OrderProvider: Pickup tasks query returned ${snapshot.docs.length} orders');
      
      if (snapshot.docs.isEmpty) {
        print('🚚 ⚠️ No pickup tasks found for delivery partner: $deliveryPartnerId');
        print('🚚 ⚠️ Query used: status IN [assigned, confirmed, ready_for_pickup] AND assignedDeliveryPartner = $deliveryPartnerId');
      } else {
        print('🚚 ✅ Found ${snapshot.docs.length} pickup tasks:');
        // Debug: Print details of each order
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('🚚 📦 Order ${doc.id}: status=${data['status']}, assignedDeliveryPartner=${data['assignedDeliveryPartner']}');
          print('🚚 📦   - OrderNumber: ${data['orderNumber']}');
          print('🚚 📦   - Customer: ${data['customer']?['name']}');
        }
      }
      
      return snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();
    }).handleError((error) {
      print('🚚 Error in pickup tasks stream: $error');
      return <OrderModel>[];
    });
  }
  
  // Get delivery tasks for delivery partner
  Stream<List<OrderModel>> getDeliveryTasksStream(String deliveryPartnerId) {
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['picked_up', 'ready_for_delivery'])
        .where('assignedDeliveryPartner', isEqualTo: deliveryPartnerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();
    }).handleError((error) {
      print('🚚 Error in delivery tasks stream: $error');
      return <OrderModel>[];
    });
  }
  
  // Get all assigned orders for delivery partner
  Stream<List<OrderModel>> getAllAssignedOrdersStream(String deliveryPartnerId) {
    return _firestore
        .collection('orders')
        .where('assignedDeliveryPartner', isEqualTo: deliveryPartnerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();
    }).handleError((error) {
      print('🚚 Error in assigned orders stream: $error');
      return <OrderModel>[];
    });
  }
  
  // Get today's tasks for delivery partner
  Stream<List<OrderModel>> getTodayTasksStream(String deliveryPartnerId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return _firestore
        .collection('orders')
        .where('assignedDeliveryPartner', isEqualTo: deliveryPartnerId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();
    }).handleError((error) {
      print('🚚 Error in today tasks stream: $error');
      return <OrderModel>[];
    });
  }
  
  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus, {
    String? notes,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      };
      
      // Add status history entry
      Map<String, dynamic> statusHistoryEntry = {
        'status': newStatus,
        'timestamp': Timestamp.now(),
        'updatedBy': 'delivery_partner',
      };
      
      if (notes != null) {
        statusHistoryEntry['notes'] = notes;
      }
      
      updateData['statusHistory'] = FieldValue.arrayUnion([statusHistoryEntry]);
      
      // Add additional data if provided
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }
      
      // Update specific fields based on status
      switch (newStatus) {
        case 'picked_up':
          updateData['pickedUpAt'] = Timestamp.now();
          break;
        case 'delivered':
          updateData['deliveredAt'] = Timestamp.now();
          break;
        case 'cancelled':
          updateData['cancelledAt'] = Timestamp.now();
          break;
      }
      
      await _firestore.collection('orders').doc(orderId).update(updateData);
      
      _isLoading = false;
      notifyListeners();
      
      print('🚚 ✅ Order $orderId status updated to $newStatus');
      return true;
      
    } catch (e) {
      print('🚚 Error updating order status: $e');
      _error = 'Failed to update order status: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Mark pickup as complete
  Future<bool> markPickupComplete(String orderId, {String? notes}) async {
    return updateOrderStatus(orderId, 'picked_up', notes: notes);
  }
  
  // Mark delivery as complete
  Future<bool> markDeliveryComplete(String orderId, {String? notes}) async {
    return updateOrderStatus(orderId, 'delivered', notes: notes);
  }
  
  // Report issue with order
  Future<bool> reportOrderIssue(String orderId, String issue, {String? notes}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      Map<String, dynamic> updateData = {
        'status': 'issue_reported',
        'updatedAt': Timestamp.now(),
        'reportedIssue': issue,
        'issueReportedAt': Timestamp.now(),
      };
      
      if (notes != null) {
        updateData['issueNotes'] = notes;
      }
      
      // Add to status history
      Map<String, dynamic> statusHistoryEntry = {
        'status': 'issue_reported',
        'timestamp': Timestamp.now(),
        'updatedBy': 'delivery_partner',
        'issue': issue,
      };
      
      if (notes != null) {
        statusHistoryEntry['notes'] = notes;
      }
      
      updateData['statusHistory'] = FieldValue.arrayUnion([statusHistoryEntry]);
      
      await _firestore.collection('orders').doc(orderId).update(updateData);
      
      _isLoading = false;
      notifyListeners();
      
      print('🚚 ✅ Issue reported for order $orderId: $issue');
      return true;
      
    } catch (e) {
      print('🚚 Error reporting order issue: $e');
      _error = 'Failed to report issue: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Get delivery partner statistics
  Future<Map<String, dynamic>> getDeliveryPartnerStats(String deliveryPartnerId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(today.year, today.month, 1);
      
      // Today's completed tasks
      final todayCompleted = await _firestore
          .collection('orders')
          .where('assignedDeliveryPartner', isEqualTo: deliveryPartnerId)
          .where('status', isEqualTo: 'delivered')
          .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      
      // Week's completed tasks
      final weekCompleted = await _firestore
          .collection('orders')
          .where('assignedDeliveryPartner', isEqualTo: deliveryPartnerId)
          .where('status', isEqualTo: 'delivered')
          .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();
      
      // Month's completed tasks
      final monthCompleted = await _firestore
          .collection('orders')
          .where('assignedDeliveryPartner', isEqualTo: deliveryPartnerId)
          .where('status', isEqualTo: 'delivered')
          .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();
      
      // Today's pending tasks
      final todayPending = await _firestore
          .collection('orders')
          .where('assignedDeliveryPartner', isEqualTo: deliveryPartnerId)
          .where('status', whereIn: ['confirmed', 'ready_for_pickup', 'picked_up', 'ready_for_delivery'])
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      
      return {
        'todayCompleted': todayCompleted.docs.length,
        'weekCompleted': weekCompleted.docs.length,
        'monthCompleted': monthCompleted.docs.length,
        'todayPending': todayPending.docs.length,
      };
      
    } catch (e) {
      print('🚚 Error getting delivery partner stats: $e');
      return {
        'todayCompleted': 0,
        'weekCompleted': 0,
        'monthCompleted': 0,
        'todayPending': 0,
      };
    }
  }
  
  // Refresh data
  void refreshData() {
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 