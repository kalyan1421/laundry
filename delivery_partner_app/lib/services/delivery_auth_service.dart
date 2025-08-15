// services/delivery_auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Authenticate delivery partner with phone + code
  Future<Map<String, dynamic>?> authenticateDeliveryPartner({
    required String phoneNumber,
    required String loginCode,
  }) async {
    try {
      // Format phone number
      String formattedPhone = phoneNumber.startsWith('+91') 
          ? phoneNumber 
          : '+91$phoneNumber';

      print('🚚 Authenticating: $formattedPhone with code: $loginCode');

      // First try phone index for faster lookup
      final phoneKey = formattedPhone.replaceAll('+', '');
      final indexDoc = await _firestore
          .collection('delivery_phone_index')
          .doc(phoneKey)
          .get();

      String? partnerId;

      if (indexDoc.exists && indexDoc.data()!['isActive'] == true) {
        partnerId = indexDoc.data()!['deliveryPartnerId'];
        print('🚚 Found partner ID from index: $partnerId');
      } else {
        // Fallback: search in main collection
        print('🚚 Searching in main delivery collection...');
        final query = await _firestore
            .collection('delivery')
            .where('phoneNumber', isEqualTo: formattedPhone)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          partnerId = query.docs.first.id;
          print('🚚 Found partner ID from main collection: $partnerId');
        }
      }

      if (partnerId == null) {
        throw Exception('No active delivery partner found with this phone number. Contact administrator.');
      }

      // Get partner data and verify code
      final partnerDoc = await _firestore.collection('delivery').doc(partnerId).get();
      
      if (!partnerDoc.exists) {
        throw Exception('Delivery partner not found');
      }

      final partnerData = partnerDoc.data()!;
      
      if (partnerData['loginCode'] != loginCode) {
        // Update failed login attempt
        await _firestore.collection('delivery').doc(partnerId).update({
          'metadata.lastLoginAttempt': Timestamp.now(),
          'metadata.loginAttempts': FieldValue.increment(1),
        });
        
        throw Exception('Invalid login code. Please check your code and try again.');
      }

      // Update successful login
      await _firestore.collection('delivery').doc(partnerId).update({
        'metadata.lastSuccessfulLogin': Timestamp.now(),
        'metadata.lastLoginAttempt': Timestamp.now(),
        'isOnline': true,
        'firstLoginRequired': false,
      });

      print('🚚 ✅ Authentication successful for: ${partnerData['name']}');

      return {
        'id': partnerId,
        ...partnerData,
      };

    } catch (e) {
      print('🚚 ❌ Authentication failed: $e');
      rethrow;
    }
  }

  /// Get delivery partner by ID
  Future<Map<String, dynamic>?> getDeliveryPartner(String partnerId) async {
    try {
      final doc = await _firestore.collection('delivery').doc(partnerId).get();
      
      if (!doc.exists) {
        return null;
      }

      return {
        'id': partnerId,
        ...doc.data()!,
      };

    } catch (e) {
      print('🚚 ❌ Error getting delivery partner: $e');
      return null;
    }
  }

  // Order-related methods removed - use OrderProvider instead

  /// Mark delivery partner as online/offline
  Future<void> updateOnlineStatus(String partnerId, bool isOnline) async {
    try {
      await _firestore.collection('delivery').doc(partnerId).update({
        'isOnline': isOnline,
        'updatedAt': Timestamp.now(),
      });

      print('🚚 Online status updated: $isOnline');

    } catch (e) {
      print('🚚 Error updating online status: $e');
      rethrow;
    }
  }

  /// Update delivery partner availability
  Future<void> updateAvailability(String partnerId, bool isAvailable) async {
    try {
      await _firestore.collection('delivery').doc(partnerId).update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.now(),
      });

      print('🚚 Availability updated: $isAvailable');

    } catch (e) {
      print('🚚 Error updating availability: $e');
      rethrow;
    }
  }
}
