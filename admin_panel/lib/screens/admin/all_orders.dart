// screens/admin/all_orders.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import 'order_details_screen.dart';
import '../../utils/phone_formatter.dart';

class AllOrders extends StatefulWidget {
  const AllOrders({super.key});

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  String _selectedFilter = 'pending'; // Default to pending for faster loading
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _orderLimit = 30; // Start with smaller limit
  bool _isSearchingCustomers = false; // Track if we're doing a customer search
  List<String> _customerSearchResults = []; // Store customer IDs from customer search
  
  final Map<String, String> _filterOptions = {
    'pending': '🟡 Pending Orders',
    'confirmed': '🔵 Confirmed Orders',
    'assigned': '🟣 Assigned Orders',
    'picked_up': '🟢 Picked Up',
    'processing': '🔄 In Processing',
    'out_for_delivery': '🚚 Out for Delivery',
    'delivered': '✅ Delivered',
    'all': '📋 All Orders',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Search customers collection for name, phone, or email matches
  Future<List<String>> _searchCustomerIds(String query) async {
    if (query.length < 3) return []; // Require at least 3 characters
    
    try {
      List<String> customerIds = [];
      
      // Search by name
      final nameQuery = await FirebaseFirestore.instance
          .collection('customer')  // Changed from 'customers' to 'customer'
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + '\uf8ff')
          .limit(20)
          .get();
      
      for (var doc in nameQuery.docs) {
        if (!customerIds.contains(doc.id)) {
          customerIds.add(doc.id);
        }
      }
      
      // Search by phone (if query looks like a phone number)
      if (RegExp(r'^[\d\+\-\s\(\)]*$').hasMatch(query)) {
        try {
          final phoneQuery = await FirebaseFirestore.instance
              .collection('customer')  // Changed from 'customers' to 'customer'
              .where('phoneNumber', isGreaterThanOrEqualTo: query)
              .where('phoneNumber', isLessThan: query + '\uf8ff')
              .limit(20)
              .get();
          
          for (var doc in phoneQuery.docs) {
            if (!customerIds.contains(doc.id)) {
              customerIds.add(doc.id);
            }
          }
        } catch (e) {
          print('Phone search error: $e');
        }
      }
      
      // Search by email (if query looks like an email)
      if (query.contains('@') || query.contains('.')) {
        try {
          final emailQuery = await FirebaseFirestore.instance
              .collection('customer')  // Changed from 'customers' to 'customer'
              .where('email', isGreaterThanOrEqualTo: query)
              .where('email', isLessThan: query + '\uf8ff')
              .limit(20)
              .get();
          
          for (var doc in emailQuery.docs) {
            if (!customerIds.contains(doc.id)) {
              customerIds.add(doc.id);
            }
          }
        } catch (e) {
          print('Email search error: $e');
        }
      }
      
      return customerIds;
    } catch (e) {
      print('Customer search error: $e');
      return [];
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    List<OrderModel> filteredOrders = orders;

    // Search query filtering
    if (_searchQuery.isNotEmpty) {
      filteredOrders = filteredOrders.where((order) {
        final query = _searchQuery.toLowerCase();
        
        // Basic order information
        final orderId = order.id.toLowerCase();
        final orderNumber = (order.orderNumber ?? '').toLowerCase();
        final customerId = (order.customerId ?? order.userId).toLowerCase();
        
        // Check for matches in order ID, order number, or customer ID
        bool basicMatch = orderId.contains(query) ||
                         orderNumber.contains(query) ||
                         customerId.contains(query);
        
        // If we did a customer search, check if this order's customer is in the results
        bool customerSearchMatch = _isSearchingCustomers && 
                                 _customerSearchResults.contains(order.customerId ?? order.userId);
        
        // Customer information from order.customer object (if available)
        final customerName = (order.customer?.name ?? '').toLowerCase();
        final customerPhone = (order.customer?.phoneNumber ?? '').toLowerCase();
        final customerEmail = (order.customer?.email ?? '').toLowerCase();
        
        // Check for matches in customer details (if available)
        bool customerDetailMatch = customerName.contains(query) ||
                                 customerPhone.contains(query) ||
                                 customerEmail.contains(query);
        
        return basicMatch || customerSearchMatch || customerDetailMatch;
      }).toList();
    }

    return filteredOrders;
  }

  void _onSearchChanged(String value) async {
    setState(() {
      _searchQuery = value;
      _isSearchingCustomers = false;
      _customerSearchResults = [];
    });
    
    // If query might be a customer search (contains letters or email-like characters)
    if (value.length >= 3 && (RegExp(r'[a-zA-Z@.]').hasMatch(value))) {
      setState(() {
        _isSearchingCustomers = true;
      });
      
      // Search customer collection
      final customerIds = await _searchCustomerIds(value);
      
      setState(() {
        _customerSearchResults = customerIds;
        _isSearchingCustomers = false;
      });
    }
  }

  void _loadMoreOrders() {
    setState(() {
      _orderLimit += 20; // Load 20 more orders
    });
  }

  String _getTimeDisplay(OrderModel order) {
    DateTime orderTime = order.createdAt?.toDate() ?? order.orderTimestamp.toDate();
    DateTime now = DateTime.now();
    
    if (orderTime.year == now.year && orderTime.month == now.month && orderTime.day == now.day) {
      return DateFormat('h:mm a').format(orderTime);
    } else {
      return DateFormat('MMM d, h:mm a').format(orderTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by order ID, customer name, phone, email...',
                      prefixIcon: _isSearchingCustomers 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _isSearchingCustomers = false;
                                  _customerSearchResults = [];
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      _onSearchChanged(value);
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _orderLimit = 30;
                    });
                  },
                  tooltip: 'Refresh orders',
                ),
              ],
            ),
          ),

          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _filterOptions.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                          _orderLimit = 30; // Reset limit when filter changes
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Orders list
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: orderProvider.getAllOrdersStream(
                statusFilter: _selectedFilter,
                limit: _orderLimit,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading orders...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading orders',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No ${_filterOptions[_selectedFilter]?.toLowerCase() ?? 'orders'} available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter orders based on search query only (status already filtered at DB level)
                List<OrderModel> filteredOrders = _filterOrders(snapshot.data!);

                if (filteredOrders.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found matching "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Order count and performance info
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${filteredOrders.length} orders',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (snapshot.data!.length >= _orderLimit)
                            TextButton.icon(
                              icon: Icon(Icons.expand_more, size: 16),
                              label: Text('Load More'),
                              onPressed: _loadMoreOrders,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Orders list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(order);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedFilter != 'pending' 
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'pending';
                  _orderLimit = 30;
                });
              },
              icon: const Icon(Icons.pending_actions),
              label: const Text('Pending'),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final timeDisplay = _getTimeDisplay(order);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: order.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Order info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client ID: ${PhoneFormatter.getClientId(order.customer?.phoneNumber)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (order.customer?.name != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Name: ${order.customer!.name}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      timeDisplay,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Arrow
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
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
}