import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  static bool _localNotificationsAvailable = false;

  // Initialize notification service
  static Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('customer granted permission');
      } else {
        print('customer declined or has not accepted permission');
      }

      // Try to initialize local notifications, but don't fail if it's not available
      await _initializeLocalNotifications();

      // Handle FCM token refresh
      messaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        // Save the new token to Firestore
        _saveRefreshedTokenToFirestore(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
      // Don't throw the error, just log it and continue
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          print('Notification tapped: ${response.payload}');
        },
      );
      
      _localNotificationsAvailable = true;
      print('Local notifications initialized successfully');
    } catch (e) {
      print('Local notifications not available: $e');
      _localNotificationsAvailable = false;
      flutterLocalNotificationsPlugin = null;
    }
  }

  // Get FCM token for current   customer
  static Future<String?> getToken() async {
    try {
      String? token = await messaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Save customer's FCM token to Firestore
  static Future<void> saveTokenToFirestore() async {
    try {
      User? customer = FirebaseAuth.instance.currentUser;
      if (customer == null) return;

      String? token = await getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('customer')
          .doc(customer.uid)
          .update({
        'fcmToken': token,
        'lastTokenUpdate': Timestamp.now(),
      });
      
      print('Token saved to Firestore');
    } catch (e) {
      print('Error saving token to Firestore: $e');
    }
  }

  // Save refreshed FCM token to Firestore
  static Future<void> _saveRefreshedTokenToFirestore(String newToken) async {
    try {
      User? customer = FirebaseAuth.instance.currentUser;
      if (customer == null) {
        print('No authenticated user found for token refresh');
        return;
      }

      await FirebaseFirestore.instance
          .collection('customer')
          .doc(customer.uid)
          .update({
        'fcmToken': newToken,
        'lastTokenUpdate': Timestamp.now(),
      });
      
      print('Refreshed FCM token saved to Firestore');
    } catch (e) {
      print('Error saving refreshed FCM token: $e');
    }
  }

  // Send notification when new order is placed
  static Future<void> sendNewOrderNotificationToAdmin(String orderId) async {
    try {
      print('🔔 Order $orderId created - notification will be sent automatically');
      
      // The Cloud Function 'sendOrderNotificationToAdmin' will automatically trigger
      // when the order document is created in Firestore with proper order details.
      // No manual call needed - the automatic trigger handles everything.
      
      // Just log that the notification system is active
      print('✅ Automatic notification system active for order: $orderId');
      print('📱 Admin will receive notification with order details automatically');
      
      // Note: The Cloud Function will update notificationSentToAdmin: true automatically
      // after sending the notification successfully
      
    } catch (e) {
      print('❌ Error in notification logging: $e');
      
      // Only use fallback if there's a critical issue with the automatic system
      print('🔄 Using fallback notification method as backup');
      await _sendNotificationFallback(orderId);
    }
  }

  // Emergency fallback method for sending notifications directly
  // Only used if the automatic Cloud Function system fails
  static Future<void> _sendNotificationFallback(String orderId) async {
    try {
      print('🚨 EMERGENCY: Using fallback notification method for order: $orderId');
      print('⚠️ This means the automatic Cloud Function may have failed');
      
      // Get all admin tokens
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('isActive', isEqualTo: true)
          .get();

      List<String> adminTokens = [];
      for (QueryDocumentSnapshot doc in adminSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['fcmToken'] != null) {
          adminTokens.add(data['fcmToken']);
          print('📱 Emergency: Found admin token: ${data['fcmToken'].substring(0, 20)}...');
        }
      }

      if (adminTokens.isEmpty) {
        print('❌ CRITICAL: No admin tokens found in emergency fallback method');
        return;
      }

      print('🔧 Emergency: Found ${adminTokens.length} admin tokens for fallback notification');

      // Send emergency notification to all admins
      await _sendNotificationToTokens(
        tokens: adminTokens,
        title: 'New Order Received (Emergency)',
        body: 'A new order #$orderId has been placed and needs assignment.',
        data: {
          'type': 'new_order',
          'orderId': orderId,
          'route': '/admin/orders',
        },
      );

      // Update order to mark notification sent
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'notificationSentToAdmin': true});
          
      print('✅ Emergency fallback notification completed for order: $orderId');
          
    } catch (e) {
      print('❌ CRITICAL ERROR in emergency fallback notification: $e');
    }
  }

  // Send notification when order is assigned to delivery person
  static Future<void> sendOrderAssignmentNotification({
    required String orderId,
    required String deliveryPersonId,
    required String customerName,
    required String pickupAddress,
  }) async {
    try {
      // Get delivery person's token
      DocumentSnapshot deliveryPersonDoc = await FirebaseFirestore.instance
          .collection('delivery')
          .doc(deliveryPersonId)
          .get();

      if (!deliveryPersonDoc.exists) {
        print('Delivery person not found');
        return;
      }

      Map<String, dynamic> data = deliveryPersonDoc.data() as Map<String, dynamic>;
      String? token = data['fcmToken'];

      if (token == null) {
        print('Delivery person token not found');
        return;
      }

      // Send notification
      await _sendNotificationToTokens(
        tokens: [token],
        title: 'New Order Assignment',
        body: 'You have been assigned order #$orderId for pickup from $pickupAddress',
        data: {
          'type': 'order_assignment',
          'orderId': orderId,
          'route': '/delivery/orders',
        },
      );

      // Update order to mark notification sent
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'notificationSentToDeliveryPerson': true});
          
    } catch (e) {
      print('Error sending assignment notification: $e');
    }
  }

  // Send status update notification to customer
  static Future<void> sendStatusUpdateNotification({
    required String orderId,
    required String customerId,
    required String status,
    required String statusMessage,
  }) async {
    try {
      // Get customer's token
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customer')
          .doc(customerId)
          .get();

      if (!customerDoc.exists) {
        print('Customer not found');
        return;
      }

      Map<String, dynamic> data = customerDoc.data() as Map<String, dynamic>;
      String? token = data['fcmToken'];

      if (token == null) {
        print('Customer token not found');
        return;
      }

      // Send notification
      await _sendNotificationToTokens(
        tokens: [token],
        title: 'Order Update',
        body: 'Your order #$orderId status: $statusMessage',
        data: {
          'type': 'status_update',
          'orderId': orderId,
          'status': status,
          'route': '/track-order',
        },
      );
      
    } catch (e) {
      print('Error sending status update notification: $e');
    }
  }

  // Generic method to send notifications to multiple tokens
  static Future<void> _sendNotificationToTokens({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Create notification documents for each token
      // This will trigger the Cloud Function to send FCM notifications
      for (String token in tokens) {
        try {
          await firestore.collection('fcm_notifications').add({
            'token': token,
            'title': title,
            'body': body,
            'data': data ?? {},
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'pending',
            'type': 'direct_token',
            'priority': 'high',
          });
          
          print("FCM: Notification queued for token: ${token.substring(0, 20)}...");
        } catch (e) {
          print("Error queuing notification for token $token: $e");
        }
      }
      
      print("FCM: ${tokens.length} notifications queued for sending");
    } catch (e) {
      print("Error in _sendNotificationToTokens: $e");
    }
  }

  // Send notification to topic (workaround for server-side messaging)
  static Future<void> _sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Note: Topic-based messaging requires server-side implementation
      // For now, we'll just ensure admins are subscribed to topics
      print('Topic notification would be sent to: $topic');
      print('Title: $title, Body: $body, Data: $data');
      
      // Alternative: Use local notifications on the admin device if it's running
      // This is a temporary workaround until proper server implementation
      
    } catch (e) {
      print('Error sending topic notification: $e');
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      
      // Show local notification only if available
      if (_localNotificationsAvailable) {
        await showLocalNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
        );
      } else {
        print('Local notifications not available, skipping local notification display');
      }
    }
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    // Handle background message logic here
  }

  // Handle message opened app
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('A new onMessageOpenedApp event was published!');
    print('Message data: ${message.data}');
    
    // Navigate to appropriate screen based on message data
    String? type = message.data['type'];
    String? orderId = message.data['orderId'];
    String? route = message.data['route'];
    
    if (type == 'status_change' && orderId != null) {
      // Navigate to track order screen
      _navigateToScreen('/track-order', arguments: orderId);
    } else if (type == 'order_assignment' && orderId != null) {
      // Navigate to track order screen
      _navigateToScreen('/track-order', arguments: orderId);
    } else if (route != null) {
      // Navigate to the specified route
      _navigateToScreen(route);
    } else {
      // Default navigation to home
      _navigateToScreen('/home');
    }
  }

  // Helper method to navigate to screens
  static void _navigateToScreen(String route, {Object? arguments}) {
    try {
      // Use the global navigator key to navigate
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed(route, arguments: arguments);
      } else {
        print('Navigator not available for navigation to: $route');
      }
    } catch (e) {
      print('Error navigating to $route: $e');
    }
  }

  // Show local notification (only if available)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_localNotificationsAvailable || flutterLocalNotificationsPlugin == null) {
      print('Local notifications not available');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'laundry_channel',
        'Laundry Management',
        channelDescription: 'Notifications for laundry management app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await flutterLocalNotificationsPlugin!.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Subscribe to order updates for delivery person
  static Future<void> subscribeToOrderUpdates(String deliveryPersonId) async {
    try {
      await messaging.subscribeToTopic('delivery_person_$deliveryPersonId');
    } catch (e) {
      print('Error subscribing to order updates: $e');
    }
  }

  // Subscribe to admin notifications
  static Future<void> subscribeToAdminNotifications() async {
    try {
      await messaging.subscribeToTopic('admin_notifications');
    } catch (e) {
      print('Error subscribing to admin notifications: $e');
    }
  }

  // Unsubscribe from topics
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}
