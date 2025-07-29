// screens/admin/all_orders.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import 'order_details_screen.dart';


class AllOrders extends StatefulWidget {
  const AllOrders({super.key});

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  String _selectedFilter = 'all'; // Default to pending for faster loading
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _orderLimit = 20; // Start with very small limit for faster loading
  bool _isSearchingCustomers = false; // Track if we're doing a customer search
  List<String> _customerSearchResults = []; // Store customer IDs from customer search
  
  // Date filtering
  DateTime? _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;
  
  final Map<String, String> _filterOptions = {
    'all': '📋 All Orders',
    'pending': '🟡 Pending Orders',
    'confirmed': '🔵 Confirmed Orders',
    'assigned': '🟣 Assigned Orders',
    'picked_up': '🟢 Picked Up',
    'processing': '🔄 In Processing',
    'out_for_delivery': '🚚 Out for Delivery',
    'delivered': '✅ Delivered',
    
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

  // Filter orders by date
  List<OrderModel> _filterOrdersByDate(List<OrderModel> orders) {
    if (_selectedDate != null) {
      return orders.where((order) {
        final orderDate = order.createdAt?.toDate() ?? order.orderTimestamp.toDate();
        return orderDate.year == _selectedDate!.year &&
               orderDate.month == _selectedDate!.month &&
               orderDate.day == _selectedDate!.day;
      }).toList();
    } else if (_startDate != null && _endDate != null) {
      return orders.where((order) {
        final orderDate = order.createdAt?.toDate() ?? order.orderTimestamp.toDate();
        return orderDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
               orderDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }
    return orders;
  }

  void _setToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _startDate = null;
      _endDate = null;
    });
  }

  void _setYesterday() {
    setState(() {
      _selectedDate = DateTime.now().subtract(const Duration(days: 1));
      _startDate = null;
      _endDate = null;
    });
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedDate = null; // Clear single date selection
      });
    }
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _startDate = null; // Clear date range selection
        _endDate = null;
      });
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
      _orderLimit += 15; // Load 15 more orders (smaller batches for better performance)
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
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar with Refresh Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by order ID, customer name, phone, email...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: _isSearchingCustomers 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : Icon(Icons.search, color: Colors.grey[600]),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey[600]),
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
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Refresh Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue[700]),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _isSearchingCustomers = false;
                            _customerSearchResults = [];
                            _selectedFilter = 'all';
                            _selectedDate = null;
                            _startDate = null;
                            _endDate = null;
                            _orderLimit = 20;
                          });
                          // Trigger a rebuild which will refresh the stream
                          Provider.of<OrderProvider>(context, listen: false).refreshOrders();
                        },
                        tooltip: 'Refresh Orders',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filter Options
                
              ],
            ),
          ),
          SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
FilterChip(
                        label: const Text('Today'),
                        selected: _selectedDate?.day == DateTime.now().day,
                        onSelected: (bool selected) {
                          if (selected) {
                            _setToday();
                          } else {
                            _clearDateFilter();
                          }
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.green[100],
                        checkmarkColor: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Yesterday'),
                        selected: _selectedDate?.day == DateTime.now().subtract(const Duration(days: 1)).day,
                        onSelected: (bool selected) {
                          if (selected) {
                            _setYesterday();
                          } else {
                            _clearDateFilter();
                          }
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.orange[100],
                        checkmarkColor: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(_selectedDate != null
                                ? DateFormat('MMM d, y').format(_selectedDate!)
                                : _startDate != null && _endDate != null
                                    ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                                    : 'Select Date'),
                          ],
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Select Date Filter'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.calendar_today),
                                      title: const Text('Single Date'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showDatePicker();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.date_range),
                                      title: const Text('Date Range'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showDateRangePicker();
                                      },
                                    ),
                                    if (_selectedDate != null || (_startDate != null && _endDate != null))
                                      ListTile(
                                        leading: const Icon(Icons.clear),
                                        title: const Text('Clear Filter'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _clearDateFilter();
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },)
                    ])),
SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status Filter Chips
                      ..._filterOptions.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(entry.value),
                          selected: _selectedFilter == entry.key,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedFilter = selected ? entry.key : 'all';
                              _orderLimit = 20;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.blue[100],
                          checkmarkColor: Colors.blue[700],
                        ),
                      )),
                      // Vertical Divider
                      Container(
                        height: 32,
                        width: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      // Date Filter Options
                      
                        // backgroundColor: (_selectedDate != null || (_startDate != null && _endDate != null))
                        //     ? Colors.blue[100]
                        //     : Colors.white,
                      
                    ],
                  ),
                ),
          // Orders List
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: orderProvider.getFastOrdersStream(
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
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_selectedDate != null || (_startDate != null && _endDate != null))
                          TextButton(
                            onPressed: _clearDateFilter,
                            child: const Text('Clear Date Filter'),
                          ),
                      ],
                    ),
                  );
                }

                // Apply date filtering
                var filteredOrders = _filterOrdersByDate(snapshot.data!);
                
                // Apply search filtering
                if (_searchQuery.isNotEmpty) {
                  filteredOrders = filteredOrders.where((order) {
                    final query = _searchQuery.toLowerCase();
                    
                    // Basic order information (always available in fast mode)
                    final orderId = order.id.toLowerCase();
                    final orderNumber = (order.orderNumber ?? '').toLowerCase();
                    final customerId = (order.customerId ?? order.userId ?? '').toLowerCase();
                    final status = order.status.toLowerCase();
                    
                    // Check for matches in basic order data
                    bool basicMatch = orderId.contains(query) ||
                                   orderNumber.contains(query) ||
                                   customerId.contains(query) ||
                                   status.contains(query);
                    
                    // Check total amount
                    bool amountMatch = order.totalAmount.toString().contains(query);
                    
                    // Check delivery address if available
                    bool addressMatch = false;
                    if (order.deliveryAddressDetails != null) {
                      final address = order.deliveryAddressDetails!;
                      addressMatch = (address.addressLine1?.toLowerCase().contains(query) ?? false) ||
                                   (address.addressLine2?.toLowerCase().contains(query) ?? false) ||
                                   (address.city?.toLowerCase().contains(query) ?? false) ||
                                   (address.pincode?.toLowerCase().contains(query) ?? false);
                    }
                    
                    // Check items if available
                    bool itemMatch = false;
                    if (order.items != null && order.items!.isNotEmpty) {
                      itemMatch = order.items!.any((item) =>
                        (item['name']?.toString().toLowerCase().contains(query) ?? false));
                    }
                    
                    return basicMatch || amountMatch || addressMatch || itemMatch;
                  }).toList();
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
                                                    'Showing ${filteredOrders.length} orders (Fast Mode)${_selectedFilter != 'all' ? ' • Filter: ${_filterOptions[_selectedFilter]}' : ''}${_searchQuery.isNotEmpty ? ' • Search: "$_searchQuery"' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (snapshot.data!.length >= _orderLimit)
                            TextButton.icon(
                              icon: const Icon(Icons.expand_more, size: 16),
                              label: const Text('Load More'),
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
                  _orderLimit = 20;
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
  
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(orderId: order.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top row with order info, status, and edit buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: _getStatusColor(order.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Order details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order number and status badge row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusDisplayName(order.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Time and date below order ID
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            timeDisplay,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          // Amount on the right
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Edit buttons and arrow
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit_order':
                        _showEditOrderDialog(order);
                        break;
                      case 'edit_address':
                        _showEditAddressDialog(order);
                        break;
                      case 'view_details':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(orderId: order.id),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit_order',
                  child: Row(
                    children: [
                          Icon(Icons.edit, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit Order'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit_address',
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Edit Address'),
                    ],
                  ),
                ),
                    const PopupMenuItem(
                      value: 'view_details',
                  child: Row(
                    children: [
                          Icon(Icons.visibility, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                        ),
                      ),
                    ],
                ),
              ],
            ),
            

          ],
        ),
      ),
    ),
  );
}

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'confirmed':
        return 'CONFIRMED';
      case 'assigned':
        return 'ASSIGNED';
      case 'picked_up':
        return 'PICKED UP';
      case 'processing':
        return 'PROCESSING';
      case 'ready_for_delivery':
        return 'READY';
      case 'out_for_delivery':
        return 'OUT FOR DELIVERY';
      case 'delivered':
      case 'completed':
        return 'DELIVERED';
      default:
        return status.toUpperCase();
    }
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

  // Show quick edit order dialog
  void _showEditOrderDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => EditOrderDialog(
        order: order,
        onOrderUpdated: () {
          setState(() {});
        },
      ),
    );
  }

  // Show quick edit address dialog
  void _showEditAddressDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => EditOrderAddressDialog(
        order: order,
        onAddressUpdated: () {
          setState(() {});
        },
      ),
    );
  }
}

