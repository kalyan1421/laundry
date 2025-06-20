// services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message: ${message.notification?.title}');
      showNotification(
        message.notification?.title ?? '',
        message.notification?.body ?? '',
      );
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened: ${message.notification?.title}');
      // Handle navigation based on message data
    });
  }

  void showNotification(String title, String body) {
    Fluttertoast.showToast(
      msg: '$title\n$body',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Static method to send notification to all admins
  static Future<void> sendNotificationToAdmins({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Get all admins (don't filter by FCM token to avoid issues with null checks)
      QuerySnapshot adminSnapshot = await firestore
          .collection('admins')
          .where('isActive', isEqualTo: true)
          .get();
      
      int successCount = 0;
      for (QueryDocumentSnapshot doc in adminSnapshot.docs) {
        try {
          await _sendNotificationToAdmin(
            adminId: doc.id,
            title: title,
            body: body,
            data: data,
          );
          successCount++;
        } catch (e) {
          print("Error sending notification to admin ${doc.id}: $e");
        }
      }
      
      print("Notifications sent to $successCount admins");
    } catch (e) {
      print("Error sending notifications to admins: $e");
    }
  }

  // Private method to send notification to specific admin
  static Future<void> _sendNotificationToAdmin({
    required String adminId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      print("📩 Attempting to send notification to admin: $adminId");
      
      final notificationData = {
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': data?['type'] ?? 'delivery_update',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print("📝 Notification data: $notificationData");
      
      // Save notification to admin's notifications collection
      DocumentReference docRef = await firestore
          .collection('admins')
          .doc(adminId)
          .collection('notifications')
          .add(notificationData);
      
      print("✅ Notification sent to admin $adminId with ID: ${docRef.id}");
    } catch (e) {
      print("❌ Error sending notification to admin $adminId: $e");
      // Re-throw the error so it can be caught by the calling function
      rethrow;
    }
  }
}
