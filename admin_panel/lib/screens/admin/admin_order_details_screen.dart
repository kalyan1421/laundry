import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Assuming you have an OrderModel in your admin panel, adjust path if needed
import 'package:admin_panel/models/order_model.dart'; 

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
                Text('Order ID: ${order.id}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Order Number: ${order.orderNumber}'),
                Text('Customer User ID: ${order.userId}'),
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
                Text('Delivery Address:', style: Theme.of(context).textTheme.titleMedium),
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
} 