import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:admin_panel/main.dart'; // Assuming navigatorKey is in main.dart or accessible globally

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Assuming your admin users are in the 'users' collection with role 'admin'
  // or in a separate 'admins' collection. Adjust if necessary.
  final FirebaseAuth _auth = FirebaseAuth.instance; 

  Future<void> initialize(BuildContext? context) async {
    // Request permission (iOS and web)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Admin FCM: User granted permission');
      _saveTokenToFirestore(); // Save token once permission is granted
    } else {
      print('Admin FCM: User declined or has not accepted permission');
      return;
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token: token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Admin FCM: Got a message whilst in the foreground!');
      print('Admin FCM: Message data: ${message.data}');
      RemoteNotification? notification = message.notification;

      if (notification != null && context != null) {
        // Show an in-app notification (e.g., SnackBar)
        // Since flutter_local_notifications was rejected, we'll use a SnackBar.
        final snackBar = SnackBar(
          content: Text(notification.body ?? 'New order received!'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              if (message.data['orderId'] != null) {
                // Ensure navigatorKey is accessible and initialized
                navigatorKey.currentState?.pushNamed(
                  '/admin_order_details', // Your route for order details
                  arguments: message.data['orderId'],
                );
              }
            },
          ),
          duration: const Duration(seconds: 10), // Keep it visible longer
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

    // Handle notification tap when app is in background (but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Admin FCM: Message opened from background: ${message.data}');
      if (message.data['orderId'] != null) {
         navigatorKey.currentState?.pushNamed(
           '/admin_order_details', 
           arguments: message.data['orderId']
         );
      }
    });

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('Admin FCM: Message opened from terminated state: ${initialMessage.data}');
      if (initialMessage.data['orderId'] != null) {
        // Store the orderId and navigate after the app is fully initialized
        // This often requires a bit of coordination with your app's root widget
        // For simplicity, we'll try direct navigation if navigatorKey is ready.
        // In a more complex app, you might store this in a provider and handle post-initialization.
         WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.pushNamed(
              '/admin_order_details',
              arguments: initialMessage.data['orderId'],
            );
         });
      }
    }
  }

  Future<void> _saveTokenToFirestore({String? token}) async {
    String? currentToken = token ?? await _firebaseMessaging.getToken();
    print("Admin FCM Token: $currentToken");

    User? currentAdmin = _auth.currentUser;
    if (currentAdmin != null && currentToken != null) {
      try {
        // Assuming admin users are stored in the 'users' collection with a 'role' field
        // Or you might have a separate 'admins' collection.
        DocumentReference adminDocRef = _firestore.collection('users').doc(currentAdmin.uid);
        
        // Check if the user is indeed an admin before saving the token
        // This check depends on how you identify admins (e.g., a 'role' field)
        // For this example, we'll assume if they are in AuthProvider (admin app), they are an admin.
        // In a real scenario, you might want to verify their role from Firestore first.

        await adminDocRef.set(
          {'fcmToken': currentToken, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        print("Admin FCM token saved to Firestore for admin: ${currentAdmin.uid}");
      } catch (e) {
        print("Admin FCM: Error saving token to Firestore: $e");
      }
    } else {
      print("Admin FCM: No admin user logged in or token is null. Token not saved.");
    }
  }

  Future<void> deleteTokenForCurrentUser() async {
    User? currentAdmin = _auth.currentUser;
     if (currentAdmin != null) {
      try {
        await _firestore.collection('users').doc(currentAdmin.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        // You might also want to delete the instance ID token itself, though Firestore deletion is key for targeting
        // await _firebaseMessaging.deleteToken(); 
        print("Admin FCM token deleted from Firestore for admin: ${currentAdmin.uid}");
      } catch (e) {
         print("Admin FCM: Error deleting token from Firestore: $e");
      }
    }
  }
}

// Background message handler (must be a top-level function)
@pragma('vm:entry-point') // Ensures tree-shaking doesn't remove it
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, like Firestore,
  // make sure you call `initializeApp` before using them.
  // await Firebase.initializeApp(); // Often needed if you do more here
  print("Admin FCM: Handling a background message: ${message.messageId}");
  print("Admin FCM: Background message data: ${message.data}");
  // Note: You cannot update UI from here directly.
  // If flutter_local_notifications were used, you could schedule one here.
  // With it rejected, this primarily serves to process data if needed or for analytics.
  // Tapping the system-generated notification will trigger onMessageOpenedApp or getInitialMessage.
} 