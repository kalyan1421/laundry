import 'package:cloud_firestore/cloud_firestore.dart';

class WorkshopWorkerModel {
  final String id;
  final String uid;
  final String name;
  final String? email; // Made optional
  final String phoneNumber;
  final String role;
  final bool isActive;
  final bool isAvailable;
  final bool isOnline;
  final bool isRegistered;
  final double rating;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double earnings;
  final List<String> currentOrders;
  final List<String> orderHistory;
  final String workshopLocation;
  final double hourlyRate;
  final String employeeId;
  final String shift;
  final String? aadharNumber;
  final String? aadharCardUrl;
  final Map<String, dynamic> documents;
  final Map<String, dynamic> bankDetails;
  final Map<String, dynamic> address;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? createdBy;
  final String? createdByRole;
  final String? registrationToken;

  WorkshopWorkerModel({
    required this.id,
    required this.uid,
    required this.name,
    this.email, // Made optional
    required this.phoneNumber,
    this.role = 'workshop_worker',
    this.isActive = true,
    this.isAvailable = true,
    this.isOnline = false,
    this.isRegistered = false,
    this.rating = 0.0,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.earnings = 0.0,
    this.currentOrders = const [],
    this.orderHistory = const [],
    this.workshopLocation = '',
    this.hourlyRate = 0.0,
    required this.employeeId,
    this.shift = 'morning',
    this.aadharNumber,
    this.aadharCardUrl,
    this.documents = const {},
    this.bankDetails = const {},
    this.address = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.createdByRole,
    this.registrationToken,
  });

  factory WorkshopWorkerModel.fromMap(Map<String, dynamic> map) {
    return WorkshopWorkerModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      role: map['role'] ?? 'workshop_worker',
      isActive: map['isActive'] ?? true,
      isAvailable: map['isAvailable'] ?? true,
      isOnline: map['isOnline'] ?? false,
      isRegistered: map['isRegistered'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalOrders: map['totalOrders'] ?? 0,
      completedOrders: map['completedOrders'] ?? 0,
      cancelledOrders: map['cancelledOrders'] ?? 0,
      earnings: (map['earnings'] ?? 0.0).toDouble(),
      currentOrders: List<String>.from(map['currentOrders'] ?? []),
      orderHistory: List<String>.from(map['orderHistory'] ?? []),
      workshopLocation: map['workshopLocation'] ?? '',
      hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
      employeeId: map['employeeId'] ?? '',
      shift: map['shift'] ?? 'morning',
      aadharNumber: map['aadharNumber'],
      aadharCardUrl: map['aadharCardUrl'],
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
      'role': role,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'isOnline': isOnline,
      'isRegistered': isRegistered,
      'rating': rating,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'earnings': earnings,
      'currentOrders': currentOrders,
      'orderHistory': orderHistory,
      'workshopLocation': workshopLocation,
      'hourlyRate': hourlyRate,
      'employeeId': employeeId,
      'shift': shift,
      'aadharNumber': aadharNumber,
      'aadharCardUrl': aadharCardUrl,
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

  // Helper method to get availability status text
  String get availabilityStatus {
    if (!isActive) return 'Inactive';
    if (!isOnline) return 'Offline';
    if (!isAvailable) return 'Busy';
    return 'Available';
  }

  // Helper method to get email display text
  String get emailText {
    return email?.isNotEmpty == true ? email! : 'Email not provided';
  }

  // Helper method to get shift display text
  String get shiftText {
    switch (shift.toLowerCase()) {
      case 'morning':
        return 'Morning (6 AM - 2 PM)';
      case 'afternoon':
        return 'Afternoon (2 PM - 10 PM)';
      case 'night':
        return 'Night (10 PM - 6 AM)';
      case 'full_day':
        return 'Full Day (6 AM - 6 PM)';
      default:
        return 'Not specified';
    }
  }

  // Helper method to get formatted hourly rate
  String get formattedHourlyRate {
    if (hourlyRate <= 0) return 'Not specified';
    return '₹${hourlyRate.toStringAsFixed(0)}/hour';
  }

  // Helper method to check if worker has required documents
  bool get hasRequiredDocuments {
    return documents.isNotEmpty && 
           documents['identity'] != null &&
           documents['identity']['verified'] == true;
  }

  // Helper method to get performance percentage
  double get performancePercentage {
    if (totalOrders == 0) return 0.0;
    return (completedOrders / totalOrders) * 100;
  }
} 