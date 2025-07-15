import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as workshop_order;
import '../models/workshop_member.dart';
import '../services/database_service.dart';
import '../services/qr_scanner_service.dart';
import '../services/notification_service.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final QRScannerService _qrScannerService = QRScannerService();
  final NotificationService _notificationService = NotificationService();

  List<workshop_order.WorkshopOrder> _orders = [];
  List<workshop_order.WorkshopOrder> _pendingOrders = [];
  List<workshop_order.WorkshopOrder> _processingOrders = [];
  List<workshop_order.WorkshopOrder> _completedOrders = [];
  workshop_order.WorkshopOrder? _currentOrder;
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _scannedData;
  List<Map<String, dynamic>> _recentScans = [];

  // Getters
  List<workshop_order.WorkshopOrder> get orders => _orders;
  List<workshop_order.WorkshopOrder> get pendingOrders => _pendingOrders;
  List<workshop_order.WorkshopOrder> get processingOrders => _processingOrders;
  List<workshop_order.WorkshopOrder> get completedOrders => _completedOrders;
  workshop_order.WorkshopOrder? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get scannedData => _scannedData;
  List<Map<String, dynamic>> get recentScans => _recentScans;

  OrderProvider() {
    _initializeOrders();
  }

  // Initialize orders
  Future<void> _initializeOrders() async {
    await loadOrders();
    await loadRecentScans();
  }

  // Load orders from database
  Future<void> loadOrders({String? memberId}) async {
    setLoading(true);
    _clearError();

    try {
      if (memberId != null) {
        // Load orders assigned to specific member
        _orders = await _databaseService.getOrdersByMember(memberId);
      } else {
        // Load all orders
        _orders = await _databaseService.getAllOrders();
      }

      // Categorize orders
      _categorizeOrders();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load orders: $e');
    } finally {
      setLoading(false);
    }
  }

  // Categorize orders by status
  void _categorizeOrders() {
    _pendingOrders = _orders.where((order) => order.status == 'pending').toList();
    _processingOrders = _orders.where((order) => order.status == 'processing').toList();
    _completedOrders = _orders.where((order) => order.status == 'completed').toList();
  }

  // Scan QR code
  Future<bool> scanQRCode(String qrData, WorkshopMember member) async {
    setLoading(true);
    _clearError();

    try {
      // Parse QR data
      final parsedData = _qrScannerService.parseQRCode(qrData);
      
      if (parsedData == null) {
        _setError('Invalid QR code format');
        return false;
      }

      _scannedData = parsedData;
      final customerId = parsedData['userId'] as String?;
      
      if (customerId == null) {
        _setError('Customer ID not found in QR code');
        return false;
      }

      // Get customer orders
      final customerOrders = await _databaseService.getOrdersByCustomer(customerId);
      
      if (customerOrders.isEmpty) {
        _setError('No orders found for this customer');
        return false;
      }

      // Find the most recent pending or processing order
      final availableOrders = customerOrders.where((order) => 
        order.status == 'pending' || order.status == 'processing'
      ).toList();

      if (availableOrders.isEmpty) {
        _setError('No pending or processing orders found for this customer');
        return false;
      }

      // Sort by created date (most recent first)
      availableOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _currentOrder = availableOrders.first;

      // Save scan record
      await _saveScanRecord(member, parsedData);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to scan QR code: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Start processing order
  Future<bool> startProcessingOrder(String orderId, WorkshopMember member) async {
    setLoading(true);
    _clearError();

    try {
      // Get order
      final order = await _databaseService.getOrder(orderId);
      if (order == null) {
        _setError('Order not found');
        return false;
      }

      // Check if order is already being processed
      if (order.status == 'processing') {
        _setError('Order is already being processed');
        return false;
      }

      // Update order status
      final updatedOrder = order.copyWith(
        status: 'processing',
        assignedTo: member.id,
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        statusHistory: [
          ...order.statusHistory,
          {
            'status': 'processing',
            'timestamp': Timestamp.now(),
            'memberId': member.id,
            'memberName': member.name,
            'note': 'Order processing started',
          }
        ],
      );

      await _databaseService.updateOrder(updatedOrder);
      _currentOrder = updatedOrder;

      // Refresh orders list
      await loadOrders();

      // Send notification to customer
      await _notificationService.sendOrderUpdateNotification(
        orderId: orderId,
        customerId: order.customerId,
        status: 'processing',
        message: 'Your order is now being processed',
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to start processing order: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Complete order
  Future<bool> completeOrder(String orderId, WorkshopMember member, double earnings) async {
    setLoading(true);
    _clearError();

    try {
      // Get order
      final order = await _databaseService.getOrder(orderId);
      if (order == null) {
        _setError('Order not found');
        return false;
      }

      // Update order status
      final updatedOrder = order.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        workshopEarnings: earnings,
        memberEarnings: {member.id: earnings},
        statusHistory: [
          ...order.statusHistory,
          {
            'status': 'completed',
            'timestamp': Timestamp.now(),
            'memberId': member.id,
            'memberName': member.name,
            'note': 'Order completed',
            'earnings': earnings,
          }
        ],
      );

      await _databaseService.updateOrder(updatedOrder);
      _currentOrder = updatedOrder;

      // Update member earnings
      await _updateMemberEarnings(member, earnings, order.totalItems);

      // Refresh orders list
      await loadOrders();

      // Send notification to customer
      await _notificationService.sendOrderUpdateNotification(
        orderId: orderId,
        customerId: order.customerId,
        status: 'completed',
        message: 'Your order has been completed and is ready for pickup',
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to complete order: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Update individual order item status
  Future<bool> updateOrderItemStatus(
    String orderId,
    String itemId,
    String status,
    WorkshopMember member,
  ) async {
    setLoading(true);
    _clearError();

    try {
      // Get order
      final order = await _databaseService.getOrder(orderId);
      if (order == null) {
        _setError('Order not found');
        return false;
      }

      // Update item status
      final updatedItems = order.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            status: status,
            assignedTo: member.id,
            startedAt: status == 'processing' ? DateTime.now() : item.startedAt,
            completedAt: status == 'completed' ? DateTime.now() : item.completedAt,
          );
        }
        return item;
      }).toList();

      // Check if all items are completed
      final allCompleted = updatedItems.every((item) => item.status == 'completed');
      final newOrderStatus = allCompleted ? 'completed' : 'processing';

      final updatedOrder = order.copyWith(
        items: updatedItems,
        status: newOrderStatus,
        completedAt: allCompleted ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateOrder(updatedOrder);
      _currentOrder = updatedOrder;

      // Refresh orders list
      await loadOrders();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update order item status: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Update member earnings
  Future<void> _updateMemberEarnings(WorkshopMember member, double earnings, int itemsProcessed) async {
    try {
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Update earnings
      final updatedEarnings = Map<String, dynamic>.from(member.earnings);
      updatedEarnings[todayKey] = (updatedEarnings[todayKey] ?? 0.0) + earnings;
      
      // Update performance
      final updatedPerformance = Map<String, dynamic>.from(member.performance);
      
      // Update completed orders
      final completedOrders = Map<String, dynamic>.from(updatedPerformance['completedOrders'] ?? {});
      completedOrders[todayKey] = (completedOrders[todayKey] ?? 0) + 1;
      updatedPerformance['completedOrders'] = completedOrders;
      
      // Update processed items
      final processedItems = Map<String, dynamic>.from(updatedPerformance['processedItems'] ?? {});
      processedItems[todayKey] = (processedItems[todayKey] ?? 0) + itemsProcessed;
      updatedPerformance['processedItems'] = processedItems;
      
      // Update member
      final updatedMember = member.copyWith(
        earnings: updatedEarnings,
        performance: updatedPerformance,
        updatedAt: DateTime.now(),
      );
      
      await _databaseService.updateWorkshopMember(updatedMember);
    } catch (e) {
      debugPrint('Failed to update member earnings: $e');
    }
  }

  // Save scan record
  Future<void> _saveScanRecord(WorkshopMember member, Map<String, dynamic> scannedData) async {
    try {
      final scanRecord = {
        'memberId': member.id,
        'memberName': member.name,
        'scannedData': scannedData,
        'timestamp': Timestamp.now(),
        'customerId': scannedData['userId'],
        'customerName': scannedData['userName'],
      };

      await _databaseService.saveScanRecord(scanRecord);
      
      // Add to recent scans
      _recentScans.insert(0, scanRecord);
      if (_recentScans.length > 10) {
        _recentScans.removeLast();
      }
    } catch (e) {
      debugPrint('Failed to save scan record: $e');
    }
  }

  // Load recent scans
  Future<void> loadRecentScans() async {
    try {
      _recentScans = await _databaseService.getRecentScans();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recent scans: $e');
    }
  }

  // Get order by ID
  Future<workshop_order.WorkshopOrder?> getOrder(String orderId) async {
    try {
      return await _databaseService.getOrder(orderId);
    } catch (e) {
      _setError('Failed to get order: $e');
      return null;
    }
  }

  // Get order by ID (alias for getOrder)
  Future<workshop_order.WorkshopOrder?> getOrderById(String orderId) async {
    return await getOrder(orderId);
  }

  // Get recent orders (last 10 orders)
  List<workshop_order.WorkshopOrder> get recentOrders {
    final sortedOrders = List<workshop_order.WorkshopOrder>.from(_orders);
    sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedOrders.take(10).toList();
  }

  // Search orders
  List<workshop_order.WorkshopOrder> searchOrders(String query) {
    if (query.isEmpty) return _orders;
    
    final lowercaseQuery = query.toLowerCase();
    return _orders.where((order) {
      return order.customerName.toLowerCase().contains(lowercaseQuery) ||
             order.customerPhone.contains(query) ||
             order.displayId.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Filter orders by status
  List<workshop_order.WorkshopOrder> filterOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Get orders by date range
  List<workshop_order.WorkshopOrder> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _orders.where((order) {
      return order.createdAt.isAfter(startDate) && order.createdAt.isBefore(endDate);
    }).toList();
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  // Clear scanned data
  void clearScannedData() {
    _scannedData = null;
    notifyListeners();
  }

  // Refresh orders
  Future<void> refreshOrders() async {
    await loadOrders();
  }

  // Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error message
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Clear error (public method)
  void clearError() {
    _clearError();
  }
} 