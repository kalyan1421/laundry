import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Generates a unique sequential order number starting from A000001
  /// Format: A000001, A000002, A000003, etc.
  static Future<String> generateUniqueOrderNumber() async {
    try {
      // Use Firestore transaction to get and increment the counter atomically
      final DocumentReference counterRef = _firestore.collection('counters').doc('order_counter');
      
      return await _firestore.runTransaction<String>((transaction) async {
        final DocumentSnapshot counterSnapshot = await transaction.get(counterRef);
        
        int nextOrderNumber;
        if (counterSnapshot.exists) {
          // Get current counter value and increment
          final data = counterSnapshot.data() as Map<String, dynamic>?;
          final currentValue = data?['value'] as int? ?? 0;
          nextOrderNumber = currentValue + 1;
        } else {
          // First time - start from 1 (will become A000001)
          nextOrderNumber = 1;
        }
        
        // Update the counter
        transaction.set(counterRef, {
          'value': nextOrderNumber,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        // Format as A000001, A000002, etc.
        return 'A${nextOrderNumber.toString().padLeft(6, '0')}';
      });
    } catch (e) {
      print('Error generating sequential order number: $e');
      // Check if it's a permission error and provide helpful message
      if (e.toString().contains('permission-denied')) {
        print('⚠️ Permission denied for order counter. Using fallback method.');
        print('💡 To fix: Update Firestore rules to allow counter access or run admin setup script.');
      }
      // Fallback to timestamp-based approach
      return _generateTimestampBasedOrderNumber();
    }
  }

  /// Generate a timestamp-based order number as fallback with A prefix
  static String _generateTimestampBasedOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = _random.nextInt(100);
    
    // Create a 6-digit number from timestamp and random
    final orderNumber = (timestamp % 100000) * 100 + random;
    return 'A${orderNumber.toString().padLeft(6, '0')}';
  }

  /// Check if an order number already exists
  static Future<bool> orderNumberExists(String orderNumber) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderNumber).get();
      return doc.exists;
    } catch (e) {
      print('Error checking order number existence: $e');
      return false;
    }
  }

  /// Generate a unique order number with retry mechanism
  static Future<String> generateUniqueOrderNumberWithRetry({int maxRetries = 5}) async {
    for (int i = 0; i < maxRetries; i++) {
      final orderNumber = await generateUniqueOrderNumber();
      final exists = await orderNumberExists(orderNumber);
      
      if (!exists) {
        return orderNumber;
      }
      
      print('Order number $orderNumber already exists, retrying... (${i + 1}/$maxRetries)');
      
      // Wait a bit before retrying
      await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
    }
    
    // If all retries failed, use timestamp-based fallback
    print('Failed to generate unique order number after $maxRetries retries, using fallback');
    return _generateTimestampBasedOrderNumber();
  }
}
