// services/admin_management_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminModel {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final bool isActive;
  final List<String> permissions;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? createdBy;
  final String? profileImageUrl;

  AdminModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.role = 'admin',
    this.isActive = true,
    this.permissions = const ['all'],
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.profileImageUrl,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AdminModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] ?? 'admin',
      isActive: data['isActive'] ?? true,
      permissions: List<String>.from(data['permissions'] ?? ['all']),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'isActive': isActive,
      'permissions': permissions,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'profileImageUrl': profileImageUrl,
    };
  }
}

class AdminManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all admins
  Stream<List<AdminModel>> getAdmins() {
    return _firestore
        .collection('admins')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminModel.fromFirestore(doc))
            .toList());
  }

  // Get single admin
  Future<AdminModel?> getAdmin(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('admins')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return AdminModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching admin $uid: $e');
      return null;
    }
  }

  // Create new admin (by existing admin)
  Future<AdminModel?> createAdmin({
    required String name,
    required String email,
    required String phoneNumber,
    List<String>? permissions,
    String? profileImageUrl,
  }) async {
    try {
      // Check if current user is admin
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Verify current user is admin
      DocumentSnapshot currentUserDoc = await _firestore
          .collection('admins')
          .doc(currentUserId)
          .get();
      
      if (!currentUserDoc.exists) {
        throw Exception('Only admins can create new admins');
      }

      // Check if email or phone already exists
      QuerySnapshot emailCheck = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (emailCheck.docs.isNotEmpty) {
        throw Exception('An admin with this email already exists');
      }

      QuerySnapshot phoneCheck = await _firestore
          .collection('admins')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (phoneCheck.docs.isNotEmpty) {
        throw Exception('An admin with this phone number already exists');
      }

      // Generate a unique ID for the admin
      String uid = _firestore.collection('admins').doc().id;
      
      Timestamp now = Timestamp.now();
      AdminModel newAdmin = AdminModel(
        uid: uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber',
        isActive: true,
        permissions: permissions ?? ['all'],
        createdAt: now,
        updatedAt: now,
        createdBy: currentUserId,
        profileImageUrl: profileImageUrl,
      );

      // Save to Firestore
      await _firestore
          .collection('admins')
          .doc(uid)
          .set(newAdmin.toFirestore());
      
      return newAdmin;
    } catch (e) {
      print('Error creating admin: $e');
      throw Exception('Failed to create admin: $e');
    }
  }

  // Update admin
  Future<void> updateAdmin(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore
          .collection('admins')
          .doc(uid)
          .update(updates);
    } catch (e) {
      print('Error updating admin $uid: $e');
      throw Exception('Failed to update admin');
    }
  }

  // Toggle admin active status
  Future<void> toggleAdminStatus(String uid, bool isActive) async {
    // Prevent deactivating self
    if (uid == _auth.currentUser?.uid && !isActive) {
      throw Exception('You cannot deactivate your own account');
    }
    
    await updateAdmin(uid, {'isActive': isActive});
  }

  // Delete admin (soft delete - deactivate)
  Future<void> deleteAdmin(String uid) async {
    // Prevent deleting self
    if (uid == _auth.currentUser?.uid) {
      throw Exception('You cannot delete your own account');
    }
    
    await updateAdmin(uid, {
      'isActive': false,
      'deletedAt': Timestamp.now(),
    });
  }

  // Update admin permissions
  Future<void> updateAdminPermissions(String uid, List<String> permissions) async {
    await updateAdmin(uid, {'permissions': permissions});
  }

  // Check if phone number is available for new admin
  Future<bool> isPhoneNumberAvailable(String phoneNumber) async {
    try {
      String formattedPhone = phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';
      
      // Check in admins
      QuerySnapshot adminCheck = await _firestore
          .collection('admins')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();
      
      // Check in delivery partners
      QuerySnapshot deliveryCheck = await _firestore
          .collection('delivery')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();
      
      return adminCheck.docs.isEmpty && deliveryCheck.docs.isEmpty;
    } catch (e) {
      print('Error checking phone availability: $e');
      return false;
    }
  }

  // Check if email is available for new admin
  Future<bool> isEmailAvailable(String email) async {
    try {
      // Check in admins
      QuerySnapshot adminCheck = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      // Check in delivery partners
      QuerySnapshot deliveryCheck = await _firestore
          .collection('delivery')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return adminCheck.docs.isEmpty && deliveryCheck.docs.isEmpty;
    } catch (e) {
      print('Error checking email availability: $e');
      return false;
    }
  }
}