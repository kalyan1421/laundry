import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/order_model.dart';
import '../../services/fcm_service.dart';
import '../../services/database_service.dart';
import '../../utils/phone_formatter.dart';
import 'edit_order_screen.dart';
import 'manage_customer_address_screen.dart';
import 'edit_order_address_screen.dart';

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
        .listen(
          (orderDoc) async {
            if (orderDoc.exists) {
              setState(() {
                _order = OrderModel.fromFirestore(
                  orderDoc as DocumentSnapshot<Map<String, dynamic>>,
                );
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
          },
          onError: (e) {
            print('Error listening to order updates: $e');
            setState(() {
              _isLoading = false;
            });
          },
        );
  }

  Future<void> _loadOrderDetails() async {
    try {
      DocumentSnapshot orderDoc =
          await _firestore.collection('orders').doc(widget.orderId).get();

      if (orderDoc.exists) {
        setState(() {
          _order = OrderModel.fromFirestore(
            orderDoc as DocumentSnapshot<Map<String, dynamic>>,
          );
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
        DocumentSnapshot customerDoc =
            await _firestore
                .collection(
                  'customer',
                ) // Changed from 'customers' to 'customer'
                .doc(customerId)
                .get();

        if (customerDoc.exists) {
          Map<String, dynamic> customerData =
              customerDoc.data() as Map<String, dynamic>;
          setState(() {
            _customerDetails = customerData;
          });
          print(
            'Customer details loaded from customer collection: ${customerData['name']}',
          );
          return;
        }
      } catch (e) {
        print('Error loading from customer collection: $e');
      }

      // If not found in customer collection, try legacy users collection
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(customerId).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _customerDetails = userData;
          });
          print(
            'Customer details loaded from users collection: ${userData['name']}',
          );
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
      QuerySnapshot snapshot =
          await _firestore
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
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)}',
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Mobile layout
            return _buildMobileLayout();
          } else {
            // Web / Desktop layout
            return _buildWebLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
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
    );
  }

  Widget _buildWebLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildOrderHeader(),
                  ),
                  // const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildOrderStatus(),
                  ),
                  // const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildCustomerInfo(),
                  ),
                ],
              ),
            ),
            // const SizedBox(width: 8),

            // Right Column
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildItemsList(),
                  ),
                  // const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildAddressInfo(),
                  ),
                  // const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildDeliveryAssignment(),
                  ),
                  // const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      semanticContainer: true,
      elevation: 8,
      color: Colors.white,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
            // Service Type Display
            if (_order!.serviceType != null && _order!.serviceType!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    _getServiceTypeIcon(_order!.serviceType!), 
                    size: 20, 
                    color: _getServiceTypeColor(_order!.serviceType!)
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getServiceTypeColor(_order!.serviceType!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getServiceTypeColor(_order!.serviceType!)),
                    ),
                    child: Text(
                      _getDisplayServiceType(_order!.serviceType!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getServiceTypeColor(_order!.serviceType!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 20, color: Colors.green[600]),
                Text(
                  '${_order!.totalAmount.toStringAsFixed(2)}',
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
      semanticContainer: true,
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    items:
                        _orderStatuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                            ),
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
            // SizedBox(
            //   width: double.maxFinite,
            //   // height: 300,
            //   child: StatusStepper(statusHistory: _order!.statusHistory),

              // _order!.statusHistory.isEmpty
              //     ? const Center(child: Text('No status history available'))
              //     : ListView.builder(
              //       shrinkWrap: true, // ✅ takes height based on content
              //       physics:
              //           const NeverScrollableScrollPhysics(), // ✅ prevents nested scroll conflict
              //       itemCount: _order!.statusHistory.length,
              //       itemBuilder: (context, index) {
              //         final history = _order!.statusHistory[index];
              //         return ListTile(
              //           leading: Icon(
              //             Icons.circle,
              //             color: _getStatusColor(history['status'] ?? ''),
              //             size: 12,
              //           ),
              //           title: Text(
              //             (history['status'] ?? 'Unknown').toUpperCase(),
              //           ),
              //           subtitle:
              //               history['timestamp'] != null
              //                   ? Text(
              //                     DateFormat('MMM d, yyyy • h:mm a').format(
              //                       (history['timestamp'] as Timestamp)
              //                           .toDate(),
              //                     ),
              //                   )
              //                   : null,
              //         );
              //       },
              //     ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      semanticContainer: true,
      elevation: 8,
      color: Colors.white,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  child:
                      _customerDetails == null
                          ? Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: Colors.red[600],
                                )
                              else if (_customerDetails!['isPlaceholder'] ==
                                  true)
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.orange[600],
                                )
                              else
                                Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.blue[600],
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _customerDetails!['name'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _customerDetails!['hasError'] == true
                                            ? Colors.red[600]
                                            : _customerDetails!['isPlaceholder'] ==
                                                true
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
                  child:
                      _customerDetails == null
                          ? Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                                _customerDetails!['hasError'] == true ||
                                        _customerDetails!['isPlaceholder'] ==
                                            true
                                    ? Icons.phone_disabled
                                    : Icons.phone,
                                size: 16,
                                color:
                                    _customerDetails!['hasError'] == true
                                        ? Colors.red[600]
                                        : _customerDetails!['isPlaceholder'] ==
                                            true
                                        ? Colors.orange[600]
                                        : Colors.green[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _customerDetails!['phoneNumber'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _customerDetails!['hasError'] == true
                                            ? Colors.red[600]
                                            : _customerDetails!['isPlaceholder'] ==
                                                true
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
                  child:
                      _customerDetails == null
                          ? Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                                _customerDetails!['hasError'] == true ||
                                        _customerDetails!['isPlaceholder'] ==
                                            true
                                    ? Icons.email_outlined
                                    : Icons.email,
                                size: 16,
                                color:
                                    _customerDetails!['hasError'] == true
                                        ? Colors.red[600]
                                        : _customerDetails!['isPlaceholder'] ==
                                            true
                                        ? Colors.orange[600]
                                        : Colors.blue[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _customerDetails!['email'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _customerDetails!['hasError'] == true
                                            ? Colors.red[600]
                                            : _customerDetails!['isPlaceholder'] ==
                                                true
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
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange[600],
                    ),
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
                    PhoneFormatter.getClientId(
                      _customerDetails?['phoneNumber'],
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            if (_order!.specialInstructions != null &&
                _order!.specialInstructions!.isNotEmpty) ...[
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
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue[600],
                        ),
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
                      style: TextStyle(color: Colors.blue[700], fontSize: 14),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
      semanticContainer: true,
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items (${_order!.items.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AdminEditOrderScreen(order: _order!),
                      ),
                    );
                    if (result == true) {
                      // Refresh order details if editing was successful
                      _loadOrderDetails();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Items'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items list
            ..._order!.items.map((item) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['name'] ?? 'Unknown Item'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (item['category'] != null)
                            Text(
                              'Category: ${item['category']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Qty: ${item['quantity'] ?? 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '₹${(item['pricePerPiece'] ?? 0).toString()}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),

            // Total amount display
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '₹${_order!.totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Card(
      semanticContainer: true,
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with address management button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Address Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_order?.customerId != null && 
                        _order?.deliveryAddressDetails?.addressId != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditOrderAddressScreen(
                            orderId: _order!.id,
                            customerId: _order!.customerId!,
                            addressId: _order!.deliveryAddressDetails!.addressId!,
                            initialAddressData: _order!.deliveryAddressDetails?.toMap(),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Address information not available for editing. CustomerId: ${_order?.customerId}, AddressId: ${_order?.deliveryAddressDetails?.addressId}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.location_city, size: 16),
                  label: const Text('Manage Address'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup Address
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
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
                          _getDetailedPickupAddress(),
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Delivery Address
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
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
                          _getDetailedDeliveryAddress(),
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      semanticContainer: true,
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Assignment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          color:
                              _order!.isAcceptedByDeliveryPerson
                                  ? Colors.green[600]
                                  : Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        // Text(
                        //   _order!.isAcceptedByDeliveryPerson
                        //       ? 'Accepted by delivery person'
                        //       : 'Waiting for acceptance',
                        //   style: TextStyle(
                        //     color: _order!.isAcceptedByDeliveryPerson
                        //         ? Colors.green[600]
                        //         : Colors.orange[600],
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
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
    return Column(
      children: [
        // Row(
        //   children: [
        //     Expanded(
        //       child: ElevatedButton.icon(
        //         onPressed: () => _showStatusHistoryDialog(),
        //         icon: const Icon(Icons.history),
        //         label: const Text('View History'),
        //         style: ElevatedButton.styleFrom(
        //           backgroundColor: Colors.purple[700],
        //           foregroundColor: Colors.white,
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : () => _showDeleteOrderDialog(),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
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

  /// Format status for display
  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isUpdating = true);

    try {
      final String oldStatus = _order!.status;

      await _firestore.collection('orders').doc(widget.orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': newStatus,
            'timestamp': Timestamp.now(),
            'updatedBy': 'admin',
            'title': 'Status Updated',
            'description':
                'Order status updated to ${newStatus.replaceAll('_', ' ')}',
          },
        ]),
      });

      // Send FCM notification to customer about status change
      try {
        // Get customer's FCM token
        final customerDoc =
            await _firestore
                .collection('customer')
                .doc(_order!.customerId)
                .get();

        if (customerDoc.exists) {
          final customerData = customerDoc.data() as Map<String, dynamic>;
          final customerFcmToken = customerData['fcmToken'] as String? ?? '';

          if (customerFcmToken.isNotEmpty) {
            // Send FCM notification to customer
            await _firestore.collection('fcm_notifications').add({
              'token': customerFcmToken,
              'title': 'Order Status Updated',
              'body':
                  'Order #${_order!.orderNumber} status: ${_formatStatus(newStatus)}',
              'data': {
                'type': 'status_change',
                'orderId': widget.orderId,
                'orderNumber': _order!.orderNumber,
                'customerId': _order!.customerId,
                'oldStatus': oldStatus,
                'newStatus': newStatus,
                'route': '/orders/track',
              },
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'pending',
              'type': 'direct_token',
              'priority': 'high',
            });

            print('✅ FCM notification queued for customer');
          }
        }
      } catch (e) {
        print('❌ Error sending FCM notification to customer: $e');
      }

      // Save notification to order's subcollection for customer
      await _firestore
          .collection('orders')
          .doc(widget.orderId)
          .collection('notifications')
          .add({
            'type': 'status_change',
            'title': 'Order Status Updated',
            'body':
                'Your order #${_order!.orderNumber} status: ${_formatStatus(newStatus)}',
            'data': {
              'orderId': widget.orderId,
              'orderNumber': _order!.orderNumber,
              'customerId': _order!.customerId,
              'oldStatus': oldStatus,
              'newStatus': newStatus,
            },
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'sent',
            'forAdmin': false,
            'read': false,
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
            content: Text('Error updating order status: $e'),
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
      builder:
          (context) => AlertDialog(
            title: const Text('Assign Delivery Person'),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  _deliveryPersons.isEmpty
                      ? const Text('No delivery persons available')
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _deliveryPersons.length,
                        itemBuilder: (context, index) {
                          final person =
                              _deliveryPersons[index].data()
                                  as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                (person['name'] ?? 'U')
                                    .substring(0, 1)
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(person['name'] ?? 'Unknown'),
                            subtitle: Text(person['phoneNumber'] ?? 'No phone'),
                            onTap:
                                () => _assignDeliveryPerson(
                                  _deliveryPersons[index],
                                ),
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
      builder:
          (context) => AlertDialog(
            title: const Text('Reassign Delivery Person'),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  _deliveryPersons.isEmpty
                      ? const Text('No delivery persons available')
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _deliveryPersons.length,
                        itemBuilder: (context, index) {
                          final person =
                              _deliveryPersons[index].data()
                                  as Map<String, dynamic>;
                          final isCurrentlyAssigned =
                              _deliveryPersons[index].id ==
                              _order!.assignedDeliveryPerson;
                          final isOnline = person['isOnline'] ?? false;
                          final isActive = person['isActive'] ?? true;

                          return ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      isCurrentlyAssigned
                                          ? Colors.green
                                          : isActive
                                          ? Colors.blue
                                          : Colors.grey,
                                  child: Text(
                                    (person['name'] ?? 'U')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color:
                                            isOnline
                                                ? Colors.green
                                                : Colors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    person['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight:
                                          isCurrentlyAssigned
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (!isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'INACTIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (isActive && isOnline)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ONLINE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (isActive && !isOnline)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'OFFLINE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(person['phoneNumber'] ?? ''),
                                if (isCurrentlyAssigned)
                                  const Text(
                                    'Currently assigned to this order',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                isCurrentlyAssigned
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                    : isActive
                                    ? (isOnline
                                        ? const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                        )
                                        : const Icon(
                                          Icons.schedule,
                                          color: Colors.orange,
                                          size: 16,
                                        ))
                                    : const Icon(
                                      Icons.block,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                            onTap:
                                isCurrentlyAssigned || !isActive
                                    ? null
                                    : () => _assignDeliveryPerson(
                                      _deliveryPersons[index],
                                    ),
                            enabled: !isCurrentlyAssigned && isActive,
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

  // Enhanced order reassignment with delivery collection cleanup
  Future<void> _assignDeliveryPerson(DocumentSnapshot deliveryPersonDoc) async {
    Navigator.pop(context); // Close dialog
    setState(() => _isUpdating = true);

    try {
      final person = deliveryPersonDoc.data() as Map<String, dynamic>;
      final String newDeliveryPartnerId = deliveryPersonDoc.id;
      final String previousDeliveryPartner =
          _order!.assignedDeliveryPerson ?? 'none';

      print('🚚 📋 Reassigning order ${widget.orderId}');
      print('🚚 📋 From: $previousDeliveryPartner');
      print('🚚 📋 To: $newDeliveryPartnerId (${person['name']})');

      // Use batch for atomic operations
      final batch = _firestore.batch();

      // Prepare the update data - Using assignedDeliveryPerson as primary field
      Map<String, dynamic> updateData = {
        'assignedDeliveryPerson':
            newDeliveryPartnerId, // Primary field for delivery partner assignment
        'assignedDeliveryPersonName': person['name'] ?? 'Unknown',
        'assignedBy': _auth.currentUser?.uid,
        'assignedAt': FieldValue.serverTimestamp(),
        'isAcceptedByDeliveryPerson': false, // Reset acceptance status
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update status based on current state
      String newStatus = 'assigned';
      String actionDescription = '';

      if (previousDeliveryPartner == 'none' ||
          previousDeliveryPartner.isEmpty) {
        // First time assignment
        actionDescription =
            'Order assigned to delivery partner: ${person['name'] ?? 'Unknown'}';
        newStatus = 'assigned';
      } else {
        // Reassignment
        actionDescription =
            'Order reassigned from previous delivery partner to: ${person['name'] ?? 'Unknown'}';
        newStatus = 'assigned'; // Reset to assigned status for new partner
      }

      updateData['status'] = newStatus;

      // Add to status history
      Map<String, dynamic> statusHistoryEntry = {
        'status': newStatus,
        'timestamp': Timestamp.now(),
        'updatedBy': 'admin',
        'updatedByUserId': _auth.currentUser?.uid,
        'title':
            previousDeliveryPartner == 'none'
                ? 'Order Assigned'
                : 'Order Reassigned',
        'description': actionDescription,
        'assignedTo': newDeliveryPartnerId,
        'assignedToName': person['name'] ?? 'Unknown',
      };

      if (previousDeliveryPartner != 'none' &&
          previousDeliveryPartner.isNotEmpty) {
        statusHistoryEntry['previouslyAssignedTo'] = previousDeliveryPartner;
        statusHistoryEntry['previouslyAssignedToName'] =
            _order!.assignedDeliveryPersonName;
      }

      updateData['statusHistory'] = FieldValue.arrayUnion([statusHistoryEntry]);

      // 1. Update the order document
      batch.update(
        _firestore.collection('orders').doc(widget.orderId),
        updateData,
      );

      // 2. Clean up previous delivery partner's records (if reassignment)
      if (previousDeliveryPartner != 'none' && 
          previousDeliveryPartner.isNotEmpty &&
          previousDeliveryPartner != newDeliveryPartnerId) {
        
        print('🚚 🧹 Cleaning up previous delivery partner records: $previousDeliveryPartner');
        
        // Remove order from previous partner's currentOrders array
        batch.update(
          _firestore.collection('delivery').doc(previousDeliveryPartner),
          {
            'currentOrders': FieldValue.arrayRemove([widget.orderId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Delete the assigned_orders subcollection document
        batch.delete(
          _firestore
              .collection('delivery')
              .doc(previousDeliveryPartner)
              .collection('assigned_orders')
              .doc(widget.orderId),
        );
      }

      // 3. Add order to new delivery partner's records
      // Get order details for the assignment record
      final orderData = _order!.toMap();
      
      // Add order to new partner's currentOrders array
      batch.update(
        _firestore.collection('delivery').doc(newDeliveryPartnerId),
        {
          'currentOrders': FieldValue.arrayUnion([widget.orderId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Create detailed order assignment record for new delivery partner
      batch.set(
        _firestore
            .collection('delivery')
            .doc(newDeliveryPartnerId)
            .collection('assigned_orders')
            .doc(widget.orderId),
        {
          'orderId': widget.orderId,
          'assignedAt': FieldValue.serverTimestamp(),
          'status': 'assigned',
          'orderDetails': {
            'customerName': orderData['customerName'] ?? _customerDetails?['name'] ?? 'Unknown',
            'customerPhone': orderData['customerPhone'] ?? _customerDetails?['phoneNumber'] ?? '',
            'pickupAddress': _getPickupAddressString(orderData),
            'deliveryAddress': _order!.displayDeliveryAddress,
            'totalAmount': orderData['totalAmount'] ?? _order!.totalAmount,
            'items': orderData['items'] ?? _order!.items.map((item) => item.toMap()).toList(),
            'specialInstructions': orderData['specialInstructions'] ?? _order!.specialInstructions ?? '',
            'orderType': orderData['orderType'] ?? 'pickup_delivery',
            'serviceType': orderData['serviceType'] ?? _order!.serviceType ?? 'laundry',
            'priority': orderData['priority'] ?? 'normal',
            'orderNumber': orderData['orderNumber'] ?? _order!.orderNumber ?? widget.orderId,
            'createdAt': orderData['createdAt'] ?? _order!.createdAt,
            'pickupDate': orderData['pickupDate'] ?? _order!.pickupDate,
            'deliveryDate': orderData['deliveryDate'] ?? _order!.deliveryDate,
            'paymentMethod': orderData['paymentMethod'] ?? _order!.paymentMethod ?? 'cod',
          },
        },
      );

      // Commit all changes atomically
      await batch.commit();

      print('🚚 ✅ Order reassignment and delivery collection cleanup completed successfully');

      // Send notification to NEW delivery person
      await _sendNotificationToDeliveryPerson(
        newDeliveryPartnerId,
        person['name'] ?? 'Unknown',
        isReassignment: previousDeliveryPartner != 'none',
      );

      // If this is a reassignment, notify the previous delivery partner
      if (previousDeliveryPartner != 'none' &&
          previousDeliveryPartner.isNotEmpty) {
        await _sendReassignmentNotificationToPreviousPartner(
          previousDeliveryPartner,
          _order!.assignedDeliveryPersonName ?? 'Unknown',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    previousDeliveryPartner == 'none'
                        ? 'Order assigned to ${person['name']}'
                        : 'Order reassigned to ${person['name']}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('🚚 ❌ Error during order reassignment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error reassigning order: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  // Enhanced notification method for assignments/reassignments
  Future<void> _sendNotificationToDeliveryPerson(
    String deliveryPartnerId,
    String deliveryPartnerName, {
    bool isReassignment = false,
  }) async {
    try {
      print(
        '🚚 📱 Sending ${isReassignment ? 'reassignment' : 'assignment'} notification to: $deliveryPartnerName',
      );

      // Get delivery partner's FCM token
      DocumentSnapshot deliveryDoc =
          await _firestore.collection('delivery').doc(deliveryPartnerId).get();

      if (!deliveryDoc.exists) {
        print('🚚 ⚠️ Delivery partner document not found: $deliveryPartnerId');
        return;
      }

      final deliveryData = deliveryDoc.data() as Map<String, dynamic>;
      final fcmToken = deliveryData['fcmToken'] as String? ?? '';

      if (fcmToken.isEmpty) {
        print(
          '🚚 ⚠️ No FCM token found for delivery partner: $deliveryPartnerName',
        );
      } else {
        // Send FCM notification
        await _firestore.collection('fcm_notifications').add({
          'token': fcmToken,
          'title':
              isReassignment
                  ? 'Order Reassigned to You'
                  : 'New Order Assignment',
          'body':
              'Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)} has been ${isReassignment ? 'reassigned to' : 'assigned to'} you',
          'data': {
            'type': 'order_assignment',
            'orderId': widget.orderId,
            'orderNumber': _order!.orderNumber ?? _order!.id.substring(0, 8),
            'customerName':
                _order!.customer?.name ??
                _customerDetails?['name'] ??
                'Unknown',
            'customerPhone':
                _order!.customer?.phoneNumber ??
                _customerDetails?['phoneNumber'] ??
                '',
            'deliveryAddress': _order!.displayDeliveryAddress,
            'totalAmount': _order!.totalAmount.toString(),
            'itemCount': _order!.items.length.toString(),
            'specialInstructions': _order!.specialInstructions ?? '',
            'assignedBy': 'admin',
            'assignedAt': DateTime.now().toIso8601String(),
            'isReassignment': isReassignment.toString(),
          },
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'type': 'direct_token',
          'priority': 'high',
        });
      }

      // Save notification to delivery partner's subcollection
      await _firestore
          .collection('delivery')
          .doc(deliveryPartnerId)
          .collection('notifications')
          .add({
            'type': 'order_assignment',
            'title':
                isReassignment
                    ? 'Order Reassigned to You'
                    : 'New Order Assignment',
            'body':
                'Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)} has been ${isReassignment ? 'reassigned to' : 'assigned to'} you',
            'data': {
              'orderId': widget.orderId,
              'orderNumber': _order!.orderNumber ?? _order!.id.substring(0, 8),
              'customerName':
                  _order!.customer?.name ??
                  _customerDetails?['name'] ??
                  'Unknown',
              'isReassignment': isReassignment,
            },
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
            'forAdmin': false,
          });

      print(
        '🚚 ✅ ${isReassignment ? 'Reassignment' : 'Assignment'} notification sent to: $deliveryPartnerName',
      );
    } catch (e) {
      print('🚚 ❌ Error sending notification to delivery person: $e');
    }
  }

  // Notify previous delivery partner about reassignment
  Future<void> _sendReassignmentNotificationToPreviousPartner(
    String previousDeliveryPartnerId,
    String previousDeliveryPartnerName,
  ) async {
    try {
      print(
        '🚚 📱 Notifying previous delivery partner about reassignment: $previousDeliveryPartnerName',
      );

      // Get previous delivery partner's FCM token
      DocumentSnapshot deliveryDoc =
          await _firestore
              .collection('delivery')
              .doc(previousDeliveryPartnerId)
              .get();

      if (!deliveryDoc.exists) {
        print(
          '🚚 ⚠️ Previous delivery partner document not found: $previousDeliveryPartnerId',
        );
        return;
      }

      final deliveryData = deliveryDoc.data() as Map<String, dynamic>;
      final fcmToken = deliveryData['fcmToken'] as String? ?? '';

      if (fcmToken.isNotEmpty) {
        // Send FCM notification
        await _firestore.collection('fcm_notifications').add({
          'token': fcmToken,
          'title': 'Order Reassigned',
          'body':
              'Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)} has been reassigned to another delivery partner',
          'data': {
            'type': 'order_reassignment',
            'orderId': widget.orderId,
            'orderNumber': _order!.orderNumber ?? _order!.id.substring(0, 8),
            'action': 'removed_from_assignment',
          },
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'type': 'direct_token',
          'priority': 'normal',
        });
      }

      // Save notification to previous delivery partner's subcollection
      await _firestore
          .collection('delivery')
          .doc(previousDeliveryPartnerId)
          .collection('notifications')
          .add({
            'type': 'order_reassignment',
            'title': 'Order Reassigned',
            'body':
                'Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)} has been reassigned to another delivery partner',
            'data': {
              'orderId': widget.orderId,
              'orderNumber': _order!.orderNumber ?? _order!.id.substring(0, 8),
              'action': 'removed_from_assignment',
            },
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
            'forAdmin': false,
          });

      print(
        '🚚 ✅ Reassignment notification sent to previous delivery partner: $previousDeliveryPartnerName',
      );
    } catch (e) {
      print(
        '🚚 ❌ Error sending reassignment notification to previous partner: $e',
      );
    }
  }

  // Helper method to get pickup address string from order data
  String _getPickupAddressString(Map<String, dynamic> orderData) {
    try {
      // Check if pickupAddress is a map (new structure)
      if (orderData['pickupAddress'] is Map<String, dynamic>) {
        final pickupAddressMap = orderData['pickupAddress'] as Map<String, dynamic>;
        return pickupAddressMap['formatted'] ?? 
               _formatAddressFromDetails(pickupAddressMap['details']) ??
               'Pickup address not available';
      }
      // Check if it's a string (legacy structure)
      else if (orderData['pickupAddress'] is String) {
        return orderData['pickupAddress'] as String;
      }
      // Fall back to order model's pickup address
      else {
        return _order!.pickupAddress;
      }
    } catch (e) {
      print('Error getting pickup address: $e');
      return _order!.pickupAddress;
    }
  }

  // Helper method to get detailed pickup address string
  String _getDetailedPickupAddress() {
    try {
      // First try to get from structured pickupAddressDetails
      if (_order?.pickupAddressDetails != null) {
        final addressMap = _order!.pickupAddressDetails!.toMap();
        final details = addressMap['details'] as Map<String, dynamic>?;
        final detailedAddress = _formatAddressFromDetails(details);
        if (detailedAddress != null && detailedAddress.isNotEmpty) {
          return detailedAddress;
        }
      }
      
      // Fall back to simple pickup address string
      if (_order?.pickupAddress != null && _order!.pickupAddress.isNotEmpty) {
        return _formatAddress(_order!.pickupAddress) ?? 'Pickup address not available';
      }
      
      return 'Pickup address not available';
    } catch (e) {
      print('Error getting detailed pickup address: $e');
      return _order?.pickupAddress ?? 'Pickup address not available';
    }
  }

  // Helper method to format address from details
  String? _formatAddressFromDetails(Map<String, dynamic>? details) {
    if (details == null) return null;
    
    List<String> parts = [];
    if (details['doorNumber'] != null) parts.add('Door: ${details['doorNumber']}');
    if (details['floorNumber'] != null) parts.add('Floor: ${details['floorNumber']}');
    if (details['apartmentName'] != null) parts.add(details['apartmentName']);
    if (details['addressLine1'] != null) parts.add(details['addressLine1']);
    if (details['addressLine2'] != null && details['addressLine2'].toString().isNotEmpty) {
      parts.add(details['addressLine2']);
    }
    if (details['landmark'] != null) parts.add('Near ${details['landmark']}');
    if (details['city'] != null) parts.add(details['city']);
    if (details['state'] != null) parts.add(details['state']);
    if (details['pincode'] != null) parts.add(details['pincode']);
    
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  // Helper method to get detailed delivery address string
  String _getDetailedDeliveryAddress() {
    try {
      // First try to get from structured deliveryAddressDetails
      if (_order?.deliveryAddressDetails != null) {
        final addressMap = _order!.deliveryAddressDetails!.toMap();
        final details = addressMap['details'] as Map<String, dynamic>?;
        final detailedAddress = _formatAddressFromDetails(details);
        if (detailedAddress != null && detailedAddress.isNotEmpty) {
          return detailedAddress;
        }
      }
      
      // Fall back to simple delivery address string
      if (_order?.deliveryAddress != null && _order!.deliveryAddress!.isNotEmpty) {
        return _formatAddress(_order!.deliveryAddress) ?? 'Delivery address not available';
      }
      
      return 'Delivery address not available';
    } catch (e) {
      print('Error getting detailed delivery address: $e');
      return _order?.deliveryAddress ?? 'Delivery address not available';
    }
  }

  void _showStatusHistoryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Order History'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child:
                  _order!.statusHistory.isEmpty
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
                            title: Text(
                              (history['status'] ?? 'Unknown').toUpperCase(),
                            ),
                            subtitle:
                                history['timestamp'] != null
                                    ? Text(
                                      DateFormat('MMM d, yyyy • h:mm a').format(
                                        (history['timestamp'] as Timestamp)
                                            .toDate(),
                                      ),
                                    )
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

  void _showDeleteOrderDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text('Delete Order'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to delete this order?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This action cannot be undone.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteOrder();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteOrder() async {
    setState(() => _isUpdating = true);

    try {
      await DatabaseService().deleteOrder(_order!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)} deleted successfully',
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
          ),
        );

        // Navigate back to orders list
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to delete order: $e'),
              ],
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String? _formatAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address not provided';
    }

    try {
      // Clean { } if present
      address = address.replaceAll(RegExp(r'[\{\}]'), '');

      // Split into key-value pairs
      final parts = address.split(',');

      String? doorNumber;
      String? floorNumber;
      String? formattedTime;
      List<String> otherParts = [];

      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim().toLowerCase();
          final value = keyValue[1].trim();

          if (key == 'doornumber') {
            doorNumber = value;
          } else if (key == 'floornumber') {
            floorNumber = value;
          } else if (key.contains('timestamp')) {
            try {
              // Try parsing timestamp
              DateTime dt = DateTime.parse(value);
              formattedTime = DateFormat("dd MMM yyyy, hh:mm a").format(dt);
            } catch (_) {
              formattedTime = value; // fallback
            }
          } else {
            otherParts.add(value);
          }
        }
      }

      // Build formatted address
      String formatted = '';
      if (doorNumber != null) formatted += 'Door No: $doorNumber\n';
      if (floorNumber != null) formatted += 'Floor: $floorNumber\n';
      if (otherParts.isNotEmpty) formatted += otherParts.join(', ');

      if (formattedTime != null) {
        formatted += '\nTime: $formattedTime';
      }

      return formatted.trim();
    } catch (e) {
      return address; // fallback
    }
  }

  /// Get appropriate icon for service type
  IconData _getServiceTypeIcon(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('ironing')) {
      return Icons.iron;
    } else if (type.contains('allied')) {
      return Icons.cleaning_services;
    } else if (type.contains('laundry')) {
      return Icons.local_laundry_service;
    }
    return Icons.miscellaneous_services;
  }

  /// Get appropriate color for service type
  Color _getServiceTypeColor(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('ironing')) {
      return Colors.orange[600]!;
    } else if (type.contains('allied')) {
      return Colors.purple[600]!;
    } else if (type.contains('laundry')) {
      return Colors.blue[600]!;
    }
    return Colors.grey[600]!;
  }

  /// Get display-friendly service type name
  String _getDisplayServiceType(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('ironing')) {
      return 'IRONING SERVICE';
    } else if (type.contains('allied')) {
      return 'ALLIED SERVICE';
    } else if (type.contains('laundry')) {
      return 'LAUNDRY SERVICE';
    }
    return serviceType.toUpperCase();
  }
}

class StatusStepper extends StatefulWidget {
  final List<Map<String, dynamic>> statusHistory;

  const StatusStepper({Key? key, required this.statusHistory})
    : super(key: key);

  @override
  State<StatusStepper> createState() => _StatusStepperState();
}

class _StatusStepperState extends State<StatusStepper> {
  late List<Map<String, dynamic>> _stableStatusHistory;

  @override
  void initState() {
    super.initState();
    _stableStatusHistory = List.from(widget.statusHistory);
  }

  @override
  void didUpdateWidget(StatusStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the history length has actually changed significantly
    if (widget.statusHistory.length != _stableStatusHistory.length) {
      // Rebuild the widget tree entirely to avoid stepper assertion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _stableStatusHistory = List.from(widget.statusHistory);
          });
        }
      });
    } else {
      // Safe to update without changing step count
      _stableStatusHistory = List.from(widget.statusHistory);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "assigned":
        return Colors.purple;
      case "picked_up":
        return Colors.teal;
      case "processing":
        return Colors.blue;
      case "ready_for_delivery":
        return Colors.amber[700]!;
      case "out_for_delivery":
        return Colors.deepOrange;
      case "delivered":
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stableStatusHistory.isEmpty) {
      return const Center(
        child: Text(
          'No status history available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stableStatusHistory.length,
      itemBuilder: (context, index) {
        final history = _stableStatusHistory[index];
        String status = (history['status'] ?? 'Unknown').toString();
        Timestamp? ts = history['timestamp'] as Timestamp?;
        String formattedTime = ts != null
            ? DateFormat('MMM d, yyyy • h:mm a').format(ts.toDate())
            : "No timestamp";

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            border: Border(
              left: BorderSide(
                color: _getStatusColor(status),
                width: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                color: _getStatusColor(status),
                size: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (history['description'] != null)
                      Text(
                        history['description'].toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
