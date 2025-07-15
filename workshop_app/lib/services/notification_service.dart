import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/order.dart' as workshop_order;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  String? _fcmToken;
  
  // Get FCM token
  String? get fcmToken => _fcmToken;

  // Initialize notification service
  Future<void> initialize() async {
    try {
      _logger.i('Initializing notification service');
      
      // Request permission
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM token
      await _getFCMToken();
      
      // Configure message handlers
      _configureMessageHandlers();
      
      _logger.i('Notification service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing notification service: $e');
      throw Exception('Failed to initialize notification service: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      _logger.i('Requesting notification permissions');
      
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      _logger.i('Notification permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _logger.w('Notification permissions denied');
        throw Exception('Notification permissions denied');
      }
    } catch (e) {
      _logger.e('Error requesting permissions: $e');
      throw Exception('Failed to request notification permissions: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      _logger.i('Initializing local notifications');
      
      const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInitializationSettings = DarwinInitializationSettings();
      
      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );
      
      _logger.i('Local notifications initialized successfully');
    } catch (e) {
      _logger.e('Error initializing local notifications: $e');
      throw Exception('Failed to initialize local notifications: $e');
    }
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _logger.i('Getting FCM token');
      _fcmToken = await _firebaseMessaging.getToken();
      _logger.i('FCM token retrieved: ${_fcmToken?.substring(0, 20)}...');
    } catch (e) {
      _logger.e('Error getting FCM token: $e');
      throw Exception('Failed to get FCM token: $e');
    }
  }

  // Configure message handlers
  void _configureMessageHandlers() {
    try {
      _logger.i('Configuring message handlers');
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      _logger.i('Message handlers configured successfully');
    } catch (e) {
      _logger.e('Error configuring message handlers: $e');
    }
  }

  // Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      _logger.i('Handling foreground message: ${message.messageId}');
      
      // Show local notification
      await _showLocalNotification(message);
      
      _logger.i('Foreground message handled successfully');
    } catch (e) {
      _logger.e('Error handling foreground message: $e');
    }
  }

  // Handle background message (static method required)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      final logger = Logger();
      logger.i('Handling background message: ${message.messageId}');
      
      // Process background message
      // Can't update UI here, only perform background tasks
      
      logger.i('Background message handled successfully');
    } catch (e) {
      Logger().e('Error handling background message: $e');
    }
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      _logger.i('Handling notification tap: ${message.messageId}');
      
      // Navigate to appropriate screen based on message data
      final data = message.data;
      
      if (data.containsKey('orderId')) {
        // Navigate to order details
        _logger.i('Navigating to order: ${data['orderId']}');
        // Navigation logic would go here
      }
      
      _logger.i('Notification tap handled successfully');
    } catch (e) {
      _logger.e('Error handling notification tap: $e');
    }
  }

  // Handle local notification tap
  Future<void> _onLocalNotificationTap(NotificationResponse response) async {
    try {
      _logger.i('Local notification tapped: ${response.payload}');
      
      if (response.payload != null) {
        // Handle payload data
        _logger.i('Processing notification payload: ${response.payload}');
        // Navigation logic would go here
      }
      
      _logger.i('Local notification tap handled successfully');
    } catch (e) {
      _logger.e('Error handling local notification tap: $e');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      _logger.i('Showing local notification');
      
      const androidDetails = AndroidNotificationDetails(
        'workshop_orders',
        'Workshop Orders',
        channelDescription: 'Notifications for workshop order updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      
      const iosDetails = DarwinNotificationDetails();
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Workshop Update',
        message.notification?.body ?? 'You have a new update',
        notificationDetails,
        payload: message.data.toString(),
      );
      
      _logger.i('Local notification shown successfully');
    } catch (e) {
      _logger.e('Error showing local notification: $e');
    }
  }

  // Send notification to customer
  Future<void> sendNotificationToCustomer({
    required String customerId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      _logger.i('Sending notification to customer: $customerId');
      
      // Get customer's FCM token from Firestore
      final customerDoc = await _firestore.collection('customers').doc(customerId).get();
      
      if (!customerDoc.exists) {
        _logger.w('Customer not found: $customerId');
        throw Exception('Customer not found');
      }
      
      final customerData = customerDoc.data() as Map<String, dynamic>;
      final fcmToken = customerData['fcmToken'] as String?;
      
      if (fcmToken == null) {
        _logger.w('Customer FCM token not found: $customerId');
        throw Exception('Customer FCM token not found');
      }
      
      // Send notification using Firebase Cloud Functions
      await _firestore.collection('notifications').add({
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'customerId': customerId,
        'type': 'order_update',
      });
      
      _logger.i('Notification sent to customer successfully');
    } catch (e) {
      _logger.e('Error sending notification to customer: $e');
      throw Exception('Failed to send notification to customer: $e');
    }
  }

  // Send order completion notification
  Future<void> sendOrderCompletionNotification({
    required workshop_order.WorkshopOrder order,
    required String workshopMemberName,
  }) async {
    try {
      _logger.i('Sending order completion notification for order: ${order.id}');
      
      await sendNotificationToCustomer(
        customerId: order.customerId,
        title: 'Order Completed! 🎉',
        body: 'Your order #${order.id.substring(0, 8)} has been completed by $workshopMemberName. Ready for pickup!',
        data: {
          'orderId': order.id,
          'type': 'order_completed',
          'status': 'completed',
          'workshopMember': workshopMemberName,
        },
      );
      
      _logger.i('Order completion notification sent successfully');
    } catch (e) {
      _logger.e('Error sending order completion notification: $e');
      throw Exception('Failed to send order completion notification: $e');
    }
  }

  // Send order processing notification
  Future<void> sendOrderProcessingNotification({
    required workshop_order.WorkshopOrder order,
    required String workshopMemberName,
  }) async {
    try {
      _logger.i('Sending order processing notification for order: ${order.id}');
      
      await sendNotificationToCustomer(
        customerId: order.customerId,
        title: 'Order in Progress 👷‍♂️',
        body: 'Your order #${order.id.substring(0, 8)} is now being processed by $workshopMemberName.',
        data: {
          'orderId': order.id,
          'type': 'order_processing',
          'status': 'processing',
          'workshopMember': workshopMemberName,
        },
      );
      
      _logger.i('Order processing notification sent successfully');
    } catch (e) {
      _logger.e('Error sending order processing notification: $e');
      throw Exception('Failed to send order processing notification: $e');
    }
  }

  // Send order update notification (generic method)
  Future<void> sendOrderUpdateNotification({
    required String orderId,
    required String customerId,
    required String status,
    required String message,
  }) async {
    try {
      _logger.i('Sending order update notification for order: $orderId');

      await sendNotificationToCustomer(
        customerId: customerId,
        title: 'Order Update',
        body: message,
        data: {
          'orderId': orderId,
          'type': 'order_update',
          'status': status,
        },
      );

      _logger.i('Order update notification sent successfully');
    } catch (e) {
      _logger.e('Error sending order update notification: $e');
      throw Exception('Failed to send order update notification: $e');
    }
  }

  // Send order ready notification
  Future<void> sendOrderReadyNotification({
    required workshop_order.WorkshopOrder order,
    required String workshopMemberName,
  }) async {
    try {
      _logger.i('Sending order ready notification for order: ${order.id}');
      
      await sendNotificationToCustomer(
        customerId: order.customerId,
        title: 'Order Ready for Pickup! 📦',
        body: 'Your order #${order.id.substring(0, 8)} is ready for pickup. Please visit our store.',
        data: {
          'orderId': order.id,
          'type': 'order_ready',
          'status': 'ready',
          'workshopMember': workshopMemberName,
        },
      );
      
      _logger.i('Order ready notification sent successfully');
    } catch (e) {
      _logger.e('Error sending order ready notification: $e');
      throw Exception('Failed to send order ready notification: $e');
    }
  }

  // Send custom notification
  Future<void> sendCustomNotification({
    required String customerId,
    required String title,
    required String body,
    String? orderId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _logger.i('Sending custom notification to customer: $customerId');
      
      final data = <String, dynamic>{
        'type': 'custom',
        ...?additionalData,
      };
      
      if (orderId != null) {
        data['orderId'] = orderId;
      }
      
      await sendNotificationToCustomer(
        customerId: customerId,
        title: title,
        body: body,
        data: data,
      );
      
      _logger.i('Custom notification sent successfully');
    } catch (e) {
      _logger.e('Error sending custom notification: $e');
      throw Exception('Failed to send custom notification: $e');
    }
  }

  // Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    String? customerId,
    int limit = 50,
  }) async {
    try {
      _logger.i('Getting notification history');
      
      Query query = _firestore
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }
      
      final querySnapshot = await query.get();
      
      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      _logger.i('Retrieved ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      _logger.e('Error getting notification history: $e');
      throw Exception('Failed to get notification history: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      _logger.i('Subscribing to topic: $topic');
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.i('Subscribed to topic successfully');
    } catch (e) {
      _logger.e('Error subscribing to topic: $e');
      throw Exception('Failed to subscribe to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      _logger.i('Unsubscribing from topic: $topic');
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic successfully');
    } catch (e) {
      _logger.e('Error unsubscribing from topic: $e');
      throw Exception('Failed to unsubscribe from topic: $e');
    }
  }

  // Update FCM token
  Future<void> updateFCMToken(String? newToken) async {
    try {
      if (newToken != null) {
        _fcmToken = newToken;
        _logger.i('FCM token updated: ${_fcmToken?.substring(0, 20)}...');
      }
    } catch (e) {
      _logger.e('Error updating FCM token: $e');
    }
  }

  // Clear local notifications
  Future<void> clearAllNotifications() async {
    try {
      _logger.i('Clearing all local notifications');
      await _localNotifications.cancelAll();
      _logger.i('All local notifications cleared');
    } catch (e) {
      _logger.e('Error clearing notifications: $e');
    }
  }

  // Clear specific notification
  Future<void> clearNotification(int notificationId) async {
    try {
      _logger.i('Clearing notification: $notificationId');
      await _localNotifications.cancel(notificationId);
      _logger.i('Notification cleared successfully');
    } catch (e) {
      _logger.e('Error clearing notification: $e');
    }
  }

  // Check notification permissions
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      _logger.e('Error checking notification permissions: $e');
      return false;
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      _logger.i('Disposing notification service');
      // Clean up resources if needed
      _logger.i('Notification service disposed');
    } catch (e) {
      _logger.e('Error disposing notification service: $e');
    }
  }
} 