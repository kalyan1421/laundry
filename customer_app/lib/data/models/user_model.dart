// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? clientId;
  final String phoneNumber;
  final String name;
  final String email;
  final String? profileImageUrl;
  final List<Address> addresses;
  final bool isProfileComplete;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp? lastSignIn;
  final String role;
  final String? qrCodeUrl;
  final int orderCount;

  UserModel({
    required this.uid,
    this.clientId,
    required this.phoneNumber,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.addresses,
    required this.isProfileComplete,
    required this.createdAt,
    required this.updatedAt,
    this.lastSignIn,
    required this.role,
    this.qrCodeUrl,
    this.orderCount = 0,
  });

  // Create UserModel from Firestore document, now taking addresses and orderCount separately
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<Address> addresses = const [], // Accept fetched addresses
    int orderCount = 0, // Accept fetched order count
  }) {
    final data = doc.data();
    if (data == null) throw Exception("User data not found in snapshot!");

    return UserModel(
      uid: doc.id,
      clientId: data['clientId'] as String?,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String?,
      addresses: addresses, // Use passed addresses
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] : Timestamp.now(),
      lastSignIn: data['lastSignIn'] as Timestamp?,
      role: data['role'] as String? ?? 'customer',
      qrCodeUrl: data['qrCodeUrl'] as String?,
      orderCount: orderCount, // Use passed order count
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      if (clientId != null) 'clientId': clientId,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (lastSignIn != null) 'lastSignIn': lastSignIn,
      'role': role,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    List<Address>? addresses,
    bool? isProfileComplete,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? lastSignIn,
    String? role,
    String? qrCodeUrl,
    int? orderCount,
  }) {
    return UserModel(
      uid: uid,
      clientId: clientId,
      phoneNumber: phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      addresses: addresses ?? this.addresses,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      role: role ?? this.role,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      orderCount: orderCount ?? this.orderCount,
    );
  }

  // Get display name
  String get displayName {
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email.split('@').first;
    return phoneNumber.replaceAll('+91', '');
  }

  // Get formatted phone number
  String get formattedPhoneNumber {
    if (phoneNumber.startsWith('+91')) {
      String number = phoneNumber.substring(3);
      if (number.length == 10) {
        return '+91 ${number.substring(0, 5)} ${number.substring(5)}';
      }
    }
    return phoneNumber;
  }

  // Check if profile has basic info
  bool get hasBasicInfo {
    return name.isNotEmpty;
  }

  // Get primary address
  Address? get primaryAddress {
    if (addresses.isEmpty) return null;
    
    // Find marked primary address
    for (Address address in addresses) {
      if (address.isPrimary) return address;
    }
    
    // Return first address if no primary found
    return addresses.first;
  }

  // Method to convert UserModel instance to a JSON map for logging or other uses
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'clientId': clientId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'isProfileComplete': isProfileComplete,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastSignIn': lastSignIn,
      'qrCodeUrl': qrCodeUrl,
      'orderCount': orderCount,
    };
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, phoneNumber: $phoneNumber, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

// Address model
class Address {
  final String id;
  final String type; // home, work, other
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String landmark;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Address({
    required this.id,
    required this.type,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.landmark,
    this.latitude,
    this.longitude,
    required this.isPrimary,
    this.createdAt,
    this.updatedAt,
  });

  // Create Address from Map
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      type: map['type'] ?? 'home',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      landmark: map['landmark'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      isPrimary: map['isPrimary'] ?? false,
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] : null,
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : null,
    );
  }

  // Convert Address to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'isPrimary': isPrimary,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  // Get full address string
  String get fullAddress {
    List<String> parts = [];
    
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2.isNotEmpty) parts.add(addressLine2);
    if (landmark.isNotEmpty) parts.add('Near $landmark');
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (pincode.isNotEmpty) parts.add(pincode);
    
    return parts.join(', ');
  }

  // Get short address (first line + city)
  String get shortAddress {
    List<String> parts = [];
    
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (city.isNotEmpty) parts.add(city);
    
    return parts.join(', ');
  }

  // Get address type display name
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'home':
        return 'Home';
      case 'work':
        return 'Work';
      case 'other':
        return 'Other';
      default:
        return type.substring(0, 1).toUpperCase() + type.substring(1);
    }
  }

  @override
  String toString() {
    return 'Address(id: $id, type: $type, address: $shortAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}