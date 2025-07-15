import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class CustomerRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to admins when a new customer registers
  static Future<void> notifyAdminOfNewCustomer({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
  }) async {
    try {
      print('🔔 Sending new customer registration notification to admins');
      
      await NotificationService.sendNotificationToAdmins(
        title: 'New Customer Registration',
        body: '$customerName has registered with phone: $customerPhone',
        data: {
          'type': 'customer_registration',
          'customerId': customerId,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'customerEmail': customerEmail,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // Also save to a general notifications collection for tracking
      await FirebaseFirestore.instance
          .collection('customerRegistrationNotifications')
          .add({
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'notifiedAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });
      
      print('✅ Customer registration notification sent successfully');
    } catch (e) {
      print('❌ Error sending customer registration notification: $e');
    }
  }

  /// Get stream of customer registration notifications for admin dashboard
  static Stream<List<Map<String, dynamic>>> getCustomerRegistrationNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('customerRegistrationNotifications')
        .orderBy('notifiedAt', descending: true)
        .limit(50) // Limit to recent 50 registrations
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

  /// Set up listener for new customer registrations
  static void setupCustomerRegistrationListener() {
    FirebaseFirestore.instance
        .collection('customer')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            // Check if this is a new registration (has profile completed recently)
            final createdAt = data['createdAt'] as Timestamp?;
            final isProfileComplete = data['isProfileComplete'] as bool? ?? false;
            
            if (createdAt != null && isProfileComplete) {
              final now = DateTime.now();
              final createdTime = createdAt.toDate();
              
              // If created within last 5 minutes, consider it a new registration
              if (now.difference(createdTime).inMinutes <= 5) {
                notifyAdminOfNewCustomer(
                  customerId: change.doc.id,
                  customerName: data['name'] ?? 'Unknown',
                  customerPhone: data['phoneNumber'] ?? 'Unknown',
                  customerEmail: data['email'] ?? 'Unknown',
                );
              }
            }
          }
        }
      }
    });
  }
} 