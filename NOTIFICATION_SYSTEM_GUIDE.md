# Laundry Management App - Notification System

## Overview

This comprehensive notification system enables real-time communication between customers, admins, and delivery persons throughout the order lifecycle. The system uses Firebase Cloud Messaging (FCM) for push notifications and includes order assignment and status tracking functionality.

## 🚀 Features Implemented

### 1. **Order Placement Notifications**
- ✅ Automatic notification to admins when new orders are placed
- ✅ Order details included in notification payload
- ✅ Real-time notification delivery

### 2. **Admin Order Management**
- ✅ View all orders with filtering (pending, assigned, completed)
- ✅ Assign orders to delivery persons
- ✅ Update order statuses
- ✅ Order details and item management

### 3. **Delivery Person Interface**
- ✅ Accept/reject assigned orders with reasons
- ✅ View order details and customer information
- ✅ Update order status throughout delivery process
- ✅ Three-tab interface: Assigned, Active, Completed

### 4. **Notification Types**
- 🔔 **New Order** → Admin
- 🔔 **Order Assignment** → Delivery Person
- 🔔 **Status Updates** → Customer
- 🔔 **Order Acceptance/Rejection** → Admin

## 📱 Components Created

### 1. **Updated OrderModel** (`customer_app/lib/data/models/order_model.dart`)
```dart
// New fields added:
- assignedDeliveryPerson: String?
- assignedDeliveryPersonName: String?
- assignedBy: String?
- assignedAt: Timestamp?
- isAcceptedByDeliveryPerson: bool
- acceptedAt: Timestamp?
- rejectionReason: String?
- notificationSentToAdmin: bool
- notificationSentToDeliveryPerson: bool
- notificationTokens: List<String>
```

### 2. **NotificationService** (`customer_app/lib/services/notification_service.dart`)
- FCM token management
- Notification sending logic
- Local notification handling
- Topic subscription management

### 3. **Admin Order Management** (`admin_panel/lib/screens/orders/order_management_screen.dart`)
- Order filtering and display
- Delivery person assignment
- Status management
- Order details viewing

### 4. **Delivery Person Interface** (`admin_panel/lib/screens/delivery/delivery_orders_screen.dart`)
- Order acceptance/rejection
- Status updates
- Order tracking
- Detailed order information

## 🔧 Setup Instructions

### 1. **Firebase Configuration**
Ensure Firebase is properly configured with FCM enabled:

```yaml
# pubspec.yaml dependencies already added:
firebase_messaging: ^14.9.4
flutter_local_notifications: ^17.2.2
http: ^1.2.2
```

### 2. **User Roles Setup**
Create users in Firestore with appropriate roles:

```javascript
// Firestore users collection
{
  "userId": {
    "name": "John Doe",
    "email": "john@example.com", 
    "role": "admin" | "delivery" | "customer",
    "fcmToken": "user_fcm_token",
    "lastTokenUpdate": timestamp
  }
}
```

### 3. **Android Permissions** (if not already added)
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
```

### 4. **iOS Configuration** (if needed)
No additional setup required for the basic implementation.

## 📋 Order Workflow

### 1. **Customer Places Order**
```
Customer App → Places Order → Notification sent to Admin
```

### 2. **Admin Assigns Order**
```
Admin Panel → Select Order → Assign to Delivery Person → Notification sent to Delivery Person
```

### 3. **Delivery Person Response**
```
Delivery App → Accept/Reject Order → Status updated in Firebase
```

### 4. **Order Progress Tracking**
```
Delivery Person → Update Status → Customer receives notification
```

## 🎯 Key Features

### **Admin Dashboard**
- **Filter Orders**: All, Pending, Assigned, Unassigned, Completed
- **Assign Delivery**: Select from available delivery persons
- **Status Management**: Update order status at any time
- **Order Details**: Complete order information and items

### **Delivery Person App**
- **Assignment Alerts**: Receive notifications for new assignments
- **Accept/Reject**: Accept orders or reject with reason
- **Status Updates**: Update order progress in real-time
- **Order Management**: View current and completed orders

### **Customer Notifications**
- **Order Placed**: Confirmation notification
- **Status Updates**: Real-time progress updates
- **Delivery Alerts**: Notifications for pickup and delivery

## 🔐 Security Features

- **User Role Validation**: Ensure only authorized users can perform actions
- **Token Management**: Secure FCM token storage and updates
- **Data Validation**: Input validation for all order operations
- **Error Handling**: Comprehensive error handling and user feedback

## 📊 Database Schema Updates

### **Orders Collection**
```javascript
{
  "orderId": {
    // Existing fields...
    "assignedDeliveryPerson": "delivery_person_uid",
    "assignedDeliveryPersonName": "John Delivery",
    "assignedBy": "admin_uid",
    "assignedAt": timestamp,
    "isAcceptedByDeliveryPerson": false,
    "acceptedAt": null,
    "rejectionReason": null,
    "notificationSentToAdmin": true,
    "notificationSentToDeliveryPerson": true,
    "notificationTokens": ["token1", "token2"]
  }
}
```

## 🔄 Status Progression

### **Order Statuses**
1. **pending** → Order placed, awaiting assignment
2. **assigned** → Assigned to delivery person
3. **accepted** → Delivery person accepted
4. **picked_up** → Items collected from customer
5. **in_progress** → Processing at facility
6. **ready_for_delivery** → Ready for return
7. **out_for_delivery** → Out for delivery
8. **delivered** → Successfully delivered
9. **completed** → Order complete

## 📱 Navigation Integration

### **Admin Panel Routes**
- `/admin/orders` → Order Management Screen
- `/admin/orders/details/:id` → Order Details

### **Delivery App Routes**
- `/delivery/orders` → Delivery Orders Screen
- `/delivery/orders/details/:id` → Order Details

## 🛠 Customization Options

### **Notification Customization**
```dart
// Modify notification content in NotificationService
await _sendNotificationToTokens(
  tokens: tokens,
  title: 'Custom Title',
  body: 'Custom message content',
  data: {'custom': 'data'},
);
```

### **Status Updates**
```dart
// Add custom status validation
List<String> allowedStatuses = [
  'pending', 'assigned', 'accepted', 'picked_up',
  'in_progress', 'ready_for_delivery', 'out_for_delivery',
  'delivered', 'completed', 'cancelled'
];
```

## 🔍 Testing

### **Test Scenarios**
1. **Place Order** → Verify admin receives notification
2. **Assign Order** → Verify delivery person receives notification  
3. **Accept Order** → Verify status update
4. **Reject Order** → Verify order returns to pending
5. **Status Updates** → Verify customer receives notifications

### **Debug Logging**
The system includes comprehensive logging for debugging:
- FCM token generation and storage
- Notification sending attempts
- Order assignment and status changes
- Error conditions and failures

## 📞 Support & Troubleshooting

### **Common Issues**
1. **Notifications not received**: Check FCM token validity
2. **Assignment failures**: Verify user roles in Firestore
3. **Status update errors**: Check Firestore security rules
4. **Token refresh**: Automatic token refresh on app start

### **Monitoring**
- Monitor Firebase Console for notification delivery
- Check Firestore for proper data updates
- Use debug logs for troubleshooting

---

## 🎉 Implementation Complete!

Your laundry management app now has a complete notification system that handles:
- ✅ Real-time order notifications
- ✅ Assignment management  
- ✅ Status tracking
- ✅ Multi-role user interface
- ✅ Comprehensive error handling

The system is ready for production use and can be extended with additional features as needed. 