import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Completely delete a customer and all associated data
  Future<CustomerDeletionResult> deleteCustomerCompletely({
    required String customerId,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      // Start a batch operation for atomic deletion
      WriteBatch batch = _firestore.batch();
      
      // Track what we're deleting for the result
      int addressesDeleted = 0;
      int ordersFound = 0;
      List<String> deletedOrderIds = [];
      
      print('🗑️ Starting complete deletion for customer: $customerId');
      
      // 1. Get and delete all customer addresses
      QuerySnapshot addressesSnapshot = await _firestore
          .collection('customer')
          .doc(customerId)
          .collection('addresses')
          .get();
      
      for (QueryDocumentSnapshot addressDoc in addressesSnapshot.docs) {
        batch.delete(addressDoc.reference);
        addressesDeleted++;
      }
      
      print('🗑️ Found $addressesDeleted addresses to delete');
      
      // 2. Handle customer orders - we'll mark them as "customer_deleted" instead of deleting
      // This preserves business records while indicating the customer is gone
      QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .get();
      
      if (ordersSnapshot.docs.isEmpty) {
        // Try with userId field as backup
        ordersSnapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: customerId)
            .get();
      }
      
      ordersFound = ordersSnapshot.docs.length;
      
      for (QueryDocumentSnapshot orderDoc in ordersSnapshot.docs) {
        // Mark orders as customer deleted instead of deleting them
        batch.update(orderDoc.reference, {
          'customerDeleted': true,
          'customerDeletedAt': FieldValue.serverTimestamp(),
          'customerDeletedBy': _auth.currentUser?.email ?? 'admin',
          'originalCustomerName': customerName,
          'originalCustomerPhone': customerPhone,
          'statusHistory': FieldValue.arrayUnion([
            {
              'status': 'customer_deleted',
              'timestamp': Timestamp.now(),
              'updatedBy': 'admin',
              'title': 'Customer Account Deleted',
              'description': 'Customer account was deleted by admin. Order preserved for records.',
            }
          ]),
        });
        deletedOrderIds.add(orderDoc.id);
      }
      
      print('🗑️ Found $ordersFound orders to mark as customer deleted');
      
      // 3. Delete any other customer-related collections (add more as needed)
      // For example: notifications, preferences, etc.
      
      // 4. Finally, delete the main customer document
      DocumentReference customerRef = _firestore.collection('customer').doc(customerId);
      batch.delete(customerRef);
      
      // Execute the batch operation
      print('🗑️ Executing batch deletion...');
      await batch.commit();
      
      print('🗑️ Customer deletion completed successfully');
      
      return CustomerDeletionResult(
        success: true,
        customerId: customerId,
        customerName: customerName,
        addressesDeleted: addressesDeleted,
        ordersMarkedAsDeleted: ordersFound,
        deletedOrderIds: deletedOrderIds,
        message: 'Customer deleted successfully. $addressesDeleted addresses removed, $ordersFound orders preserved with deletion marker.',
      );
      
    } catch (e) {
      print('🗑️ Error during customer deletion: $e');
      
      return CustomerDeletionResult(
        success: false,
        customerId: customerId,
        customerName: customerName,
        addressesDeleted: 0,
        ordersMarkedAsDeleted: 0,
        deletedOrderIds: [],
        message: 'Failed to delete customer: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  /// Get deletion preview - shows what will be deleted without actually deleting
  Future<CustomerDeletionPreview> getCustomerDeletionPreview(String customerId) async {
    try {
      // Count addresses
      QuerySnapshot addressesSnapshot = await _firestore
          .collection('customer')
          .doc(customerId)
          .collection('addresses')
          .get();
      
      // Count orders
      QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .get();
      
      if (ordersSnapshot.docs.isEmpty) {
        // Try with userId field as backup
        ordersSnapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: customerId)
            .get();
      }
      
      // Get order statuses for preview
      Map<String, int> ordersByStatus = {};
      List<Map<String, dynamic>> recentOrders = [];
      
      for (QueryDocumentSnapshot orderDoc in ordersSnapshot.docs) {
        Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
        String status = orderData['status'] ?? 'unknown';
        ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;
        
        // Keep track of recent orders for preview
        if (recentOrders.length < 5) {
          recentOrders.add({
            'id': orderDoc.id,
            'orderNumber': orderData['orderNumber'],
            'status': status,
            'totalAmount': orderData['totalAmount'],
            'createdAt': orderData['orderTimestamp'] ?? orderData['createdAt'],
          });
        }
      }
      
      return CustomerDeletionPreview(
        customerId: customerId,
        addressCount: addressesSnapshot.docs.length,
        orderCount: ordersSnapshot.docs.length,
        ordersByStatus: ordersByStatus,
        recentOrders: recentOrders,
        canDelete: true,
        warnings: _generateDeletionWarnings(ordersSnapshot.docs.length, ordersByStatus),
      );
      
    } catch (e) {
      return CustomerDeletionPreview(
        customerId: customerId,
        addressCount: 0,
        orderCount: 0,
        ordersByStatus: {},
        recentOrders: [],
        canDelete: false,
        warnings: ['Error fetching customer data: ${e.toString()}'],
      );
    }
  }

  List<String> _generateDeletionWarnings(int orderCount, Map<String, int> ordersByStatus) {
    List<String> warnings = [];
    
    if (orderCount > 0) {
      warnings.add('Customer has $orderCount orders that will be marked as "customer deleted" but preserved for business records.');
    }
    
    if (ordersByStatus.containsKey('pending') || ordersByStatus.containsKey('confirmed')) {
      int activeOrders = (ordersByStatus['pending'] ?? 0) + (ordersByStatus['confirmed'] ?? 0);
      warnings.add('Customer has $activeOrders active orders that are not yet completed.');
    }
    
    if (ordersByStatus.containsKey('processing') || ordersByStatus.containsKey('out_for_delivery')) {
      int inProcessOrders = (ordersByStatus['processing'] ?? 0) + (ordersByStatus['out_for_delivery'] ?? 0);
      warnings.add('Customer has $inProcessOrders orders currently being processed or out for delivery.');
    }
    
    return warnings;
  }
}

/// Result of customer deletion operation
class CustomerDeletionResult {
  final bool success;
  final String customerId;
  final String customerName;
  final int addressesDeleted;
  final int ordersMarkedAsDeleted;
  final List<String> deletedOrderIds;
  final String message;
  final String? error;

  CustomerDeletionResult({
    required this.success,
    required this.customerId,
    required this.customerName,
    required this.addressesDeleted,
    required this.ordersMarkedAsDeleted,
    required this.deletedOrderIds,
    required this.message,
    this.error,
  });
}

/// Preview of what will be deleted
class CustomerDeletionPreview {
  final String customerId;
  final int addressCount;
  final int orderCount;
  final Map<String, int> ordersByStatus;
  final List<Map<String, dynamic>> recentOrders;
  final bool canDelete;
  final List<String> warnings;

  CustomerDeletionPreview({
    required this.customerId,
    required this.addressCount,
    required this.orderCount,
    required this.ordersByStatus,
    required this.recentOrders,
    required this.canDelete,
    required this.warnings,
  });
}
