import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import './task_detail_screen.dart';

class DeliveryTasksScreen extends StatefulWidget {
  final String userId;

  const DeliveryTasksScreen({super.key, required this.userId});

  @override
  State<DeliveryTasksScreen> createState() => _DeliveryTasksScreenState();
}

class _DeliveryTasksScreenState extends State<DeliveryTasksScreen> {
  int _selectedTab = 0; // 0 for All, 1 for Pickups, 2 for Deliveries
  String _selectedFilter = 'all'; // all, today, this_week

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Tasks'),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Text('Today Only'),
              ),
              const PopupMenuItem(
                value: 'this_week',
                child: Text('This Week'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          _buildTabBar(),
          
          // Task List
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('All', 0)),
          const SizedBox(width: 8),
          Expanded(child: _buildTabButton('Pickups', 1)),
          const SizedBox(width: 8),
          Expanded(child: _buildTabButton('Deliveries', 2)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    final orderProvider = Provider.of<OrderProvider>(context);

    return StreamBuilder<List<OrderModel>>(
      stream: orderProvider.getDeliveryOrdersStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allOrders = snapshot.data ?? [];
        final filteredOrders = _filterOrders(allOrders);

        if (filteredOrders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildTaskCard(order);
          },
        );
      },
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    List<OrderModel> filtered = orders;

    // Filter by time
    if (_selectedFilter == 'today') {
      final today = DateTime.now();
      filtered = orders.where((order) {
        final orderDate = order.orderTimestamp.toDate();
        return orderDate.year == today.year &&
               orderDate.month == today.month &&
               orderDate.day == today.day;
      }).toList();
    } else if (_selectedFilter == 'this_week') {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      filtered = orders.where((order) {
        final orderDate = order.orderTimestamp.toDate();
        return orderDate.isAfter(weekStart) && orderDate.isBefore(weekEnd);
      }).toList();
    }

    // Filter by tab
    if (_selectedTab == 1) {
      // Pickups only
      filtered = filtered.where((order) => _isPickupTask(order)).toList();
    } else if (_selectedTab == 2) {
      // Deliveries only
      filtered = filtered.where((order) => !_isPickupTask(order)).toList();
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    String message = 'No tasks found';
    IconData icon = Icons.assignment_outlined;

    if (_selectedTab == 1) {
      message = 'No pickup tasks';
      icon = Icons.get_app;
    } else if (_selectedTab == 2) {
      message = 'No delivery tasks';
      icon = Icons.local_shipping;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New tasks will appear here when assigned',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(OrderModel order) {
    final isPickup = _isPickupTask(order);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _navigateToTaskDetail(order),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left indicator
                Container(
                  width: 4,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isPickup ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Order content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${isPickup ? 'Pickup' : 'Delivery'} - Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(order.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Customer info
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            order.customer?.name ?? 'Unknown Customer',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Address
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.pickupAddress ?? order.deliveryAddress ?? 'Address not available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Bottom row
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _getTaskTime(order),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  bool _isPickupTask(OrderModel order) {
    return ['pending', 'confirmed', 'assigned', 'ready_for_pickup'].contains(order.status);
  }

  String _getTaskTime(OrderModel order) {
    if (order.pickupDate != null && order.pickupTimeSlot != null) {
      return order.pickupTimeSlot!;
    }
    if (order.deliveryDate != null && order.deliveryTimeSlot != null) {
      return order.deliveryTimeSlot!;
    }
    return DateFormat('MMM d, h:mm a').format(order.orderTimestamp.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
      case 'assigned':
        return const Color(0xFF3B82F6);
      case 'processing':
      case 'in_progress':
        return const Color(0xFF8B5CF6);
      case 'ready_for_pickup':
      case 'ready_for_delivery':
        return const Color(0xFF06B6D4);
      case 'out_for_delivery':
        return const Color(0xFF10B981);
      case 'delivered':
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _navigateToTaskDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(order: order),
      ),
    );
  }
} 