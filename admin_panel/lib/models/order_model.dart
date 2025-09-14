// models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import './user_model.dart'; // Assuming UserModel is in the same directory

class DeliveryAddress {
  final String? addressId;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pincode;
  final String? floor;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final Timestamp? createdAt;
  final String? doorNumber;
  final String? floorNumber;
  final String? apartmentName;
  final String? country;
  final String? type;
  final String? addressType;
  final bool? isPrimary;

  DeliveryAddress({
    this.addressId,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.pincode,
    this.floor,
    this.landmark,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.doorNumber,
    this.floorNumber,
    this.apartmentName,
    this.country,
    this.type,
    this.addressType,
    this.isPrimary,
  });

  factory DeliveryAddress.fromMap(Map<String, dynamic> data) {
    // Handle nested structure: deliveryAddress.details
    Map<String, dynamic> details = data['details'] ?? data;
    
    return DeliveryAddress(
      addressId: data['addressId']?.toString(),
      addressLine1: details['addressLine1']?.toString(),
      addressLine2: details['addressLine2']?.toString(),
      city: details['city']?.toString(),
      state: details['state']?.toString(),
      pincode: details['pincode']?.toString(),
      floor: details['floor']?.toString() ?? details['florr']?.toString(), // Fix "florr" typo
      landmark: details['landmark']?.toString(),
      latitude: details['latitude'] is num ? details['latitude'].toDouble() : null,
      longitude: details['longitude'] is num ? details['longitude'].toDouble() : null,
      createdAt: details['createdAt'] != null ? _parseTimestamp(details['createdAt']) : null,
      doorNumber: details['doorNumber']?.toString(),
      floorNumber: details['floorNumber']?.toString(),
      apartmentName: details['apartmentName']?.toString(),
      country: details['country']?.toString(),
      type: details['type']?.toString(),
      addressType: details['addressType']?.toString(),
      isPrimary: details['isPrimary'] == true,
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (addressLine1?.isNotEmpty == true) parts.add(addressLine1!);
    if (addressLine2?.isNotEmpty == true) parts.add(addressLine2!);
    if (floor?.isNotEmpty == true) parts.add('Floor: ${floor!}');
    if (landmark?.isNotEmpty == true) parts.add('Near ${landmark!}');
    if (city?.isNotEmpty == true) parts.add(city!);
    if (state?.isNotEmpty == true) parts.add(state!);
    if (pincode?.isNotEmpty == true) parts.add(pincode!);
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() {
    return {
      if (addressId != null) 'addressId': addressId,
      'details': {
        if (addressLine1 != null) 'addressLine1': addressLine1,
        if (addressLine2 != null) 'addressLine2': addressLine2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (floor != null) 'floor': floor,
        if (landmark != null) 'landmark': landmark,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (createdAt != null) 'createdAt': createdAt,
        if (doorNumber != null) 'doorNumber': doorNumber,
        if (floorNumber != null) 'floorNumber': floorNumber,
        if (apartmentName != null) 'apartmentName': apartmentName,
        if (country != null) 'country': country,
        if (type != null) 'type': type,
        if (addressType != null) 'addressType': addressType,
        if (isPrimary != null) 'isPrimary': isPrimary,
      }
    };
  }

  static Timestamp _parseTimestamp(dynamic timestampData) {
    try {
      if (timestampData is Timestamp) return timestampData;
      if (timestampData is int) return Timestamp.fromMillisecondsSinceEpoch(timestampData);
      if (timestampData is String) {
        final parsed = DateTime.tryParse(timestampData);
        if (parsed != null) return Timestamp.fromDate(parsed);
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
    }
    return Timestamp.now();
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String? customerId; // Added for the Firestore structure
  final String? orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String? paymentMethod;
  final String? deliveryAddress; // Legacy string field
  final DeliveryAddress? deliveryAddressDetails; // New structured field
  final String pickupAddress;
  final DeliveryAddress? pickupAddressDetails; // New structured field for pickup
  final double? deliveryLatitude; // Direct coordinate fields for compatibility
  final double? deliveryLongitude;
  final Timestamp orderTimestamp;
  final Timestamp? createdAt; // Added for Firestore structure
  final String? serviceType;
  final String? assignedTo;
  final String? assignedBy; // Added for Firestore structure
  final UserModel? customer; // Added customer details

  // Assignment and delivery person fields
  final String? assignedDeliveryPerson;
  final String? assignedDeliveryPersonName;
  final Timestamp? assignedAt;
  final bool isAcceptedByDeliveryPerson;

  // Scheduling fields
  final Timestamp? pickupDate;
  final String? pickupTimeSlot;
  final Timestamp? deliveryDate;
  final String? deliveryTimeSlot;

  // Customer instructions
  final String? specialInstructions;

  // Notification status
  final bool notificationSentToAdmin;
  final bool? notificationSentToDeliveryPerson;

  // Status history
  final List<Map<String, dynamic>> statusHistory;

  OrderModel({
    required this.id,
    required this.userId,
    this.customerId,
    this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.deliveryAddress,
    this.deliveryAddressDetails,
    required this.pickupAddress,
    this.pickupAddressDetails,
    this.deliveryLatitude,
    this.deliveryLongitude,
    required this.orderTimestamp,
    this.createdAt,
    this.serviceType,
    this.assignedTo,
    this.assignedBy,
    this.customer, // Added to constructor
    // Assignment fields
    this.assignedDeliveryPerson,
    this.assignedDeliveryPersonName,
    this.assignedAt,
    this.isAcceptedByDeliveryPerson = false,
    // Scheduling fields
    this.pickupDate,
    this.pickupTimeSlot,
    this.deliveryDate,
    this.deliveryTimeSlot,
    // Customer instructions
    this.specialInstructions,
    // Notification status
    this.notificationSentToAdmin = false,
    this.notificationSentToDeliveryPerson,
    // Status history
    this.statusHistory = const [],
  });

  // Get delivery address as string for display
  String get displayDeliveryAddress {
    if (deliveryAddressDetails != null) {
      return deliveryAddressDetails!.fullAddress;
    }
    return deliveryAddress ?? 'No delivery address';
  }

  // Get delivery coordinates - prioritize DeliveryAddress fields
  double? get latitude {
    return deliveryAddressDetails?.latitude ?? deliveryLatitude;
  }

  double? get longitude {
    return deliveryAddressDetails?.longitude ?? deliveryLongitude;
  }

  // Check if coordinates are available
  bool get hasCoordinates {
    return latitude != null && longitude != null;
  }

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Safe extraction helper function
    T? safeExtract<T>(String key, T? defaultValue) {
      try {
        final value = data[key];
        if (value == null) return defaultValue;
        if (value is T) return value;
        if (T == String && value != null) return value.toString() as T;
        if (T == double && value is num) return value.toDouble() as T;
        if (T == int && value is num) return value.toInt() as T;
        if (T == bool && value != null) {
          if (value is bool) return value as T;
          if (value is String) return (value.toLowerCase() == 'true') as T;
          return (value == 1 || value == true) as T;
        }
        return defaultValue;
      } catch (e) {
        print('Error extracting $key: $e');
        return defaultValue;
      }
    }

    // Parse delivery address from nested structure
    DeliveryAddress? parseDeliveryAddress(dynamic addressData) {
      try {
        if (addressData is Map<String, dynamic>) {
          return DeliveryAddress.fromMap(addressData);
        }
      } catch (e) {
        print('Error parsing delivery address: $e');
      }
      return null;
    }

    // Parse status history
    List<Map<String, dynamic>> parseStatusHistory(dynamic historyData) {
      try {
        if (historyData is List) {
          return historyData
              .where((item) => item != null)
              .map((item) => item is Map<String, dynamic> ? item : <String, dynamic>{})
              .toList();
        }
      } catch (e) {
        print('Error parsing status history: $e');
      }
      return [];
    }

    return OrderModel(
      id: doc.id,
      userId: safeExtract<String>('userId', '') ?? '',
      customerId: safeExtract<String>('customerId', null),
      orderNumber: safeExtract<String>('orderNumber', null),
      items: _parseItems(data['items']),
      totalAmount: safeExtract<double>('totalAmount', 0.0) ?? 0.0,
      status: safeExtract<String>('status', 'Unknown') ?? 'Unknown',
      paymentMethod: safeExtract<String>('paymentMethod', null),
      deliveryAddress: safeExtract<String>('deliveryAddress', null),
      deliveryAddressDetails: parseDeliveryAddress(data['deliveryAddressDetails']),
      pickupAddress: safeExtract<String>('pickupAddress', null) ?? '',
      pickupAddressDetails: parseDeliveryAddress(data['pickupAddressDetails']),
      deliveryLatitude: safeExtract<double>('latitude', null) ?? safeExtract<double>('deliveryLatitude', null),
      deliveryLongitude: safeExtract<double>('longitude', null) ?? safeExtract<double>('deliveryLongitude', null),
      orderTimestamp: _parseTimestamp(data['orderTimestamp'] ?? data['createdAt']),
      createdAt: data['createdAt'] != null ? _parseTimestamp(data['createdAt']) : null,
      serviceType: safeExtract<String>('serviceType', null),
      assignedTo: safeExtract<String>('assignedTo', null),
      assignedBy: safeExtract<String>('assignedBy', null),
      customer: null, // Customer will be populated by the service layer
      // Assignment fields
      assignedDeliveryPerson: safeExtract<String>('assignedDeliveryPerson', null),
      assignedDeliveryPersonName: safeExtract<String>('assignedDeliveryPersonName', null),
      assignedAt: data['assignedAt'] != null ? _parseTimestamp(data['assignedAt']) : null,
      isAcceptedByDeliveryPerson: safeExtract<bool>('isAcceptedByDeliveryPerson', false) ?? false,
      // Scheduling fields
      pickupDate: data['pickupDate'] != null ? _parseTimestamp(data['pickupDate']) : null,
      pickupTimeSlot: safeExtract<String>('pickupTimeSlot', null),
      deliveryDate: data['deliveryDate'] != null ? _parseTimestamp(data['deliveryDate']) : null,
      deliveryTimeSlot: safeExtract<String>('deliveryTimeSlot', null),
      // Customer instructions
      specialInstructions: safeExtract<String>('specialInstructions', null),
      // Notification status
      notificationSentToAdmin: safeExtract<bool>('notificationSentToAdmin', false) ?? false,
      notificationSentToDeliveryPerson: safeExtract<bool>('notificationSentToDeliveryPerson', null),
      // Status history
      statusHistory: parseStatusHistory(data['statusHistory']),
    );
  }

  static List<OrderItem> _parseItems(dynamic itemsData) {
    try {
      if (itemsData is List) {
        return itemsData
            .where((item) => item != null)
            .map((itemData) {
              try {
                if (itemData is Map<String, dynamic>) {
                  return OrderItem.fromMap(itemData);
                }
                return null;
              } catch (e) {
                print('Error parsing order item: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<OrderItem>()
            .toList();
      }
    } catch (e) {
      print('Error parsing items list: $e');
    }
    return [];
  }

  static Timestamp _parseTimestamp(dynamic timestampData) {
    try {
      if (timestampData is Timestamp) return timestampData;
      if (timestampData is int) return Timestamp.fromMillisecondsSinceEpoch(timestampData);
      if (timestampData is String) {
        final parsed = DateTime.tryParse(timestampData);
        if (parsed != null) return Timestamp.fromDate(parsed);
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
    }
    return Timestamp.now();
  }

  OrderModel copyWith({UserModel? customerInfo}) {
    return OrderModel(
      id: id,
      userId: userId,
      customerId: customerId,
      orderNumber: orderNumber,
      items: items,
      totalAmount: totalAmount,
      status: status,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      deliveryAddressDetails: deliveryAddressDetails,
      pickupAddress: pickupAddress,
      pickupAddressDetails: pickupAddressDetails,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      orderTimestamp: orderTimestamp,
      createdAt: createdAt,
      serviceType: serviceType,
      assignedTo: assignedTo,
      assignedBy: assignedBy,
      customer: customerInfo ?? customer, // Use new customerInfo or keep existing
      // Assignment fields
      assignedDeliveryPerson: assignedDeliveryPerson,
      assignedDeliveryPersonName: assignedDeliveryPersonName,
      assignedAt: assignedAt,
      isAcceptedByDeliveryPerson: isAcceptedByDeliveryPerson,
      // Scheduling fields
      pickupDate: pickupDate,
      pickupTimeSlot: pickupTimeSlot,
      deliveryDate: deliveryDate,
      deliveryTimeSlot: deliveryTimeSlot,
      // Customer instructions
      specialInstructions: specialInstructions,
      // Notification status
      notificationSentToAdmin: notificationSentToAdmin,
      notificationSentToDeliveryPerson: notificationSentToDeliveryPerson,
      // Status history
      statusHistory: statusHistory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      if (customerId != null) 'customerId': customerId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
      if (deliveryAddressDetails != null) 'deliveryAddressDetails': deliveryAddressDetails!.toMap(),
      'pickupAddress': pickupAddress,
      if (pickupAddressDetails != null) 'pickupAddressDetails': pickupAddressDetails!.toMap(),
      'orderTimestamp': orderTimestamp,
      if (createdAt != null) 'createdAt': createdAt,
      'serviceType': serviceType,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (assignedBy != null) 'assignedBy': assignedBy,
      // Assignment fields
      if (assignedDeliveryPerson != null) 'assignedDeliveryPerson': assignedDeliveryPerson,
      if (assignedDeliveryPersonName != null) 'assignedDeliveryPersonName': assignedDeliveryPersonName,
      if (assignedAt != null) 'assignedAt': assignedAt,
      'isAcceptedByDeliveryPerson': isAcceptedByDeliveryPerson,
      // Scheduling fields
      if (pickupDate != null) 'pickupDate': pickupDate,
      if (pickupTimeSlot != null) 'pickupTimeSlot': pickupTimeSlot,
      if (deliveryDate != null) 'deliveryDate': deliveryDate,
      if (deliveryTimeSlot != null) 'deliveryTimeSlot': deliveryTimeSlot,
      // Customer instructions
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
      // Notification status
      'notificationSentToAdmin': notificationSentToAdmin,
      if (notificationSentToDeliveryPerson != null) 'notificationSentToDeliveryPerson': notificationSentToDeliveryPerson,
      // Status history
      'statusHistory': statusHistory,
    };
  }
}

class OrderItem {
  final String itemId;
  final String name;
  final int quantity;
  final double pricePerPiece;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.pricePerPiece,
  });

  // Add operator[] for backward compatibility with existing code
  dynamic operator [](String key) {
    switch (key) {
      case 'name':
        return name;
      case 'quantity':
        return quantity;
      case 'price':
      case 'pricePerPiece':
        return pricePerPiece;
      case 'itemId':
        return itemId;
      default:
        return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'pricePerPiece': pricePerPiece,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    // Safe extraction helper function
    T? safeExtract<T>(List<String> keys, T? defaultValue) {
      for (String key in keys) {
        try {
          final value = map[key];
          if (value == null) continue;
          if (value is T) return value;
          if (T == String && value != null) return value.toString() as T;
          if (T == double && value is num) return value.toDouble() as T;
          if (T == int && value is num) return value.toInt() as T;
        } catch (e) {
          print('Error extracting $key: $e');
          continue;
        }
      }
      return defaultValue;
    }

    return OrderItem(
      itemId: safeExtract<String>(['itemId', 'garmentId', 'productId'], '') ?? '',
      name: safeExtract<String>(['name', 'itemName'], 'Unknown Item') ?? 'Unknown Item',
      quantity: safeExtract<int>(['quantity'], 0) ?? 0,
      pricePerPiece: safeExtract<double>(['pricePerPiece', 'price'], 0.0) ?? 0.0,
    );
  }
}
