import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates order pickup address, delivery address, and customer's saved address
  /// This ensures that when admin edits an address in order management,
  /// all three addresses (pickup, delivery, and customer's saved address) are updated
  static Future<bool> updateOrderAndCustomerAddress({
    required String orderId,
    required String customerId,
    required String addressId,
    required Map<String, dynamic> updatedAddressData,
  }) async {
    try {
      // Start a batch write to ensure all updates succeed or fail together
      WriteBatch batch = _firestore.batch();

      // Update the order's both pickup and delivery addresses
      DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
      
      // Format the address for display in order
      String formattedAddress = _formatAddressForOrder(updatedAddressData);
      
      // Create the address structure for the order
      Map<String, dynamic> orderAddressUpdate = {
        // Update both pickup and delivery addresses to be the same
        'pickupAddress': formattedAddress,
        'deliveryAddress': formattedAddress,
        'deliveryAddressDetails': {
          'addressId': addressId,
          'details': updatedAddressData,
        },
        // Also update pickup address details to match delivery
        'pickupAddressDetails': {
          'addressId': addressId,
          'details': updatedAddressData,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.update(orderRef, orderAddressUpdate);

      // Update the customer's address in their address collection
      DocumentReference customerAddressRef = _firestore
          .collection('customer')
          .doc(customerId)
          .collection('addresses')
          .doc(addressId);

      Map<String, dynamic> customerAddressUpdate = {
        ...updatedAddressData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.update(customerAddressRef, customerAddressUpdate);

      // Commit the batch
      await batch.commit();

      print('✅ Successfully updated order pickup address, delivery address, and customer address');
      return true;
    } catch (e) {
      print('❌ Error updating addresses: $e');
      return false;
    }
  }

  /// Formats address data for the order's deliveryAddress string field
  static String _formatAddressForOrder(Map<String, dynamic> addressData) {
    List<String> parts = [];
    
    if (addressData['doorNumber']?.toString().isNotEmpty == true) {
      parts.add('Door: ${addressData['doorNumber']}');
    }
    if (addressData['floorNumber']?.toString().isNotEmpty == true) {
      parts.add('Floor: ${addressData['floorNumber']}');
    }
    if (addressData['addressLine1']?.toString().isNotEmpty == true) {
      parts.add(addressData['addressLine1'].toString());
    }
    if (addressData['addressLine2']?.toString().isNotEmpty == true) {
      parts.add(addressData['addressLine2'].toString());
    }
    if (addressData['landmark']?.toString().isNotEmpty == true) {
      parts.add('Near ${addressData['landmark']}');
    }
    if (addressData['city']?.toString().isNotEmpty == true) {
      parts.add(addressData['city'].toString());
    }
    if (addressData['state']?.toString().isNotEmpty == true) {
      parts.add(addressData['state'].toString());
    }
    if (addressData['pincode']?.toString().isNotEmpty == true) {
      parts.add(addressData['pincode'].toString());
    }
    
    return parts.join(', ');
  }

  /// Gets customer address by ID for editing
  static Future<Map<String, dynamic>?> getCustomerAddress({
    required String customerId,
    required String addressId,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('customer')
          .doc(customerId)
          .collection('addresses')
          .doc(addressId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting customer address: $e');
      return null;
    }
  }

  /// Validates address data before updating
  static bool validateAddressData(Map<String, dynamic> addressData) {
    // Check required fields
    if (addressData['addressLine1']?.toString().trim().isEmpty == true) {
      return false;
    }
    if (addressData['city']?.toString().trim().isEmpty == true) {
      return false;
    }
    if (addressData['state']?.toString().trim().isEmpty == true) {
      return false;
    }
    if (addressData['pincode']?.toString().trim().isEmpty == true) {
      return false;
    }
    
    // Validate pincode format (should be 6 digits)
    String? pincode = addressData['pincode']?.toString().trim();
    if (pincode != null && pincode.isNotEmpty) {
      if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
        return false;
      }
    }
    
    return true;
  }
}
