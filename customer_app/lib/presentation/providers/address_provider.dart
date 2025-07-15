import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/data/models/address_model.dart';
import 'package:customer_app/core/utils/address_utils.dart';
import 'package:flutter/foundation.dart';

class AddressProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'customer';
  final String _addressesSubcollection = 'addresses';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<AddressModel> _addresses = [];
  List<AddressModel> get addresses => _addresses;

  // Add a new address using standardized format
  Future<bool> addAddress(String userId, String phoneNumber, Map<String, dynamic> addressData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🏠 ADDRESS PROVIDER: Adding address with standardized format');
      print('🏠 ADDRESS PROVIDER: User ID: $userId');
      print('🏠 ADDRESS PROVIDER: Phone Number: $phoneNumber');
      
      // Use AddressUtils to save with standardized format
      final documentId = await AddressUtils.saveAddressWithStandardFormat(
        userId: userId,
        phoneNumber: phoneNumber,
        doorNumber: addressData['doorNumber'] ?? '',
        floorNumber: addressData['floorNumber'] ?? '',
        addressLine1: addressData['addressLine1'] ?? '',
        landmark: addressData['landmark'] ?? '',
        city: addressData['city'] ?? '',
        state: addressData['state'] ?? '',
        pincode: addressData['pincode'] ?? '',
        addressLine2: addressData['addressLine2'],
        apartmentName: addressData['apartmentName'],
        addressType: addressData['addressType'] ?? 'home',
        latitude: addressData['latitude'] is double ? addressData['latitude'] : null,
        longitude: addressData['longitude'] is double ? addressData['longitude'] : null,
        isPrimary: addressData['isPrimary'] ?? false,
      );

      if (documentId != null) {
        print('🏠 ADDRESS PROVIDER: Address saved with ID: $documentId');
        await getAddresses(userId);
        _isLoading = false;
        return true;
      } else {
        throw Exception('Failed to save address');
      }
    } catch (e) {
      _error = "Failed to add address: ${e.toString()}";
      print('🏠 ADDRESS PROVIDER: Error adding address: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch addresses from the user's 'addresses' subcollection
  Future<void> getAddresses(String userId) async {
    if (userId.isEmpty) {
      _addresses = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;

    try {
      print('🏠 ADDRESS PROVIDER: Fetching addresses for user: $userId');
      QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_addressesSubcollection)
          .orderBy('createdAt', descending: true)
          .get();

      print('🏠 ADDRESS PROVIDER: Found ${snapshot.docs.length} addresses');
      
      _addresses = snapshot.docs
          .map((doc) => AddressModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Failed to fetch addresses: ${e.toString()}";
      print('🏠 ADDRESS PROVIDER: Error fetching addresses: $_error');
      _addresses = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing address using standardized format
  Future<bool> updateAddress(String userId, String addressId, Map<String, dynamic> updatedAddressData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🏠 ADDRESS PROVIDER: Updating address with ID: $addressId');
      
      // Use AddressUtils to update with standardized format
      final success = await AddressUtils.updateAddressWithStandardFormat(
        userId: userId,
        documentId: addressId,
        doorNumber: updatedAddressData['doorNumber'] ?? '',
        floorNumber: updatedAddressData['floorNumber'] ?? '',
        addressLine1: updatedAddressData['addressLine1'] ?? '',
        landmark: updatedAddressData['landmark'] ?? '',
        city: updatedAddressData['city'] ?? '',
        state: updatedAddressData['state'] ?? '',
        pincode: updatedAddressData['pincode'] ?? '',
        addressLine2: updatedAddressData['addressLine2'],
        apartmentName: updatedAddressData['apartmentName'],
        addressType: updatedAddressData['addressType'] ?? 'home',
        latitude: updatedAddressData['latitude'] is double ? updatedAddressData['latitude'] : null,
        longitude: updatedAddressData['longitude'] is double ? updatedAddressData['longitude'] : null,
        isPrimary: updatedAddressData['isPrimary'] ?? false,
      );

      if (success) {
        print('🏠 ADDRESS PROVIDER: Address updated successfully');
        await getAddresses(userId);
        _isLoading = false;
        return true;
      } else {
        throw Exception('Failed to update address');
      }
    } catch (e) {
      _error = "Failed to update address: ${e.toString()}";
      print('🏠 ADDRESS PROVIDER: Error updating address: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete an address from the user's 'addresses' subcollection
  Future<bool> deleteAddress(String userId, String addressId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🏠 ADDRESS PROVIDER: Deleting address with ID: $addressId');
      
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_addressesSubcollection)
          .doc(addressId)
          .delete();

      print('🏠 ADDRESS PROVIDER: Address deleted successfully');
      await getAddresses(userId);

      _isLoading = false;
      return true;
    } catch (e) {
      _error = "Failed to delete address: ${e.toString()}";
      print('🏠 ADDRESS PROVIDER: Error deleting address: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear addresses (useful for logout)
  void clearAddresses() {
    _addresses = [];
    _error = null;
    notifyListeners();
  }

  // Get primary address
  AddressModel? getPrimaryAddress() {
    try {
      return _addresses.firstWhere((address) => address.isPrimary);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }
} 