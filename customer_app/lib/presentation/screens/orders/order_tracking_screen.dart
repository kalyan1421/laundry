import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:customer_app/presentation/screens/orders/edit_order_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // Support phone number
  final String supportPhoneNumber = '+919566654788'; // Replace with actual support number

  // Function to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  // Contact support function
  void _contactSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.headset_mic, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  const Text(
                    'Contact Support',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Need help with your order? Our support team is here to assist you.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _makePhoneCall(supportPhoneNumber);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Function to edit order (navigate to edit screen)
  void _editOrder(OrderModel order) {
    // Check if order can be edited
    if (!_canEditOrder(order)) {
      _showErrorSnackBar('This order cannot be edited at this stage');
      return;
    }

    // Navigate to edit order screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditOrderScreen(order: order),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh order data if edit was successful
        setState(() {
          // Order data will be refreshed when this screen rebuilds
        });
      }
    });
  }

  // Function to check if order can be edited
  bool _canEditOrder(OrderModel order) {
    // Customer can edit order only until it's confirmed by admin
    // Allow editing ONLY for pending status - once admin confirms, editing is disabled

    String orderStatus = order.status.toLowerCase().trim();

    // Allow editing ONLY for pending status (before admin confirmation)
    List<String> editableStatuses = [
      'pending',
      'placed',
      'order_placed',
      'new_order',
    ];

    bool isEditable = editableStatuses.contains(orderStatus);
    print('Order ${order.id} status: "$orderStatus", editable: $isEditable');

    return isEditable;
  }

  // Function to show error messages
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        foregroundColor: context.onBackgroundColor,
        title: Text('Track Order'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with order number and support button (matching TrackOrderScreen)
            Container(
              color: context.backgroundColor,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${widget.order.orderNumber}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Color(0xFF0F3057)
                                  : context.onBackgroundColor),
                        ),
                        // Service Type Display
                        if (widget.order.serviceType != null && widget.order.serviceType.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getServiceTypeIcon(widget.order.serviceType),
                                size: 16,
                                color: _getServiceTypeColor(widget.order.serviceType),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getServiceTypeColor(widget.order.serviceType).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getServiceTypeColor(widget.order.serviceType).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getDisplayServiceType(widget.order.serviceType),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getServiceTypeColor(widget.order.serviceType),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.headset_mic_outlined,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Color(0xFF0F3057)
                            : context.onBackgroundColor),
                    onPressed: _contactSupport,
                  ),
                ],
              ),
            ),
            
            // Horizontal Progress Timeline
            Container(
              color: context.backgroundColor,
              child: _buildHorizontalProgressTimeline(widget.order),
            ),
            const SizedBox(height: 8),
            
            // Status Updates
            _buildStatusUpdates(widget.order),
            const SizedBox(height: 8),
            
            // Order Details
            _buildOrderDetails(widget.order),
            const SizedBox(height: 8),
            
            // Pickup & Delivery
            _buildPickupDelivery(widget.order),
            const SizedBox(height: 8),
            
            // Action Buttons
            _buildActionButtons(widget.order),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalProgressTimeline(OrderModel order) {
    // Check if order is cancelled - show special cancelled status
    if (order.status.toLowerCase() == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Order Cancelled',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Define the order status steps for normal orders (added pending at top)
    List<Map<String, String>> statusSteps = [
      {'title': 'Pending', 'status': 'pending'},
      {'title': 'Confirmed', 'status': 'confirmed'},
      {'title': 'Picked Up', 'status': 'picked_up'},
      {'title': 'Processing', 'status': 'processing'},
      {'title': 'Ready', 'status': 'ready'},
      {'title': 'Delivered', 'status': 'delivered'},
    ];

    int currentIndex = statusSteps.indexWhere(
        (step) => step['status']?.toLowerCase() == order.status.toLowerCase());

    if (currentIndex == -1) {
      // Map common status variations
      switch (order.status.toLowerCase()) {
        case 'pending':
          currentIndex = 0; // First step - Pending
          break;
        case 'confirmed':
          currentIndex = 1; // Second step - Confirmed
          break;
        case 'picked_up':
        case 'pickup_completed':
          currentIndex = 2; // Third step - Picked Up
          break;
        case 'processing':
        case 'in_progress':
          currentIndex = 3; // Fourth step - Processing
          break;
        case 'ready_for_delivery':
        case 'ready':
          currentIndex = 4; // Fifth step - Ready
          break;
        case 'completed':
        case 'delivered':
          currentIndex = 5; // Sixth step - Delivered
          break;
        default:
          currentIndex = 0; // Default to pending
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
                          ? Icon(Icons.check, color: Colors.white, size: 12)
                          : null,
                    ),
                    if (index < statusSteps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentIndex
                              ? Colors.teal
                              : Colors.grey[300],
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
        color: context.backgroundColor,
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
          Text(
            'Status Updates',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.light
                    ? Color(0xFF0F3057)
                    : context.onBackgroundColor),
          ),
          const SizedBox(height: 16),
          ...statusHistory.reversed
              .map((status) => _buildStatusUpdateItem(status))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateItem(Map<String, dynamic> status) {
    Timestamp timestamp = status['timestamp'] ?? Timestamp.now();
    String statusText =
        status['title'] ?? _getStatusTitle(status['status'] ?? '');
    String formattedDate =
        DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate());

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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.onBackgroundColor,
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

  Widget _buildOrderDetails(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.backgroundColor,
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
              Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Color(0xFF0F3057)
                      : context.onBackgroundColor,
                ),
              ),
              if (_canEditOrder(order))
                TextButton.icon(
                  onPressed: () => _editOrder(order),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: context.onBackgroundColor,
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
          const Divider(),
          const SizedBox(height: 16),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getItemIcon(item['category']?.toString() ?? ''),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name']?.toString() ?? 'Unknown Item',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.onBackgroundColor,
                            ),
                          ),
                          Text(
                            '${item['category']?.toString() ?? 'Unknown'} • Qty: ${item['quantity']?.toString() ?? '0'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${_calculateItemTotal(item).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.onBackgroundColor,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPickupDelivery(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.backgroundColor,
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
          Text(
            'Pickup & Delivery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.light
                  ? Color(0xFF0F3057)
                  : context.onBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Pickup Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.pickupTimeSlot ?? 'TBD',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.pickupAddress,
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
          const Divider(),
          const SizedBox(height: 16),
          
          // Delivery Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_downward,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryTimeSlot ?? 'TBD',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryAddress,
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
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    bool canEdit = _canEditOrder(order);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Edit Order Button (only show if order can be edited)
          if (canEdit)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _editOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3057),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Edit Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          if (canEdit) const SizedBox(height: 12),
          
          // Call Support Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _contactSupport,
              icon: const Icon(Icons.headset_mic),
              label: const Text('Contact Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Cancel Order Button (only for pending/confirmed orders)
          if (order.status.toLowerCase() == 'pending' || 
              order.status.toLowerCase() == 'confirmed')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCancelOrderDialog(order),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: Text('Are you sure you want to cancel order #${order.orderNumber}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelOrder(order);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _cancelOrder(OrderModel order) {
    // Implement order cancellation logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order cancellation functionality coming soon!')),
    );
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
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
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Status Updated';
    }
  }

  IconData _getItemIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('iron')) {
      return Icons.iron;
    } else if (cat.contains('wash')) {
      return Icons.local_laundry_service;
    } else {
      return Icons.checkroom;
    }
  }

  /// Calculate total price for an item
  double _calculateItemTotal(Map<String, dynamic> item) {
    try {
      // Get price - try different field names as they might vary
      double price = 0.0;
      
      // Try different price field names
      if (item['price'] != null) {
        price = (item['price'] is int) ? (item['price'] as int).toDouble() : (item['price'] as double? ?? 0.0);
      } else if (item['pricePerPiece'] != null) {
        price = (item['pricePerPiece'] is int) ? (item['pricePerPiece'] as int).toDouble() : (item['pricePerPiece'] as double? ?? 0.0);
      } else if (item['unitPrice'] != null) {
        price = (item['unitPrice'] is int) ? (item['unitPrice'] as int).toDouble() : (item['unitPrice'] as double? ?? 0.0);
      }
      
      // Get quantity
      int quantity = 0;
      if (item['quantity'] != null) {
        quantity = (item['quantity'] is int) ? (item['quantity'] as int) : int.tryParse(item['quantity'].toString()) ?? 0;
      }
      
      double total = price * quantity;
      print('Item: ${item['name']}, Price: $price, Quantity: $quantity, Total: $total');
      
      return total;
    } catch (e) {
      print('Error calculating item total: $e, Item data: $item');
      return 0.0;
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

  /// Get display text for service type
  String _getDisplayServiceType(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('ironing')) {
      return 'IRONING';
    } else if (type.contains('allied')) {
      return 'ALLIED SERVICE';
    } else if (type.contains('laundry')) {
      return 'LAUNDRY';
    }
    return serviceType.toUpperCase();
  }
}