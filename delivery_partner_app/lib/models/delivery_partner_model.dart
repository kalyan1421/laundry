// models/delivery_partner_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryPartnerModel {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String licenseNumber;
  final String? aadharNumber;
  final String? loginCode;
  final String role;
  final bool isActive;
  final bool isAvailable;
  final bool isOnline;
  final bool isRegistered;
  final double rating;
  final int totalDeliveries;
  final int completedDeliveries;
  final int cancelledDeliveries;
  final double earnings;
  final List<String> currentOrders;
  final List<String> orderHistory;
  final Map<String, dynamic> vehicleInfo;
  final Map<String, dynamic> documents;
  final Map<String, dynamic> bankDetails;
  final Map<String, dynamic> address;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? createdBy;
  final String? createdByRole;
  final String? registrationToken;

  DeliveryPartnerModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.licenseNumber,
    this.aadharNumber,
    this.loginCode,
    this.role = 'delivery',
    this.isActive = true,
    this.isAvailable = true,
    this.isOnline = false,
    this.isRegistered = false,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.completedDeliveries = 0,
    this.cancelledDeliveries = 0,
    this.earnings = 0.0,
    this.currentOrders = const [],
    this.orderHistory = const [],
    this.vehicleInfo = const {},
    this.documents = const {},
    this.bankDetails = const {},
    this.address = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.createdByRole,
    this.registrationToken,
  });

  factory DeliveryPartnerModel.fromMap(Map<String, dynamic> map) {
    return DeliveryPartnerModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      aadharNumber: map['aadharNumber'],
      loginCode: map['loginCode'],
      role: map['role'] ?? 'delivery',
      isActive: map['isActive'] ?? true,
      isAvailable: map['isAvailable'] ?? true,
      isOnline: map['isOnline'] ?? false,
      isRegistered: map['isRegistered'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalDeliveries: map['totalDeliveries'] ?? 0,
      completedDeliveries: map['completedDeliveries'] ?? 0,
      cancelledDeliveries: map['cancelledDeliveries'] ?? 0,
      earnings: (map['earnings'] ?? 0.0).toDouble(),
      currentOrders: List<String>.from(map['currentOrders'] ?? []),
      orderHistory: List<String>.from(map['orderHistory'] ?? []),
      vehicleInfo: Map<String, dynamic>.from(map['vehicleInfo'] ?? {}),
      documents: Map<String, dynamic>.from(map['documents'] ?? {}),
      bankDetails: Map<String, dynamic>.from(map['bankDetails'] ?? {}),
      address: Map<String, dynamic>.from(map['address'] ?? {}),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
      createdBy: map['createdBy'],
      createdByRole: map['createdByRole'],
      registrationToken: map['registrationToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'aadharNumber': aadharNumber,
      'loginCode': loginCode,
      'role': role,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'isOnline': isOnline,
      'isRegistered': isRegistered,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'completedDeliveries': completedDeliveries,
      'cancelledDeliveries': cancelledDeliveries,
      'earnings': earnings,
      'currentOrders': currentOrders,
      'orderHistory': orderHistory,
      'vehicleInfo': vehicleInfo,
      'documents': documents,
      'bankDetails': bankDetails,
      'address': address,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'registrationToken': registrationToken,
    };
  }

  // Helper method to get formatted phone number for display
  String get formattedPhone {
    if (phoneNumber.startsWith('+91')) {
      return phoneNumber.substring(3);
    }
    return phoneNumber;
  }

  // Helper method to check if all required documents are uploaded
  bool get hasAllDocuments {
    return documents.isNotEmpty && 
           documents['license'] != null &&
           documents['license']['verified'] == true;
  }

  // Helper method to get availability status text
  String get availabilityStatus {
    if (!isActive) return 'Inactive';
    if (!isOnline) return 'Offline';
    if (!isAvailable) return 'Busy';
    return 'Available';
  }
}