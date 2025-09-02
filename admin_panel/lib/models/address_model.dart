// lib/models/address_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id; // Document ID from Firestore
  final String type; // home, work, other
  final String doorNumber;
  final String? floorNumber;
  final String? apartmentName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark; // nearbyLandmark in some contexts
  final String? country;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AddressModel({
    required this.id,
    required this.type,
    required this.doorNumber,
    this.floorNumber,
    this.apartmentName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.country = 'India',
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.createdAt,
    this.updatedAt,
  });

  // Factory method to create from Firestore data
  factory AddressModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    final addressLine1 = data['addressLine1'] as String? ?? '';
    
    // Parse door number and floor number from addressLine1 if they exist
    String doorNumber = data['doorNumber'] as String? ?? '';
    String? floorNumber = data['floorNumber'] as String?;
    String? apartmentName = data['apartmentName'] as String?;
    String cleanAddressLine1 = addressLine1;
    
    // If doorNumber is empty, try to extract it from addressLine1
    if (doorNumber.isEmpty && addressLine1.isNotEmpty) {
      // Look for patterns like "Door: 411-1" or "Door: 123"
      final doorMatch = RegExp(r'Door:\s*([^,]+)').firstMatch(addressLine1);
      if (doorMatch != null) {
        doorNumber = doorMatch.group(1)?.trim() ?? '';
      }
    }
    
    // If floorNumber is empty, try to extract it from addressLine1
    if (floorNumber == null && addressLine1.isNotEmpty) {
      // Look for patterns like "Floor: 3rd floor" or "Floor: 2"
      final floorMatch = RegExp(r'Floor:\s*([^,]+)').firstMatch(addressLine1);
      if (floorMatch != null) {
        floorNumber = floorMatch.group(1)?.trim();
      }
    }
    
    // Clean addressLine1 by removing extracted door and floor info
    if (doorNumber.isNotEmpty || floorNumber != null) {
      cleanAddressLine1 = addressLine1
          .replaceAll(RegExp(r'Door:\s*[^,]+,?\s*'), '')
          .replaceAll(RegExp(r'Floor:\s*[^,]+,?\s*'), '')
          .trim();
      // Remove leading comma if exists
      if (cleanAddressLine1.startsWith(',')) {
        cleanAddressLine1 = cleanAddressLine1.substring(1).trim();
      }
    }
    
    return AddressModel(
      id: documentId,
      type: data['type'] as String? ?? data['addressType'] as String? ?? 'home',
      doorNumber: doorNumber,
      floorNumber: floorNumber,
      apartmentName: apartmentName,
      addressLine1: cleanAddressLine1,
      addressLine2: data['addressLine2'] as String?,
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      pincode: data['pincode'] as String? ?? '',
      landmark: data['landmark'] as String? ?? data['nearbyLandmark'] as String?,
      country: data['country'] as String? ?? 'India',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      isPrimary: data['isPrimary'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    // Build the complete addressLine1 with door and floor info if available
    List<String> addressParts = [];
    
    if (doorNumber.isNotEmpty) {
      addressParts.add('Door: $doorNumber');
    }
    if (floorNumber != null && floorNumber!.isNotEmpty) {
      addressParts.add('Floor: $floorNumber');
    }
    if (addressLine1.isNotEmpty) {
      addressParts.add(addressLine1);
    }
    
    final completeAddressLine1 = addressParts.join(', ');
    
    return {
      'type': type,
      'addressType': type, // For backward compatibility
      'doorNumber': doorNumber,
      'floorNumber': floorNumber,
      'apartmentName': apartmentName,
      'addressLine1': completeAddressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'nearbyLandmark': landmark, // For backward compatibility
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'isPrimary': isPrimary,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Full formatted address string
  String get fullAddress {
    List<String> parts = [];
    
    // If we have structured parts, build them
    List<String> structuredParts = [];
    if (doorNumber.isNotEmpty) structuredParts.add('Door: $doorNumber');
    if (floorNumber != null && floorNumber!.isNotEmpty) structuredParts.add('Floor: $floorNumber');
    if (apartmentName != null && apartmentName!.isNotEmpty) structuredParts.add(apartmentName!);
    
    // Add structured parts first
    if (structuredParts.isNotEmpty) {
      parts.add(structuredParts.join(', '));
    }
    
    // Add address lines
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) parts.add(addressLine2!);
    
    // Add landmark if available
    if (landmark != null && landmark!.isNotEmpty) {
      parts.add('Near $landmark');
    }
    
    // Add location details
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (pincode.isNotEmpty) parts.add(pincode);
    if (country != null && country! != 'India') parts.add(country!);
    
    return parts.join(', ');
  }

  // Short address for display
  String get shortAddress {
    List<String> parts = [];
    
    if (doorNumber.isNotEmpty && apartmentName != null && apartmentName!.isNotEmpty) {
      parts.add('$doorNumber, $apartmentName');
    } else if (doorNumber.isNotEmpty) {
      parts.add(doorNumber);
    } else if (addressLine1.isNotEmpty) {
      parts.add(addressLine1);
    }
    
    if (city.isNotEmpty) parts.add(city);
    
    return parts.join(', ');
  }

  // Display name for address type
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'home':
        return 'Home';
      case 'work':
        return 'Work';
      case 'other':
        return 'Other';
      default:
        if (type.isEmpty) return 'Other';
        return type.substring(0, 1).toUpperCase() + type.substring(1);
    }
  }

  // Copy with method for updates
  AddressModel copyWith({
    String? id,
    String? type,
    String? doorNumber,
    String? floorNumber,
    String? apartmentName,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    String? country,
    double? latitude,
    double? longitude,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      type: type ?? this.type,
      doorNumber: doorNumber ?? this.doorNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      apartmentName: apartmentName ?? this.apartmentName,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AddressModel(id: $id, type: $type, fullAddress: $fullAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
