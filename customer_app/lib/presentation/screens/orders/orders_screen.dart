// screens/orders/orders_screen.dart
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
// Import for OrderDetailsScreen - will create this file later
import 'package:customer_app/presentation/screens/orders/order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Query to get ALL orders for the current user
      // Try both 'userId' and 'customerId' fields for compatibility
      _ordersStream = _firestore
          .collection('orders')
          .where('customerId', isEqualTo: currentUser.uid)
          .snapshots()
          .map((snapshot) {
        List<OrderModel> orders =
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

        // If no orders found with customerId, try with userId
        if (orders.isEmpty) {
          return <OrderModel>[];
        }

        // Sort by orderTimestamp in descending order (latest first)
        orders.sort((a, b) {
          Timestamp aTime = a.orderTimestamp;
          Timestamp bTime = b.orderTimestamp;
          return bTime.compareTo(aTime); // Descending order - latest first
        });

        return orders;
      }).handleError((error) {
        print('Error fetching orders with customerId: $error');
        // Fallback to userId query if customerId fails
        return _firestore
            .collection('orders')
            .where('userId', isEqualTo: currentUser.uid)
            .get()
            .then((snapshot) {
          List<OrderModel> orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();

          orders.sort((a, b) {
            Timestamp aTime = a.orderTimestamp;
            Timestamp bTime = b.orderTimestamp;
            return bTime.compareTo(aTime);
          });

          return orders;
        }).catchError((e) {
          print('Error fetching orders with userId: $e');
          return <OrderModel>[];
        });
      });
    }
  }

  Widget _getStatusChip(String status) {
    Color chipColor = Colors.grey;
    Color textColor = Colors.white;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'confirmed':
        chipColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'in progress':
      case 'processing':
        chipColor = Colors.teal[100]!;
        textColor = Colors.teal[800]!;
        break;
      case 'out for delivery':
        chipColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
      case 'delivered':
      case 'completed':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'cancelled':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: textColor, fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    // Using order.orderTimestamp for display, which maps to 'orderTimestamp' from Firestore
    String formattedDate =
        DateFormat('EEE, MMM d, yyyy').format(order.orderTimestamp.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderNumber}', // Using orderNumber which defaults to doc.id
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3057)),
                ),
                _getStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.local_laundry_service_outlined,
                    color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.serviceType, // Using the determined serviceType
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  formattedDate, // Displaying the formatted orderTimestamp
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsScreen(order: order),
                      ),
                    );
                  },
                  child: const Text('View Details',
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your orders.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: StreamBuilder<List<OrderModel>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error fetching orders: \${snapshot.error}');
            return Center(
                child: Text('Error loading orders: \${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    const Text(
                      'No active orders',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F3057)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your orders will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF0F3057), // Primary color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        // Navigate to home or new order screen
                        // Assuming you have a main navigation handler that can switch tabs
                        // For simplicity, directly popping or navigating to a known route like '/home'
                        // If you have a BottomNavigationBar managed by a parent, you might call a method to switch tabs.
                        // Example: Provider.of<AppStateManager>(context, listen: false).goToTab(AppTab.home);
                        Navigator.of(context).popUntil((route) => route
                            .isFirst); // Go to the very first screen (usually home)

                        // If your HomeScreen is a specific route and you are not using a tab manager:
                        // Navigator.pushNamedAndRemoveUntil(context, '/home_screen_route_name', (route) => false);
                      },
                      child: const Text('Place New Order',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          List<OrderModel> orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          );
        },
      ),
    );
  }
}
