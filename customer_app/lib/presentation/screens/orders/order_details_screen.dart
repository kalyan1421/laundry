import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:customer_app/services/order_notification_service.dart';
import 'package:customer_app/presentation/screens/orders/order_tracking_screen.dart';
import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isCancelling = false;

  Future<void> _cancelOrder() async {
    final TextEditingController reasonController = TextEditingController();
    bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter cancellation reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) return;

    String reason = reasonController.text.trim();
    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a cancellation reason')),
        );
      }
      return;
    }

    setState(() => _isCancelling = true);

    try {
      // Update order status
      await _firestore.collection('orders').doc(widget.order.id).update({
        'status': 'cancelled',
        'cancelReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'cancelled',
            'timestamp': Timestamp.now(),
            'reason': reason,
            'updatedBy': 'customer',
            'title': 'Order Cancelled',
            'description': 'Order cancelled by customer: $reason',
          }
        ]),
      });

      // Send notification to admin
      await OrderNotificationService.notifyAdminOfOrderCancellation(
        orderId: widget.order.id,
        orderNumber: widget.order.orderNumber ?? 'N/A',
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error cancelling order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        foregroundColor: context.onBackgroundColor,
        title: Text('Order #${widget.order.orderNumber ?? widget.order.id}'),
      ),
      body: _isCancelling
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order status
                  _buildStatusSection(),
                  const Divider(),

                  // Order details
                  _buildOrderDetails(),
                  const Divider(),

                  // Items
                  _buildItemsList(),
                  const Divider(),

                  // Addresses
                  _buildAddressSection(),
                  const Divider(),

                  // Payment details
                  _buildPaymentSection(),
                  const SizedBox(height: 16),

                  // Action buttons row
                  Row(
                    children: [
                      // Track Order button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to order tracking screen with the specific order
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderTrackingScreen(order: widget.order),
                              ),
                            );
                          },
                          icon: const Icon(Icons.track_changes, color: Colors.white),
                          label: const Text('Track Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3057),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      
                      // Cancel button (only show if order is cancellable)
                      if (_canCancelOrder()) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _cancelOrder,
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text('Cancel Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  bool _canCancelOrder() {
    // Define cancellable statuses
    const cancellableStatuses = ['pending', 'confirmed'];
    return cancellableStatuses.contains(widget.order.status.toLowerCase());
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${_formatStatus(widget.order.status)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.order.status.toLowerCase() == 'cancelled')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Reason: ${widget.order.statusHistory.lastWhere((h) => h['status'] == 'cancelled')['reason'] ?? 'No reason provided'}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildOrderDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${widget.order.orderNumber ?? widget.order.id}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Placed on: ${_formatDate(widget.order.orderTimestamp)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // Service Type section
            Row(
              children: [
                Icon(
                  _getServiceIcon(widget.order.serviceType),
                  color: _getServiceColor(widget.order.serviceType),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Service Type: ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getServiceColor(widget.order.serviceType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getServiceColor(widget.order.serviceType).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    widget.order.serviceType,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getServiceColor(widget.order.serviceType),
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
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                return ListTile(
                  title: Text(item['name'] ?? 'Unknown Item'),
                  subtitle: Text('${_getItemQuantity(item)} x ₹${_getItemPrice(item).toStringAsFixed(2)}'),
                  trailing: Text(
                    '₹${(_getItemQuantity(item) * _getItemPrice(item)).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: ₹${(widget.order.totalAmount ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Addresses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAddressCard('Pickup Address', widget.order.pickupAddress),
            const SizedBox(height: 8),
            _buildAddressCard('Delivery Address', widget.order.deliveryAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(String title, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(address),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Method: ${widget.order.paymentMethod}'),
            // Add more payment details as needed
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'ironing service':
      case 'ironing':
        return Icons.iron;
      case 'laundry service':
      case 'laundry':
        return Icons.local_laundry_service;
      case 'allied service':
      case 'allied':
        return Icons.cleaning_services;
      case 'mixed':
        return Icons.miscellaneous_services;
      default:
        return Icons.room_service;
    }
  }

  Color _getServiceColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'ironing service':
      case 'ironing':
        return Colors.orange;
      case 'laundry service':
      case 'laundry':
        return Colors.blue;
      case 'allied service':
      case 'allied':
        return Colors.green;
      case 'mixed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  int _getItemQuantity(Map<String, dynamic> item) {
    // Handle different possible field names and types
    final quantity = item['quantity'];
    if (quantity == null) return 0;
    if (quantity is int) return quantity;
    if (quantity is double) return quantity.toInt();
    if (quantity is String) return int.tryParse(quantity) ?? 0;
    return 0;
  }

  double _getItemPrice(Map<String, dynamic> item) {
    // Handle different possible field names and types for price
    double price = 0.0;
    
    // Try different field names for price
    final priceValue = item['price'] ?? item['pricePerPiece'] ?? item['unitPrice'] ?? 0;
    
    if (priceValue == null) return 0.0;
    if (priceValue is double) return priceValue;
    if (priceValue is int) return priceValue.toDouble();
    if (priceValue is String) return double.tryParse(priceValue) ?? 0.0;
    
    return price;
  }
}
