import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<List<UserModel>> get usersStream {
    return _firestore.collectionGroup('customer').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // A more robust stream that combines users from all relevant collections
  Stream<List<UserModel>> get allUsersStream {
    // Use a simple approach that listens to customer collection primarily
    // and fetches other collections when needed
    return _firestore.collection('customer').snapshots().asyncMap((customerSnapshot) async {
      List<UserModel> allUsers = [];
      
      // Process customer collection
      print('Customer collection docs: ${customerSnapshot.docs.length}');
      for (var doc in customerSnapshot.docs) {
        try {
          UserModel user = UserModel.fromFirestore(doc);
          print('Customer loaded: ${user.name} (${user.email}) - Phone: ${user.phoneNumber}');
          allUsers.add(user);
        } catch (e) {
          print('Error parsing customer document ${doc.id}: $e');
          print('Document data: ${doc.data()}');
        }
      }
      
      // Also fetch delivery and admin users
      try {
        QuerySnapshot deliverySnapshot = await _firestore.collection('delivery').get();
        print('Delivery collection docs: ${deliverySnapshot.docs.length}');
        for (var doc in deliverySnapshot.docs) {
          try {
            UserModel user = UserModel.fromFirestore(doc);
            print('Delivery partner loaded: ${user.name} (${user.email}) - Phone: ${user.phoneNumber}');
            allUsers.add(user);
          } catch (e) {
            print('Error parsing delivery document ${doc.id}: $e');
            print('Document data: ${doc.data()}');
          }
        }
        
        QuerySnapshot adminsSnapshot = await _firestore.collection('admins').get();
        print('Admin collection docs: ${adminsSnapshot.docs.length}');
        for (var doc in adminsSnapshot.docs) {
          try {
            UserModel user = UserModel.fromFirestore(doc);
            print('Admin loaded: ${user.name} (${user.email}) - Phone: ${user.phoneNumber}');
            allUsers.add(user);
          } catch (e) {
            print('Error parsing admin document ${doc.id}: $e');
            print('Document data: ${doc.data()}');
          }
        }
      } catch (e) {
        print('Error fetching additional collections: $e');
      }
      
      print('Total users loaded: ${allUsers.length}');
            return allUsers;
        });
  }

  // Search users by phone number
  Future<List<UserModel>> searchUsersByPhone(String phoneNumber) async {
    List<UserModel> allUsers = [];
    
    try {
      // Search in customer collection
      QuerySnapshot customerSnapshot = await _firestore
          .collection('customer')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();
      
      // Search in delivery collection
      QuerySnapshot deliverySnapshot = await _firestore
          .collection('delivery')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();
      
      // Search in admins collection
      QuerySnapshot adminSnapshot = await _firestore
          .collection('admins')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      // Combine results
      for (var doc in customerSnapshot.docs) {
        allUsers.add(UserModel.fromFirestore(doc));
      }
      for (var doc in deliverySnapshot.docs) {
        allUsers.add(UserModel.fromFirestore(doc));
      }
      for (var doc in adminSnapshot.docs) {
        allUsers.add(UserModel.fromFirestore(doc));
      }
    } catch (e) {
      print('Error searching users by phone: $e');
    }
    
    return allUsers;
  }

  // Search users by email
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    List<UserModel> allUsers = [];
    
    try {
      // Search in customer collection
      QuerySnapshot customerSnapshot = await _firestore
          .collection('customer')
          .where('email', isEqualTo: email)
          .get();
      
      // Search in delivery collection
      QuerySnapshot deliverySnapshot = await _firestore
          .collection('delivery')
          .where('email', isEqualTo: email)
          .get();
      
      // Search in admins collection
      QuerySnapshot adminSnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();

      // Combine results
      for (var doc in customerSnapshot.docs) {
        allUsers.add(UserModel.fromFirestore(doc));
      }
      for (var doc in deliverySnapshot.docs) {
        allUsers.add(UserModel.fromFirestore(doc));
      }
      for (var doc in adminSnapshot.docs) {
        allUsers.add(UserModel.fromFirestore(doc));
      }
    } catch (e) {
      print('Error searching users by email: $e');
    }
    
    return allUsers;
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Try customer collection first
      DocumentSnapshot customerDoc = await _firestore.collection('customer').doc(userId).get();
      if (customerDoc.exists) {
        return UserModel.fromFirestore(customerDoc);
      }
      
      // Try delivery collection
      DocumentSnapshot deliveryDoc = await _firestore.collection('delivery').doc(userId).get();
      if (deliveryDoc.exists) {
        return UserModel.fromFirestore(deliveryDoc);
      }
      
      // Try admins collection
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(userId).get();
      if (adminDoc.exists) {
        return UserModel.fromFirestore(adminDoc);
      }
    } catch (e) {
      print('Error getting user by ID: $e');
    }
    
    return null;
  }

  Future<int> getTotalOrdersForUser(String userId) async {
    final snapshot = await _firestore.collection('orders').where('userId', isEqualTo: userId).get();
    return snapshot.docs.length;
  }

  Future<int> getActiveOrdersForUser(String userId) async {
    final snapshot = await _firestore.collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', whereNotIn: ['completed', 'cancelled']).get();
    return snapshot.docs.length;
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection(user.role == 'customer' ? 'customer' : user.role).doc(user.uid).update(user.toFirestore());
      notifyListeners();
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId, String role) async {
    try {
      await _firestore.collection(role == 'customer' ? 'customer' : role).doc(userId).delete();
      notifyListeners();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // If you add location to UserModel and want to fetch it specifically or format it:
  // String getUserDisplayLocation(UserModel user) { ... }
} 