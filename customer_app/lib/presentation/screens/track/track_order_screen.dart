import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<OrderModel?>? _latestOrderStream;

  // Support phone number
  final String supportPhoneNumber = '+919876543210'; // Replace with actual support number

  @override
  void initState() {
    super.initState();
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      print('TrackOrderScreen: Current user ID: ${currentUser.uid}');
      
      // First try with customerId
      _latestOrderStream = _firestore
          .collection('orders')
          .where('customerId', isEqualTo: currentUser.uid)
          .snapshots()
          .map((snapshot) {
            print('TrackOrderScreen: Received ${snapshot.docs.length} orders with customerId query');
            if (snapshot.docs.isEmpty) {
              print('TrackOrderScreen: No orders found with customerId, trying userId...');
              // If no results with customerId, this will trigger the handleError
              throw Exception('No orders found with customerId');
            }
            
            return _processOrders(snapshot.docs, currentUser.uid);
          })
          .handleError((error) {
            print('TrackOrderScreen: customerId query failed: $error, trying userId...');
            
            // Fallback to userId query
            return _firestore
                .collection('orders')
                .where('userId', isEqualTo: currentUser.uid)
                .get()
                .then((snapshot) {
                  print('TrackOrderScreen: Received ${snapshot.docs.length} orders with userId query');
                  if (snapshot.docs.isEmpty) {
                    print('TrackOrderScreen: No orders found with userId either');
                    return null;
                  }
                  return _processOrders(snapshot.docs, currentUser.uid);
                })
                .catchError((e) {
                  print('TrackOrderScreen: Both queries failed: $e');
                  return null;
                });
          });
    } else {
      print('TrackOrderScreen: No current user found');
    }
  }
  
  OrderModel? _processOrders(List<QueryDocumentSnapshot> docs, String userId) {
    // Debug: Print all order IDs and timestamps
    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      print('TrackOrderScreen: Order ${doc.id}, timestamp: ${data['orderTimestamp']}, status: ${data['status']}, customerId: ${data['customerId']}, userId: ${data['userId']}');
    }
    
    // Get all orders and sort them to find the latest one
    List<OrderModel> orders = docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();
    
    print('TrackOrderScreen: Parsed ${orders.length} OrderModel objects');
    
    // Sort by orderTimestamp in descending order to get the latest order
    orders.sort((a, b) {
      Timestamp timeA = a.orderTimestamp;
      Timestamp timeB = b.orderTimestamp;
      return timeB.compareTo(timeA); // Descending order
    });
    
    OrderModel latestOrder = orders.first;
    print('TrackOrderScreen: Latest order: ${latestOrder.id}, status: ${latestOrder.status}');
    
    return latestOrder;
  }

  // Function to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorSnackBar('Could not launch phone dialer');
      }
    } catch (e) {
      print('Error launching phone dialer: $e');
      _showErrorSnackBar('Error opening phone dialer');
    }
  }

  // Function to show error messages
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to show success messages
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Function to show confirmation dialog
  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Function to cancel order
  Future<void> _cancelOrder(OrderModel order) async {
    // Check if order can be cancelled
    if (!_canCancelOrder(order.status)) {
      _showErrorSnackBar('This order cannot be cancelled at this stage');
      return;
    }

    bool shouldCancel = await _showConfirmationDialog(
      'Cancel Order',
      'Are you sure you want to cancel this order? This action cannot be undone.',
    );

    if (!shouldCancel) return;

    try {
      // Update order status to cancelled
      await _firestore.collection('orders').doc(order.id).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'cancelled',
            'timestamp': Timestamp.now(),
            'updatedBy': 'customer',
            'title': 'Order Cancelled',
          }
        ]),
      });

      _showSuccessSnackBar('Order cancelled successfully');
    } catch (e) {
      print('Error cancelling order: $e');
      _showErrorSnackBar('Failed to cancel order. Please try again.');
    }
  }

  // Function to check if order can be cancelled
  bool _canCancelOrder(String status) {
    List<String> cancellableStatuses = [
      'pending',
      'confirmed',
      'picked_up',
    ];
    return cancellableStatuses.contains(status.toLowerCase());
  }

  // Function to edit order (navigate to edit screen)
  void _editOrder(OrderModel order) {
    // Check if order can be edited
    if (!_canEditOrder(order.status)) {
      _showErrorSnackBar('This order cannot be edited at this stage');
      return;
    }

    // TODO: Navigate to edit order screen
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Order'),
          content: const Text('Edit order functionality will be implemented here. You can modify pickup/delivery times, add special instructions, etc.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessSnackBar('Edit functionality coming soon!');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to check if order can be edited
  bool _canEditOrder(String status) {
    List<String> editableStatuses = [
      'pending',
      'confirmed',
    ];
    return editableStatuses.contains(status.toLowerCase());
  }

  // Function to contact support
  Future<void> _contactSupport() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Call Support'),
                subtitle: Text(supportPhoneNumber),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(supportPhoneNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.blue),
                title: const Text('Chat Support'),
                subtitle: const Text('Start a live chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showSuccessSnackBar('Chat support coming soon!');
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.orange),
                title: const Text('Email Support'),
                subtitle: const Text('support@cloudironing.com'),
                onTap: () {
                  Navigator.pop(context);
                  _launchEmail();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Function to launch email
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@cloudironing.com',
      query: 'subject=Order Support Request&body=Hello, I need help with my order.',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar('Could not launch email client');
      }
    } catch (e) {
      print('Error launching email: $e');
      _showErrorSnackBar('Error opening email client');
    }
  }

  // Function to show quick actions menu
  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Call Support'),
                subtitle: const Text('Get immediate help'),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(supportPhoneNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                title: const Text('New Order'),
                subtitle: const Text('Place a new order'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to home screen for new order
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.orange),
                title: const Text('Order History'),
                subtitle: const Text('View all orders'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to orders screen
                  DefaultTabController.of(context)?.animateTo(1);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalProgressTimeline(OrderModel order) {
    // Define the order status steps
    List<Map<String, String>> statusSteps = [
      {'title': 'Confirmed', 'status': 'confirmed'},
      {'title': 'Picked Up', 'status': 'picked_up'},
      {'title': 'Processing', 'status': 'processing'},
      {'title': 'Ready', 'status': 'ready'},
      {'title': 'Delivered', 'status': 'delivered'},
    ];

    int currentIndex = statusSteps.indexWhere((step) => 
        step['status']?.toLowerCase() == order.status.toLowerCase());
    
    if (currentIndex == -1) {
      // Map common status variations
      switch (order.status.toLowerCase()) {
        case 'pending':
          currentIndex = 0;
          break;
        case 'confirmed':
          currentIndex = 0;
          break;
        case 'picked_up':
        case 'pickup_completed':
          currentIndex = 1;
          break;
        case 'processing':
        case 'in_progress':
          currentIndex = 2;
          break;
        case 'ready_for_delivery':
        case 'ready':
          currentIndex = 3;
          break;
        case 'completed':
        case 'delivered':
          currentIndex = 4;
          break;
        default:
          currentIndex = 1; // Default to picked up since that's the current status
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(statusSteps.length, (index) {
          bool isCompleted = index <= currentIndex;
          bool isCurrent = index == currentIndex;
          
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted 
                            ? (isCurrent ? Colors.blue : Colors.teal)
                            : Colors.grey[300],
                      ),
                      child: isCompleted 
                          ? Icon(
                              Icons.check, 
                              color: Colors.white, 
                              size: 12
                            )
                          : null,
                    ),
                    if (index < statusSteps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentIndex ? Colors.teal : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  statusSteps[index]['title']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCompleted 
                        ? (isCurrent ? Colors.blue : Colors.teal)
                        : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusUpdates(OrderModel order) {
    // Create mock status history if not available
    List<Map<String, dynamic>> statusHistory = order.statusHistory.isNotEmpty 
        ? order.statusHistory 
        : [
            {
              'status': order.status,
              'timestamp': order.orderTimestamp,
              'title': _getStatusTitle(order.status),
            }
          ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Updates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F3057),
            ),
          ),
          const SizedBox(height: 16),
          ...statusHistory.reversed.map((status) => _buildStatusUpdateItem(status)).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateItem(Map<String, dynamic> status) {
    Timestamp timestamp = status['timestamp'] ?? Timestamp.now();
    String statusText = status['title'] ?? _getStatusTitle(status['status'] ?? '');
    String formattedDate = DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Order Confirmed';
      case 'picked_up':
      case 'pickup_completed':
        return 'Pickup Completed';
      case 'processing':
      case 'in_progress':
        return 'Processing Started';
      case 'ready':
      case 'ready_for_delivery':
        return 'Ready for Delivery';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
      case 'completed':
        return 'Order Delivered';
      default:
        return 'Status Updated';
    }
  }

  Widget _buildOrderDetails(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F3057),
                ),
              ),
              if (_canEditOrder(order.status))
                TextButton.icon(
                  onPressed: () => _editOrder(order),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_laundry_service_outlined,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.serviceType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items.length} items • ₹${order.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // TODO: Implement view items functionality
              _showItemsDialog(order);
            },
            child: Row(
              children: [
                const Text(
                  'View Items',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.blue,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to show items dialog
  void _showItemsDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Order Items'),
          content: SizedBox(
            width: double.maxFinite,
            child: order.items.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: order.items.length,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return ListTile(
                        leading: const Icon(Icons.local_laundry_service_outlined),
                        title: Text(item['name'] ?? 'Item'),
                        subtitle: Text('Quantity: ${item['quantity'] ?? 1}'),
                        trailing: Text('₹${item['pricePerPiece'] ?? 0}'),
                      );
                    },
                  )
                : const Text('No items found'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPickupDelivery(OrderModel order) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup & Delivery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F3057),
            ),
          ),
          const SizedBox(height: 16),
          // Pickup Details
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('EEE, MMM d').format(order.pickupDate.toDate())} • ${order.pickupTimeSlot}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.pickupAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Delivery Details
          if (order.deliveryDate != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('EEE, MMM d').format(order.deliveryDate!.toDate())} • ${order.deliveryTimeSlot ?? 'TBD'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contact Support Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _contactSupport,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.headset_mic_outlined,
                    color: Colors.black87,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Contact Support',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel Order Button (only show if order can be cancelled)
          if (_canCancelOrder(order.status))
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => _cancelOrder(order),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Cancel Order',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to track your orders.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: StreamBuilder<OrderModel?>(
          stream: _latestOrderStream,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Text(
                'Order #${snapshot.data!.orderNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F3057),
                ),
              );
            }
            return const Text(
              'Track Order',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F3057),
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.headset_mic_outlined,
              color: Color(0xFF0F3057),
            ),
            onPressed: _contactSupport,
          ),
        ],
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _latestOrderStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading order: ${snapshot.error}'),
            );
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.track_changes_outlined,
                      size: 100,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No orders to track',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F3057),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Place an order to track its progress here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          OrderModel order = snapshot.data!;
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Horizontal Progress Timeline
                Container(
                  color: Colors.white,
                  child: _buildHorizontalProgressTimeline(order),
                ),
                const SizedBox(height: 8),
                // Status Updates
                _buildStatusUpdates(order),
                const SizedBox(height: 8),
                // Order Details
                _buildOrderDetails(order),
                const SizedBox(height: 8),
                // Pickup & Delivery
                _buildPickupDelivery(order),
                const SizedBox(height: 8),
                // Action Buttons
                _buildActionButtons(order),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      
    );
  }
} 