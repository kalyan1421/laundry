import 'package:cloud_firestore/cloud_firestore.dart';

class AddressUtils {
  /// Creates standardized address data map with required fields
  static Map<String, dynamic> createStandardizedAddressData({
    required String doorNumber,
    required String floorNumber,
    required String addressLine1,
    required String landmark,
    required String city,
    required String state,
    required String pincode,
    String? addressLine2,
    String? apartmentName,
    String addressType = 'home',
    double? latitude,
    double? longitude,
    bool isPrimary = false,
    String country = 'India',
  }) {
    return {
      'doorNumber': doorNumber.trim(),
      'floorNumber': floorNumber.trim(),
      'addressLine1': addressLine1.trim(),
      'addressLine2': addressLine2?.trim() ?? '',
      'apartmentName': apartmentName?.trim() ?? '',
      'landmark': landmark.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'country': country,
      'addressType': addressType,
      'type': addressType, // For backward compatibility
      'latitude': latitude,
      'longitude': longitude,
      'isPrimary': isPrimary,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Generates document ID based on phone number and address index
  /// Format: phoneNumber_addressIndex (e.g., "9876543210_1")
  static String generateAddressDocumentId(String phoneNumber, int addressIndex) {
    // Remove +91 prefix if present
    String cleanPhoneNumber = phoneNumber.startsWith('+91') 
        ? phoneNumber.substring(3) 
        : phoneNumber;
    
    // Remove any non-digit characters
    cleanPhoneNumber = cleanPhoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    return '${cleanPhoneNumber}_$addressIndex';
  }

  /// Gets the next address index for a user
  static Future<int> getNextAddressIndex(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customer')
          .doc(userId)
          .collection('addresses')
          .get();
      
      if (snapshot.docs.isEmpty) {
        return 1; // First address
      }
      
      // Count existing addresses to determine next index
      int maxIndex = 0;
      for (var doc in snapshot.docs) {
        // Extract index from document ID (format: phoneNumber_index)
        final parts = doc.id.split('_');
        if (parts.length >= 2) {
          final index = int.tryParse(parts.last) ?? 0;
          if (index > maxIndex) {
            maxIndex = index;
          }
        }
      }
      
      return maxIndex + 1;
    } catch (e) {
      print('Error getting next address index: $e');
      return 1; // Default to 1 if error occurs
    }
  }

  /// Saves address with standardized format and phone number-based document ID
  static Future<String?> saveAddressWithStandardFormat({
    required String userId,
    required String phoneNumber,
    required String doorNumber,
    required String floorNumber,
    required String addressLine1,
    required String landmark,
    required String city,
    required String state,
    required String pincode,
    String? addressLine2,
    String? apartmentName,
    String addressType = 'home',
    double? latitude,
    double? longitude,
    bool isPrimary = false,
    String? customDocumentId, // For updating existing addresses
  }) async {
    try {
      // Create standardized address data
      final addressData = createStandardizedAddressData(
        doorNumber: doorNumber,
        floorNumber: floorNumber,
        addressLine1: addressLine1,
        landmark: landmark,
        city: city,
        state: state,
        pincode: pincode,
        addressLine2: addressLine2,
        apartmentName: apartmentName,
        addressType: addressType,
        latitude: latitude,
        longitude: longitude,
        isPrimary: isPrimary,
      );

      String documentId;
      if (customDocumentId != null) {
        // Use provided document ID (for updates)
        documentId = customDocumentId;
      } else {
        // Generate new document ID based on phone number and index
        final addressIndex = await getNextAddressIndex(userId);
        documentId = generateAddressDocumentId(phoneNumber, addressIndex);
      }

      // Save to Firestore with custom document ID
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(userId)
          .collection('addresses')
          .doc(documentId)
          .set(addressData);

      print('✅ Address saved successfully with ID: $documentId');
      print('📍 Address data: $addressData');

      return documentId;
    } catch (e) {
      print('❌ Error saving address: $e');
      return null;
    }
  }

  /// Updates an existing address with standardized format
  static Future<bool> updateAddressWithStandardFormat({
    required String userId,
    required String documentId,
    required String doorNumber,
    required String floorNumber,
    required String addressLine1,
    required String landmark,
    required String city,
    required String state,
    required String pincode,
    String? addressLine2,
    String? apartmentName,
    String addressType = 'home',
    double? latitude,
    double? longitude,
    bool isPrimary = false,
  }) async {
    try {
      // Create standardized address data (excluding createdAt for updates)
      final addressData = createStandardizedAddressData(
        doorNumber: doorNumber,
        floorNumber: floorNumber,
        addressLine1: addressLine1,
        landmark: landmark,
        city: city,
        state: state,
        pincode: pincode,
        addressLine2: addressLine2,
        apartmentName: apartmentName,
        addressType: addressType,
        latitude: latitude,
        longitude: longitude,
        isPrimary: isPrimary,
      );

      // Remove createdAt for updates
      addressData.remove('createdAt');

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(userId)
          .collection('addresses')
          .doc(documentId)
          .update(addressData);

      print('✅ Address updated successfully with ID: $documentId');
      return true;
    } catch (e) {
      print('❌ Error updating address: $e');
      return false;
    }
  }

  /// Formats address display text from standardized fields
  static String formatAddressDisplay({
    required String doorNumber,
    required String floorNumber,
    required String addressLine1,
    required String landmark,
    required String city,
    required String state,
    required String pincode,
    String? apartmentName,
  }) {
    List<String> parts = [];

    // Add door and floor info
    if (doorNumber.isNotEmpty) {
      parts.add('Door: $doorNumber');
    }
    if (floorNumber.isNotEmpty) {
      parts.add('Floor: $floorNumber');
    }
    if (apartmentName != null && apartmentName.isNotEmpty) {
      parts.add(apartmentName);
    }

    // Add address line
    if (addressLine1.isNotEmpty) {
      parts.add(addressLine1);
    }

    // Add landmark
    if (landmark.isNotEmpty) {
      parts.add('Near $landmark');
    }

    // Add location
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (pincode.isNotEmpty) parts.add(pincode);

    return parts.join(', ');
  }

  /// Extracts phone number from user data
  static String extractPhoneNumber(Map<String, dynamic> userData) {
    String phoneNumber = userData['phoneNumber'] ?? '';
    
    // Remove +91 prefix if present
    if (phoneNumber.startsWith('+91')) {
      phoneNumber = phoneNumber.substring(3);
    }
    
    // Remove any non-digit characters
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    return phoneNumber;
  }
} 