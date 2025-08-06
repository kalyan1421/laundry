// services/delivery_partner_service.dart - No Firebase Auth operations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

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
  Future<Map<String, int>> getDeliveryPartnerStats() async {
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
        'offline': active - online,
        'online': online,
      };
    } catch (e) {
      print('Error getting delivery person stats: $e');
      return {
        'total': 0,
        'active': 0,
        'offline': 0,
        'online': 0,
      };
    }
  }

  // Create delivery person by admin with proper authentication setup
  Future<DeliveryPartnerModel?> createDeliveryPartnerByAdmin({
    required String name,
    required String email,
    required String phoneNumber,
    required String licenseNumber,
    String? createdByUid,
  }) async {
    try {
      // Format phone number consistently
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      
      // Generate a unique ID for the delivery person
      String deliveryPartnerId = _firestore.collection('delivery').doc().id;
      
      // Generate a simple 4-digit login code
      final random = Random.secure();
      String loginCode = (1000 + random.nextInt(9000)).toString();
      
      // Create delivery person data with authentication setup
      final deliveryPartnerData = {
        'id': deliveryPartnerId,
        'uid': null, // Will be set when they first login and verify phone
        'name': name,
        'email': email.toLowerCase(),
        'phoneNumber': formattedPhone,
        'licenseNumber': licenseNumber.toUpperCase(),
        'role': 'delivery',
        'isActive': true,
        'isAvailable': true,
        'isOnline': false,
        'isRegistered': false, // Will be set to true on first login
        'authenticationStatus': 'pending_verification', // New field to track auth status
        'canLogin': true, // Allow login attempts
        'firstLoginRequired': true, // Indicates first-time login needed
        'loginCode': loginCode,
        'registrationToken': loginCode, // Keep for backward compatibility
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
        // Add metadata for tracking
        'metadata': {
          'createdByAdmin': true,
          'needsPhoneVerification': true,
          'loginAttempts': 0,
          'lastLoginAttempt': null,
        }
      };

      // Save to Firestore with the phone number as a searchable field
      await _firestore.collection('delivery').doc(deliveryPartnerId).set(deliveryPartnerData);
      
      // Also create an index entry for quick phone lookup during login
      await _firestore.collection('delivery_phone_index').doc(formattedPhone.replaceAll('+', '')).set({
        'phoneNumber': formattedPhone,
        'deliveryPartnerId': deliveryPartnerId,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'createdBy': createdByUid ?? 'admin',
      });
      
      print('✅ Delivery person created successfully with ID: $deliveryPartnerId');
      print('📱 Phone indexed for login: $formattedPhone');
      
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
      
      // Check phone index first for faster lookup
      String phoneKey = formattedPhone.replaceAll('+', '');
      final indexDoc = await _firestore
          .collection('delivery_phone_index')
          .doc(phoneKey)
          .get();
      
      if (indexDoc.exists && indexDoc.data()?['isActive'] == true) {
        print('Phone number $formattedPhone already exists in index');
        return false;
      }
      
      // Check in delivery collection for backward compatibility
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

  // Update delivery partner online status
  Future<void> updateOnlineStatus(String deliveryPartnerId, bool isOnline) async {
    try {
      await _firestore.collection('delivery').doc(deliveryPartnerId).update({
        'isOnline': isOnline,
        'lastStatusUpdate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      print('✅ Updated online status for $deliveryPartnerId: $isOnline');
    } catch (e) {
      print('❌ Error updating online status: $e');
      throw Exception('Failed to update online status');
    }
  }

  // Get all delivery partners with real-time updates
  Stream<List<DeliveryPartnerModel>> getAllDeliveryPartners() {
    return _firestore
        .collection('delivery')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryPartnerModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get only online delivery partners
  Stream<List<DeliveryPartnerModel>> getOnlineDeliveryPartners() {
    return _firestore
        .collection('delivery')
        .where('isOnline', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryPartnerModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Toggle delivery partner active status
  Future<void> toggleActiveStatus(String deliveryPartnerId, bool isActive) async {
    try {
      await _firestore.collection('delivery').doc(deliveryPartnerId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      print('✅ Updated active status for $deliveryPartnerId: $isActive');
    } catch (e) {
      print('❌ Error updating active status: $e');
      throw Exception('Failed to update active status');
    }
  }



  // Generate new login code for delivery partner
  Future<void> generateNewLoginCode(String deliveryPartnerId) async {
    try {
      final random = Random.secure();
      String newLoginCode = (1000 + random.nextInt(9000)).toString();
      
      await _firestore.collection('delivery').doc(deliveryPartnerId).update({
        'loginCode': newLoginCode,
        'registrationToken': newLoginCode, // Keep for backward compatibility
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ Generated new login code for $deliveryPartnerId: $newLoginCode');
    } catch (e) {
      print('❌ Error generating new login code: $e');
      throw Exception('Failed to generate new login code');
    }
  }

  // Migration function to create phone index for existing delivery partners
  Future<void> migrateExistingDeliveryPartnersToPhoneIndex() async {
    try {
      print('🔄 Starting migration of existing delivery partners to phone index...');
      
      // Get all active delivery partners
      final QuerySnapshot deliverySnapshot = await _firestore
          .collection('delivery')
          .where('isActive', isEqualTo: true)
          .get();
      
      int migrated = 0;
      int skipped = 0;
      
      for (var doc in deliverySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final phoneNumber = data['phoneNumber'] as String?;
          
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            String phoneKey = phoneNumber.replaceAll('+', '');
            
            // Check if phone index already exists
            final indexDoc = await _firestore
                .collection('delivery_phone_index')
                .doc(phoneKey)
                .get();
            
            if (!indexDoc.exists) {
              // Create phone index entry
              await _firestore.collection('delivery_phone_index').doc(phoneKey).set({
                'phoneNumber': phoneNumber,
                'deliveryPartnerId': doc.id,
                'isActive': true,
                'createdAt': Timestamp.now(),
                'createdBy': 'migration',
                'migratedAt': Timestamp.now(),
              });
              
              print('✅ Migrated delivery partner ${doc.id} with phone $phoneNumber');
              migrated++;
            } else {
              print('⏭️ Phone index already exists for ${doc.id}');
              skipped++;
            }
          } else {
            print('⚠️ Delivery partner ${doc.id} has no phone number');
            skipped++;
          }
        } catch (e) {
          print('❌ Error migrating delivery partner ${doc.id}: $e');
          skipped++;
        }
      }
      
      print('🎉 Migration completed: $migrated migrated, $skipped skipped');
      
    } catch (e) {
      print('❌ Error during migration: $e');
      throw Exception('Migration failed: ${e.toString()}');
    }
  }
}