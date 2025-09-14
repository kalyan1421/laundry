// lib/data/models/address_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id; // Document ID from Firestore
  final String type; // home, work, other
  final String addressLine1;
  final String? addressLine2; // Made nullable as it might be optional
  final String city;
  final String state;
  final String pincode;
  final String? landmark; // Made nullable
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final DateTime? createdAt; // Set by Firestore server timestamp
  final DateTime? updatedAt; // Set by Firestore server timestamp
  final String? doorNumber; // New field
  final String? floorNumber; // New field
  final String? apartmentName; // New field
  final String? country; // New field
  final String? addressType; // New field

  AddressModel({
    required this.id,
    required this.type,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.latitude,
    this.longitude,
    this.isPrimary = false, // Default to false if not provided
    this.createdAt,
    this.updatedAt,
    this.doorNumber,
    this.floorNumber,
    this.apartmentName,
    this.country,
    this.addressType,
  });

  // Corrected factory method to be used by AddressProvider
  factory AddressModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AddressModel(
      id: documentId, // Use the document ID passed from Firestore
      type: data['type'] as String? ?? 'home',
      addressLine1: data['addressLine1'] as String? ?? '',
      addressLine2: data['addressLine2'] as String?,
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      pincode: data['pincode'] as String? ?? '',
      landmark: data['landmark'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      isPrimary: data['isPrimary'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      doorNumber: data['doorNumber'] as String?,
      floorNumber: data['floorNumber'] as String?,
      apartmentName: data['apartmentName'] as String?,
      country: data['country'] as String?,
      addressType: data['addressType'] as String?,
    );
  }

  // Data sent to Firestore when creating or updating an address.
  // id, createdAt, and updatedAt are handled by Firestore/Provider.
  Map<String, dynamic> toMap() {
    return {
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
      'doorNumber': doorNumber,
      'floorNumber': floorNumber,
      'apartmentName': apartmentName,
      'country': country,
      'addressType': addressType,
      // 'createdAt' and 'updatedAt' are set using FieldValue.serverTimestamp() in the provider.
      // 'id' is the document ID and not stored as a field within the document.
    };
  }

  String get fullAddress {
    List<String> parts = [];
    if (doorNumber != null && doorNumber!.isNotEmpty) parts.add(doorNumber!);
    if (floorNumber != null && floorNumber!.isNotEmpty) parts.add(floorNumber!);
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) parts.add(addressLine2!);
    if (landmark != null && landmark!.isNotEmpty) parts.add('Near $landmark');
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (pincode.isNotEmpty) parts.add(pincode);
    
    return parts.join(', ');
  }

  String get shortAddress {
    List<String> parts = [];
    
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (city.isNotEmpty) parts.add(city);
    
    return parts.join(', ');
  }

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

  AddressModel copyWith({
    String? id, // id can also be copied if needed, though typically it's fixed
    String? type,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    double? latitude,
    double? longitude,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? doorNumber,
    String? floorNumber,
    String? apartmentName,
    String? country,
    String? addressType,
  }) {
    return AddressModel(
      id: id ?? this.id,
      type: type ?? this.type,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt, // Keep existing if not provided
      updatedAt: updatedAt ?? this.updatedAt, // Keep existing if not provided
      doorNumber: doorNumber ?? this.doorNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      apartmentName: apartmentName ?? this.apartmentName,
      country: country ?? this.country,
      addressType: addressType ?? this.addressType,
    );
  }
}