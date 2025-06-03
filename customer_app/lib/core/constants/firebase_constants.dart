// Day 2: Database Schema Design

// lib/core/constants/firebase_constants.dart
class FirebaseConstants {
  // Collection names
  static const String usersCollection = 'users';
  static const String itemsCollection = 'items';
  static const String ordersCollection = 'orders';
  static const String bannersCollection = 'banners';
  static const String offersCollection = 'offers';
  static const String categoriesCollection = 'categories';

  // Storage paths
  static const String userProfileImages = 'users/{userId}/profile';
  static const String itemImages = 'items';
  static const String bannerImages = 'banners';
  static const String orderImages = 'orders/{orderId}';

  // Order statuses
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusPickedUp = 'picked_up';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // Item categories
  static const String categoryShirts = 'shirts';
  static const String categoryTrousers = 'trousers';
  static const String categorySuits = 'suits';
  static const String categoryDresses = 'dresses';
  static const String categorySarees = 'sarees';
  static const String categoryOthers = 'others';
}

/*
FIRESTORE DATABASE SCHEMA:

users/
├── {userId}
│   ├── name: string
│   ├── phone: string
│   ├── email: string (optional)
│   ├── profileImageUrl: string (optional)
│   ├── addresses: array
│   │   ├── type: string (home/work/other)
│   │   ├── addressLine1: string
│   │   ├── addressLine2: string
│   │   ├── city: string
│   │   ├── state: string
│   │   ├── pincode: string
│   │   ├── landmark: string
│   │   ├── latitude: number
│   │   ├── longitude: number
│   │   └── isPrimary: boolean
│   ├── isProfileComplete: boolean
│   ├── isAdmin: boolean
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

items/
├── {itemId}
│   ├── name: string
│   ├── price: number
│   ├── category: string
│   ├── imageUrl: string
│   ├── description: string
│   ├── isActive: boolean
│   ├── order: number (for sorting)
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

orders/
├── {orderId}
│   ├── userId: string
│   ├── orderNumber: string (auto-generated)
│   ├── items: array
│   │   ├── itemId: string
│   │   ├── itemName: string
│   │   ├── quantity: number
│   │   ├── price: number
│   │   └── subtotal: number
│   ├── totalAmount: number
│   ├── deliveryCharge: number
│   ├── discount: number
│   ├── finalAmount: number
│   ├── status: string
│   ├── deliveryAddress: object
│   ├── pickupAddress: object (optional)
│   ├── scheduledPickupTime: timestamp
│   ├── scheduledDeliveryTime: timestamp
│   ├── actualPickupTime: timestamp (optional)
│   ├── actualDeliveryTime: timestamp (optional)
│   ├── specialInstructions: string
│   ├── beforeImages: array (URLs)
│   ├── afterImages: array (URLs)
│   ├── feedback: object (optional)
│   │   ├── rating: number
│   │   ├── comment: string
│   │   └── createdAt: timestamp
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

banners/
├── {bannerId}
│   ├── title: string
│   ├── subtitle: string
│   ├── imageUrl: string
│   ├── actionType: string (none/offer/external)
│   ├── actionData: string (offerId/URL)
│   ├── isActive: boolean
│   ├── order: number
│   ├── startDate: timestamp
│   ├── endDate: timestamp
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

offers/
├── {offerId}
│   ├── title: string
│   ├── description: string
│   ├── discountType: string (percentage/fixed)
│   ├── discount: number
│   ├── minOrderAmount: number
│   ├── maxDiscountAmount: number (for percentage)
│   ├── applicableItems: array (itemIds or categories)
│   ├── promoCode: string (optional)
│   ├── usageLimit: number
│   ├── usageCount: number
│   ├── isActive: boolean
│   ├── validFrom: timestamp
│   ├── validUntil: timestamp
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

categories/
├── {categoryId}
│   ├── name: string
│   ├── icon: string (icon name or URL)
│   ├── color: string (hex color)
│   ├── order: number
│   ├── isActive: boolean
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

notifications/
├── {notificationId}
│   ├── userId: string
│   ├── title: string
│   ├── message: string
│   ├── type: string (order/offer/general)
│   ├── data: object (additional data)
│   ├── isRead: boolean
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

settings/
├── app_settings
│   ├── deliveryCharges: object
│   │   ├── baseCharge: number
│   │   ├── freeDeliveryMinAmount: number
│   │   └── expressDeliveryCharge: number
│   ├── serviceTiming: object
│   │   ├── pickupStartTime: string
│   │   ├── pickupEndTime: string
│   │   ├── deliveryStartTime: string
│   │   └── deliveryEndTime: string
│   ├── serviceAreas: array
│   ├── contactInfo: object
│   ├── termsAndConditions: string
│   ├── privacyPolicy: string
│   └── updatedAt: timestamp
*/