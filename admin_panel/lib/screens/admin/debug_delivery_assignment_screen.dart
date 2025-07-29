import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';

class DebugDeliveryAssignmentScreen extends StatefulWidget {
  const DebugDeliveryAssignmentScreen({super.key});

  @override
  State<DebugDeliveryAssignmentScreen> createState() => _DebugDeliveryAssignmentScreenState();
}

class _DebugDeliveryAssignmentScreenState extends State<DebugDeliveryAssignmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _debugOutput = '';
  bool _isLoading = false;

  Future<void> _debugOrderAssignments() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '🔍 Debugging order assignments...\n\n';
    });

    try {
      StringBuffer output = StringBuffer();
      output.writeln('🔍 DEBUGGING ORDER ASSIGNMENTS');
      output.writeln('=' * 50);
      output.writeln();

      // 1. Get all delivery partners
      output.writeln('📋 DELIVERY PARTNERS:');
      output.writeln('-' * 30);
      
      final deliveryPartnersSnapshot = await _firestore
          .collection('delivery')
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in deliveryPartnersSnapshot.docs) {
        final data = doc.data();
        output.writeln('ID: ${doc.id}');
        output.writeln('Name: ${data['name']}');
        output.writeln('Phone: ${data['phoneNumber']}');
        output.writeln('Active: ${data['isActive']}');
        output.writeln();
      }

      // 2. Get all assigned orders
      output.writeln('📦 ASSIGNED ORDERS:');
      output.writeln('-' * 30);
      
      final assignedOrdersSnapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: ['assigned', 'confirmed', 'ready_for_pickup'])
          .get();

      if (assignedOrdersSnapshot.docs.isEmpty) {
        output.writeln('❌ No orders found with status: assigned, confirmed, or ready_for_pickup');
      } else {
        for (var doc in assignedOrdersSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          output.writeln('Order ID: ${doc.id}');
          output.writeln('Order Number: ${data['orderNumber'] ?? 'N/A'}');
          output.writeln('Status: ${data['status']}');
          output.writeln('Assigned Delivery Partner: ${data['assignedDeliveryPartner'] ?? 'NOT ASSIGNED'}');
          output.writeln('Assigned Partner Name: ${data['assignedDeliveryPersonName'] ?? 'N/A'}');
          output.writeln('Assigned At: ${data['assignedAt'] ?? 'N/A'}');
          output.writeln('Customer: ${data['customer']?['name'] ?? 'N/A'}');
          output.writeln();
        }
      }

      // 3. Check delivery phone index
      output.writeln('📱 DELIVERY PHONE INDEX:');
      output.writeln('-' * 30);
      
      final phoneIndexSnapshot = await _firestore
          .collection('delivery_phone_index')
          .get();

      for (var doc in phoneIndexSnapshot.docs) {
        final data = doc.data();
        output.writeln('Phone Key: ${doc.id}');
        output.writeln('Delivery Partner ID: ${data['deliveryPartnerId']}');
        output.writeln('Phone Number: ${data['phoneNumber']}');
        output.writeln('Active: ${data['isActive']}');
        output.writeln('Linked to UID: ${data['linkedToUID'] ?? 'Not linked'}');
        output.writeln();
      }

      // 4. Recent order assignments
      output.writeln('🕐 RECENT ASSIGNMENTS (Last 24 hours):');
      output.writeln('-' * 30);
      
      final yesterday = Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1)));
      final recentAssignmentsSnapshot = await _firestore
          .collection('orders')
          .where('assignedAt', isGreaterThan: yesterday)
          .orderBy('assignedAt', descending: true)
          .get();

      if (recentAssignmentsSnapshot.docs.isEmpty) {
        output.writeln('❌ No recent assignments found');
      } else {
        for (var doc in recentAssignmentsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          output.writeln('Order: ${data['orderNumber'] ?? doc.id}');
          output.writeln('Assigned to: ${data['assignedDeliveryPartner']}');
          output.writeln('Partner Name: ${data['assignedDeliveryPersonName']}');
          output.writeln('Status: ${data['status']}');
          
          if (data['assignedAt'] != null) {
            final assignedAt = (data['assignedAt'] as Timestamp).toDate();
            output.writeln('Assigned at: $assignedAt');
          }
          output.writeln();
        }
      }

      setState(() {
        _debugOutput = output.toString();
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _debugOutput = '❌ Error during debugging: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSpecificDeliveryPartner() async {
    // Show dialog to input delivery partner ID
    String? partnerId = await _showInputDialog('Enter Delivery Partner ID to test');
    if (partnerId == null || partnerId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _debugOutput = '🧪 Testing specific delivery partner: $partnerId\n\n';
    });

    try {
      StringBuffer output = StringBuffer();
      output.writeln('🧪 TESTING DELIVERY PARTNER: $partnerId');
      output.writeln('=' * 50);
      output.writeln();

      // Check if delivery partner exists
      final partnerDoc = await _firestore.collection('delivery').doc(partnerId).get();
      
      if (!partnerDoc.exists) {
        output.writeln('❌ Delivery partner not found!');
      } else {
        final partnerData = partnerDoc.data()!;
        output.writeln('✅ Delivery partner found:');
        output.writeln('Name: ${partnerData['name']}');
        output.writeln('Phone: ${partnerData['phoneNumber']}');
        output.writeln('Active: ${partnerData['isActive']}');
        output.writeln('UID: ${partnerData['uid'] ?? 'Not linked'}');
        output.writeln();
      }

      // Check orders assigned to this partner
      output.writeln('📦 ORDERS ASSIGNED TO THIS PARTNER:');
      output.writeln('-' * 40);

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('assignedDeliveryPartner', isEqualTo: partnerId)
          .get();

      if (ordersSnapshot.docs.isEmpty) {
        output.writeln('❌ No orders assigned to this delivery partner');
      } else {
        output.writeln('Found ${ordersSnapshot.docs.length} assigned orders:');
        output.writeln();
        
        for (var doc in ordersSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          output.writeln('Order: ${data['orderNumber'] ?? doc.id}');
          output.writeln('Status: ${data['status']}');
          output.writeln('Customer: ${data['customer']?['name'] ?? 'N/A'}');
          
          if (data['assignedAt'] != null) {
            final assignedAt = (data['assignedAt'] as Timestamp).toDate();
            output.writeln('Assigned: $assignedAt');
          }
          output.writeln();
        }
      }

      // Test the exact query that delivery partner app uses
      output.writeln('🔍 TESTING DELIVERY PARTNER APP QUERY:');
      output.writeln('-' * 40);
      
      final appQuerySnapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: ['assigned', 'confirmed', 'ready_for_pickup'])
          .where('assignedDeliveryPartner', isEqualTo: partnerId)
          .get();

      output.writeln('Query: status IN [assigned, confirmed, ready_for_pickup] AND assignedDeliveryPartner = $partnerId');
      output.writeln('Results: ${appQuerySnapshot.docs.length} orders');
      
      if (appQuerySnapshot.docs.isNotEmpty) {
        output.writeln('✅ Delivery partner app should see these orders:');
        for (var doc in appQuerySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          output.writeln('- ${data['orderNumber'] ?? doc.id} (${data['status']})');
        }
      } else {
        output.writeln('❌ No orders found with the delivery partner app query');
      }

      setState(() {
        _debugOutput = output.toString();
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _debugOutput = '❌ Error testing delivery partner: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _showInputDialog(String title) async {
    String? result;
    await showDialog(
      context: context,
      builder: (context) {
        String input = '';
        return AlertDialog(
          title: Text(title),
          content: TextField(
            onChanged: (value) => input = value,
            decoration: InputDecoration(
              hintText: 'Enter ID...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                result = input;
                Navigator.pop(context);
              },
              child: Text('Test'),
            ),
          ],
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Delivery Assignments'),
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
                      '🔧 Debug Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _debugOrderAssignments,
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Debug All Assignments'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testSpecificDeliveryPartner,
                          icon: const Icon(Icons.person_search),
                          label: const Text('Test Specific Partner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_debugOutput.isNotEmpty)
              Expanded(
                child: Card(
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
                              'Debug Output',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _debugOutput = ''),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _debugOutput,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'Click a debug button to start analyzing the delivery assignment system.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 