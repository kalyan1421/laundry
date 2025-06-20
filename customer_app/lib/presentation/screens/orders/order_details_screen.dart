import 'package:customer_app/data/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.orderNumber}'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F3057)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF0F3057),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('Order Summary'),
            _buildDetailRow('Order ID:', '#${order.orderNumber}'),
            _buildDetailRow('Status:', order.status),
            _buildDetailRow('Order Date:', DateFormat('EEE, MMM d, yyyy - hh:mm a').format(order.orderTimestamp.toDate())),
            _buildDetailRow('Service Type:', order.serviceType),
            _buildDetailRow('Total Amount:', '₹${order.totalAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Payment Method:', order.paymentMethod),
            const SizedBox(height: 20),

            _buildSectionTitle('Pickup Details'),
            _buildDetailRow('Address:', order.pickupAddress),
            _buildDetailRow('Date:', DateFormat('EEE, MMM d, yyyy').format(order.pickupDate.toDate())),
            _buildDetailRow('Time Slot:', order.pickupTimeSlot),
            const SizedBox(height: 20),

            if (order.deliveryDate != null && order.deliveryTimeSlot != null) ...[
              _buildSectionTitle('Delivery Details'),
              _buildDetailRow('Address:', order.deliveryAddress),
              _buildDetailRow('Date:', DateFormat('EEE, MMM d, yyyy').format(order.deliveryDate!.toDate())),
              _buildDetailRow('Time Slot:', order.deliveryTimeSlot!),
              const SizedBox(height: 20),
            ],
            
            if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Special Instructions'),
                  Text(order.specialInstructions!, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 20),
                ],
              ),

            _buildSectionTitle('Items Ordered (${order.items.length})'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(item['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('Category: ${item['category'] ?? 'N/A'}'),
                    trailing: Text('Qty: ${item['quantity'] ?? 0} x ₹${(item['pricePerPiece'] ?? 0).toStringAsFixed(0)}'),
                  ),
                );
              },
            ),
            // TODO: Add more details as needed, e.g., tracking history, customer details (if admin view)
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F3057)),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
