import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String? orderNumber;
  final String serviceType;
  final Timestamp orderTimestamp;
  final String status;
  final double totalAmount;
  final List<Map<String, dynamic>> items;
  final String pickupAddress;
  final String deliveryAddress;
  final Timestamp pickupDate;
  final String pickupTimeSlot;
  final Timestamp? deliveryDate;
  final String? deliveryTimeSlot;
  final String paymentMethod;
  final String? specialInstructions;
  final List<Map<String, dynamic>> statusHistory;
  
  // Address fields from Firebase
  final double? latitude;
  final double? longitude;
  final String? pincode;
  final String? state;
  final String? addressType;
  final String? landmark;
  
  // Assignment and management fields
  final String? assignedDeliveryPerson;
  final String? assignedDeliveryPersonName;
  final String? assignedBy; // Admin who assigned
  final Timestamp? assignedAt;
  final bool isAcceptedByDeliveryPerson;
  final Timestamp? acceptedAt;
  final String? rejectionReason;
  final bool notificationSentToAdmin;
  final bool notificationSentToDeliveryPerson;
  final List<String> notificationTokens; // FCM tokens for notifications
  final List<Map<String, dynamic>> notifications; // All notification details stored in order

  OrderModel({
    required this.id,
    required this.userId,
    this.orderNumber,
    required this.serviceType,
    required this.orderTimestamp,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.pickupDate,
    required this.pickupTimeSlot,
    this.deliveryDate,
    this.deliveryTimeSlot,
    required this.paymentMethod,
    this.specialInstructions,
    required this.statusHistory,
    this.latitude,
    this.longitude,
    this.pincode,
    this.state,
    this.addressType,
    this.landmark,
    // Assignment fields
    this.assignedDeliveryPerson,
    this.assignedDeliveryPersonName,
    this.assignedBy,
    this.assignedAt,
    this.isAcceptedByDeliveryPerson = false,
    this.acceptedAt,
    this.rejectionReason,
    this.notificationSentToAdmin = false,
    this.notificationSentToDeliveryPerson = false,
    this.notificationTokens = const [],
    this.notifications = const [],
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Determine serviceType based on items with intelligent categorization
      String determinedServiceType = _determineServiceTypeFromItems(data['items'] as List?);
      
      // Parse statusHistory safely
      List<Map<String, dynamic>> parsedStatusHistory = [];
      if (data['statusHistory'] is List) {
        for (var item in (data['statusHistory'] as List)) {
          if (item is Map<String, dynamic>) {
            parsedStatusHistory.add(item);
          }
        }
      }
      
      // Parse notification tokens
      List<String> tokens = [];
      if (data['notificationTokens'] is List) {
        tokens = List<String>.from(data['notificationTokens']);
      }
      
      // Parse notifications
      List<Map<String, dynamic>> notificationsList = [];
      if (data['notifications'] is List) {
        for (var item in (data['notifications'] as List)) {
          if (item is Map<String, dynamic>) {
            notificationsList.add(item);
          }
        }
      }
      
      // Parse pickup address from the nested structure
      String pickupAddr = 'N/A';
      if (data['pickupAddress'] is Map) {
        Map<String, dynamic> pickupAddressMap = data['pickupAddress'];
        if (pickupAddressMap['formatted'] != null) {
          pickupAddr = pickupAddressMap['formatted'].toString();
        } else if (pickupAddressMap['details'] is Map) {
          Map<String, dynamic> details = pickupAddressMap['details'];
          List<String> addressParts = [];
          if (details['addressLine1'] != null) addressParts.add(details['addressLine1'].toString());
          if (details['addressLine2'] != null && details['addressLine2'].toString().trim().isNotEmpty) {
            addressParts.add(details['addressLine2'].toString());
          }
          if (details['city'] != null) addressParts.add(details['city'].toString());
          if (details['state'] != null) addressParts.add(details['state'].toString());
          if (details['pincode'] != null) addressParts.add(details['pincode'].toString());
          pickupAddr = addressParts.join(', ');
        }
      } else if (data['pickupAddress'] != null) {
        pickupAddr = data['pickupAddress'].toString();
      }
      
      // Parse delivery address from the nested structure
      String deliveryAddr = pickupAddr; // Default to pickup address
      if (data['deliveryAddress'] is Map) {
        Map<String, dynamic> deliveryAddressMap = data['deliveryAddress'];
        if (deliveryAddressMap['formatted'] != null) {
          deliveryAddr = deliveryAddressMap['formatted'].toString();
        } else if (deliveryAddressMap['details'] is Map) {
          Map<String, dynamic> details = deliveryAddressMap['details'];
          List<String> addressParts = [];
          if (details['addressLine1'] != null) addressParts.add(details['addressLine1'].toString());
          if (details['addressLine2'] != null && details['addressLine2'].toString().trim().isNotEmpty) {
            addressParts.add(details['addressLine2'].toString());
          }
          if (details['city'] != null) addressParts.add(details['city'].toString());
          if (details['state'] != null) addressParts.add(details['state'].toString());
          if (details['pincode'] != null) addressParts.add(details['pincode'].toString());
          deliveryAddr = addressParts.join(', ');
        }
      } else if (data['deliveryAddress'] != null) {
        deliveryAddr = data['deliveryAddress'].toString();
      }
      
      // Use orderTimestamp as primary timestamp
      Timestamp orderTs = data['orderTimestamp'] ?? data['createdAt'] ?? data['updatedAt'] ?? Timestamp.now();
      
      // Get status from Firebase data
      String orderStatus = data['status']?.toString() ?? 'pending';
      
      // Safe conversion for all fields
      String userId = data['customerId']?.toString() ?? data['userId']?.toString() ?? '';
      // Since we're using order number as document ID, use doc.id as order number
      String orderNumber = doc.id;
      double totalAmount = 0.0;
      
      // Handle totalAmount conversion safely
      if (data['totalAmount'] != null) {
        if (data['totalAmount'] is num) {
          totalAmount = data['totalAmount'].toDouble();
        } else {
          try {
            totalAmount = double.parse(data['totalAmount'].toString());
          } catch (e) {
            print('Error parsing totalAmount: ${data['totalAmount']}, using 0.0');
            totalAmount = 0.0;
          }
        }
      }
      
      // Handle items list safely
      List<Map<String, dynamic>> itemsList = [];
      if (data['items'] is List) {
        for (var item in (data['items'] as List)) {
          if (item is Map<String, dynamic>) {
            itemsList.add(item);
          } else if (item is Map) {
            // Convert to Map<String, dynamic> if it's just a Map
            itemsList.add(Map<String, dynamic>.from(item));
          }
        }
      }

      // Extract latitude and longitude from address details
      double? lat, lng;
      String? pincode, state, addressType, landmark;
      
      // Try to get location data from pickupAddress first
      if (data['pickupAddress'] is Map) {
        Map<String, dynamic> pickupAddressMap = data['pickupAddress'];
        if (pickupAddressMap['details'] is Map) {
          Map<String, dynamic> details = pickupAddressMap['details'];
          lat = details['latitude'] is num ? details['latitude'].toDouble() : null;
          lng = details['longitude'] is num ? details['longitude'].toDouble() : null;
          pincode = details['pincode']?.toString();
          state = details['state']?.toString();
          addressType = details['type']?.toString();
          landmark = details['landmark']?.toString();
        }
      }

      return OrderModel(
        id: doc.id,
        userId: userId,
        orderNumber: orderNumber,
        serviceType: determinedServiceType,
        orderTimestamp: orderTs,
        status: orderStatus,
        totalAmount: totalAmount,
        items: itemsList,
        pickupAddress: pickupAddr,
        deliveryAddress: deliveryAddr,
        pickupDate: data['pickupDate'] ?? Timestamp.now(),
        pickupTimeSlot: data['pickupTimeSlot']?.toString() ?? 'N/A',
        deliveryDate: data['deliveryDate'],
        deliveryTimeSlot: data['deliveryTimeSlot']?.toString(),
        paymentMethod: data['paymentMethod']?.toString() ?? 'N/A',
        specialInstructions: data['specialInstructions']?.toString(),
        statusHistory: parsedStatusHistory,
        latitude: lat,
        longitude: lng,
        pincode: pincode,
        state: state,
        addressType: addressType,
        landmark: landmark,
        // Assignment fields
        assignedDeliveryPerson: data['assignedDeliveryPerson']?.toString(),
        assignedDeliveryPersonName: data['assignedDeliveryPersonName']?.toString(),
        assignedBy: data['assignedBy']?.toString(),
        assignedAt: data['assignedAt'],
        isAcceptedByDeliveryPerson: data['isAcceptedByDeliveryPerson'] ?? false,
        acceptedAt: data['acceptedAt'],
        rejectionReason: data['rejectionReason']?.toString(),
        notificationSentToAdmin: data['notificationSentToAdmin'] ?? false,
        notificationSentToDeliveryPerson: data['notificationSentToDeliveryPerson'] ?? false,
        notificationTokens: tokens,
        notifications: notificationsList,
      );
    } catch (e) {
      print('Error parsing order document ${doc.id}: $e');
      print('Document data: ${doc.data()}');
      
      // Return a default order with minimal data to prevent app crash
      return OrderModel(
        id: doc.id,
        userId: '',
        orderNumber: doc.id,
        serviceType: 'Laundry Service',
        orderTimestamp: Timestamp.now(),
        status: 'unknown',
        totalAmount: 0.0,
        items: [],
        pickupAddress: 'N/A',
        deliveryAddress: 'N/A',
        pickupDate: Timestamp.now(),
        pickupTimeSlot: 'N/A',
        paymentMethod: 'N/A',
        statusHistory: [],
        notifications: [],
      );
    }
  }
  
  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderNumber': orderNumber,
      'serviceType': serviceType,
      'orderTimestamp': orderTimestamp,
      'status': status,
      'totalAmount': totalAmount,
      'items': items,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'pickupDate': pickupDate,
      'pickupTimeSlot': pickupTimeSlot,
      'deliveryDate': deliveryDate,
      'deliveryTimeSlot': deliveryTimeSlot,
      'paymentMethod': paymentMethod,
      'specialInstructions': specialInstructions,
      'statusHistory': statusHistory,
      'latitude': latitude,
      'longitude': longitude,
      'pincode': pincode,
      'state': state,
      'type': addressType,
      'landmark': landmark,
      // Assignment fields
      'assignedDeliveryPerson': assignedDeliveryPerson,
      'assignedDeliveryPersonName': assignedDeliveryPersonName,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt,
      'isAcceptedByDeliveryPerson': isAcceptedByDeliveryPerson,
      'acceptedAt': acceptedAt,
      'rejectionReason': rejectionReason,
      'notificationSentToAdmin': notificationSentToAdmin,
      'notificationSentToDeliveryPerson': notificationSentToDeliveryPerson,
      'notificationTokens': notificationTokens,
      'notifications': notifications,
      'updatedAt': Timestamp.now(),
    };
  }
  
  // Static method to determine service type from items
  static String _determineServiceTypeFromItems(List? items) {
    if (items == null || items.isEmpty) {
      return 'Laundry Service';
    }
    
    // Count items by category
    Map<String, int> categoryCount = {};
    int totalItems = 0;
    
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        totalItems += (item['quantity'] as int?) ?? 1;
        String category = item['category']?.toString().toLowerCase() ?? '';
        
        // Normalize category names
        if (category.contains('iron') || category == 'ironing') {
          categoryCount['ironing'] = (categoryCount['ironing'] ?? 0) + ((item['quantity'] as int?) ?? 1);
        } else if (category.contains('allied') || category == 'allied service' || category == 'allied services') {
          categoryCount['allied'] = (categoryCount['allied'] ?? 0) + ((item['quantity'] as int?) ?? 1);
        } else {
          // Everything else is considered laundry (wash & fold, dry cleaning, etc.)
          categoryCount['laundry'] = (categoryCount['laundry'] ?? 0) + ((item['quantity'] as int?) ?? 1);
        }
      }
    }
    
    // Determine service type based on items
    int ironingCount = categoryCount['ironing'] ?? 0;
    int alliedCount = categoryCount['allied'] ?? 0;
    int laundryCount = categoryCount['laundry'] ?? 0;
    
    // Check for combinations
    List<String> serviceTypes = [];
    if (ironingCount > 0) serviceTypes.add('Ironing');
    if (alliedCount > 0) serviceTypes.add('Allied');
    if (laundryCount > 0) serviceTypes.add('Laundry');
    
    if (serviceTypes.length > 1) {
      return 'Mixed Service (${serviceTypes.join(' & ')})';
    } else if (ironingCount > 0) {
      return 'Ironing Service';
    } else if (alliedCount > 0) {
      return 'Allied Service';
    } else {
      return 'Laundry Service';
    }
  }
  
  // Copy with method for updates
  OrderModel copyWith({
    String? status,
    String? assignedDeliveryPerson,
    String? assignedDeliveryPersonName,
    String? assignedBy,
    Timestamp? assignedAt,
    bool? isAcceptedByDeliveryPerson,
    Timestamp? acceptedAt,
    String? rejectionReason,
    bool? notificationSentToAdmin,
    bool? notificationSentToDeliveryPerson,
    List<String>? notificationTokens,
    List<Map<String, dynamic>>? statusHistory,
    List<Map<String, dynamic>>? notifications,
  }) {
    return OrderModel(
      id: id,
      userId: userId,
      orderNumber: orderNumber,
      serviceType: serviceType,
      orderTimestamp: orderTimestamp,
      status: status ?? this.status,
      totalAmount: totalAmount,
      items: items,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      pickupDate: pickupDate,
      pickupTimeSlot: pickupTimeSlot,
      deliveryDate: deliveryDate,
      deliveryTimeSlot: deliveryTimeSlot,
      paymentMethod: paymentMethod,
      specialInstructions: specialInstructions,
      statusHistory: statusHistory ?? this.statusHistory,
      latitude: latitude,
      longitude: longitude,
      pincode: pincode,
      state: state,
      addressType: addressType,
      landmark: landmark,
      assignedDeliveryPerson: assignedDeliveryPerson ?? this.assignedDeliveryPerson,
      assignedDeliveryPersonName: assignedDeliveryPersonName ?? this.assignedDeliveryPersonName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      isAcceptedByDeliveryPerson: isAcceptedByDeliveryPerson ?? this.isAcceptedByDeliveryPerson,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notificationSentToAdmin: notificationSentToAdmin ?? this.notificationSentToAdmin,
      notificationSentToDeliveryPerson: notificationSentToDeliveryPerson ?? this.notificationSentToDeliveryPerson,
      notificationTokens: notificationTokens ?? this.notificationTokens,
      notifications: notifications ?? this.notifications,
    );
  }
}
