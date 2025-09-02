import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_creation_service.dart';

/// Service to handle Firebase Auth integration for admin-created customers
/// This service should be called from the customer app when a user logs in
class AuthIntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CustomerCreationService _customerCreationService = CustomerCreationService();

  /// Handles user login and links admin-created customer if exists
  /// This method should be called from the customer app's auth service
  Future<Map<String, dynamic>> handleUserLogin({
    required String phoneNumber,
    required String firebaseUid,
    String? userName,
    String? email,
  }) async {
    try {
      print('🔗 Handling user login for phone: $phoneNumber, UID: $firebaseUid');

      // Check if this is an admin-created customer
      final isAdminCreated = await _customerCreationService.isAdminCreatedCustomer(phoneNumber);
      
      if (isAdminCreated) {
        print('🔗 Found admin-created customer, linking with Firebase Auth...');
        
        // Link the customer with Firebase Auth
        final linkResult = await _customerCreationService.linkCustomerWithAuth(
          phoneNumber: phoneNumber,
          firebaseUid: firebaseUid,
        );

        if (linkResult['success'] == true) {
          print('🔗 ✅ Successfully linked admin-created customer');
          return {
            'success': true,
            'isAdminCreated': true,
            'message': 'Account linked successfully',
            'customerId': firebaseUid,
          };
        } else {
          print('🔗 ❌ Failed to link admin-created customer: ${linkResult['error']}');
          return {
            'success': false,
            'error': 'Failed to link existing account: ${linkResult['error']}',
          };
        }
      } else {
        print('🔗 No admin-created customer found, proceeding with normal auth flow');
        
        // Check if customer already exists with Firebase UID
        final existingCustomer = await _getCustomerByFirebaseUid(firebaseUid);
        
        if (existingCustomer != null) {
          print('🔗 Customer already exists with Firebase UID');
          return {
            'success': true,
            'isAdminCreated': false,
            'isExisting': true,
            'customerId': firebaseUid,
          };
        } else {
          print('🔗 New customer, needs to complete profile');
          return {
            'success': true,
            'isAdminCreated': false,
            'isExisting': false,
            'needsProfileSetup': true,
            'customerId': firebaseUid,
          };
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error handling user login: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Gets customer by Firebase UID
  Future<Map<String, dynamic>?> _getCustomerByFirebaseUid(String firebaseUid) async {
    try {
      final customerDoc = await _firestore.collection('customer').doc(firebaseUid).get();
      
      if (customerDoc.exists) {
        final data = customerDoc.data()!;
        data['id'] = customerDoc.id;
        return data;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting customer by Firebase UID: $e');
      return null;
    }
  }

  /// Creates a new customer document for Firebase Auth user
  /// This is used when a user logs in for the first time (not admin-created)
  Future<Map<String, dynamic>> createFirebaseAuthCustomer({
    required String firebaseUid,
    required String phoneNumber,
    String? name,
    String? email,
  }) async {
    try {
      print('🔧 Creating new Firebase Auth customer...');
      
      final clientId = phoneNumber.replaceAll('+91', '');
      
      // Generate QR code for the new customer
      String? qrCodeUrl;
      try {
        final customerCreationService = CustomerCreationService();
        qrCodeUrl = await customerCreationService.generateQRCode(firebaseUid, clientId);
        print('🔧 QR code generated for new customer: $qrCodeUrl');
      } catch (e) {
        print('⚠️ QR code generation failed for new customer: $e');
        // Continue without QR code - not critical
      }

      // Prepare customer document data
      final customerData = {
        'uid': firebaseUid,
        'name': name ?? '',
        'email': email ?? '',
        'phoneNumber': phoneNumber,
        'role': 'customer',
        'isProfileComplete': name != null && name.isNotEmpty,
        'isAdminCreated': false,
        'authLinked': true,
        'clientId': clientId,
        'qrCodeUrl': qrCodeUrl,
        'profileImageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'self_registration',
      };

      // Create customer document
      await _firestore.collection('customer').doc(firebaseUid).set(customerData);
      print('🔧 New Firebase Auth customer created');

      return {
        'success': true,
        'customerId': firebaseUid,
        'qrCodeUrl': qrCodeUrl,
      };

    } catch (e, stackTrace) {
      print('❌ Error creating Firebase Auth customer: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Updates customer profile information
  Future<Map<String, dynamic>> updateCustomerProfile({
    required String customerId,
    String? name,
    String? email,
    String? profileImageUrl,
  }) async {
    try {
      print('🔧 Updating customer profile for ID: $customerId');
      
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updateData['name'] = name;
      }
      
      if (email != null) {
        updateData['email'] = email;
      }
      
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      // Mark profile as complete if name is provided
      if (name != null && name.isNotEmpty) {
        updateData['isProfileComplete'] = true;
      }

      await _firestore.collection('customer').doc(customerId).update(updateData);
      print('🔧 Customer profile updated successfully');

      return {
        'success': true,
        'message': 'Profile updated successfully',
      };

    } catch (e, stackTrace) {
      print('❌ Error updating customer profile: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Updates customer's last sign in time
  Future<void> updateLastSignIn(String customerId) async {
    try {
      await _firestore.collection('customer').doc(customerId).update({
        'lastSignIn': FieldValue.serverTimestamp(),
      });
      print('🔧 Updated last sign in for customer: $customerId');
    } catch (e) {
      print('❌ Error updating last sign in: $e');
      // Don't throw error as this is not critical
    }
  }

  /// Checks if a customer exists by phone number
  Future<bool> customerExistsByPhone(String phoneNumber) async {
    try {
      // Check in both admin-created and Firebase Auth customers
      final querySnapshot = await _firestore
          .collection('customer')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking customer existence: $e');
      return false;
    }
  }

  /// Gets customer data by ID
  Future<Map<String, dynamic>?> getCustomerById(String customerId) async {
    try {
      final customerDoc = await _firestore.collection('customer').doc(customerId).get();
      
      if (customerDoc.exists) {
        final data = customerDoc.data()!;
        data['id'] = customerDoc.id;
        return data;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting customer by ID: $e');
      return null;
    }
  }
}
