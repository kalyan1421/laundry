import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Generates a unique sequential order number starting from C000001
  /// Format: C000001, C000002, C000003, etc.
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
          // First time - start from 1 (will become C000001)
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



  /// Generate a timestamp-based order number as fallback with C prefix
  static String _generateTimestampBasedOrderNumber() {
    // Use current timestamp and some randomness
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    
    // Take last 4 digits of timestamp and add 2 random digits
    final lastFourDigits = timestamp % 10000;
    final randomTwoDigits = _random.nextInt(100);
    
    // Combine to create 6-digit number
    final orderNumber = (lastFourDigits * 100 + randomTwoDigits) % 1000000;
    
    // Ensure it's at least 6 digits and add C prefix
    return 'C${orderNumber.toString().padLeft(6, '0')}';
  }

  /// Validate if a string is a valid order number (C000001 format)
  static bool isValidOrderNumber(String orderNumber) {
    if (orderNumber.length != 7) return false;
    
    // Check if format is C followed by 6 digits
    return RegExp(r'^C\d{6}$').hasMatch(orderNumber);
  }

  /// Generate a formatted order number with prefix (e.g., "ORD-C000001")
  static String generateFormattedOrderNumber(String orderNumber) {
    return 'ORD-$orderNumber';
  }
} 