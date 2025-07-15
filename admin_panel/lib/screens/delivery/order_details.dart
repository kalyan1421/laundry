// screens/delivery/order_details.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../models/user_model.dart';
import '../../utils/phone_formatter.dart';
import 'map_navigation.dart';

class OrderDetails extends StatelessWidget {
  final OrderModel order;

  const OrderDetails({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = order.orderNumber != null && order.orderNumber!.isNotEmpty
        ? 'Order #${order.orderNumber}'
        : 'Order #${order.id.substring(0, 8)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Name: ${order.customer?.name ?? "N/A"}'),
                    const SizedBox(height: 4),
                    Text('Client ID: ${PhoneFormatter.getClientId(order.customer?.phoneNumber)}'),
                    const SizedBox(height: 4),
                    Text('Phone: ${order.customer?.phoneNumber ?? "N/A"}'),
                    if (order.customer?.email != null && order.customer!.email.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Email: ${order.customer!.email}'),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: order.customer?.phoneNumber != null && order.customer!.phoneNumber!.isNotEmpty
                                 ? () => _makePhoneCall(order.customer!.phoneNumber!)
                                 : null,
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call Customer'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Items
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${item.name} (x${item.quantity})')),
                              Text('₹${(item.pricePerPiece * item.quantity).toStringAsFixed(2)}'),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
                    ),
                    const Divider(height: 20, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Addresses Card
            if (order.pickupAddress != null || order.deliveryAddress != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.pickupAddress != null && order.pickupAddress!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pickup Address:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(order.pickupAddress!),
                          const SizedBox(height: 12),
                        ],
                      ),
                    if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Address:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(order.deliveryAddress!),
                        ],
                      ),
                  ],), 
              )
            ),
            const SizedBox(height: 16),

            // Payment & Status
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Mode:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Chip(
                          label: Text(order.paymentMethod?.toUpperCase() ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.w500)
                          ),
                          backgroundColor: order.paymentMethod?.toLowerCase() == 'cash'
                              ? Colors.green.shade100
                              : Colors.blue.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Chip(
                          label: Text(order.status.toUpperCase(), 
                            style: const TextStyle(fontWeight: FontWeight.w500)
                          ),
                          backgroundColor: _getStatusColor(order.status),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (order.pickupAddress != null && order.pickupAddress!.isNotEmpty) || (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                      ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapNavigation(
                              pickupAddress: order.pickupAddress,
                              deliveryAddress: order.deliveryAddress,
                            ),
                          ),
                        );
                      }
                      : null,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getNextStatus(order.status) != null 
                      ? () => _updateOrderStatus(context)
                      : null,
                    icon: const Icon(Icons.sync_alt_rounded),
                    label: Text(_getNextStatusText(order.status)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getNextStatus(order.status) == null ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Consider showing a snackbar or log if can't launch
        print('Could not launch $launchUri');
      }
    } catch (e) {
      print('Error launching phone call: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange.shade200;
      case 'confirmed': return Colors.blue.shade200;
      case 'assigned': return Colors.lightBlue.shade300;
      case 'processing':
      case 'in_progress': return Colors.indigo.shade200;
      case 'ready_for_pickup': return Colors.teal.shade200;
      case 'out_for_delivery': return Colors.purple.shade200;
      case 'delivered':
      case 'completed': return Colors.green.shade300;
      case 'cancelled': return Colors.red.shade300;
      case 'on_hold': return Colors.amber.shade300;
      default: return Colors.grey.shade300;
    }
  }
  
  String? _getNextStatus(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'pending': return 'confirmed';
      case 'confirmed': return 'processing'; // Or 'assigned' if that's the flow
      case 'assigned': return 'in_progress'; // Or 'out_for_pickup' etc.
      case 'processing': return 'ready_for_pickup';
      case 'in_progress': return 'out_for_delivery'; // Assuming this is after pickup for a delivery service type
      case 'ready_for_pickup': return 'out_for_delivery'; // If it's a pickup by customer, then 'completed'
      case 'out_for_delivery': return 'delivered';
      // 'delivered' and 'completed' are terminal unless there's a return/issue flow
      // 'cancelled' is also terminal
      default: return null;
    }
  }

  String _getNextStatusText(String currentStatus) {
    String? nextStatus = _getNextStatus(currentStatus);
    if (nextStatus == null) {
      if (currentStatus.toLowerCase() == 'completed' || currentStatus.toLowerCase() == 'delivered' || currentStatus.toLowerCase() == 'cancelled') {
          return currentStatus.toUpperCase(); // Show current status if terminal
      }
      return 'Update Status';
    }
    // Simple capitalization for display
    return 'Mark as ${nextStatus[0].toUpperCase()}${nextStatus.substring(1)}';
  }

  void _updateOrderStatus(BuildContext context) async {
    String? newStatus = _getNextStatus(order.status);

    if (newStatus != null && newStatus != order.status) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      try {
        await orderProvider.updateOrderStatus(order.id, newStatus);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order status updated to $newStatus'), backgroundColor: Colors.green),
          );
          // Optionally pop if this screen is on top of a list that needs refresh
          // Navigator.pop(context); 
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No further status update available or status is terminal.'), backgroundColor: Colors.amber),
        );
    }
  }
}
