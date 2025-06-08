// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? clientId;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final bool? isProfileComplete;
  final String? profileImageUrl;
  final String? qrCodeUrl;
  final Timestamp? createdAt;
  final Timestamp? lastSignIn;
  final Timestamp? updatedAt;

  UserModel({
    required this.uid,
    this.clientId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.isProfileComplete,
    this.profileImageUrl,
    this.qrCodeUrl,
    this.createdAt,
    this.lastSignIn,
    this.updatedAt,
  });

  UserModel copyWith({
    String? uid,
    String? clientId,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    bool? isProfileComplete,
    String? profileImageUrl,
    String? qrCodeUrl,
    Timestamp? createdAt,
    Timestamp? lastSignIn,
    Timestamp? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("User document data is null for doc ID: ${doc.id}");
    }
    return UserModel(
      uid: doc.id,
      clientId: data['clientId'] as String?,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      role: data['role'] as String? ?? 'customer',
      isProfileComplete: data['isProfileComplete'] as bool?,
      profileImageUrl: data['profileImageUrl'] as String?,
      qrCodeUrl: data['qrCodeUrl'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      lastSignIn: data['lastSignIn'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'clientId': clientId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'isProfileComplete': isProfileComplete,
      'profileImageUrl': profileImageUrl,
      'qrCodeUrl': qrCodeUrl,
      'createdAt': createdAt,
      'lastSignIn': lastSignIn,
      'updatedAt': updatedAt,
    };
  }
}
