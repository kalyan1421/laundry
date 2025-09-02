// services/delivery_partner_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryPartnerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new delivery partner with phone + code authentication
  Future<void> addDeliveryPartner({
    required String name,
    required String phoneNumber,
    required String email,
    required String licenseNumber,
    required String aadharNumber,
    required String loginCode,
    required bool isActive,
    required String createdBy,
    required String createdByRole,
  }) async {
    try {
      // Format phone number
      String formattedPhone = phoneNumber.startsWith('+91') 
          ? phoneNumber 
          : '+91$phoneNumber';

      // Check if phone number already exists
      final existingQuery = await _firestore
          .collection('delivery')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('A delivery partner with this phone number already exists');
      }

      // Check if login code already exists
      final codeQuery = await _firestore
          .collection('delivery')
          .where('loginCode', isEqualTo: loginCode)
          .limit(1)
          .get();

      if (codeQuery.docs.isNotEmpty) {
        throw Exception('This login code is already in use. Please choose a different code.');
      }

      final now = Timestamp.now();
      
      // Create delivery partner document
      final deliveryData = {
        'name': name,
        'phoneNumber': formattedPhone,
        'email': email,
        'licenseNumber': licenseNumber,
        'aadharNumber': aadharNumber,
        'loginCode': loginCode,
        'isActive': isActive,
        'isAvailable': true,
        'isOnline': false,
        'isRegistered': false,
        'firstLoginRequired': true,
        'authenticationStatus': 'pending',
        'role': 'delivery',
        'rating': 0.0,
        'totalDeliveries': 0,
        'completedDeliveries': 0,
        'cancelledDeliveries': 0,
        'earnings': 0.0,
        'currentOrders': [],
        'orderHistory': [],
        'vehicleInfo': {},
        'documents': {},
        'bankDetails': {},
        'address': {},
        'createdAt': now,
        'updatedAt': now,
        'createdBy': createdBy,
        'createdByRole': createdByRole,
        'metadata': {
          'loginAttempts': 0,
          'lastLoginAttempt': null,
          'lastSuccessfulLogin': null,
          'firstLoginCompleted': false,
          'linkedToFirebaseAuth': false,
          'linkedAt': null,
        },
      };

      // Add to delivery collection
      final docRef = await _firestore.collection('delivery').add(deliveryData);
      
      // Create phone index for faster lookups
      final phoneKey = formattedPhone.replaceAll('+', '');
      await _firestore.collection('delivery_phone_index').doc(phoneKey).set({
        'deliveryPartnerId': docRef.id,
        'phoneNumber': formattedPhone,
        'isActive': isActive,
        'createdAt': now,
      });

      print('✅ Delivery partner added successfully: ${docRef.id}');

    } catch (e) {
      print('❌ Error adding delivery partner: $e');
      rethrow;
    }
  }

  /// Update delivery partner information
  Future<void> updateDeliveryPartner({
    required String partnerId,
    required String name,
    required String phoneNumber,
    required String email,
    required String licenseNumber,
    required String aadharNumber,
    required String loginCode,
    required bool isActive,
  }) async {
    try {
      // Format phone number
      String formattedPhone = phoneNumber.startsWith('+91') 
          ? phoneNumber 
          : '+91$phoneNumber';

      // Get current partner data
      final currentDoc = await _firestore.collection('delivery').doc(partnerId).get();
      if (!currentDoc.exists) {
        throw Exception('Delivery partner not found');
      }

      final currentData = currentDoc.data()!;
      final currentPhone = currentData['phoneNumber'];
      final currentCode = currentData['loginCode'];

      // Check if phone number is changing and if new number already exists
      if (formattedPhone != currentPhone) {
        final existingQuery = await _firestore
            .collection('delivery')
            .where('phoneNumber', isEqualTo: formattedPhone)
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          throw Exception('A delivery partner with this phone number already exists');
        }
      }

      // Check if login code is changing and if new code already exists
      if (loginCode != currentCode) {
        final codeQuery = await _firestore
            .collection('delivery')
            .where('loginCode', isEqualTo: loginCode)
            .limit(1)
            .get();

        if (codeQuery.docs.isNotEmpty) {
          throw Exception('This login code is already in use. Please choose a different code.');
        }
      }

      // Update delivery partner
      await _firestore.collection('delivery').doc(partnerId).update({
        'name': name,
        'phoneNumber': formattedPhone,
        'email': email,
        'licenseNumber': licenseNumber,
        'aadharNumber': aadharNumber,
        'loginCode': loginCode,
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });

      // Update phone index if phone number changed
      if (formattedPhone != currentPhone) {
        // Remove old index
        if (currentPhone != null) {
          final oldPhoneKey = currentPhone.replaceAll('+', '');
          await _firestore.collection('delivery_phone_index').doc(oldPhoneKey).delete();
        }

        // Create new index
        final phoneKey = formattedPhone.replaceAll('+', '');
        await _firestore.collection('delivery_phone_index').doc(phoneKey).set({
          'deliveryPartnerId': partnerId,
          'phoneNumber': formattedPhone,
          'isActive': isActive,
          'createdAt': Timestamp.now(),
        });
      } else {
        // Update existing index
        final phoneKey = formattedPhone.replaceAll('+', '');
        await _firestore.collection('delivery_phone_index').doc(phoneKey).update({
          'isActive': isActive,
        });
      }

      print('✅ Delivery partner updated successfully: $partnerId');

    } catch (e) {
      print('❌ Error updating delivery partner: $e');
      rethrow;
    }
  }

  /// Toggle delivery partner active status
  Future<void> togglePartnerStatus(String partnerId, bool isActive) async {
    try {
      await _firestore.collection('delivery').doc(partnerId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });

      // Update phone index
      final doc = await _firestore.collection('delivery').doc(partnerId).get();
      if (doc.exists) {
        final phoneNumber = doc.data()!['phoneNumber'];
        if (phoneNumber != null) {
          final phoneKey = phoneNumber.replaceAll('+', '');
          await _firestore.collection('delivery_phone_index').doc(phoneKey).update({
            'isActive': isActive,
          });
        }
      }

      print('✅ Partner status toggled: $partnerId -> $isActive');

    } catch (e) {
      print('❌ Error toggling partner status: $e');
      rethrow;
    }
  }

  /// Reset delivery partner login code
  Future<void> resetLoginCode(String partnerId, String newCode) async {
    try {
      // Check if new code already exists
      final codeQuery = await _firestore
          .collection('delivery')
          .where('loginCode', isEqualTo: newCode)
          .limit(1)
          .get();

      if (codeQuery.docs.isNotEmpty && codeQuery.docs.first.id != partnerId) {
        throw Exception('This login code is already in use. Please choose a different code.');
      }

      await _firestore.collection('delivery').doc(partnerId).update({
        'loginCode': newCode,
        'updatedAt': Timestamp.now(),
        'firstLoginRequired': true, // Require them to login again
      });

      print('✅ Login code reset for partner: $partnerId');

    } catch (e) {
      print('❌ Error resetting login code: $e');
      rethrow;
    }
  }

  /// Delete delivery partner
  Future<void> deleteDeliveryPartner(String partnerId) async {
    try {
      // Get partner data to clean up phone index
      final doc = await _firestore.collection('delivery').doc(partnerId).get();
      
      if (doc.exists) {
        final phoneNumber = doc.data()!['phoneNumber'];
        
        // Delete phone index
        if (phoneNumber != null) {
          final phoneKey = phoneNumber.replaceAll('+', '');
          await _firestore.collection('delivery_phone_index').doc(phoneKey).delete();
        }
      }

      // Delete delivery partner
      await _firestore.collection('delivery').doc(partnerId).delete();

      print('✅ Delivery partner deleted: $partnerId');

    } catch (e) {
      print('❌ Error deleting delivery partner: $e');
      rethrow;
    }
  }

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

      // First try phone index for faster lookup
      final phoneKey = formattedPhone.replaceAll('+', '');
      final indexDoc = await _firestore
          .collection('delivery_phone_index')
          .doc(phoneKey)
          .get();

      String? partnerId;

      if (indexDoc.exists && indexDoc.data()!['isActive'] == true) {
        partnerId = indexDoc.data()!['deliveryPartnerId'];
      } else {
        // Fallback: search in main collection
        final query = await _firestore
            .collection('delivery')
            .where('phoneNumber', isEqualTo: formattedPhone)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          partnerId = query.docs.first.id;
        }
      }

      if (partnerId == null) {
        throw Exception('No active delivery partner found with this phone number');
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
        
        throw Exception('Invalid login code');
      }

      // Update successful login
      await _firestore.collection('delivery').doc(partnerId).update({
        'metadata.lastSuccessfulLogin': Timestamp.now(),
        'metadata.lastLoginAttempt': Timestamp.now(),
        'isOnline': true,
      });

      return {
        'id': partnerId,
        ...partnerData,
      };

    } catch (e) {
      print('❌ Error authenticating delivery partner: $e');
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
      print('❌ Error getting delivery partner: $e');
      return null;
    }
  }

  /// Get all delivery partners
  Stream<List<Map<String, dynamic>>> getAllDeliveryPartners() {
    return _firestore
        .collection('delivery')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Assign order to delivery partner with cleanup of previous assignments
  Future<void> assignOrderToPartner({
    required String orderId,
    required String partnerId,
    required Map<String, dynamic> orderDetails,
  }) async {
    try {
      final batch = _firestore.batch();

      // Get current order to check for previous assignment
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      final previousDeliveryPartner = orderDoc.exists 
          ? (orderDoc.data()!['assignedDeliveryPerson'] ?? orderDoc.data()!['assignedTo'])
          : null;

      // Update order with assignment (using consistent field names)
      batch.update(
        _firestore.collection('orders').doc(orderId),
        {
          'assignedTo': partnerId,
          'assignedDeliveryPerson': partnerId, // Primary field
          'status': 'assigned',
          'assignedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      );

      // Clean up previous delivery partner's records (if reassignment)
      if (previousDeliveryPartner != null && 
          previousDeliveryPartner.toString().isNotEmpty &&
          previousDeliveryPartner != partnerId) {
        
        print('🚚 🧹 Cleaning up previous delivery partner records: $previousDeliveryPartner');
        
        // Remove order from previous partner's currentOrders array
        batch.update(
          _firestore.collection('delivery').doc(previousDeliveryPartner),
          {
            'currentOrders': FieldValue.arrayRemove([orderId]),
            'updatedAt': Timestamp.now(),
          },
        );

        // Delete the assigned_orders subcollection document
        batch.delete(
          _firestore
              .collection('delivery')
              .doc(previousDeliveryPartner)
              .collection('assigned_orders')
              .doc(orderId),
        );
      }

      // Add order to delivery partner's current orders
      batch.update(
        _firestore.collection('delivery').doc(partnerId),
        {
          'currentOrders': FieldValue.arrayUnion([orderId]),
          'updatedAt': Timestamp.now(),
        },
      );

      // Create order assignment record for delivery partner
      batch.set(
        _firestore.collection('delivery').doc(partnerId).collection('assigned_orders').doc(orderId),
        {
          'orderId': orderId,
          'assignedAt': Timestamp.now(),
          'status': 'assigned',
          'orderDetails': orderDetails,
        },
      );

      await batch.commit();

      print('✅ Order $orderId assigned to partner $partnerId with proper cleanup');

    } catch (e) {
      print('❌ Error assigning order to partner: $e');
      rethrow;
    }
  }
}
