import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Generates a unique sequential order number based on service type
  /// Format: CI000001 for Ironing, CL000001 for Allied services, C000001 for others
  static Future<String> generateUniqueOrderNumber({String? serviceType}) async {
    try {
      // Determine the counter collection and prefix based on service type
      String prefix = 'C';
      String counterDocId = 'order_counter';
      
      if (serviceType != null) {
        final lowerServiceType = serviceType.toLowerCase();
        if (lowerServiceType.contains('ironing')) {
          prefix = 'CI';
          counterDocId = 'ironing_order_counter';
        } else if (lowerServiceType.contains('allied')) {
          prefix = 'CL';
          counterDocId = 'allied_order_counter';
        }
      }
      
      print('🔢 ORDER NUMBER: Generating ${prefix}XXXXXX for service: $serviceType using counter: $counterDocId');
      
      // Use Firestore transaction to get and increment the counter atomically
      final DocumentReference counterRef = _firestore.collection('counters').doc(counterDocId);
      
      return await _firestore.runTransaction<String>((transaction) async {
        try {
          print('🔄 TRANSACTION: Starting transaction for counter: $counterDocId');
          final DocumentSnapshot counterSnapshot = await transaction.get(counterRef);
          
          int nextOrderNumber;
          if (counterSnapshot.exists) {
            // Get current counter value and increment
            final data = counterSnapshot.data() as Map<String, dynamic>?;
            print('📋 TRANSACTION: Counter data: $data');
            final currentValue = data?['value'] as int? ?? 0;
            nextOrderNumber = currentValue + 1;
            print('📊 COUNTER: Found existing counter with value $currentValue, incrementing to $nextOrderNumber');
          } else {
            // First time - start from 1 (will become CI000001, CL000001, or C000001)
            nextOrderNumber = 1;
            print('🆕 COUNTER: Creating new counter document, starting from $nextOrderNumber');
          }
          
          // Validate the number before formatting
          if (nextOrderNumber <= 0) {
            print('⚠️ WARNING: Invalid order number $nextOrderNumber, using 1 instead');
            nextOrderNumber = 1;
          }
          
          // Update the counter
          print('💾 TRANSACTION: Updating counter to value: $nextOrderNumber');
          transaction.set(counterRef, {
            'value': nextOrderNumber,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          
          // Format with appropriate prefix: CI000001, CL000001, or C000001
          final paddedNumber = nextOrderNumber.toString().padLeft(6, '0');
          final generatedNumber = '$prefix$paddedNumber';
          print('🔢 FORMATTING: prefix="$prefix", number=$nextOrderNumber, padded="$paddedNumber"');
          print('✅ ORDER NUMBER: Successfully generated: $generatedNumber');
          return generatedNumber;
        } catch (transactionError) {
          print('❌ TRANSACTION ERROR: $transactionError');
          rethrow;
        }
      });
    } catch (e) {
      print('❌ ORDER NUMBER: Error generating sequential order number: $e');
      // Check if it's a permission error and provide helpful message
      if (e.toString().contains('permission-denied')) {
        print('⚠️ PERMISSION DENIED: Counter access denied. Check Firestore security rules.');
        print('💡 SOLUTION: Update Firestore rules to allow counter access.');
      } else if (e.toString().contains('not-found')) {
        print('⚠️ COUNTER NOT FOUND: Counter document missing.');
        print('💡 SOLUTION: Run setup script to create missing counter documents.');
      }
      
      print('🔄 FALLBACK: Using timestamp-based order number generation...');
      final fallbackNumber = _generateTimestampBasedOrderNumber(serviceType);
      print('⚠️ FALLBACK RESULT: $fallbackNumber (Note: This is not sequential!)');
      return fallbackNumber;
    }
  }



  /// Generate a timestamp-based order number as fallback with service-specific prefix
  static String _generateTimestampBasedOrderNumber(String? serviceType) {
    print('🔄 FALLBACK: Generating timestamp-based number for service: $serviceType');
    
    // Use current timestamp and some randomness
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    
    // Take last 4 digits of timestamp and add 2 random digits
    final lastFourDigits = timestamp % 10000;
    final randomTwoDigits = _random.nextInt(100);
    
    // Combine to create 6-digit number
    final orderNumber = (lastFourDigits * 100 + randomTwoDigits) % 1000000;
    
    // Ensure we have at least 1 if the calculation results in 0
    final finalOrderNumber = orderNumber == 0 ? 1 : orderNumber;
    
    // Determine prefix based on service type
    String prefix = 'C';
    if (serviceType != null) {
      final lowerServiceType = serviceType.toLowerCase();
      if (lowerServiceType.contains('ironing')) {
        prefix = 'CI';
      } else if (lowerServiceType.contains('allied')) {
        prefix = 'CL';
      }
    }
    
    print('🔢 FALLBACK CALC: timestamp=$timestamp, lastFour=$lastFourDigits, random=$randomTwoDigits');
    print('🔢 FALLBACK CALC: calculated=$orderNumber, final=$finalOrderNumber, prefix="$prefix"');
    
    // Ensure it's at least 6 digits and add appropriate prefix
    final paddedNumber = finalOrderNumber.toString().padLeft(6, '0');
    final result = '$prefix$paddedNumber';
    print('🔢 FALLBACK RESULT: "$result"');
    return result;
  }

  /// Validate if a string is a valid order number (C000001, CI000001, or CL000001 format)
  static bool isValidOrderNumber(String orderNumber) {
    if (orderNumber.length < 7 || orderNumber.length > 8) return false;
    
    // Check if format is C, CI, or CL followed by 6 digits
    return RegExp(r'^(C|CI|CL)\d{6}$').hasMatch(orderNumber);
  }

  /// Generate a formatted order number with prefix (e.g., "ORD-C000001")
  static String generateFormattedOrderNumber(String orderNumber) {
    return 'ORD-$orderNumber';
  }
} 