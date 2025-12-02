// services/delivery_partner_service.dart - No Firebase Auth operations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';
import '../models/delivery_partner_model.dart';

class DeliveryPartnerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Toggle delivery person active status
  Future<bool> toggleDeliveryPartnerStatus(String id, bool isActive) async {
    try {
      await _firestore.collection('delivery').doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error toggling delivery person status: $e');
      return false;
    }
  }

  // Delete delivery person (soft delete)
  Future<bool> deleteDeliveryPartner(String id) async {
    try {
      await _firestore.collection('delivery').doc(id).update({
        'isActive': false,
        'isDeleted': true,
        'deletedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error deleting delivery person: $e');
      return false;
    }
  }

  // Get delivery person statistics
  Future<Map<String, dynamic>> getDeliveryPartnerStats() async {
    try {
      final snapshot = await _firestore
          .collection('delivery')
          .where('isDeleted', isNotEqualTo: true)
          .get();

      int total = snapshot.docs.length;
      int active = snapshot.docs.where((doc) => doc.data()['isActive'] == true).length;
      int online = snapshot.docs.where((doc) => doc.data()['isOnline'] == true).length;
      int available = snapshot.docs.where((doc) => 
        doc.data()['isActive'] == true && 
        doc.data()['isAvailable'] == true
      ).length;

      return {
        'total': total,
        'active': active,
        'inactive': total - active,
        'online': online,
        'available': available,
      };
    } catch (e) {
      print('Error getting delivery person stats: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'online': 0,
        'available': 0,
      };
    }
  }

  // Create delivery person by admin WITHOUT any Firebase Auth operations
  Future<DeliveryPartnerModel?> createDeliveryPartnerByAdmin({
    required String name,
    required String email,
    required String phoneNumber,
    required String licenseNumber,
    String? createdByUid,
  }) async {
    try {
      // Format phone number
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      
      // Generate a unique ID for the delivery person
      String deliveryPartnerId = _firestore.collection('delivery').doc().id;
      
      // Generate a secure registration token
      final random = Random.secure();
      var values = List<int>.generate(4, (i) => random.nextInt(255));
      String registrationToken = base64UrlEncode(values).substring(0, 6).toUpperCase();
      
      // Create delivery person data
      final deliveryPartnerData = {
        'id': deliveryPartnerId,
        'uid': deliveryPartnerId, // Will be updated when they first login
        'name': name,
        'email': email.toLowerCase(),
        'phoneNumber': formattedPhone,
        'licenseNumber': licenseNumber.toUpperCase(),
        'role': 'delivery',
        'isActive': true,
        'isAvailable': true,
        'isOnline': false,
        'isRegistered': false, // Will be set to true on first login
        'registrationToken': registrationToken,
        'rating': 0.0,
        'totalDeliveries': 0,
        'completedDeliveries': 0,
        'cancelledDeliveries': 0,
        'earnings': 0.0,
        'currentOrders': [],
        'orderHistory': [],
        'vehicleInfo': {},
        'documents': {
          'license': {
            'number': licenseNumber.toUpperCase(),
            'verified': false,
          }
        },
        'bankDetails': {},
        'address': {},
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'createdBy': createdByUid ?? 'admin',
        'createdByRole': 'admin',
      };

      // Save to Firestore
      await _firestore.collection('delivery').doc(deliveryPartnerId).set(deliveryPartnerData);
      
      print('✅ Delivery person created successfully with ID: $deliveryPartnerId');
      
      // Return the created delivery person
      return DeliveryPartnerModel.fromMap(deliveryPartnerData);
      
    } catch (e) {
      print('❌ Error creating delivery person: $e');
      throw Exception('Failed to create delivery person: ${e.toString()}');
    }
  }

  // Check if phone number is available
  Future<bool> isPhoneNumberAvailable(String phoneNumber) async {
    try {
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      
      // Check in delivery collection
      final deliveryQuery = await _firestore
          .collection('delivery')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();
          
      // Also check in delivery collection for legacy data
      final personnelQuery = await _firestore
          .collection('delivery')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();
      
      return deliveryQuery.docs.isEmpty && personnelQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking phone availability: $e');
      // Return false to prevent duplicate creation on error
      return false;
    }
  }

  // Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      String lowerEmail = email.toLowerCase();
      
      // Check in delivery collection
      final deliveryQuery = await _firestore
          .collection('delivery')
          .where('email', isEqualTo: lowerEmail)
          .limit(1)
          .get();
          
      // Also check in delivery collection for legacy data
      final personnelQuery = await _firestore
          .collection('delivery')
          .where('email', isEqualTo: lowerEmail)
          .limit(1)
          .get();
      
      return deliveryQuery.docs.isEmpty && personnelQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking email availability: $e');
      // Return false to prevent duplicate creation on error
      return false;
    }
  }

  // Check if license number is available
  Future<bool> isLicenseNumberAvailable(String licenseNumber) async {
    try {
      String upperLicense = licenseNumber.toUpperCase();
      
      // Check in delivery collection
      final deliveryQuery = await _firestore
          .collection('delivery')
          .where('licenseNumber', isEqualTo: upperLicense)
          .limit(1)
          .get();
      
      // Also check in documents.license.number field
      final docsQuery = await _firestore
          .collection('delivery')
          .where('documents.license.number', isEqualTo: upperLicense)
          .limit(1)
          .get();
          
      // Check in delivery collection for legacy data
      final personnelQuery = await _firestore
          .collection('delivery')
          .where('licenseNumber', isEqualTo: upperLicense)
          .limit(1)
          .get();
      
      return deliveryQuery.docs.isEmpty && docsQuery.docs.isEmpty && personnelQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking license availability: $e');
      // Return false to prevent duplicate creation on error
      return false;
    }
  }

  // Get all delivery persons
  Stream<List<DeliveryPartnerModel>> getDeliveryPartners() {
    return _firestore
        .collection('delivery')
        .where('isDeleted', isNotEqualTo: true)
        .orderBy('isDeleted')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeliveryPartnerModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((error) {
      print('Error in delivery persons stream: $error');
      return <DeliveryPartnerModel>[];
    });
  }

  // Get active delivery persons
  Stream<List<DeliveryPartnerModel>> getActiveDeliveryPartners() {
    return _firestore
        .collection('delivery')
        .where('isActive', isEqualTo: true)
        .where('isDeleted', isNotEqualTo: true)
        .orderBy('isDeleted')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeliveryPartnerModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((error) {
      print('Error in active delivery persons stream: $error');
      return <DeliveryPartnerModel>[];
    });
  }

  // Get delivery person by ID
  Future<DeliveryPartnerModel?> getDeliveryPartnerById(String id) async {
    try {
      final doc = await _firestore.collection('delivery').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return DeliveryPartnerModel.fromMap({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting delivery person: $e');
      return null;
    }
  }

  // Update delivery person
  Future<bool> updateDeliveryPartner(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('delivery').doc(id).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error updating delivery person: $e');
      return false;
    }
  }

  /// Respond to an order offer using a Firestore transaction
  /// This prevents race conditions when multiple drivers respond simultaneously
  Future<void> respondToOrderOffer({
    required String driverId,
    required String orderId,
    required bool accepted,
    String? driverName,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final driverRef = _firestore.collection('delivery').doc(driverId);

    return _firestore.runTransaction((transaction) async {
      // Read both documents atomically
      final orderSnapshot = await transaction.get(orderRef);
      final driverSnapshot = await transaction.get(driverRef);

      if (!orderSnapshot.exists) {
        throw Exception('Order no longer exists');
      }

      final orderData = orderSnapshot.data() as Map<String, dynamic>;
      final offeredDriver = orderData['currentOfferedDriver'];

      // Verify the offer is still valid for THIS driver
      if (offeredDriver == null || offeredDriver['id'] != driverId) {
        throw Exception('Offer expired or assigned to another driver');
      }

      // Get driver name from snapshot if not provided
      String deliveryPersonName = driverName ?? 'Driver';
      if (driverSnapshot.exists) {
        final driverData = driverSnapshot.data() as Map<String, dynamic>;
        deliveryPersonName = driverData['name'] ?? deliveryPersonName;
      }

      if (accepted) {
        // ACCEPT FLOW: Assign order to this driver
        transaction.update(orderRef, {
          'status': 'confirmed',
          'assignmentStatus': 'assigned',
          'assignedDeliveryPerson': driverId,
          'assignedDeliveryPersonName': deliveryPersonName,
          'currentOfferedDriver': FieldValue.delete(),
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'statusHistory': FieldValue.arrayUnion([
            {
              'status': 'confirmed',
              'timestamp': Timestamp.now(),
              'title': 'Order Confirmed',
              'description': 'Delivery partner $deliveryPersonName has accepted the order',
            }
          ]),
        });

        transaction.update(driverRef, {
          'currentOrders': FieldValue.arrayUnion([orderId]),
          'isAvailable': false, // Mark driver as busy
          'currentOffer': FieldValue.delete(),
          'lastOrderAcceptedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Order $orderId accepted by driver $driverId');
      } else {
        // REJECT FLOW: Mark rejected and trigger search for next driver
        transaction.update(orderRef, {
          'assignmentStatus': 'searching', // Cloud Function will find next driver
          'rejectedByDrivers': FieldValue.arrayUnion([driverId]),
          'currentOfferedDriver': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(driverRef, {
          'currentOffer': FieldValue.delete(),
        });

        print('❌ Order $orderId rejected by driver $driverId');
      }
    });
  }
}
