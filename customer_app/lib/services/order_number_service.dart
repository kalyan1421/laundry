import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Generates a unique sequential order number starting from 100000
  /// Format: XXXXXX (where X is a digit from 0-9)
  /// Range: 100000 and increments by 1 for each order
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
          final currentValue = data?['value'] as int? ?? 99999;
          nextOrderNumber = currentValue + 1;
        } else {
          // First time - start from 100000
          nextOrderNumber = 100000;
        }
        
        // Update the counter
        transaction.set(counterRef, {
          'value': nextOrderNumber,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        return nextOrderNumber.toString();
      });
    } catch (e) {
      print('Error generating sequential order number: $e');
      // Fallback to timestamp-based approach
      return _generateTimestampBasedOrderNumber();
    }
  }



  /// Generate a timestamp-based 6-digit order number as fallback
  static String _generateTimestampBasedOrderNumber() {
    // Use current timestamp and some randomness
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    
    // Take last 4 digits of timestamp and add 2 random digits
    final lastFourDigits = timestamp % 10000;
    final randomTwoDigits = _random.nextInt(100);
    
    // Combine to create 6-digit number
    final orderNumber = (lastFourDigits * 100 + randomTwoDigits) % 1000000;
    
    // Ensure it's at least 6 digits
    return orderNumber.toString().padLeft(6, '0');
  }

  /// Validate if a string is a valid 6-digit order number
  static bool isValidOrderNumber(String orderNumber) {
    if (orderNumber.length != 6) return false;
    
    // Check if all characters are digits
    return RegExp(r'^\d{6}$').hasMatch(orderNumber);
  }

  /// Generate a formatted order number with prefix (e.g., "ORD-123456")
  static String generateFormattedOrderNumber(String orderNumber) {
    return 'ORD-$orderNumber';
  }
} 