import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class OrderNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send notification to admin when a new order is placed
  static Future<void> notifyAdminOfNewOrder({
    required String orderId,
    required String orderNumber,
    required double totalAmount,
    required int itemCount,
    required String pickupAddress,
    String? specialInstructions,
  }) async {
    try {
      print('🔔 Sending new order notification to admin');

      // Get current user's data
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return;
      }

      final customerDoc = await _firestore
          .collection('customer')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) {
        print('❌ Customer document not found');
        return;
      }

      final customerData = customerDoc.data() as Map<String, dynamic>;

      // Save notification to orders collection
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('notifications')
          .add({
        'type': 'new_order',
        'title': 'New Order Received',
        'body': 'Order #$orderNumber has been placed',
        'data': {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerId': user.uid,
          'customerName': customerData['name'] ?? 'Unknown',
          'customerPhone': customerData['phoneNumber'] ?? 'Unknown',
          'totalAmount': totalAmount,
          'itemCount': itemCount,
          'pickupAddress': pickupAddress,
          'specialInstructions': specialInstructions,
        },
        'notifiedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'forAdmin': true,
        'read': false,
      });

      print('✅ Order notification sent to admin successfully');
    } catch (e) {
      print('❌ Error sending order notification to admin: $e');
    }
  }

  /// Send notification to admin when order is cancelled by customer
  static Future<void> notifyAdminOfOrderCancellation({
    required String orderId,
    required String orderNumber,
    required String reason,
  }) async {
    try {
      print('🔔 Sending order cancellation notification to admin');

      // Get current user's data
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return;
      }

      final customerDoc = await _firestore
          .collection('customer')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) {
        print('❌ Customer document not found');
        return;
      }

      final customerData = customerDoc.data() as Map<String, dynamic>;

      // Save notification to orders collection
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('notifications')
          .add({
        'type': 'order_cancellation',
        'title': 'Order Cancelled',
        'body': 'Order #$orderNumber has been cancelled by customer',
        'data': {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerId': user.uid,
          'customerName': customerData['name'] ?? 'Unknown',
          'customerPhone': customerData['phoneNumber'] ?? 'Unknown',
          'reason': reason,
        },
        'notifiedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'forAdmin': true,
        'read': false,
      });

      print('✅ Order cancellation notification sent to admin successfully');
    } catch (e) {
      print('❌ Error sending order cancellation notification to admin: $e');
    }
  }

  /// Send notification when order is edited
  static Future<void> notifyOrderEdit({
    required String orderId,
    required String orderNumber,
    required Map<String, dynamic> changes,
  }) async {
    try {
      print('🔔 Sending order edit notification to admins');

      // Get current user's data
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return;
      }

      final customerDoc = await _firestore
          .collection('customer')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) {
        print('❌ Customer document not found');
        return;
      }

      final customerData = customerDoc.data() as Map<String, dynamic>;
      final String changesText = _formatChanges(changes);

      String title = 'Order Modified';
      String body = 'Order #$orderNumber has been modified by ${customerData['name'] ?? 'Customer'}';

      // Send FCM notifications to all admins
      try {
        final adminSnapshot = await _firestore
            .collection('admins')
            .where('isActive', isEqualTo: true)
            .get();

        for (var adminDoc in adminSnapshot.docs) {
          final adminData = adminDoc.data();
          final adminFcmToken = adminData['fcmToken'] as String?;
          
          if (adminFcmToken != null && adminFcmToken.isNotEmpty) {
            await _firestore.collection('fcm_notifications').add({
              'token': adminFcmToken,
              'title': title,
              'body': body,
              'data': {
                'type': 'order_edit',
                'orderId': orderId,
                'orderNumber': orderNumber,
                'customerId': user.uid,
                'customerName': customerData['name'] ?? 'Unknown',
                'customerPhone': customerData['phoneNumber'] ?? 'Unknown',
                'changes': changesText,
                'route': '/admin/orders/$orderId',
              },
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'pending',
              'type': 'direct_token',
              'priority': 'high',
            });
          }
        }
        
        print('✅ FCM notifications queued for ${adminSnapshot.docs.length} admins');
      } catch (e) {
        print('❌ Error sending FCM notifications to admins: $e');
      }

      // Save notification to orders collection
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('notifications')
          .add({
        'type': 'order_edit',
        'title': title,
        'body': body,
        'data': {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerId': user.uid,
          'customerName': customerData['name'] ?? 'Unknown',
          'customerPhone': customerData['phoneNumber'] ?? 'Unknown',
          'changes': changes,
          'changesText': changesText,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'forAdmin': true,
        'read': false,
      });

      print('✅ Order edit notification saved successfully');
    } catch (e) {
      print('❌ Error sending order edit notification: $e');
    }
  }

  /// Format changes for notification
  static String _formatChanges(Map<String, dynamic> changes) {
    List<String> formattedChanges = [];
    changes.forEach((key, value) {
      formattedChanges.add('$key: $value');
    });
    return formattedChanges.join('\n');
  }

  /// Send notification when order status changes
  static Future<void> notifyStatusChange({
    required String orderId,
    required String orderNumber,
    required String oldStatus,
    required String newStatus,
    required String customerId,
  }) async {
    try {
      print('🔔 Sending status change notification');

      final String title = 'Order Status Updated';
      final String body = 'Order #$orderNumber: ${_formatStatus(newStatus)}';

      // Save notification to orders collection
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('notifications')
          .add({
        'type': 'status_change',
        'title': title,
        'body': body,
        'data': {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerId': customerId,
          'oldStatus': oldStatus,
          'newStatus': newStatus,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'forAdmin': false,
        'read': false,
      });

      // Show local notification if available
      await NotificationService.showLocalNotification(
        title: title,
        body: body,
        payload: {
          'type': 'status_change',
          'orderId': orderId,
          'orderNumber': orderNumber,
          'oldStatus': oldStatus,
          'newStatus': newStatus,
        }.toString(),
      );

      print('✅ Status change notification sent successfully');
    } catch (e) {
      print('❌ Error sending status change notification: $e');
    }
  }

  /// Set up listener for order status changes
  static void setupOrderStatusListener() {
    // Get current user
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No authenticated user found for order status listener');
      return;
    }

    print('✅ Setting up order status listener for user: ${user.uid}');

    // Listen to user's orders
    _firestore
        .collection('orders')
        .where('customerId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final orderId = change.doc.id;
        final orderNumber = data['orderNumber'] ?? 'N/A';

        if (change.type == DocumentChangeType.modified) {
          // Get previous version of the document
          final oldData = change.doc.metadata.hasPendingWrites
              ? null
              : (await _firestore.collection('orders').doc(orderId).get()).data();

          if (oldData != null) {
            // Check for status change
            final oldStatus = oldData['status'];
            final newStatus = data['status'];

            if (oldStatus != newStatus) {
              print('🔔 Order status changed: $orderId from $oldStatus to $newStatus');
              
              // Show local notification for status change
              String title = _formatStatus(newStatus);
              String body = 'Order #$orderNumber has been ${newStatus.toLowerCase()}';

              await NotificationService.showLocalNotification(
                title: title,
                body: body,
                payload: {
                  'type': 'status_change',
                  'orderId': orderId,
                  'orderNumber': orderNumber,
                  'oldStatus': oldStatus,
                  'newStatus': newStatus,
                }.toString(),
              );

              // Save notification to order's notifications collection
              try {
                await _firestore
                    .collection('orders')
                    .doc(orderId)
                    .collection('notifications')
                    .add({
                  'type': 'status_change',
                  'title': title,
                  'body': body,
                  'data': {
                    'orderId': orderId,
                    'orderNumber': orderNumber,
                    'oldStatus': oldStatus,
                    'newStatus': newStatus,
                  },
                  'notifiedAt': FieldValue.serverTimestamp(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'status': 'sent',
                  'forAdmin': false,
                  'read': false,
                });
                print('✅ Status change notification saved to database');
              } catch (e) {
                print('❌ Error saving status change notification: $e');
              }
            }

            // Check for delivery person assignment
            final oldDeliveryPerson = oldData['assignedDeliveryPerson'];
            final newDeliveryPerson = data['assignedDeliveryPerson'];

            if (oldDeliveryPerson != newDeliveryPerson && newDeliveryPerson != null) {
              String title = 'Delivery Partner Assigned';
              String body = 'Order #$orderNumber has been assigned to a delivery partner';

              await NotificationService.showLocalNotification(
                title: title,
                body: body,
                payload: {
                  'type': 'delivery_assignment',
                  'orderId': orderId,
                  'orderNumber': orderNumber,
                  'deliveryPartnerId': newDeliveryPerson,
                }.toString(),
              );
            }
          }
        }
      }
    }, onError: (error) {
      print('❌ Error in order status listener: $error');
    });
  }

  /// Format status for display
  static String _formatStatus(String status) {
    // Map of status codes to user-friendly messages
    final statusMessages = {
      'pending': 'Order Placed',
      'confirmed': 'Order Confirmed',
      'assigned': 'Delivery Partner Assigned',
      'picked_up': 'Picked Up',
      'processing': 'In Processing',
      'ready_for_delivery': 'Ready for Delivery',
      'out_for_delivery': 'Out for Delivery',
      'delivered': 'Delivered',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    };

    // Return mapped message or fallback to formatted status
    return statusMessages[status] ?? status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get stream of order notifications for customer
  static Stream<List<Map<String, dynamic>>> getOrderNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collectionGroup('notifications')
        .where('data.customerId', isEqualTo: user.uid)
        .orderBy('notifiedAt', descending: true)
        .limit(50)
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
} 