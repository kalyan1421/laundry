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
  final String? preBuiltFullAddress; // For Firebase fullAddress field
  
  // Store original structured data for getters
  final Map<String, dynamic>? _originalData;

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
    this.preBuiltFullAddress,
    Map<String, dynamic>? originalData,
  }) : _originalData = originalData;

  // Getters for structured address components
  String get doorNumber {
    // First try to get from original data
    if (_originalData != null && _originalData!['doorNumber'] != null) {
      return _originalData!['doorNumber'].toString().trim();
    }
    
    // Try to extract from addressLine1
    if (addressLine1.contains('Door:')) {
      RegExp doorRegex = RegExp(r'Door:\s*([^,]+)');
      Match? doorMatch = doorRegex.firstMatch(addressLine1);
      if (doorMatch != null) {
        return doorMatch.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }

  String get floorNumber {
    // First try to get from original data
    if (_originalData != null && _originalData!['floorNumber'] != null) {
      return _originalData!['floorNumber'].toString().trim();
    }
    
    // Try to extract from addressLine1
    if (addressLine1.contains('Floor:')) {
      RegExp floorRegex = RegExp(r'Floor:\s*([^,]+)');
      Match? floorMatch = floorRegex.firstMatch(addressLine1);
      if (floorMatch != null) {
        return floorMatch.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }

  String get apartmentName {
    // First try to get from original data
    if (_originalData != null && _originalData!['apartmentName'] != null) {
      return _originalData!['apartmentName'].toString().trim();
    }
    
    // Try to extract from addressLine1
    if (addressLine1.contains('Floor:') && addressLine1.contains(',')) {
      RegExp apartmentRegex = RegExp(r'Floor:\s*[^,]+,\s*([^,]+)');
      Match? apartmentMatch = apartmentRegex.firstMatch(addressLine1);
      if (apartmentMatch != null) {
        String apartment = apartmentMatch.group(1)?.trim() ?? '';
        // Don't include the main address part
        if (!apartment.toLowerCase().contains('road') && 
            !apartment.toLowerCase().contains('street') &&
            !apartment.toLowerCase().contains('lane') &&
            !apartment.toLowerCase().contains('avenue')) {
          return apartment;
        }
      }
    }
    
    return '';
  }

  // Create Address from Map
  factory Address.fromMap(Map<String, dynamic> map) {
    // Helper function to get first non-empty value
    String getFirstNonEmpty(List<String?> values) {
      for (String? value in values) {
        if (value != null && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return '';
    }

    // Helper function to safely convert to double
    double? safeToDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Helper function to safely convert to bool
    bool safeToBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      if (value is int) return value == 1;
      return false;
    }

    // For standardized address format, we directly use the fields
    String doorNumber = getFirstNonEmpty([
      map['doorNumber'] as String?,
    ]);
    
    String floorNumber = getFirstNonEmpty([
      map['floorNumber'] as String?,
    ]);
    
    String apartmentName = getFirstNonEmpty([
      map['apartmentName'] as String?,
    ]);

    // Primary address line - use addressLine1 directly for standardized format
    String addressLine1 = getFirstNonEmpty([
      map['addressLine1'] as String?,
      map['address'] as String?,
      map['street'] as String?,
    ]);

    // Build comprehensive address line 1 for display if we have structured data
    if (doorNumber.isNotEmpty || floorNumber.isNotEmpty || apartmentName.isNotEmpty) {
      List<String> structuredParts = [];
      
      if (doorNumber.isNotEmpty) {
        structuredParts.add('Door: $doorNumber');
      }
      if (floorNumber.isNotEmpty) {
        structuredParts.add('Floor: $floorNumber');
      }
      if (apartmentName.isNotEmpty) {
        structuredParts.add(apartmentName);
      }
      
      // Combine structured parts with address line
      if (structuredParts.isNotEmpty) {
        if (addressLine1.isNotEmpty) {
          addressLine1 = '${structuredParts.join(', ')}, $addressLine1';
        } else {
          addressLine1 = structuredParts.join(', ');
        }
      }
    }

    return Address(
      id: map['id'] ?? '',
      
      // Address type handling
      type: getFirstNonEmpty([
        map['type'] as String?,
        map['addressType'] as String?,
      ]).toLowerCase().isEmpty ? 'home' : getFirstNonEmpty([
        map['type'] as String?,
        map['addressType'] as String?,
      ]).toLowerCase(),
      
      // Use the built address line 1 (may include structured data)
      addressLine1: addressLine1,
      
      // Secondary address line
      addressLine2: getFirstNonEmpty([
        map['addressLine2'] as String?,
        map['floor'] as String?,
        map['apartment'] as String?,
      ]),
      
      // City handling
      city: getFirstNonEmpty([
        map['city'] as String?,
        map['locality'] as String?,
      ]),
      
      // State handling
      state: getFirstNonEmpty([
        map['state'] as String?,
        map['administrativeArea'] as String?,
      ]),
      
      // Pincode handling
      pincode: getFirstNonEmpty([
        map['pincode'] as String?,
        map['postalCode'] as String?,
        map['zip'] as String?,
      ]),
      
      // Landmark handling - use standardized field first
      landmark: getFirstNonEmpty([
        map['landmark'] as String?,
        map['nearbyLandmark'] as String?,
        map['nearby'] as String?,
      ]),
      
      // Coordinate handling with safety checks
      latitude: safeToDouble(map['latitude']),
      longitude: safeToDouble(map['longitude']),
      
      // Primary flag handling
      isPrimary: safeToBool(map['isPrimary']),
      
      // Timestamp handling
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] : null,
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : null,
      
      // Pre-built full address
      preBuiltFullAddress: map['fullAddress'] as String?,
      
      // Pass original data for getters
      originalData: map,
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
      if (preBuiltFullAddress != null) 'fullAddress': preBuiltFullAddress,
    };
  }

  // Get full formatted address
  String get fullAddress {
    // If pre-built full address exists, use it
    if (preBuiltFullAddress != null && preBuiltFullAddress!.trim().isNotEmpty) {
      return preBuiltFullAddress!;
    }
    
    // Build comprehensive address from components
    List<String> parts = [];
    
    // Check if addressLine1 already contains door/floor info (from profile setup)
    String cleanAddressLine1 = addressLine1;
    bool hasStructuredInfo = false;
    
    // Extract structured info if present in addressLine1
    if (addressLine1.contains('Door:') || addressLine1.contains('Floor:')) {
      hasStructuredInfo = true;
      // Use the structured format as-is
      parts.add(addressLine1);
    } else {
      // Build structured format from individual components
      List<String> buildingParts = [];
      
      // Add door number if available
      if (addressLine1.trim().isNotEmpty && 
          !addressLine1.toLowerCase().contains('door') &&
          !addressLine1.toLowerCase().contains('floor')) {
        // Check if addressLine1 looks like a door number (short and alphanumeric)
        if (addressLine1.trim().length <= 10 && 
            RegExp(r'^[a-zA-Z0-9\-/\s]+$').hasMatch(addressLine1.trim())) {
          buildingParts.add('Door: ${addressLine1.trim()}');
        } else {
          // It's a regular address line
          buildingParts.add(addressLine1.trim());
        }
      } else if (addressLine1.trim().isNotEmpty) {
        buildingParts.add(addressLine1.trim());
      }
      
      // Add floor number if available and not already in addressLine1
      if (addressLine2.trim().isNotEmpty && 
          !addressLine2.toLowerCase().contains('floor') &&
          !hasStructuredInfo) {
        // Check if addressLine2 looks like a floor number
        if (addressLine2.trim().length <= 10 && 
            RegExp(r'^[a-zA-Z0-9\-/\s]+$').hasMatch(addressLine2.trim())) {
          buildingParts.add('Floor: ${addressLine2.trim()}');
        } else {
          // It's additional address info
          buildingParts.add(addressLine2.trim());
        }
      } else if (addressLine2.trim().isNotEmpty) {
        buildingParts.add(addressLine2.trim());
      }
      
      if (buildingParts.isNotEmpty) {
        parts.add(buildingParts.join(', '));
      }
    }
    
    // Add addressLine2 if it's not already processed and not empty
    if (addressLine2.trim().isNotEmpty && !hasStructuredInfo) {
      // Only add if it's not already included above
      if (!parts.any((part) => part.contains(addressLine2.trim()))) {
        parts.add(addressLine2.trim());
      }
    }
    
    // Add landmark if available
    if (landmark.trim().isNotEmpty) {
      String landmarkText = landmark.trim();
      // Add "Near" prefix if not already present
      if (!landmarkText.toLowerCase().startsWith('near')) {
        landmarkText = 'Near $landmarkText';
      }
      parts.add(landmarkText);
    }
    
    // Add location details
    if (city.trim().isNotEmpty) parts.add(city.trim());
    if (state.trim().isNotEmpty) parts.add(state.trim());
    if (pincode.trim().isNotEmpty) parts.add(pincode.trim());
    
    // Join all parts with commas
    String result = parts.where((part) => part.trim().isNotEmpty).join(', ');
    
    // Debug logging
    print('🏠 Address.fullAddress: Building address from components');
    print('🏠 AddressLine1: "$addressLine1"');
    print('🏠 AddressLine2: "$addressLine2"');
    print('🏠 Landmark: "$landmark"');
    print('🏠 City: "$city"');
    print('🏠 State: "$state"');
    print('🏠 Pincode: "$pincode"');
    print('🏠 Result: "$result"');
    
    return result.isNotEmpty ? result : 'Address not available';
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