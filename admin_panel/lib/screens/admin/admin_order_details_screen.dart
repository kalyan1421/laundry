import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Assuming you have an OrderModel in your admin panel, adjust path if needed
import 'package:admin_panel/models/order_model.dart';
import '../../utils/phone_formatter.dart';
import 'edit_order_address_screen.dart';

class AdminOrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const AdminOrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Assuming your Admin OrderModel has a fromFirestore factory
          final order = OrderModel.fromFirestore(snapshot.data!);

          // TODO: Build your detailed order view UI here using order data
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: <Widget>[
                Row(
                  children: [
                    Text('Order ID: ${order.id}', style: Theme.of(context).textTheme.titleLarge),
                    if (order.serviceType != null && order.serviceType!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getServiceTypeColor(order.serviceType!).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getServiceTypeColor(order.serviceType!)),
                        ),
                        child: Text(
                          order.serviceType!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getServiceTypeColor(order.serviceType!),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text('Order Number: ${order.orderNumber}'),
                Text('Client ID: ${PhoneFormatter.getClientId(order.customer?.phoneNumber)}'),
                Text('Status: ${order.status}'),
                Text('Total Amount: ₹${order.totalAmount}'),
                Text('Payment Method: ${order.paymentMethod ?? "N/A"}'),
                Text('Order Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderTimestamp.toDate())}'),
                const SizedBox(height: 16),
                Text('Items:', style: Theme.of(context).textTheme.titleMedium),
                if (order.items.isNotEmpty)
                  ...order.items.map((item) => ListTile(
                        title: Text(item.name),
                        subtitle: Text('Qty: ${item.quantity}'),
                        trailing: Text('₹${item.pricePerPiece * item.quantity}'),
                      )).toList()
                else
                  const Text('No items in this order.'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Delivery Address:', style: Theme.of(context).textTheme.titleMedium),
                    if (order.deliveryAddressDetails?.addressId != null && order.customerId != null)
                      TextButton.icon(
                        onPressed: () => _editOrderAddress(context, order),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                  ],
                ),
                Text(order.deliveryAddress ?? 'N/A'),
                const SizedBox(height: 8),
                Text('Pickup Address:', style: Theme.of(context).textTheme.titleMedium),
                Text(order.pickupAddress ?? 'N/A'),
                // Add more details as needed: delivery timeslot, pickup timeslot, special instructions etc.
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getServiceTypeColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'laundry':
        return Colors.blue;
      case 'dry cleaning':
      case 'dry_cleaning':
        return Colors.purple;
      case 'ironing':
        return Colors.orange;
      case 'wash & iron':
      case 'wash_iron':
        return Colors.green;
      case 'express':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _editOrderAddress(BuildContext context, OrderModel order) async {
    if (order.deliveryAddressDetails?.addressId == null || order.customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit address: Missing address ID or customer ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to address editing screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditOrderAddressScreen(
          orderId: order.id,
          customerId: order.customerId!,
          addressId: order.deliveryAddressDetails!.addressId!,
          initialAddressData: order.deliveryAddressDetails?.toMap(),
        ),
      ),
    );

    // If address was updated, show success message and potentially refresh the screen
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup, delivery, and customer address updated successfully! Please refresh to see changes.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
} 