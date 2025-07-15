import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/order_model.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  List<OrderModel> allOrders = [];
  List<OrderModel> filteredOrders = [];
  bool isLoading = true;
  String selectedStatus = 'All';
  
  final List<String> statusFilters = [
    'All',
    'pending',
    'confirmed',
    'processing',
    'out for delivery',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (currentUser == null) return;

    try {
      setState(() => isLoading = true);

      // Query orders for both customerId and userId fields for backward compatibility
      final List<QuerySnapshot> queries = await Future.wait([
        _firestore
            .collection('orders')
            .where('customerId', isEqualTo: currentUser!.uid)
            .orderBy('orderTimestamp', descending: true)
            .get(),
        _firestore
            .collection('orders')
            .where('userId', isEqualTo: currentUser!.uid)
            .orderBy('orderTimestamp', descending: true)
            .get(),
      ]);

      Set<String> processedOrderIds = {};
      List<OrderModel> orders = [];

      // Process both query results and avoid duplicates
      for (QuerySnapshot querySnapshot in queries) {
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          if (!processedOrderIds.contains(doc.id)) {
            processedOrderIds.add(doc.id);
            try {
              OrderModel order = OrderModel.fromFirestore(doc);
              orders.add(order);
            } catch (e) {
              print('Error parsing order ${doc.id}: $e');
            }
          }
        }
      }

      // Sort by timestamp (most recent first)
      orders.sort((a, b) => b.orderTimestamp.compareTo(a.orderTimestamp));

      setState(() {
        allOrders = orders;
        _filterOrders();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e')),
        );
      }
    }
  }

  void _filterOrders() {
    if (selectedStatus == 'All') {
      filteredOrders = List.from(allOrders);
    } else {
      filteredOrders = allOrders
          .where((order) => order.status.toLowerCase() == selectedStatus.toLowerCase())
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status Filter Bar
          Container(
            height: 50,
            color: Colors.blue[50],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: statusFilters.length,
              itemBuilder: (context, index) {
                String status = statusFilters[index];
                bool isSelected = selectedStatus == status;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      status == 'All' ? 'All Orders' : status.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedStatus = status;
                        _filterOrders();
                      });
                    },
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.white,
                    elevation: isSelected ? 2 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );
              },
            ),
          ),
          
          // Orders List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(filteredOrders[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            selectedStatus == 'All' ? 'No orders yet' : 'No ${selectedStatus.toLowerCase()} orders',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedStatus == 'All' 
                ? 'Your order history will appear here'
                : 'No orders found with ${selectedStatus.toLowerCase()} status',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (selectedStatus == 'All') ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Shopping'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    String formattedDate = DateFormat('EEE, MMM d, yyyy').format(order.orderTimestamp.toDate());
    String formattedTime = DateFormat('hh:mm a').format(order.orderTimestamp.toDate());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$formattedDate • $formattedTime',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Order Items Preview
              if (order.items.isNotEmpty) ...[
                Text(
                  '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: order.items.take(3).map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item['name']} (${item['quantity']})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )).toList(),
                ),
                if (order.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${order.items.length - 3} more items',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
              
              const SizedBox(height: 12),
              
              // Order Footer
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 16, color: Colors.green[600]),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[600],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(order: order),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ],
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
      case 'processing':
      case 'in progress':
        return Colors.teal;
      case 'out for delivery':
        return Colors.purple;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 