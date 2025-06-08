// screens/orders/track_orders_screen.dart
import 'package:customer_app/data/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/presentation/screens/orders/order_details_screen.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({Key? key}) : super(key: key);

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  OrderModel? _lastOrder;
  bool _isLoading = true;
  String _error = '';

  // Define order stages for the tracker UI
  final List<String> _orderStages = [
    'Pending',
    'Confirmed',
    'Processing', // Or 'In Progress'
    'Out for Delivery',
    'Delivered' // Or 'Completed'
  ];

  @override
  void initState() {
    super.initState();
    _fetchLastOrder();
  }

  Future<void> _fetchLastOrder() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final snapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: currentUser.uid)
            // .where('orderStatus', whereNotIn: ['Delivered', 'Completed', 'Cancelled']) // Optional: to only track active orders
            .orderBy('orderTimestamp', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          _lastOrder = OrderModel.fromFirestore(snapshot.docs.first);
        } else {
          _lastOrder = null; // No orders found
        }
      } catch (e) {
        print('Error fetching last order: $e');
        _error = 'Failed to load order details. Please try again.';
      }
    } else {
      _error = 'Please log in to track your orders.';
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget _getStatusChip(String status) {
    Color chipColor = Colors.grey;
    Color textColor = Colors.white;
    // Using similar styling as OrdersScreen for consistency
    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'confirmed':
        chipColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'in progress': // Added this for consistency if your status is 'In Progress'
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
      default:
        chipColor = Colors.grey[300]!;
        textColor = Colors.grey[700]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildProgressIndicator(String currentStatus) {
    int currentIndex = _orderStages.indexWhere((stage) => stage.toLowerCase() == currentStatus.toLowerCase());
    if (currentIndex == -1 && (currentStatus.toLowerCase() == 'in progress' || currentStatus.toLowerCase() == 'processing')) {
        currentIndex = _orderStages.indexWhere((stage) => stage.toLowerCase() == 'processing');
    } else if (currentIndex == -1 && (currentStatus.toLowerCase() == 'delivered' || currentStatus.toLowerCase() == 'completed')) {
        currentIndex = _orderStages.indexWhere((stage) => stage.toLowerCase() == 'delivered');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_orderStages.length, (index) {
          bool isActive = index <= currentIndex;
          bool isCurrent = index == currentIndex;
          return Column(
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isActive ? (isCurrent ? Colors.blueAccent : Colors.green) : Colors.grey[400],
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                _orderStages[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? (isCurrent ? Colors.blueAccent : Colors.black87) : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Text(_error, style: const TextStyle(fontSize: 16, color: Colors.red)),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: _fetchLastOrder, child: const Text('Retry'))
                ]
            )
          )
        )
      );
    }

    if (_lastOrder == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.track_changes_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                const Text(
                  'No Orders to Track',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0F3057)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Once you place an order, you can track its progress here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                 const SizedBox(height: 30),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003B73), 
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () { // Navigate to place order screen (e.g., HomeScreen)
                         Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Place New Order', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If we have an order, display its details
    String formattedPickupDate = DateFormat('EEE, MMM d, yyyy').format(_lastOrder!.pickupDate.toDate());
    String formattedDeliveryDate = DateFormat('EEE, MMM d, yyyy').format(_lastOrder!.deliveryDate.toDate());

    return Scaffold(
      // appBar: AppBar( // Removed existing AppBar
      //   title: const Text('Track Order'),
      // ),
      body: RefreshIndicator(
        onRefresh: _fetchLastOrder,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(), // Ensures RefreshIndicator works even if content is small
          child: Card(
            elevation: 4,
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
                        'Order #${_lastOrder!.orderNumber}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F3057)),
                      ),
                      _getStatusChip(_lastOrder!.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastOrder!.serviceType,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                  const Divider(height: 24, thickness: 1),
                  
                  _buildProgressIndicator(_lastOrder!.status),
                  
                  const Divider(height: 24, thickness: 1),
                  
                  const Text('Order Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF0F3057))),
                  const SizedBox(height: 8),
                  _buildDetailRow('Pickup:', '$formattedPickupDate, ${_lastOrder!.pickupTimeSlot}'),
                  _buildDetailRow('Delivery:', '$formattedDeliveryDate, ${_lastOrder!.deliveryTimeSlot}'),
                  _buildDetailRow('Total Amount:', '₹${_lastOrder!.totalAmount.toStringAsFixed(0)}'),
                  
                  if (_lastOrder!.specialInstructions != null && _lastOrder!.specialInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Special Instructions:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F3057))),
                    const SizedBox(height: 4),
                    Text(_lastOrder!.specialInstructions!, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('View Full Order Details'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: _lastOrder!),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 15)
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[800])),
          Expanded(child: Text(value, style: TextStyle(fontSize: 15, color: Colors.grey[700]))),
        ],
      ),
    );
  }
}
