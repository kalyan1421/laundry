// widgets/order_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/user_model.dart'; // Import UserModel if not already imported
import '../utils/phone_formatter.dart';

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${order.id.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer: ${PhoneFormatter.getClientId(order.customer?.phoneNumber)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
            if (order.customer?.name != null)
              Text('Name: ${order.customer!.name}'),
            Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderTimestamp.toDate())}'),
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
                Text('Client ID: ${PhoneFormatter.getClientId(order.customer?.phoneNumber)}'),
                if (order.customer?.email != null && order.customer!.email.isNotEmpty)
                  Text('Email: ${order.customer!.email}'),
                Text('Payment: ${order.paymentMethod ?? "N/A"}'),
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
                      Text('${item.name} x${item.quantity}'),
                      Text('₹${item.pricePerPiece * item.quantity}'),
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
        return Colors.orange[100]!;
      case 'confirmed':
        return Colors.blue[100]!;
      case 'assigned':
        return Colors.purple[100]!;
      case 'picked_up':
        return Colors.indigo[100]!;
      case 'processing':
        return Colors.amber[100]!;
      case 'ready_for_delivery':
        return Colors.teal[100]!;
      case 'out_for_delivery':
        return Colors.cyan[100]!;
      case 'delivered':
        return Colors.green[100]!;
      case 'completed':
        return Colors.green[200]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
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
