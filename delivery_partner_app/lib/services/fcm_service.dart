import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';

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
      print('FCM: User granted permission');
      _saveTokenToFirestore(); // Save token once permission is granted
    } else {
      print('FCM: User declined or has not accepted permission');
      return;
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token: token);
    });

    // Handle foreground messages - Enhanced for delivery partners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('FCM: Got a message whilst in the foreground!');
      print('FCM: Message data: ${message.data}');
      RemoteNotification? notification = message.notification;

      if (notification != null && context != null) {
        // Enhanced notification handling for delivery partners
        String notificationType = message.data['type'] ?? 'general';
        
        if (notificationType == 'order_assignment') {
          // Special handling for order assignment notifications
          print('🚚 📦 NEW ORDER ASSIGNMENT RECEIVED!');
          print('🚚 Order Number: ${message.data['orderNumber']}');
          print('🚚 Customer: ${message.data['customerName']}');
          print('🚚 Amount: ₹${message.data['totalAmount']}');
          
          final snackBar = SnackBar(
            content: Container(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                  notification.title ?? 'New Order Assignment',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                Text(notification.body ?? 'You have a new order assigned'),
                  if (message.data['orderNumber'] != null) ...[
                    SizedBox(height: 4),
                    Text('Order: #${message.data['orderNumber']}', 
                         style: TextStyle(color: Colors.yellow)),
              ],
                  if (message.data['customerName'] != null) ...[
                    SizedBox(height: 2),
                    Text('Customer: ${message.data['customerName']}'),
                  ],
                  if (message.data['totalAmount'] != null) ...[
                    SizedBox(height: 2),
                    Text('Amount: ₹${message.data['totalAmount']}', 
                         style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            backgroundColor: Colors.green.shade700,
            action: SnackBarAction(
              label: '👀 VIEW',
              onPressed: () => _handleNotificationTap(message.data),
              textColor: Colors.white,
            ),
            duration: const Duration(seconds: 15),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          
          // Trigger OrderProvider notification handling
          try {
            final orderProvider = Provider.of<OrderProvider>(context, listen: false);
            orderProvider.handleOrderAssignmentNotification(message.data);
          } catch (e) {
            print('🚚 ⚠️ Could not trigger OrderProvider notification: $e');
          }
        } else {
          // Standard notification handling
          final snackBar = SnackBar(
            content: Text(notification.body ?? 'New notification received!'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _handleNotificationTap(message.data),
            ),
            duration: const Duration(seconds: 10),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    });

    // Handle notification tap when app is in background (but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('FCM: Message opened from background: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('FCM: Message opened from terminated state: ${initialMessage.data}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print('🚚 FCM: Handling notification tap with data: $data');
    
    String notificationType = data['type'] ?? 'general';
    
    if (notificationType == 'order_assignment' && data['orderId'] != null) {
      // Navigate to task detail screen for delivery partners
      print('🚚 Navigating to order details for: ${data['orderId']}');
      
      // Since we don't have named routes, we'll need to navigate from current context
      // This will be handled when the user taps on the notification
      // The dashboard will already be updated via real-time streams
      
      // For now, just print the order details for debugging
      print('🚚 Order Assignment Details:');
      print('   Order ID: ${data['orderId']}');
      print('   Order Number: ${data['orderNumber']}');
      print('   Customer: ${data['customerName']}');
      print('   Address: ${data['deliveryAddress']}');
      print('   Amount: ₹${data['totalAmount']}');
      print('   Items: ${data['itemCount']}');
      
    } else if (data['orderId'] != null) {
      print('🚚 General order notification for: ${data['orderId']}');
    } else {
      print('🚚 General notification received');
    }
  }

  Future<void> _saveTokenToFirestore({String? token}) async {
    String? currentToken = token ?? await _firebaseMessaging.getToken();
    print("Admin FCM Token: $currentToken");

    User? currentAdmin = _auth.currentUser;
    if (currentAdmin != null && currentToken != null) {
      try {
        // Save token to admins collection
        await _saveTokenToAdminCollection(currentAdmin.uid, currentToken);
        
        // Also save to delivery collection if applicable (for dual role users)
        await _saveTokenToDeliveryCollection(currentAdmin.uid, currentToken);
        
        print("Admin FCM token saved to Firestore for user: ${currentAdmin.uid}");
      } catch (e) {
        print("Admin FCM: Error saving token to Firestore: $e");
      }
    } else {
      print("Admin FCM: No user logged in or token is null. Token not saved.");
    }
  }

  Future<void> _saveTokenToAdminCollection(String uid, String token) async {
    try {
      // Check if user exists in admins collection
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        await _firestore.collection('admins').doc(uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("FCM token saved to admins collection for: $uid");
      } else {
        // Search by phone number in case UID doesn't match
        String? userPhone = _auth.currentUser?.phoneNumber;
        if (userPhone != null) {
          QuerySnapshot adminQuery = await _firestore
              .collection('admins')
              .where('phoneNumber', isEqualTo: userPhone)
              .limit(1)
              .get();
          
          if (adminQuery.docs.isNotEmpty) {
            String adminDocId = adminQuery.docs.first.id;
            await _firestore.collection('admins').doc(adminDocId).update({
              'fcmToken': token,
              'uid': uid, // Update UID as well
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print("FCM token saved to admins collection by phone for: $adminDocId");
          }
        }
      }
    } catch (e) {
      print("Error saving token to admins collection: $e");
    }
  }

  Future<void> _saveTokenToDeliveryCollection(String uid, String token) async {
    try {
      // Check if user exists in delivery collection
      DocumentSnapshot deliveryDoc = await _firestore.collection('delivery').doc(uid).get();
      if (deliveryDoc.exists) {
        await _firestore.collection('delivery').doc(uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("FCM token saved to delivery collection for: $uid");
      } else {
        // Search by phone number in case UID doesn't match
        String? userPhone = _auth.currentUser?.phoneNumber;
        if (userPhone != null) {
          QuerySnapshot deliveryQuery = await _firestore
              .collection('delivery')
              .where('phoneNumber', isEqualTo: userPhone)
              .limit(1)
              .get();
          
          if (deliveryQuery.docs.isNotEmpty) {
            String deliveryDocId = deliveryQuery.docs.first.id;
            await _firestore.collection('delivery').doc(deliveryDocId).update({
              'fcmToken': token,
              'uid': uid, // Update UID as well
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print("FCM token saved to delivery collection by phone for: $deliveryDocId");
          }
        }
      }
    } catch (e) {
      print("Error saving token to delivery collection: $e");
    }
  }

  Future<void> deleteTokenForCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        // Delete from admins collection
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(currentUser.uid).get();
        if (adminDoc.exists) {
          await _firestore.collection('admins').doc(currentUser.uid).update({
            'fcmToken': FieldValue.delete(),
          });
        }
        
        // Delete from delivery collection
        DocumentSnapshot deliveryDoc = await _firestore.collection('delivery').doc(currentUser.uid).get();
        if (deliveryDoc.exists) {
          await _firestore.collection('delivery').doc(currentUser.uid).update({
            'fcmToken': FieldValue.delete(),
          });
        }
        
        // Delete the instance ID token itself
        await _firebaseMessaging.deleteToken(); 
        print("FCM token deleted from Firestore for user: ${currentUser.uid}");
      } catch (e) {
         print("FCM: Error deleting token from Firestore: $e");
      }
    }
  }

  // Method to manually save/update FCM token (to be called after login)
  Future<void> saveFCMTokenAfterLogin() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("FCM: No current user found during token save");
        return;
      }

      String? token = await _firebaseMessaging.getToken();
      if (token == null) {
        print("FCM: No FCM token available");
        return;
      }

      print("FCM: Saving token for user ${currentUser.uid}: $token");

      // Try to save to both collections to ensure token is saved
      bool adminSaved = await _saveTokenToAdminCollectionWithRetry(currentUser.uid, token);
      bool deliverySaved = await _saveTokenToDeliveryCollectionWithRetry(currentUser.uid, token);

      if (adminSaved || deliverySaved) {
        print("FCM: Token successfully saved");
      } else {
        print("FCM: Failed to save token to any collection");
        // If both fail, try with phone number matching
        await _saveTokenByPhoneNumber(token);
      }

    } catch (e) {
      print("Error saving FCM token after login: $e");
    }
  }

  Future<bool> _saveTokenToAdminCollectionWithRetry(String uid, String token) async {
    try {
      // First try by UID
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        await _firestore.collection('admins').doc(uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("FCM token saved to admins collection for UID: $uid");
        return true;
      }
      return false;
    } catch (e) {
      print("Error saving token to admins collection by UID: $e");
      return false;
    }
  }

  Future<bool> _saveTokenToDeliveryCollectionWithRetry(String uid, String token) async {
    try {
      // First try by UID
      DocumentSnapshot deliveryDoc = await _firestore.collection('delivery').doc(uid).get();
      if (deliveryDoc.exists) {
        await _firestore.collection('delivery').doc(uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("FCM token saved to delivery collection for UID: $uid");
        return true;
      }
      return false;
    } catch (e) {
      print("Error saving token to delivery collection by UID: $e");
      return false;
    }
  }

  Future<void> _saveTokenByPhoneNumber(String token) async {
    try {
      String? userPhone = _auth.currentUser?.phoneNumber;
      if (userPhone == null) {
        print("FCM: No phone number available for token save");
        return;
      }

      print("FCM: Trying to save token by phone number: $userPhone");

      // Try different phone number formats
      List<String> phoneFormats = [
        userPhone,                              // +919063290632
        userPhone.replaceAll('+91', ''),        // 9063290632
        '+91${userPhone.replaceAll('+91', '')}', // Ensure +91 prefix
      ];

      // Try admins collection
      for (String phoneFormat in phoneFormats) {
        QuerySnapshot adminQuery = await _firestore
            .collection('admins')
            .where('phoneNumber', isEqualTo: phoneFormat)
            .limit(1)
            .get();
        
        if (adminQuery.docs.isNotEmpty) {
          String adminDocId = adminQuery.docs.first.id;
          await _firestore.collection('admins').doc(adminDocId).update({
            'fcmToken': token,
            'uid': _auth.currentUser!.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print("FCM token saved to admins collection by phone ($phoneFormat): $adminDocId");
          return;
        }
      }

      // Try delivery collection
      for (String phoneFormat in phoneFormats) {
        QuerySnapshot deliveryQuery = await _firestore
            .collection('delivery')
            .where('phoneNumber', isEqualTo: phoneFormat)
            .limit(1)
            .get();
        
        if (deliveryQuery.docs.isNotEmpty) {
          String deliveryDocId = deliveryQuery.docs.first.id;
          await _firestore.collection('delivery').doc(deliveryDocId).update({
            'fcmToken': token,
            'uid': _auth.currentUser!.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print("FCM token saved to delivery collection by phone ($phoneFormat): $deliveryDocId");
          return;
        }
      }

      print("FCM: No matching documents found for any phone format");

    } catch (e) {
      print("Error saving FCM token by phone number: $e");
    }
  }

  // Enhanced method specifically for delivery person during login
  static Future<void> ensureDeliveryPersonTokenSaved({
    required String phoneNumber,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) {
      print("FCM: No FCM token available for delivery person");
      return;
    }

    try {
      // Find delivery person by phone number
      final deliverySnapshot = await FirebaseFirestore.instance
          .collection('delivery')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      print("FCM: Ensuring delivery person token is saved: $token");

      if (deliverySnapshot.docs.isNotEmpty) {
        final doc = deliverySnapshot.docs.first;
        final currentData = doc.data();
        final currentTokens = List<String>.from(currentData['fcmTokens'] ?? []);

        // Only update if token is not already in the list
        if (!currentTokens.contains(token)) {
          currentTokens.add(token);
          
          await doc.reference.update({
            'fcmTokens': currentTokens,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
            'registrationToken': token, // Keep single token for backwards compatibility
          });

          print("FCM: Delivery person token saved successfully for doc: ${doc.id}");
        } else {
          print("FCM: Token already exists for delivery person");
        }
      } else {
        print("FCM: No matching delivery person document found");
      }
    } catch (e) {
      print("FCM: Error ensuring delivery person token saved: $e");
    }
  }

  // Static method to send notification to multiple tokens
  static Future<void> sendToMultipleTokens({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
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
      print("Error in sendToMultipleTokens: $e");
    }
  }

  // Instance method wrapper for backward compatibility
  Future<void> ensureDeliveryPartnerTokenSaved() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("FCM: No current user for delivery token save");
        return;
      }

      String? token = await _firebaseMessaging.getToken();
      String? phoneNumber = currentUser.phoneNumber;
      
      if (phoneNumber != null) {
        await ensureDeliveryPersonTokenSaved(
          phoneNumber: phoneNumber,
          token: token,
        );
      }
    } catch (e) {
      print("FCM: Error in ensureDeliveryPartnerTokenSaved wrapper: $e");
    }
  }

  // Enhanced method to send notification to specific delivery person with order details
  static Future<void> sendNotificationToDeliveryPerson({
    required String deliveryPersonId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get delivery person's details and FCM token
      DocumentSnapshot deliveryDoc = await FirebaseFirestore.instance
          .collection('delivery')
          .doc(deliveryPersonId)
          .get();

      if (!deliveryDoc.exists) {
        print("Delivery person not found: $deliveryPersonId");
        return;
      }

      Map<String, dynamic>? deliveryData = deliveryDoc.data() as Map<String, dynamic>?;
      String deliveryPersonName = deliveryData?['name'] ?? 'Delivery Person';

      // Check for both fcmToken (singular) and fcmTokens (plural) for compatibility
      List<String> fcmTokens = [];
      
      // First check for multiple tokens (fcmTokens)
      if (deliveryData?['fcmTokens'] != null) {
        fcmTokens = List<String>.from(deliveryData?['fcmTokens'] ?? []);
      }
      
      // If no multiple tokens, check for single token (fcmToken)
      if (fcmTokens.isEmpty && deliveryData?['fcmToken'] != null) {
        String singleToken = deliveryData?['fcmToken'] as String;
        if (singleToken.isNotEmpty) {
          fcmTokens = [singleToken];
        }
      }
      
      if (fcmTokens.isEmpty) {
        print("❌ No FCM token found for delivery person: $deliveryPersonId");
        print("🔍 Delivery data keys: ${deliveryData?.keys.toList()}");
        return;
      }

      print("🚚 📱 Found ${fcmTokens.length} FCM token(s) for delivery partner: $deliveryPersonName");

      // Enhanced notification data
      Map<String, dynamic> notificationData = {
        'type': 'order_assignment',
        'deliveryPersonId': deliveryPersonId,
        'deliveryPersonName': deliveryPersonName,
        'timestamp': DateTime.now().toIso8601String(),
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        ...?data,
      };

      // Send to all tokens for this delivery person
      await sendToMultipleTokens(
        tokens: fcmTokens,
        title: title,
        body: body,
        data: notificationData,
      );
      
      print("🚚 ✅ Push notification sent to delivery partner: $deliveryPersonName");
      print("🚚 📱 Tokens used: ${fcmTokens.length}");

      // Save notification to delivery person's notifications collection
      await FirebaseFirestore.instance
          .collection('delivery')
          .doc(deliveryPersonId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'data': notificationData,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Enhanced order assignment notification sent to delivery person: $deliveryPersonId");
    } catch (e) {
      print("Error sending notification to delivery person: $e");
    }
  }

  // Backward compatibility method
  static Future<void> sendOrderAssignmentNotification({
    required String deliveryPartnerId,
    required String orderId,
    required String orderNumber,
    String? customerName,
    String? deliveryAddress,
    double? totalAmount,
    int? itemCount,
    String? specialInstructions,
  }) async {
    String title = 'New Order Assignment #$orderNumber';
    String body = 'You have been assigned a new order';
    
    if (customerName != null && deliveryAddress != null) {
      body += '\nCustomer: $customerName';
      body += '\nAddress: ${deliveryAddress.length > 50 ? deliveryAddress.substring(0, 50) + '...' : deliveryAddress}';
    }
    
    if (totalAmount != null) {
      body += '\nAmount: ₹${totalAmount.toStringAsFixed(2)}';
    }
    
    if (itemCount != null) {
      body += '\nItems: $itemCount piece${itemCount > 1 ? 's' : ''}';
    }

    Map<String, dynamic> data = {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'deliveryPartnerId': deliveryPartnerId,
    };

    if (customerName != null) data['customerName'] = customerName;
    if (deliveryAddress != null) data['deliveryAddress'] = deliveryAddress;
    if (totalAmount != null) data['totalAmount'] = totalAmount.toString();
    if (itemCount != null) data['itemCount'] = itemCount.toString();
    if (specialInstructions != null) data['specialInstructions'] = specialInstructions;

    await sendNotificationToDeliveryPerson(
      deliveryPersonId: deliveryPartnerId,
      title: title,
      body: body,
      data: data,
    );
  }

  // Static method to send notification to specific delivery partner
  static Future<void> sendNotificationToDeliveryPartner({
    required String deliveryPartnerId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Get delivery partner's FCM token
      DocumentSnapshot deliveryDoc = await firestore
          .collection('delivery')
          .doc(deliveryPartnerId)
          .get();
      
      if (deliveryDoc.exists) {
        Map<String, dynamic>? deliveryData = deliveryDoc.data() as Map<String, dynamic>?;
        String? fcmToken = deliveryData?['fcmToken'];
        
        if (fcmToken != null) {
          // Save notification to delivery partner's notifications collection
          await firestore
              .collection('delivery')
              .doc(deliveryPartnerId)
              .collection('notifications')
              .add({
            'title': title,
            'body': body,
            'data': data ?? {},
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': data?['type'] ?? 'general',
          });
          
          print("Notification sent to delivery partner: $deliveryPartnerId");
        } else {
          print("No FCM token found for delivery partner: $deliveryPartnerId");
        }
      } else {
        print("Delivery partner not found: $deliveryPartnerId");
      }
    } catch (e) {
      print("Error sending notification to delivery partner: $e");
    }
  }

  // Static method to send notification to all delivery partners
  static Future<void> sendNotificationToAllDeliveryPartners({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Get all delivery partners with FCM tokens
      QuerySnapshot deliverySnapshot = await firestore
          .collection('delivery')
          .where('fcmToken', isNotEqualTo: null)
          .get();
      
      for (QueryDocumentSnapshot doc in deliverySnapshot.docs) {
        await sendNotificationToDeliveryPartner(
          deliveryPartnerId: doc.id,
          title: title,
          body: body,
          data: data,
        );
      }
      
      print("Notifications sent to ${deliverySnapshot.docs.length} delivery partners");
    } catch (e) {
      print("Error sending notifications to all delivery partners: $e");
    }
  }

  // Method to check if delivery partner has FCM token
  Future<Map<String, dynamic>> checkDeliveryPartnerFCMToken() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'hasToken': false, 'error': 'No current user'};
      }

      String uid = currentUser.uid;
      String? userPhone = currentUser.phoneNumber;

      // Check all delivery documents
      QuerySnapshot allDelivery = await _firestore.collection('delivery').get();
      
      for (QueryDocumentSnapshot doc in allDelivery.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Check if this document matches by UID or phone
          bool uidMatch = data['uid']?.toString() == uid;
          bool phoneMatch = false;
          
          if (userPhone != null && data['phoneNumber'] != null) {
            String docPhone = data['phoneNumber'].toString();
            List<String> phoneFormats = [
              userPhone,                              // +919063290632
              userPhone.replaceAll('+91', ''),        // 9063290632
              '+91${userPhone.replaceAll('+91', '')}', // Ensure +91 prefix
            ];
            
            phoneMatch = phoneFormats.contains(docPhone) || 
                        docPhone == userPhone ||
                        docPhone == userPhone.replaceAll('+91', '');
          }
          
          if (uidMatch || phoneMatch) {
            String? fcmToken = data['fcmToken'];
            return {
              'hasToken': fcmToken != null && fcmToken.isNotEmpty,
              'token': fcmToken,
              'documentId': doc.id,
              'matchedBy': uidMatch ? 'UID' : 'Phone',
              'deliveryPartnerName': data['name'] ?? 'Unknown',
              'phoneNumber': data['phoneNumber'] ?? 'Unknown',
              'isActive': data['isActive'] ?? false,
              'lastUpdated': data['updatedAt']?.toString() ?? 'Unknown'
            };
          }
        } catch (e) {
          print("Error checking delivery doc ${doc.id}: $e");
        }
      }
      
      return {'hasToken': false, 'error': 'No matching delivery partner document found'};
      
    } catch (e) {
      return {'hasToken': false, 'error': 'Error checking FCM token: $e'};
    }
  }

  // Method to force refresh FCM token for current delivery partner
  Future<Map<String, dynamic>> forceRefreshDeliveryToken() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'No current user'};
      }

      // Delete existing token and get new one
      await _firebaseMessaging.deleteToken();
      await Future.delayed(Duration(seconds: 2)); // Wait for deletion
      
      String? newToken = await _firebaseMessaging.getToken();
      if (newToken == null) {
        return {'success': false, 'error': 'Failed to get new FCM token'};
      }

      // Save the new token
      if (currentUser != null) {
        String? phoneNumber = currentUser.phoneNumber;
        if (phoneNumber != null) {
          await ensureDeliveryPersonTokenSaved(
            phoneNumber: phoneNumber,
            token: newToken,
          );
        }
      }
      
      return {
        'success': true, 
        'newToken': newToken,
        'message': 'FCM token refreshed successfully'
      };
      
    } catch (e) {
      return {'success': false, 'error': 'Error refreshing FCM token: $e'};
    }
  }

  // Debug method to check all delivery partners' FCM token status
  static Future<void> debugAllDeliveryPartnerTokens() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      QuerySnapshot allDelivery = await firestore.collection('delivery').get();
      print('=== DELIVERY PARTNERS FCM TOKEN DEBUG ===');
      print('Total delivery partners: ${allDelivery.docs.length}');
      
      for (QueryDocumentSnapshot doc in allDelivery.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String? fcmToken = data['fcmToken'];
          
          print('---');
          print('Doc ID: ${doc.id}');
          print('Name: ${data['name'] ?? 'Unknown'}');
          print('Phone: ${data['phoneNumber'] ?? 'Unknown'}');
          print('UID: ${data['uid'] ?? 'Not Set'}');
          print('Has FCM Token: ${fcmToken != null && fcmToken.isNotEmpty}');
          print('Is Active: ${data['isActive'] ?? false}');
          print('Last Updated: ${data['updatedAt']?.toString() ?? 'Unknown'}');
          if (fcmToken != null && fcmToken.isNotEmpty) {
            print('Token Preview: ${fcmToken.substring(0, 20)}...');
          }
        } catch (e) {
          print('Error processing doc ${doc.id}: $e');
        }
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('Error in debugAllDeliveryPartnerTokens: $e');
    }
  }

  // Test method to verify notification flow for delivery partners
  static Future<Map<String, dynamic>> testDeliveryPartnerNotificationFlow(String deliveryPartnerId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      print('🧪 Testing notification flow for delivery partner: $deliveryPartnerId');
      
      // Step 1: Check if delivery partner exists
      DocumentSnapshot deliveryDoc = await firestore
          .collection('delivery')
          .doc(deliveryPartnerId)
          .get();
      
      if (!deliveryDoc.exists) {
        return {'success': false, 'error': 'Delivery partner not found'};
      }
      
      Map<String, dynamic>? deliveryData = deliveryDoc.data() as Map<String, dynamic>?;
      String? fcmToken = deliveryData?['fcmToken'];
      String partnerName = deliveryData?['name'] ?? 'Unknown';
      
      print('🧪 Partner: $partnerName, Has FCM Token: ${fcmToken != null}');
      
      // Step 2: Test notification creation
      try {
        await sendNotificationToDeliveryPartner(
          deliveryPartnerId: deliveryPartnerId,
          title: 'Test Notification',
          body: 'This is a test notification to verify the notification flow',
          data: {
            'type': 'test',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
        
        print('🧪 Test notification sent successfully');
        
        // Step 3: Verify notification was saved
        QuerySnapshot notifications = await firestore
            .collection('delivery')
            .doc(deliveryPartnerId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        
        if (notifications.docs.isNotEmpty) {
          var latestNotification = notifications.docs.first.data() as Map<String, dynamic>;
          print('🧪 Latest notification: ${latestNotification['title']}');
          
          return {
            'success': true,
            'partnerName': partnerName,
            'hasFcmToken': fcmToken != null,
            'notificationSaved': true,
            'latestNotification': latestNotification,
            'message': 'Notification flow test completed successfully'
          };
        } else {
          return {
            'success': false,
            'error': 'Notification was not saved to Firestore'
          };
        }
        
      } catch (e) {
        return {
          'success': false,
          'error': 'Failed to send notification: $e'
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Test failed: $e'
      };
    }
  }

  // Method to test complete delivery partner notification flow with enhanced order details
  Future<Map<String, dynamic>> testEnhancedDeliveryPartnerNotificationFlow({
    String? testOrderId,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'No current user'};
      }

      String uid = currentUser.uid;
      print("=== Enhanced Delivery Partner Notification Test ===");
      print("Current User: $uid");

      // Step 1: Check if delivery partner exists and has FCM token
      Map<String, dynamic> tokenCheck = await checkDeliveryPartnerFCMToken();
      print("Token Check Result: $tokenCheck");

      if (!tokenCheck['hasToken']) {
        return {
          'success': false,
          'error': 'No FCM token found',
          'details': tokenCheck
        };
      }

      String? deliveryPartnerId = tokenCheck['documentId'];
      if (deliveryPartnerId == null) {
        return {'success': false, 'error': 'No delivery partner document ID found'};
      }

      // Step 2: Get a test order or create sample data
      String orderId = testOrderId ?? 'test_order_${DateTime.now().millisecondsSinceEpoch}';
      String orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      try {
        if (testOrderId != null) {
          // Try to get real order data
          DocumentSnapshot orderDoc = await _firestore.collection('orders').doc(testOrderId).get();
          if (orderDoc.exists) {
            Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
            
            // Extract customer information
            String? customerId = orderData['customerId'];
            String? customerName = 'Customer';
            
            if (customerId != null) {
              try {
                DocumentSnapshot customerDoc = await _firestore.collection('customer').doc(customerId).get();
                if (customerDoc.exists) {
                  Map<String, dynamic> customerData = customerDoc.data() as Map<String, dynamic>;
                  customerName = customerData['name'] ?? customerData['fullName'] ?? 'Customer';
                }
              } catch (e) {
                print("Error fetching customer details: $e");
              }
            }

            // Extract delivery address
            String deliveryAddress = 'Delivery Address';
            if (orderData['deliveryAddress'] != null) {
              if (orderData['deliveryAddress'] is Map) {
                Map<String, dynamic> addressData = orderData['deliveryAddress'];
                Map<String, dynamic> details = addressData['details'] ?? addressData;
                
                List<String> addressParts = [];
                if (details['addressLine1'] != null) addressParts.add(details['addressLine1']);
                if (details['addressLine2'] != null) addressParts.add(details['addressLine2']);
                if (details['city'] != null) addressParts.add(details['city']);
                
                deliveryAddress = addressParts.join(', ');
              } else if (orderData['deliveryAddress'] is String) {
                deliveryAddress = orderData['deliveryAddress'];
              }
            }

            // Extract order details
            double totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();
            List items = orderData['items'] ?? [];
            int itemCount = items.fold(0, (sum, item) {
              if (item is Map<String, dynamic>) {
                return sum + ((item['quantity'] ?? 0) as int);
              }
              return sum;
            });

            String? specialInstructions = orderData['specialInstructions'];
            String actualOrderNumber = orderData['orderNumber'] ?? orderNumber;

            // Step 3: Send enhanced notification
            await FcmService.sendOrderAssignmentNotification(
              deliveryPartnerId: deliveryPartnerId,
              orderId: orderId,
              orderNumber: actualOrderNumber,
              customerName: customerName,
              deliveryAddress: deliveryAddress,
              totalAmount: totalAmount,
              itemCount: itemCount,
              specialInstructions: specialInstructions,
            );

            return {
              'success': true,
              'message': 'Enhanced notification sent successfully',
              'deliveryPartnerId': deliveryPartnerId,
              'orderId': orderId,
              'orderNumber': actualOrderNumber,
              'customerName': customerName,
              'deliveryAddress': deliveryAddress,
              'totalAmount': totalAmount,
              'itemCount': itemCount,
              'hasSpecialInstructions': specialInstructions != null,
            };
          }
        }
      } catch (e) {
        print("Error fetching real order data, using sample data: $e");
      }

      // Step 3: Send sample enhanced notification if no real order found
      await FcmService.sendOrderAssignmentNotification(
        deliveryPartnerId: deliveryPartnerId,
        orderId: orderId,
        orderNumber: orderNumber,
        customerName: 'John Doe',
        deliveryAddress: 'Floor: first, Door: 101, J-201, Jillalguda',
        totalAmount: 299.50,
        itemCount: 5,
        specialInstructions: 'Handle with care, fragile items',
      );

      return {
        'success': true,
        'message': 'Enhanced sample notification sent successfully',
        'deliveryPartnerId': deliveryPartnerId,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'sampleData': true,
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Error in enhanced notification test: $e'
      };
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