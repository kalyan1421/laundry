// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final String name;
  final String email;
  final String profileImageUrl;
  final List<Address> addresses;
  final bool isProfileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSignIn;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.addresses,
    required this.isProfileComplete,
    this.createdAt,
    this.updatedAt,
    this.lastSignIn,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      addresses: (data['addresses'] as List<dynamic>?)
          ?.map((address) => Address.fromMap(address as Map<String, dynamic>))
          .toList() ?? [],
      isProfileComplete: data['isProfileComplete'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      lastSignIn: data['lastSignIn'] != null 
          ? (data['lastSignIn'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'isProfileComplete': isProfileComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    List<Address>? addresses,
    bool? isProfileComplete,
  }) {
    return UserModel(
      uid: uid,
      phoneNumber: phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      addresses: addresses ?? this.addresses,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastSignIn: lastSignIn,
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
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
      'updatedAt': FieldValue.serverTimestamp(),
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