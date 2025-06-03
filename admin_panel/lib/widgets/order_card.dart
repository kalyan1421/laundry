
// widgets/order_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(String)? onStatusChange;
  final Function(String)? onAssign;

  const OrderCard({
    super.key,
    required this.order,
    this.onStatusChange,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order #${order.id.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text(
                order.status.toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _getStatusColor(order.status),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.userName}'),
            Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Details
                const Text(
                  'Customer Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Phone: ${order.userPhone}'),
                Text('Payment: ${order.paymentMode}'),
                const SizedBox(height: 16),

                // Order Items
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.itemName} x${item.quantity}'),
                      Text('₹${item.price * item.quantity}'),
                    ],
                  ),
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${order.totalAmount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                if (onStatusChange != null || onAssign != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (order.status == 'pending' && onAssign != null)
                        ElevatedButton(
                          onPressed: () => _showAssignDialog(context),
                          child: const Text('Assign'),
                        ),
                      const SizedBox(width: 8),
                      if (onStatusChange != null)
                        ElevatedButton(
                          onPressed: () => _showStatusDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Update Status'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade100;
      case 'assigned':
      case 'in_progress':
        return Colors.blue.shade100;
      case 'completed':
        return Colors.green.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('In Progress'),
              onTap: () {
                Navigator.pop(context);
                onStatusChange!('in_progress');
              },
            ),
            ListTile(
              title: const Text('Completed'),
              onTap: () {
                Navigator.pop(context);
                onStatusChange!('completed');
              },
            ),
            ListTile(
              title: const Text('Cancelled'),
              onTap: () {
                Navigator.pop(context);
                onStatusChange!('cancelled');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    // In a real app, you would fetch available delivery personnel
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to Delivery Person'),
        content: const Text('Select a delivery person from the list'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Assign to a delivery person (hardcoded for demo)
              onAssign!('delivery_person_id');
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}
