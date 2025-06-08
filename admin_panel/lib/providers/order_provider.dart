// providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
    return _firestore
        .collection('orders')
        .orderBy('orderTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      _allOrders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      return _allOrders;
    });
  }
  
  Stream<List<OrderModel>> getDeliveryOrdersStream(String deliveryId) {
    return _firestore
        .collection('orders')
        .where('assignedTo', isEqualTo: deliveryId)
        .orderBy('orderTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      _deliveryOrders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      return _deliveryOrders;
    });
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
  
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> assignOrder(String orderId, String deliveryPersonId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'assignedTo': deliveryPersonId,
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
}
