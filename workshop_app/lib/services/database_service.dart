import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/workshop_member.dart';
import '../models/order.dart' as workshop_order;

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Collection references
  CollectionReference get _workshopMembersCollection => _firestore.collection('workshop_members');
  CollectionReference get _workshopWorkersCollection => _firestore.collection('workshop_workers');
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _scanRecordsCollection => _firestore.collection('scan_records');
  CollectionReference get _earningsRecordsCollection => _firestore.collection('earnings_records');
  CollectionReference get _workshopsCollection => _firestore.collection('workshops');

  // WORKSHOP MEMBER OPERATIONS

  // Save workshop member
  Future<void> saveWorkshopMember(WorkshopMember member) async {
    try {
      _logger.i('Saving workshop member: ${member.id}');
      await _workshopMembersCollection.doc(member.id).set(member.toFirestore());
      _logger.i('Workshop member saved successfully');
    } catch (e) {
      _logger.e('Error saving workshop member: $e');
      throw Exception('Failed to save workshop member: $e');
    }
  }

  // Get workshop member by ID
  Future<WorkshopMember?> getWorkshopMember(String memberId) async {
    try {
      _logger.i('Getting workshop member: $memberId');
      final doc = await _workshopMembersCollection.doc(memberId).get();
      
      if (doc.exists) {
        final member = WorkshopMember.fromFirestore(doc);
        _logger.i('Workshop member retrieved successfully');
        return member;
      } else {
        _logger.w('Workshop member not found: $memberId');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting workshop member: $e');
      throw Exception('Failed to get workshop member: $e');
    }
  }

  // Update workshop member
  Future<void> updateWorkshopMember(WorkshopMember member) async {
    try {
      _logger.i('Updating workshop member: ${member.id}');
      await _workshopMembersCollection.doc(member.id).update(member.toFirestore());
      _logger.i('Workshop member updated successfully');
    } catch (e) {
      _logger.e('Error updating workshop member: $e');
      throw Exception('Failed to update workshop member: $e');
    }
  }

  // Get workshop members by workshop ID
  Future<List<WorkshopMember>> getWorkshopMembers(String workshopId) async {
    try {
      _logger.i('Getting workshop members for workshop: $workshopId');
      final querySnapshot = await _workshopMembersCollection
          .where('workshopId', isEqualTo: workshopId)
          .where('isActive', isEqualTo: true)
          .get();
      
      final members = querySnapshot.docs
          .map((doc) => WorkshopMember.fromFirestore(doc))
          .toList();
      
      _logger.i('Retrieved ${members.length} workshop members');
      return members;
    } catch (e) {
      _logger.e('Error getting workshop members: $e');
      throw Exception('Failed to get workshop members: $e');
    }
  }

  // DELETE workshop member
  Future<void> deleteWorkshopMember(String memberId) async {
    try {
      _logger.i('Deleting workshop member: $memberId');
      await _workshopMembersCollection.doc(memberId).delete();
      _logger.i('Workshop member deleted successfully');
    } catch (e) {
      _logger.e('Error deleting workshop member: $e');
      throw Exception('Failed to delete workshop member: $e');
    }
  }

  // ORDER OPERATIONS

  // Get order by ID
  Future<workshop_order.WorkshopOrder?> getOrder(String orderId) async {
    try {
      _logger.i('Getting order: $orderId');
      final doc = await _ordersCollection.doc(orderId).get();
      
      if (doc.exists) {
        final order = workshop_order.WorkshopOrder.fromFirestore(doc);
        _logger.i('Order retrieved successfully');
        return order;
      } else {
        _logger.w('Order not found: $orderId');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting order: $e');
      throw Exception('Failed to get order: $e');
    }
  }

  // Update order
  Future<void> updateOrder(workshop_order.WorkshopOrder order) async {
    try {
      _logger.i('Updating order: ${order.id}');
      await _ordersCollection.doc(order.id).update(order.toFirestore());
      _logger.i('Order updated successfully');
    } catch (e) {
      _logger.e('Error updating order: $e');
      throw Exception('Failed to update order: $e');
    }
  }

  // Get all orders
  Future<List<workshop_order.WorkshopOrder>> getAllOrders() async {
    try {
      _logger.i('Getting all orders');
      final querySnapshot = await _ordersCollection
          .orderBy('createdAt', descending: true)
          .limit(100) // Limit for performance
          .get();
      
      final orders = querySnapshot.docs
          .map((doc) => workshop_order.WorkshopOrder.fromFirestore(doc))
          .toList();
      
      _logger.i('Retrieved ${orders.length} orders');
      return orders;
    } catch (e) {
      _logger.e('Error getting orders: $e');
      throw Exception('Failed to get orders: $e');
    }
  }

  // Get orders by member (assigned to specific workshop member)
  Future<List<workshop_order.WorkshopOrder>> getOrdersByMember(String memberId) async {
    try {
      _logger.i('Getting orders for member: $memberId');
      final querySnapshot = await _ordersCollection
          .where('assignedTo', isEqualTo: memberId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final orders = querySnapshot.docs
          .map((doc) => workshop_order.WorkshopOrder.fromFirestore(doc))
          .toList();
      
      _logger.i('Retrieved ${orders.length} orders for member');
      return orders;
    } catch (e) {
      _logger.e('Error getting orders by member: $e');
      throw Exception('Failed to get orders by member: $e');
    }
  }

  // Get orders by customer ID
  Future<List<workshop_order.WorkshopOrder>> getOrdersByCustomer(String customerId) async {
    try {
      _logger.i('Getting orders for customer: $customerId');
      final querySnapshot = await _ordersCollection
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final orders = querySnapshot.docs
          .map((doc) => workshop_order.WorkshopOrder.fromFirestore(doc))
          .toList();
      
      _logger.i('Retrieved ${orders.length} orders for customer');
      return orders;
    } catch (e) {
      _logger.e('Error getting orders by customer: $e');
      throw Exception('Failed to get orders by customer: $e');
    }
  }

  // Get orders by status
  Future<List<workshop_order.WorkshopOrder>> getOrdersByStatus(String status) async {
    try {
      _logger.i('Getting orders with status: $status');
      final querySnapshot = await _ordersCollection
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      
      final orders = querySnapshot.docs
          .map((doc) => workshop_order.WorkshopOrder.fromFirestore(doc))
          .toList();
      
      _logger.i('Retrieved ${orders.length} orders with status $status');
      return orders;
    } catch (e) {
      _logger.e('Error getting orders by status: $e');
      throw Exception('Failed to get orders by status: $e');
    }
  }

  // Get orders by date range
  Future<List<workshop_order.WorkshopOrder>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      _logger.i('Getting orders between $startDate and $endDate');
      final querySnapshot = await _ordersCollection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();
      
      final orders = querySnapshot.docs
          .map((doc) => workshop_order.WorkshopOrder.fromFirestore(doc))
          .toList();
      
      _logger.i('Retrieved ${orders.length} orders in date range');
      return orders;
    } catch (e) {
      _logger.e('Error getting orders by date range: $e');
      throw Exception('Failed to get orders by date range: $e');
    }
  }

  // SCAN RECORDS OPERATIONS

  // Save scan record
  Future<void> saveScanRecord(Map<String, dynamic> scanRecord) async {
    try {
      _logger.i('Saving scan record for member: ${scanRecord['memberId']}');
      await _scanRecordsCollection.add(scanRecord);
      _logger.i('Scan record saved successfully');
    } catch (e) {
      _logger.e('Error saving scan record: $e');
      throw Exception('Failed to save scan record: $e');
    }
  }

  // Get recent scans (last 50)
  Future<List<Map<String, dynamic>>> getRecentScans() async {
    try {
      _logger.i('Getting recent scans');
      final querySnapshot = await _scanRecordsCollection
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      final scans = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      
      _logger.i('Retrieved ${scans.length} recent scans');
      return scans;
    } catch (e) {
      _logger.e('Error getting recent scans: $e');
      throw Exception('Failed to get recent scans: $e');
    }
  }

  // Get scans by member
  Future<List<Map<String, dynamic>>> getScansByMember(String memberId) async {
    try {
      _logger.i('Getting scans for member: $memberId');
      final querySnapshot = await _scanRecordsCollection
          .where('memberId', isEqualTo: memberId)
          .orderBy('timestamp', descending: true)
          .get();
      
      final scans = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      
      _logger.i('Retrieved ${scans.length} scans for member');
      return scans;
    } catch (e) {
      _logger.e('Error getting scans by member: $e');
      throw Exception('Failed to get scans by member: $e');
    }
  }

  // EARNINGS RECORDS OPERATIONS

  // Save earnings record
  Future<void> saveEarningsRecord(Map<String, dynamic> earningsRecord) async {
    try {
      _logger.i('Saving earnings record for member: ${earningsRecord['memberId']}');
      await _earningsRecordsCollection.add(earningsRecord);
      _logger.i('Earnings record saved successfully');
    } catch (e) {
      _logger.e('Error saving earnings record: $e');
      throw Exception('Failed to save earnings record: $e');
    }
  }

  // Get member earnings history
  Future<List<Map<String, dynamic>>> getMemberEarningsHistory(String memberId) async {
    try {
      _logger.i('Getting earnings history for member: $memberId');
      final querySnapshot = await _earningsRecordsCollection
          .where('memberId', isEqualTo: memberId)
          .orderBy('timestamp', descending: true)
          .get();
      
      final earnings = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      
      _logger.i('Retrieved ${earnings.length} earnings records for member');
      return earnings;
    } catch (e) {
      _logger.e('Error getting member earnings history: $e');
      throw Exception('Failed to get member earnings history: $e');
    }
  }

  // Get earnings by date range
  Future<List<Map<String, dynamic>>> getEarningsByDateRange(
    String memberId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      _logger.i('Getting earnings for member $memberId between $startDate and $endDate');
      final querySnapshot = await _earningsRecordsCollection
          .where('memberId', isEqualTo: memberId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('timestamp', descending: true)
          .get();
      
      final earnings = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      
      _logger.i('Retrieved ${earnings.length} earnings records in date range');
      return earnings;
    } catch (e) {
      _logger.e('Error getting earnings by date range: $e');
      throw Exception('Failed to get earnings by date range: $e');
    }
  }

  // ANALYTICS AND AGGREGATION METHODS

  // Get member performance stats
  Future<Map<String, dynamic>> getMemberPerformanceStats(String memberId) async {
    try {
      _logger.i('Getting performance stats for member: $memberId');
      
      // Get completed orders count
      final completedOrders = await _ordersCollection
          .where('assignedTo', isEqualTo: memberId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      // Get total earnings from earnings records
      final earningsSnapshot = await _earningsRecordsCollection
          .where('memberId', isEqualTo: memberId)
          .get();
      
      double totalEarnings = 0.0;
      int totalItems = 0;
      
      for (final doc in earningsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalEarnings += (data['earnings'] ?? 0.0).toDouble();
        totalItems += ((data['itemsProcessed'] ?? 0) as num).toInt();
      }
      
      final stats = {
        'completedOrders': completedOrders.docs.length,
        'totalEarnings': totalEarnings,
        'totalItems': totalItems,
        'averageEarningsPerOrder': completedOrders.docs.isNotEmpty 
            ? totalEarnings / completedOrders.docs.length 
            : 0.0,
        'averageEarningsPerItem': totalItems > 0 
            ? totalEarnings / totalItems 
            : 0.0,
      };
      
      _logger.i('Performance stats calculated successfully');
      return stats;
    } catch (e) {
      _logger.e('Error getting member performance stats: $e');
      throw Exception('Failed to get member performance stats: $e');
    }
  }

  // Get workshop stats
  Future<Map<String, dynamic>> getWorkshopStats(String workshopId) async {
    try {
      _logger.i('Getting workshop stats for: $workshopId');
      
      // Get workshop members
      final membersSnapshot = await _workshopMembersCollection
          .where('workshopId', isEqualTo: workshopId)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Get orders assigned to workshop members
      final List<String> memberIds = membersSnapshot.docs.map((doc) => doc.id).toList();
      
      if (memberIds.isEmpty) {
        return {
          'totalMembers': 0,
          'totalOrders': 0,
          'completedOrders': 0,
          'pendingOrders': 0,
          'totalEarnings': 0.0,
        };
      }
      
      // Get orders (limited query due to Firestore limitations)
      final ordersSnapshot = await _ordersCollection
          .where('workshopId', isEqualTo: workshopId)
          .get();
      
      int completedOrders = 0;
      int pendingOrders = 0;
      double totalEarnings = 0.0;
      
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        
        if (status == 'completed') {
          completedOrders++;
          totalEarnings += (data['workshopEarnings'] ?? 0.0).toDouble();
        } else if (status == 'pending' || status == 'processing') {
          pendingOrders++;
        }
      }
      
      final stats = {
        'totalMembers': membersSnapshot.docs.length,
        'totalOrders': ordersSnapshot.docs.length,
        'completedOrders': completedOrders,
        'pendingOrders': pendingOrders,
        'totalEarnings': totalEarnings,
      };
      
      _logger.i('Workshop stats calculated successfully');
      return stats;
    } catch (e) {
      _logger.e('Error getting workshop stats: $e');
      throw Exception('Failed to get workshop stats: $e');
    }
  }

  // UTILITY METHODS

  // Create a batch write
  WriteBatch createBatch() {
    return _firestore.batch();
  }

  // Execute batch write
  Future<void> executeBatch(WriteBatch batch) async {
    try {
      await batch.commit();
      _logger.i('Batch operation executed successfully');
    } catch (e) {
      _logger.e('Error executing batch operation: $e');
      throw Exception('Failed to execute batch operation: $e');
    }
  }

  // Create a transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    try {
      _logger.i('Running transaction');
      final result = await _firestore.runTransaction<T>(updateFunction);
      _logger.i('Transaction completed successfully');
      return result;
    } catch (e) {
      _logger.e('Error running transaction: $e');
      throw Exception('Failed to run transaction: $e');
    }
  }

  // Listen to real-time updates for orders
  Stream<List<workshop_order.WorkshopOrder>> getOrdersStream({String? memberId, String? status}) {
    try {
      Query query = _ordersCollection.orderBy('createdAt', descending: true);
      
      if (memberId != null) {
        query = query.where('assignedTo', isEqualTo: memberId);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      return query.limit(50).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => workshop_order.WorkshopOrder.fromFirestore(doc)).toList();
      });
    } catch (e) {
      _logger.e('Error setting up orders stream: $e');
      throw Exception('Failed to set up orders stream: $e');
    }
  }

  // Listen to real-time updates for workshop member
  Stream<WorkshopMember?> getWorkshopMemberStream(String memberId) {
    try {
      return _workshopMembersCollection.doc(memberId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          return WorkshopMember.fromFirestore(snapshot);
        }
        return null;
      });
    } catch (e) {
      _logger.e('Error setting up workshop member stream: $e');
      throw Exception('Failed to set up workshop member stream: $e');
    }
  }

  // PHONE AUTHENTICATION METHODS

  // Check if workshop worker exists with phone number
  Future<bool> checkWorkshopWorkerByPhone(String phoneNumber) async {
    try {
      _logger.i('Checking if workshop worker exists with phone: $phoneNumber');
      final querySnapshot = await _workshopWorkersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      final exists = querySnapshot.docs.isNotEmpty;
      _logger.i('Workshop worker exists: $exists');
      return exists;
    } catch (e) {
      _logger.e('Error checking workshop worker by phone: $e');
      throw Exception('Failed to check workshop worker by phone: $e');
    }
  }

  // Get workshop worker by phone number
  Future<WorkshopMember?> getWorkshopWorkerByPhone(String phoneNumber) async {
    try {
      _logger.i('Getting workshop worker by phone: $phoneNumber');
      final querySnapshot = await _workshopWorkersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        // Convert workshop worker data to WorkshopMember format
        final member = WorkshopMember(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          profileImageUrl: data['profileImageUrl'],
          workshopId: data['workshopLocation'] ?? 'default',
          role: data['role'] ?? 'worker',
          isActive: data['isActive'] ?? true,
          joinedDate: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          lastLoginAt: data['lastLoginAt'] != null 
              ? (data['lastLoginAt'] as Timestamp).toDate()
              : null,
          performance: _convertPerformanceData(data),
          earnings: _convertEarningsData(data),
          specialties: List<String>.from(data['skills'] ?? []),
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          updatedAt: data['updatedAt'] != null 
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
        
        _logger.i('Workshop worker retrieved successfully');
        return member;
      } else {
        _logger.w('Workshop worker not found with phone: $phoneNumber');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting workshop worker by phone: $e');
      throw Exception('Failed to get workshop worker by phone: $e');
    }
  }

  // Update workshop worker UID after phone authentication
  Future<void> updateWorkshopWorkerUID(String workerId, String firebaseUID) async {
    try {
      _logger.i('Updating workshop worker UID: $workerId -> $firebaseUID');
      await _workshopWorkersCollection.doc(workerId).update({
        'uid': firebaseUID,
        'isRegistered': true,
        'lastLoginAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      _logger.i('Workshop worker UID updated successfully');
    } catch (e) {
      _logger.e('Error updating workshop worker UID: $e');
      throw Exception('Failed to update workshop worker UID: $e');
    }
  }

  // Update workshop worker last login
  Future<void> updateWorkshopWorkerLastLogin(String workerId) async {
    try {
      _logger.i('Updating workshop worker last login: $workerId');
      await _workshopWorkersCollection.doc(workerId).update({
        'lastLoginAt': Timestamp.now(),
        'isOnline': true,
        'updatedAt': Timestamp.now(),
      });
      _logger.i('Workshop worker last login updated successfully');
    } catch (e) {
      _logger.e('Error updating workshop worker last login: $e');
      throw Exception('Failed to update workshop worker last login: $e');
    }
  }

  // Convert performance data from workshop worker to member format
  Map<String, dynamic> _convertPerformanceData(Map<String, dynamic> data) {
    return {
      'completedOrders': _createDailyStats(data['completedOrders'] ?? 0),
      'processedItems': _createDailyStats(data['totalOrders'] ?? 0),
      'rating': (data['rating'] ?? 0.0).toDouble(),
    };
  }

  // Convert earnings data from workshop worker to member format
  Map<String, dynamic> _convertEarningsData(Map<String, dynamic> data) {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return {
      todayKey: (data['earnings'] ?? 0.0).toDouble(),
    };
  }

  // Create daily stats format
  Map<String, dynamic> _createDailyStats(int value) {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return {
      todayKey: value,
    };
  }
} 