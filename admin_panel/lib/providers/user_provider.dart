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
    Stream<QuerySnapshot> users = _firestore.collection('customer').snapshots();
    Stream<QuerySnapshot> delivery = _firestore.collection('delivery').snapshots();
    Stream<QuerySnapshot> admins = _firestore.collection('admins').snapshots();

    return Stream<List<QuerySnapshot>>.periodic(const Duration(milliseconds: 50), (count) => [])
        .asyncMap((_) async {
            final results = await Future.wait([
                users.first,
                delivery.first,
                admins.first,
            ]);
            return results;
        }).map((snapshots) {
            List<UserModel> allUsers = [];
            for (var snapshot in snapshots) {
                for (var doc in snapshot.docs) {
                    allUsers.add(UserModel.fromFirestore(doc));
                }
            }
            return allUsers;
        });
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