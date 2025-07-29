import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/fcm_service.dart';
import '../../models/delivery_partner_model.dart';

class TestDeliveryNotificationScreen extends StatefulWidget {
  const TestDeliveryNotificationScreen({super.key});

  @override
  State<TestDeliveryNotificationScreen> createState() => _TestDeliveryNotificationScreenState();
}

class _TestDeliveryNotificationScreenState extends State<TestDeliveryNotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DeliveryPartnerModel> _deliveryPartners = [];
  bool _isLoading = true;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _loadDeliveryPartners();
  }

  Future<void> _loadDeliveryPartners() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('delivery')
          .where('isActive', isEqualTo: true)
          .get();

             final partners = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Add document ID to the data
            return DeliveryPartnerModel.fromMap(data);
          })
          .toList();

      setState(() {
        _deliveryPartners = partners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResult = 'Error loading delivery partners: $e';
      });
    }
  }

  Future<void> _testNotification(DeliveryPartnerModel partner) async {
    setState(() {
      _testResult = '🚚 Testing notification to ${partner.name}...';
    });

    try {
      // Test notification data
      final testData = {
        'type': 'order_assignment',
        'orderId': 'TEST_ORDER_001',
        'orderNumber': 'TEST-001',
        'customerName': 'Test Customer',
        'customerPhone': '+91XXXXXXXXXX',
        'deliveryAddress': '123 Test Street, Test City',
        'totalAmount': '299.00',
        'itemCount': '2',
        'specialInstructions': 'This is a test notification',
        'assignedBy': 'admin_test',
        'assignedAt': DateTime.now().toIso8601String(),
      };

      // Send test notification
      await FcmService.sendNotificationToDeliveryPerson(
        deliveryPersonId: partner.id,
        title: '🧪 Test Order Assignment',
        body: 'This is a test notification for Order #TEST-001',
        data: testData,
      );

      setState(() {
        _testResult = '✅ Test notification sent to ${partner.name}\n'
            'Check the delivery partner app for the notification.\n'
            'Time: ${DateTime.now().toString()}';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Failed to send test notification to ${partner.name}\n'
            'Error: $e';
      });
    }
  }

  Future<void> _checkPartnerTokens(DeliveryPartnerModel partner) async {
    setState(() {
      _testResult = '🔍 Checking FCM tokens for ${partner.name}...';
    });

    try {
      final DocumentSnapshot doc = await _firestore
          .collection('delivery')
          .doc(partner.id)
          .get();

      if (!doc.exists) {
        setState(() {
          _testResult = '❌ Partner document not found';
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final fcmToken = data['fcmToken'] as String?;
      final fcmTokens = data['fcmTokens'] as List?;

      String result = '🔍 FCM Token Check for ${partner.name}:\n\n';
      result += 'Single Token (fcmToken): ${fcmToken != null ? "✅ Present" : "❌ Missing"}\n';
      if (fcmToken != null) {
        result += 'Token Preview: ${fcmToken.substring(0, 20)}...\n';
      }
      
      result += 'Multiple Tokens (fcmTokens): ${fcmTokens != null ? "✅ Present (${fcmTokens.length})" : "❌ Missing"}\n';
      
      result += '\nPhone Number: ${partner.phoneNumber}\n';
      result += 'Active Status: ${partner.isActive ? "✅ Active" : "❌ Inactive"}\n';
      result += 'Document ID: ${partner.id}\n';

      setState(() {
        _testResult = result;
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Error checking tokens: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Delivery Notifications'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Notification Test Center',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use this screen to test notifications to delivery partners. '
                      'Make sure the delivery partner app is installed and running.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _deliveryPartners.length,
                  itemBuilder: (context, index) {
                    final partner = _deliveryPartners[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3A8A),
                          child: Text(
                            partner.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(partner.name),
                        subtitle: Text(partner.phoneNumber),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => _checkPartnerTokens(partner),
                              tooltip: 'Check FCM Tokens',
                            ),
                            IconButton(
                              icon: const Icon(Icons.notifications_active),
                              onPressed: () => _testNotification(partner),
                              tooltip: 'Send Test Notification',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            if (_testResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terminal),
                          const SizedBox(width: 8),
                          const Text(
                            'Test Results',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _testResult = ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _testResult,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 