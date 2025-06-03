
// screens/admin/all_orders.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/order_card.dart';

class AllOrders extends StatelessWidget {
  const AllOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      body: StreamBuilder<List<OrderModel>>(
        stream: orderProvider.getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No orders found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final order = snapshot.data![index];
              return OrderCard(
                order: order,
                onStatusChange: (newStatus) async {
                  await orderProvider.updateOrderStatus(order.id, newStatus);
                },
                onAssign: (deliveryPersonId) async {
                  await orderProvider.assignOrder(order.id, deliveryPersonId);
                },
              );
            },
          );
        },
      ),
    );
  }
}