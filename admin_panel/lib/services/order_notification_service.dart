import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'fcm_service.dart';
import '../models/order_model.dart';

class OrderNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to admins when a new order is placed
  static Future<void> notifyAdminOfNewOrder({
    required String orderId,
    required String orderNumber,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required double totalAmount,
    required int itemCount,
  }) async {
    try {
      print('🔔 Sending new order notification to admins');
      
      // Format the notification body with order details
      String body = 'Order ID: $orderNumber\n'
          'Client ID: $customerPhone\n'  // Using phone as client ID
          'Amount: ₹${totalAmount.toStringAsFixed(2)}\n'
          'Items: $itemCount';

      await NotificationService.sendNotificationToAdmins(
        title: 'New Order Received',
        body: body,
        data: {
          'type': 'new_order',
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerId': customerId,
          'customerPhone': customerPhone,
          'totalAmount': totalAmount.toString(),
          'itemCount': itemCount.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // Save notification to orders collection for tracking
      await _saveOrderNotification(
        orderId: orderId,
        type: 'new_order',
        title: 'New Order Received',
        body: body,
        data: {
          'orderNumber': orderNumber,
          'customerId': customerId,
          'customerPhone': customerPhone,
          'totalAmount': totalAmount,
          'itemCount': itemCount,
        },
        forAdmin: true,
      );
      
      print('✅ Order notification sent successfully');
    } catch (e) {
      print('❌ Error sending order notification: $e');
    }
  }

  /// Notify admin when order is edited
  static Future<void> notifyAdminOfOrderEdit({
    required String orderId,
    required String orderNumber,
    required String customerPhone,
    required Map<String, dynamic> changes,
  }) async {
    try {
      print('🔔 Sending order edit notification to admins');

      String changesText = changes.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');

      String body = 'Order ID: $orderNumber\n'
          'Client ID: $customerPhone\n'
          'Changes:\n$changesText';

      await NotificationService.sendNotificationToAdmins(
        title: 'Order Modified',
        body: body,
        data: {
          'type': 'order_edit',
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerPhone': customerPhone,
          'changes': changes.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Save notification
      await _saveOrderNotification(
        orderId: orderId,
        type: 'order_edit',
        title: 'Order Modified',
        body: body,
        data: {
          'orderNumber': orderNumber,
          'customerPhone': customerPhone,
          'changes': changes.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
        },
        forAdmin: true,
      );
    } catch (e) {
      print('❌ Error sending order edit notification: $e');
    }
  }

  /// Notify admin when order is cancelled
  static Future<void> notifyAdminOfOrderCancellation({
    required String orderId,
    required String orderNumber,
    required String customerPhone,
    required String reason,
  }) async {
    try {
      print('🔔 Sending order cancellation notification to admins');

      String body = 'Order ID: $orderNumber\n'
          'Client ID: $customerPhone\n'
          'Reason: $reason';

      await NotificationService.sendNotificationToAdmins(
        title: 'Order Cancelled',
        body: body,
        data: {
          'type': 'order_cancellation',
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerPhone': customerPhone,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Save notification
      await _saveOrderNotification(
        orderId: orderId,
        type: 'order_cancellation',
        title: 'Order Cancelled',
        body: body,
        data: {
          'orderNumber': orderNumber,
          'customerPhone': customerPhone,
          'reason': reason,
        },
        forAdmin: true,
      );
    } catch (e) {
      print('❌ Error sending order cancellation notification: $e');
    }
  }

  /// Notify customer when order status changes
  static Future<void> notifyCustomerOfStatusChange({
    required String orderId,
    required String orderNumber,
    required String customerId,
    required String customerFcmToken,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      print('🔔 Sending status change notification to customer');

      String title = 'Order Status Updated';
      String body = 'Order #$orderNumber: ${_formatStatus(newStatus)}';

      // Send FCM notification to customer using the new system
      if (customerFcmToken.isNotEmpty) {
        await FcmService.sendToMultipleTokens(
          tokens: [customerFcmToken],
          title: title,
          body: body,
          data: {
            'type': 'status_change',
            'orderId': orderId,
            'orderNumber': orderNumber,
            'oldStatus': oldStatus,
            'newStatus': newStatus,
            'customerId': customerId,
            'route': '/orders/track',
          },
        );
      }

      // Save notification to order's subcollection for customer
      await _saveOrderNotification(
        orderId: orderId,
        type: 'status_change',
        title: title,
        body: body,
        data: {
          'orderNumber': orderNumber,
          'oldStatus': oldStatus,
          'newStatus': newStatus,
          'customerId': customerId,
        },
        forAdmin: false,
      );

      print('✅ Status change notification sent to customer');
    } catch (e) {
      print('❌ Error sending status change notification: $e');
    }
  }

  /// Notify delivery partner when order is assigned
  static Future<void> notifyDeliveryPartnerOfAssignment({
    required String orderId,
    required String orderNumber,
    required String deliveryPartnerId,
    required String customerName,
    required String deliveryAddress,
    required double totalAmount,
    required int itemCount,
    String? specialInstructions,
  }) async {
    try {
      print('🔔 Sending order assignment notification to delivery partner');

      // Get delivery partner's FCM token
      DocumentSnapshot deliveryDoc = await _firestore
          .collection('delivery')
          .doc(deliveryPartnerId)
          .get();

      if (!deliveryDoc.exists) {
        print('❌ Delivery partner not found: $deliveryPartnerId');
        return;
      }

      Map<String, dynamic> deliveryData = deliveryDoc.data() as Map<String, dynamic>;
      String? fcmToken = deliveryData['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ No FCM token found for delivery partner: $deliveryPartnerId');
        return;
      }

      String title = 'New Order Assignment';
      String body = 'Order ID: $orderNumber\n'
          'Customer: $customerName\n'
          'Address: $deliveryAddress\n'
          'Amount: ₹${totalAmount.toStringAsFixed(2)}\n'
          'Items: $itemCount';

      if (specialInstructions != null && specialInstructions.isNotEmpty) {
        body += '\nSpecial Instructions: $specialInstructions';
      }

      // Send FCM notification
      await FcmService.sendToMultipleTokens(
        tokens: [fcmToken],
        title: title,
        body: body,
        data: {
          'type': 'order_assignment',
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerName': customerName,
          'deliveryAddress': deliveryAddress,
          'totalAmount': totalAmount.toString(),
          'itemCount': itemCount.toString(),
          'specialInstructions': specialInstructions,
        },
      );

      // Save notification to delivery partner's notifications
      await _firestore
          .collection('delivery')
          .doc(deliveryPartnerId)
          .collection('notifications')
          .add({
        'type': 'order_assignment',
        'title': title,
        'body': body,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'notifiedAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'customerName': customerName,
          'deliveryAddress': deliveryAddress,
          'totalAmount': totalAmount,
          'itemCount': itemCount,
          'specialInstructions': specialInstructions,
        },
      });

      print('✅ Order assignment notification sent successfully');
    } catch (e) {
      print('❌ Error sending order assignment notification: $e');
    }
  }

  /// Helper method to save notifications
  static Future<void> _saveOrderNotification({
    required String orderId,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required bool forAdmin,
  }) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('notifications')
          .add({
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'notifiedAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'forAdmin': forAdmin,
        'read': false,
      });
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  /// Set up listener for order changes
  static void setupOrderListener() {
    _firestore
        .collection('orders')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final orderId = change.doc.id;
        final orderNumber = data['orderNumber'] ?? 'N/A';
        final customerId = data['customerId'] ?? 'Unknown';
        final customerPhone = data['customerPhone'] ?? 'Unknown';

        switch (change.type) {
          case DocumentChangeType.added:
            // Handle new order
            if (_isRecentChange(data['createdAt'])) {
              final customerDoc = await _firestore
                  .collection('customers')
                  .doc(customerId)
                  .get();

              if (customerDoc.exists) {
                final customerData = customerDoc.data() as Map<String, dynamic>;
                
                await notifyAdminOfNewOrder(
                  orderId: orderId,
                  orderNumber: orderNumber,
                  customerId: customerId,
                  customerName: customerData['name'] ?? 'Unknown',
                  customerPhone: customerPhone,
                  totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
                  itemCount: (data['items'] as List?)?.length ?? 0,
                );
              }
            }
            break;

          case DocumentChangeType.modified:
            // Get previous version of the document
            final oldData = change.doc.metadata.hasPendingWrites
                ? null
                : (await _firestore.collection('orders').doc(orderId).get()).data();

            if (oldData != null) {
              // Check for status change
              final oldStatus = oldData['status'];
              final newStatus = data['status'];
              
              if (oldStatus != newStatus) {
                // Notify customer of status change
                final customerFcmToken = await _getCustomerFcmToken(customerId);
                if (customerFcmToken != null) {
                  await notifyCustomerOfStatusChange(
                    orderId: orderId,
                    orderNumber: orderNumber,
                    customerId: customerId,
                    customerFcmToken: customerFcmToken,
                    oldStatus: oldStatus,
                    newStatus: newStatus,
                  );
                }

                // If order is cancelled, notify admin
                if (newStatus == 'cancelled') {
                  await notifyAdminOfOrderCancellation(
                    orderId: orderId,
                    orderNumber: orderNumber,
                    customerPhone: customerPhone,
                    reason: data['cancelReason'] ?? 'No reason provided',
                  );
                }

                // If order is assigned to delivery partner, notify them
                if (newStatus == 'assigned' && data['assignedDeliveryPerson'] != null) {
                  final customerDoc = await _firestore
                      .collection('customers')
                      .doc(customerId)
                      .get();

                  if (customerDoc.exists) {
                    final customerData = customerDoc.data() as Map<String, dynamic>;
                    await notifyDeliveryPartnerOfAssignment(
                      orderId: orderId,
                      orderNumber: orderNumber,
                      deliveryPartnerId: data['assignedDeliveryPerson'],
                      customerName: customerData['name'] ?? 'Unknown',
                      deliveryAddress: data['deliveryAddress'] ?? 'Address not provided',
                      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
                      itemCount: (data['items'] as List?)?.length ?? 0,
                      specialInstructions: data['specialInstructions'],
                    );
                  }
                }
              }

              // Check for other changes
              final changes = _getChanges(oldData, data);
              if (changes.isNotEmpty) {
                await notifyAdminOfOrderEdit(
                  orderId: orderId,
                  orderNumber: orderNumber,
                  customerPhone: customerPhone,
                  changes: changes,
                );
              }
            }
            break;

          default:
            break;
        }
      }
    });
  }

  /// Helper method to check if a change is recent (within last 5 minutes)
  static bool _isRecentChange(dynamic timestamp) {
    if (timestamp == null) return false;
    final createdAt = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    return now.difference(createdAt).inMinutes <= 5;
  }

  /// Helper method to get customer's FCM token
  static Future<String?> _getCustomerFcmToken(String customerId) async {
    try {
      final doc = await _firestore
          .collection('customers')
          .doc(customerId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fcmToken'] as String?;
      }
    } catch (e) {
      print('Error getting customer FCM token: $e');
    }
    return null;
  }

  /// Helper method to get changes between old and new data
  static Map<String, dynamic> _getChanges(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final changes = <String, dynamic>{};
    
    // Fields to check for changes
    final fieldsToCheck = {
      'totalAmount': 'Total Amount',
      'items': 'Items',
      'deliveryAddress': 'Delivery Address',
      'pickupAddress': 'Pickup Address',
      'specialInstructions': 'Special Instructions',
      'paymentMethod': 'Payment Method',
      'status': 'Status',
      'assignedDeliveryPerson': 'Assigned Delivery Person',
    };

    for (var entry in fieldsToCheck.entries) {
      final field = entry.key;
      final displayName = entry.value;
      
      if (!_areEqual(oldData[field], newData[field])) {
        changes[displayName] = newData[field].toString();
      }
    }

    return changes;
  }

  /// Helper method to compare values
  static bool _areEqual(dynamic val1, dynamic val2) {
    if (val1 == null && val2 == null) return true;
    if (val1 == null || val2 == null) return false;
    
    if (val1 is List && val2 is List) {
      if (val1.length != val2.length) return false;
      for (var i = 0; i < val1.length; i++) {
        if (!_areEqual(val1[i], val2[i])) return false;
      }
      return true;
    }
    
    return val1 == val2;
  }

  /// Get stream of order notifications for admin dashboard
  static Stream<List<Map<String, dynamic>>> getOrderNotificationsStream() {
    return _firestore
        .collectionGroup('notifications')
        .where('type', whereIn: ['new_order', 'order_edit', 'order_cancellation'])
        .where('forAdmin', isEqualTo: true)
        .orderBy('notifiedAt', descending: true)
        .limit(50) // Limit to recent 50 notifications
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String orderId, String notificationId) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Format status for display
  static String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
} 