import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/order_model.dart';
import '../../services/fcm_service.dart';
import '../../utils/phone_formatter.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  OrderModel? _order;
  List<DocumentSnapshot> _deliveryPersons = [];
  Map<String, dynamic>? _customerDetails;
  bool _isLoading = true;
  bool _isUpdating = false;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  
  final List<String> _orderStatuses = [
    'pending',
    'confirmed', 
    'assigned',
    'picked_up',
    'processing',
    'ready_for_delivery',
    'out_for_delivery',
    'delivered',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _setupOrderListener();
    _loadDeliveryPersons();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _setupOrderListener() {
    _orderSubscription = _firestore
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((orderDoc) async {
      if (orderDoc.exists) {
        setState(() {
          _order = OrderModel.fromFirestore(orderDoc as DocumentSnapshot<Map<String, dynamic>>);
        });
        
        // Load customer details after order is loaded
        await _loadCustomerDetails();
        
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (e) {
      print('Error listening to order updates: $e');
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _loadOrderDetails() async {
    try {
      DocumentSnapshot orderDoc = await _firestore
          .collection('orders')
          .doc(widget.orderId)
          .get();
      
      if (orderDoc.exists) {
        setState(() {
          _order = OrderModel.fromFirestore(orderDoc as DocumentSnapshot<Map<String, dynamic>>);
        });
        
        // Load customer details after order is loaded
        await _loadCustomerDetails();
        
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading order: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomerDetails() async {
    if (_order == null) return;
    
    try {
      String? customerId = _order!.customerId ?? _order!.userId;
      if (customerId == null) return;
      
      // Try to get customer from customer collection
      try {
        DocumentSnapshot customerDoc = await _firestore
            .collection('customer')  // Changed from 'customers' to 'customer'
            .doc(customerId)
            .get();
        
        if (customerDoc.exists) {
          Map<String, dynamic> customerData = customerDoc.data() as Map<String, dynamic>;
          setState(() {
            _customerDetails = customerData;
          });
          print('Customer details loaded from customer collection: ${customerData['name']}');
          return;
        }
      } catch (e) {
        print('Error loading from customer collection: $e');
      }
      
      // If not found in customer collection, try legacy users collection
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(customerId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _customerDetails = userData;
          });
          print('Customer details loaded from users collection: ${userData['name']}');
          return;
        }
      } catch (e) {
        print('Error loading from users collection: $e');
      }
      
      // Fallback: Try to extract customer info from the order data itself
      // Check if customer details are embedded in the order
      if (_order!.customer != null) {
        setState(() {
          _customerDetails = {
            'name': _order!.customer!.name ?? 'Unknown Customer',
            'phoneNumber': _order!.customer!.phoneNumber ?? 'N/A',
            'email': _order!.customer!.email ?? 'N/A',
          };
        });
        print('Customer details loaded from order customer object');
        return;
      }
      
      // Check if customer info is in order properties
      Map<String, dynamic> fallbackCustomerData = {};
      
      // Create a basic placeholder with customer ID
      String fallbackCustomerId = _order!.customerId ?? _order!.userId;
      fallbackCustomerData = {
        'name': 'Customer #${fallbackCustomerId.substring(0, 8)}',
        'phoneNumber': 'N/A (Details not loaded)',
        'email': 'N/A (Details not loaded)',
        'isPlaceholder': true,
      };
      
      setState(() {
        _customerDetails = fallbackCustomerData;
      });
      print('Using basic customer placeholder with ID: $fallbackCustomerId');
      return;
      
    } catch (e) {
      print('Error loading customer details: $e');
    }
  }

  Future<void> _loadDeliveryPersons() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('delivery')
          .where('isActive', isEqualTo: true)
          .get();
      
      setState(() {
        _deliveryPersons = snapshot.docs;
      });
    } catch (e) {
      print('Error loading delivery persons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Order not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            const SizedBox(height: 16),
            _buildOrderStatus(),
            const SizedBox(height: 16),
            _buildCustomerInfo(),
            const SizedBox(height: 16),
            _buildItemsList(),
            const SizedBox(height: 16),
            _buildAddressInfo(),
            const SizedBox(height: 16),
            _buildDeliveryAssignment(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order!.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _order!.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${DateFormat('MMM d, yyyy • h:mm a').format(_order!.orderTimestamp.toDate())}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 20, color: Colors.green[600]),
                Text(
                  '₹${_order!.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _order!.status,
                    decoration: const InputDecoration(
                      labelText: 'Current Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _orderStatuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null && newStatus != _order!.status) {
                        _updateOrderStatus(newStatus);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Customer Name
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Name:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: _customerDetails == null
                      ? Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading customer details...',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            if (_customerDetails!['hasError'] == true)
                              Icon(Icons.error_outline, size: 16, color: Colors.red[600])
                            else if (_customerDetails!['isPlaceholder'] == true)
                              Icon(Icons.info_outline, size: 16, color: Colors.orange[600])
                            else
                              Icon(Icons.person, size: 16, color: Colors.blue[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _customerDetails!['name'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _customerDetails!['hasError'] == true 
                                      ? Colors.red[600]
                                      : _customerDetails!['isPlaceholder'] == true
                                          ? Colors.orange[600]
                                          : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Phone Number
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Phone:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: _customerDetails == null
                      ? Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Icon(
                              _customerDetails!['hasError'] == true || _customerDetails!['isPlaceholder'] == true
                                  ? Icons.phone_disabled
                                  : Icons.phone, 
                              size: 16, 
                              color: _customerDetails!['hasError'] == true 
                                  ? Colors.red[600]
                                  : _customerDetails!['isPlaceholder'] == true
                                      ? Colors.orange[600]
                                      : Colors.green[600]
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _customerDetails!['phoneNumber'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _customerDetails!['hasError'] == true 
                                      ? Colors.red[600]
                                      : _customerDetails!['isPlaceholder'] == true
                                          ? Colors.orange[600]
                                          : Colors.green[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Email
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Email:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: _customerDetails == null
                      ? Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Icon(
                              _customerDetails!['hasError'] == true || _customerDetails!['isPlaceholder'] == true
                                  ? Icons.email_outlined
                                  : Icons.email, 
                              size: 16, 
                              color: _customerDetails!['hasError'] == true 
                                  ? Colors.red[600]
                                  : _customerDetails!['isPlaceholder'] == true
                                      ? Colors.orange[600]
                                      : Colors.blue[600]
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _customerDetails!['email'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _customerDetails!['hasError'] == true 
                                      ? Colors.red[600]
                                      : _customerDetails!['isPlaceholder'] == true
                                          ? Colors.orange[600]
                                          : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Permission notice if applicable
            if (_customerDetails?['isPlaceholder'] == true) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Customer details are restricted. Check Firestore security rules to allow admin access to customer data.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Client ID (Phone Number)
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Client ID:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    PhoneFormatter.getClientId(_customerDetails?['phoneNumber']),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_order!.specialInstructions != null && _order!.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 4),
              Text(
                          'Special Instructions:',
                style: TextStyle(
                            fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _order!.specialInstructions!,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Payment:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      (_order!.paymentMethod ?? 'N/A').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${_order!.items.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._order!.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name'] ?? 'Unknown Item'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text('Qty: ${item['quantity'] ?? 1}'),
                    const SizedBox(width: 16),
                    Text(
                      '₹${(item['price'] ?? 0).toString()}',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Pickup Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Address:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAddress(_order!.pickupAddress),
                        style: const TextStyle(height: 1.4),
                ),
              ],
            ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Delivery Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.green[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Address:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAddress(_order!.deliveryAddress),
                        style: const TextStyle(height: 1.4),
                ),
              ],
            ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Schedule Information
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                  'Pickup: ${_order!.pickupDate != null ? DateFormat('MMM d, yyyy').format(_order!.pickupDate!.toDate()) : 'TBD'} (${_order!.pickupTimeSlot ?? 'TBD'})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            if (_order!.deliveryDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.purple[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                    'Delivery: ${DateFormat('MMM d, yyyy').format(_order!.deliveryDate!.toDate())} (${_order!.deliveryTimeSlot ?? 'TBD'})',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAssignment() {
    bool isAssigned = _order!.assignedDeliveryPerson != null;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Assignment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isAssigned) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Assigned to: ${_order!.assignedDeliveryPersonName ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_order!.assignedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Assigned on: ${DateFormat('MMM d, yyyy • h:mm a').format(_order!.assignedAt!.toDate())}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    Row(
                      children: [
                        Icon(
                          _order!.isAcceptedByDeliveryPerson 
                              ? Icons.check_circle 
                              : Icons.schedule,
                          color: _order!.isAcceptedByDeliveryPerson 
                              ? Colors.green[600] 
                              : Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _order!.isAcceptedByDeliveryPerson 
                              ? 'Accepted by delivery person'
                              : 'Waiting for acceptance',
                          style: TextStyle(
                            color: _order!.isAcceptedByDeliveryPerson 
                                ? Colors.green[600] 
                                : Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showReassignDialog,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Reassign Delivery Person'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'No delivery person assigned',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showAssignDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Assign Delivery Person'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _order!.notificationSentToAdmin 
                ? null 
                : () => _sendNotificationToAdmin(),
            icon: Icon(_order!.notificationSentToAdmin 
                ? Icons.notifications_active 
                : Icons.notifications),
            label: Text(_order!.notificationSentToAdmin 
                ? 'Notification Sent' 
                : 'Send Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _order!.notificationSentToAdmin 
                  ? Colors.grey 
                  : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showStatusHistoryDialog(),
            icon: const Icon(Icons.history),
            label: const Text('View History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'picked_up':
        return Colors.teal;
      case 'processing':
        return Colors.indigo;
      case 'ready_for_delivery':
        return Colors.amber[700]!;
      case 'out_for_delivery':
        return Colors.deepOrange;
      case 'delivered':
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    
    try {
      await _firestore.collection('orders').doc(widget.orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': newStatus,
            'timestamp': Timestamp.now(),
            'updatedBy': 'admin',
            'title': 'Status Updated',
            'description': 'Order status updated to ${newStatus.replaceAll('_', ' ')}',
          }
        ]),
      });
      
      // No need to reload - real-time listener will handle the update
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showAssignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Delivery Person'),
        content: SizedBox(
          width: double.maxFinite,
          child: _deliveryPersons.isEmpty
              ? const Text('No delivery persons available')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _deliveryPersons.length,
                  itemBuilder: (context, index) {
                    final person = _deliveryPersons[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (person['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(person['name'] ?? 'Unknown'),
                      subtitle: Text(person['phoneNumber'] ?? 'No phone'),
                      onTap: () => _assignDeliveryPerson(_deliveryPersons[index]),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReassignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Delivery Person'),
        content: SizedBox(
          width: double.maxFinite,
          child: _deliveryPersons.isEmpty
              ? const Text('No delivery persons available')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _deliveryPersons.length,
                  itemBuilder: (context, index) {
                    final person = _deliveryPersons[index].data() as Map<String, dynamic>;
                    final isCurrentlyAssigned = _deliveryPersons[index].id == _order!.assignedDeliveryPerson;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrentlyAssigned ? Colors.green : null,
                        child: Text(
                          (person['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(person['name'] ?? 'Unknown'),
                      subtitle: Text(
                        isCurrentlyAssigned 
                            ? 'Currently assigned' 
                            : (person['phoneNumber'] ?? 'No phone'),
                      ),
                      trailing: isCurrentlyAssigned 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: isCurrentlyAssigned 
                          ? null 
                          : () => _assignDeliveryPerson(_deliveryPersons[index]),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignDeliveryPerson(DocumentSnapshot deliveryPersonDoc) async {
    Navigator.pop(context); // Close dialog
    setState(() => _isUpdating = true);
    
    try {
      final person = deliveryPersonDoc.data() as Map<String, dynamic>;
      
      await _firestore.collection('orders').doc(widget.orderId).update({
        'assignedDeliveryPerson': deliveryPersonDoc.id,
        'assignedDeliveryPersonName': person['name'] ?? 'Unknown',
        'assignedBy': _auth.currentUser?.uid,
        'assignedAt': FieldValue.serverTimestamp(),
        'isAcceptedByDeliveryPerson': false,
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'assigned',
            'timestamp': Timestamp.now(),
            'updatedBy': 'admin',
            'title': 'Order Assigned',
            'description': 'Order assigned to delivery partner: ${person['name'] ?? 'Unknown'}',
            'assignedTo': deliveryPersonDoc.id,
          }
        ]),
      });
      
      // Send notification to delivery person
      await _sendNotificationToDeliveryPerson(deliveryPersonDoc.id, person['name'] ?? 'Unknown');
      
      // No need to reload - real-time listener will handle the update
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order assigned to ${person['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning delivery person: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _sendNotificationToAdmin() async {
    // This would call the Cloud Function to resend admin notification
    // For now, just mark as sent
    try {
      await _firestore.collection('orders').doc(widget.orderId).update({
        'notificationSentToAdmin': true,
        'updatedAt': Timestamp.now(),
      });
      
      await _loadOrderDetails();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin notification sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _order!.statusHistory.isEmpty
              ? const Center(child: Text('No status history available'))
              : ListView.builder(
                  itemCount: _order!.statusHistory.length,
                  itemBuilder: (context, index) {
                    final history = _order!.statusHistory[index];
                    return ListTile(
                      leading: Icon(
                        Icons.circle,
                        color: _getStatusColor(history['status'] ?? ''),
                        size: 12,
                      ),
                      title: Text((history['status'] ?? 'Unknown').toUpperCase()),
                      subtitle: history['timestamp'] != null
                          ? Text(DateFormat('MMM d, yyyy • h:mm a').format(
                              (history['timestamp'] as Timestamp).toDate(),
                            ))
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotificationToDeliveryPerson(String deliveryPartnerId, String deliveryPartnerName) async {
    try {
      await FcmService.sendNotificationToDeliveryPartner(
        deliveryPartnerId: deliveryPartnerId,
        title: 'New Order Assignment',
        body: 'You have been assigned to Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)}',
        data: {
          'type': 'order_assignment',
          'orderId': widget.orderId,
          'orderNumber': _order!.orderNumber ?? _order!.id.substring(0, 8),
          'customerName': _order!.customer?.name ?? 'Unknown',
          'amount': _order!.totalAmount.toString(),
        },
      );
      print('Notification sent to delivery person: $deliveryPartnerName');
    } catch (e) {
      print('Error sending notification to delivery person: $e');
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address not provided';
    }

    // Try to parse address if it's in JSON format
    try {
      // If address contains structured data, format it nicely
      if (address.contains('"doorNumber"') || address.contains('"floorNumber"')) {
        // This would be a JSON string, parse it
        final Map<String, dynamic> addressData = {};
        
        // Extract key-value pairs using regex or simple parsing
        final doorMatch = RegExp(r'"doorNumber"\s*:\s*"([^"]*)"').firstMatch(address);
        final floorMatch = RegExp(r'"floorNumber"\s*:\s*"([^"]*)"').firstMatch(address);
        final landmarkMatch = RegExp(r'"landmark"\s*:\s*"([^"]*)"').firstMatch(address);
        final streetMatch = RegExp(r'"street"\s*:\s*"([^"]*)"').firstMatch(address);
        final areaMatch = RegExp(r'"area"\s*:\s*"([^"]*)"').firstMatch(address);
        final cityMatch = RegExp(r'"city"\s*:\s*"([^"]*)"').firstMatch(address);
        final pincodeMatch = RegExp(r'"pincode"\s*:\s*"([^"]*)"').firstMatch(address);

        List<String> addressParts = [];
        
        if (doorMatch != null && doorMatch.group(1)!.isNotEmpty) {
          addressParts.add('Door: ${doorMatch.group(1)}');
        }
        if (floorMatch != null && floorMatch.group(1)!.isNotEmpty) {
          addressParts.add('Floor: ${floorMatch.group(1)}');
        }
        if (streetMatch != null && streetMatch.group(1)!.isNotEmpty) {
          addressParts.add(streetMatch.group(1)!);
        }
        if (landmarkMatch != null && landmarkMatch.group(1)!.isNotEmpty) {
          addressParts.add('Near ${landmarkMatch.group(1)}');
        }
        if (areaMatch != null && areaMatch.group(1)!.isNotEmpty) {
          addressParts.add(areaMatch.group(1)!);
        }
        if (cityMatch != null && cityMatch.group(1)!.isNotEmpty) {
          addressParts.add(cityMatch.group(1)!);
        }
        if (pincodeMatch != null && pincodeMatch.group(1)!.isNotEmpty) {
          addressParts.add('PIN: ${pincodeMatch.group(1)}');
        }

        return addressParts.isNotEmpty ? addressParts.join('\n') : address;
      }
    } catch (e) {
      // If parsing fails, return the original address
    }

    return address;
  }
} 