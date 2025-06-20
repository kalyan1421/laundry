import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/data/models/address_model.dart'; // Assuming you have an AddressModel
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart'; // For generating unique address IDs

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

  // Add a new address to the user's 'addresses' subcollection
  Future<bool> addAddress(String userId, Map<String, dynamic> addressData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String addressId = const Uuid().v4();
      Map<String, dynamic> dataToSet = {
        ...addressData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_addressesSubcollection)
          .doc(addressId)
          .set(dataToSet);

      await getAddresses(userId);
      
      _isLoading = false;
      return true;
    } catch (e) {
      _error = "Failed to add address: ${e.toString()}";
      print(_error);
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
    // notifyListeners(); // Consider if initial loading notification is desired here

    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_addressesSubcollection)
          .orderBy('createdAt', descending: true) // Optional: order by creation time
          .get();

      _addresses = snapshot.docs
          .map((doc) => AddressModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Failed to fetch addresses: ${e.toString()}";
      print(_error);
      _addresses = []; // Clear addresses on error
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing address in the user's 'addresses' subcollection
  Future<bool> updateAddress(String userId, String addressId, Map<String, dynamic> updatedAddressData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> dataToUpdate = {
        ...updatedAddressData,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      dataToUpdate.remove('id');
      dataToUpdate.remove('createdAt');

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_addressesSubcollection)
          .doc(addressId)
          .update(dataToUpdate);

      await getAddresses(userId);

      _isLoading = false;
      return true;
    } catch (e) {
      _error = "Failed to update address: ${e.toString()}";
      print(_error);
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
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_addressesSubcollection)
          .doc(addressId)
          .delete();

      await getAddresses(userId);

      _isLoading = false;
      return true;
    } catch (e) {
      _error = "Failed to delete address: ${e.toString()}";
      print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
} 