// Quick Edit Order Dialog
class EditOrderDialog extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onOrderUpdated;

  const EditOrderDialog({
    super.key,
    required this.order,
    required this.onOrderUpdated,
  });

  @override
  State<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<EditOrderDialog> {
  late TextEditingController _statusController;
  late TextEditingController _notesController;
  late TextEditingController _totalAmountController;
  bool _isUpdating = false;

  final List<String> _statusOptions = [
    'pending',
    'confirmed',
    'assigned',
    'picked_up',
    'processing',
    'ready_for_delivery',
    'out_for_delivery',
    'delivered',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _statusController = TextEditingController(text: widget.order.status);
    _notesController = TextEditingController(text: widget.order.specialInstructions ?? '');
    _totalAmountController = TextEditingController(text: widget.order.totalAmount.toString());
  }

  @override
  void dispose() {
    _statusController.dispose();
    _notesController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  Future<void> _updateOrder() async {
    setState(() => _isUpdating = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'status': _statusController.text,
        'specialInstructions': _notesController.text.trim(),
        'totalAmount': double.tryParse(_totalAmountController.text) ?? widget.order.totalAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onOrderUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Order #${widget.order.orderNumber ?? widget.order.id.substring(0, 8)}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Dropdown
            DropdownButtonFormField<String>(
              value: _statusController.text,
              decoration: const InputDecoration(
                labelText: 'Order Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _statusController.text = value;
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Total Amount
            TextFormField(
              controller: _totalAmountController,
              decoration: const InputDecoration(
                labelText: 'Total Amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Special Instructions
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Special Instructions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

// Quick Edit Address Dialog
class EditOrderAddressDialog extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onAddressUpdated;

  const EditOrderAddressDialog({
    super.key,
    required this.order,
    required this.onAddressUpdated,
  });

  @override
  State<EditOrderAddressDialog> createState() => _EditOrderAddressDialogState();
}

class _EditOrderAddressDialogState extends State<EditOrderAddressDialog> {
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _landmarkController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final address = widget.order.deliveryAddressDetails;
    _addressLine1Controller = TextEditingController(text: address?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: address?.addressLine2 ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _pincodeController = TextEditingController(text: address?.pincode ?? '');
    _landmarkController = TextEditingController(text: address?.landmark ?? '');
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress() async {
    setState(() => _isUpdating = true);
    
    try {
      Map<String, dynamic> updatedAddress = {
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'landmark': _landmarkController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'deliveryAddress.details': updatedAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onAddressUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Delivery Address - Order #${widget.order.orderNumber ?? widget.order.id.substring(0, 8)}'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _addressLine1Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _addressLine2Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 2',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_work),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin_drop),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  labelText: 'Landmark',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Update Address'),
        ),
      ],
    );
  }
}
