import 'dart:async';
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

  StreamSubscription<QuerySnapshot>? _addressesSubscription;
  String? _currentUserId;

  // Add a new address using standardized format
  Future<bool> addAddress(String userId, String phoneNumber,
      Map<String, dynamic> addressData) async {
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
        latitude:
            addressData['latitude'] is double ? addressData['latitude'] : null,
        longitude: addressData['longitude'] is double
            ? addressData['longitude']
            : null,
        isPrimary: addressData['isPrimary'] ?? false,
      );

      if (documentId != null) {
        print('🏠 ADDRESS PROVIDER: Address saved with ID: $documentId');
        // No need to call getAddresses - the stream will automatically update
        _isLoading = false;
        notifyListeners();
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

  // Start listening to real-time address updates
  void startListeningToAddresses(String userId) {
    if (userId.isEmpty) {
      _addresses = [];
      notifyListeners();
      return;
    }

    // Cancel previous subscription if exists
    _addressesSubscription?.cancel();

    _currentUserId = userId;

    Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    try {
      print(
          '🏠 ADDRESS PROVIDER: Starting real-time listener for user: $userId');

      _addressesSubscription = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_addressesSubcollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (QuerySnapshot snapshot) {
          print(
              '🏠 ADDRESS PROVIDER: Real-time update - Found ${snapshot.docs.length} addresses');

          _addresses = snapshot.docs
              .map((doc) => AddressModel.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          _error = "Failed to listen to addresses: ${error.toString()}";
          print('🏠 ADDRESS PROVIDER: Error listening to addresses: $_error');
          _addresses = [];
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = "Failed to start listening to addresses: ${e.toString()}";
      print('🏠 ADDRESS PROVIDER: Error starting listener: $_error');
      _addresses = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch addresses from the user's 'addresses' subcollection (kept for backward compatibility)
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
          .map((doc) => AddressModel.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
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
  Future<bool> updateAddress(String userId, String addressId,
      Map<String, dynamic> updatedAddressData) async {
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
        latitude: updatedAddressData['latitude'] is double
            ? updatedAddressData['latitude']
            : null,
        longitude: updatedAddressData['longitude'] is double
            ? updatedAddressData['longitude']
            : null,
        isPrimary: updatedAddressData['isPrimary'] ?? false,
      );

      if (success) {
        print('🏠 ADDRESS PROVIDER: Address updated successfully');
        // No need to call getAddresses - the stream will automatically update
        _isLoading = false;
        notifyListeners();
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
      // No need to call getAddresses - the stream will automatically update
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Failed to delete address: ${e.toString()}";
      print('🏠 ADDRESS PROVIDER: Error deleting address: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Stop listening to address updates
  void stopListeningToAddresses() {
    _addressesSubscription?.cancel();
    _addressesSubscription = null;
    _currentUserId = null;
    print('🏠 ADDRESS PROVIDER: Stopped listening to addresses');
  }

  // Clear addresses (useful for logout)
  void clearAddresses() {
    stopListeningToAddresses();
    _addresses = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListeningToAddresses();
    super.dispose();
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
