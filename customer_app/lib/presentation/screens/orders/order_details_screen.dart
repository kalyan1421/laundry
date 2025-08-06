import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:customer_app/services/order_notification_service.dart';
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
      appBar: AppBar(
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

                  // Cancel button (only show if order is cancellable)
                  if (_canCancelOrder())
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _cancelOrder,
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text('Cancel Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
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
                  title: Text(item['name']),
                  subtitle: Text('${item['quantity']} x ₹${item['pricePerPiece']}'),
                  trailing: Text(
                    '₹${(item['quantity'] * item['pricePerPiece']).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: ₹${widget.order.totalAmount.toStringAsFixed(2)}',
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
}
