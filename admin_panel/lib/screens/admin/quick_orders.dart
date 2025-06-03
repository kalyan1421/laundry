
// screens/admin/quick_orders.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/order_provider.dart';

class QuickOrders extends StatelessWidget {
  const QuickOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: orderProvider.getQuickOrderNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No quick order requests'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data![index];
              final orderType = notification['orderType'] as String;
              final isCallType = orderType == 'call';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCallType ? Icons.phone : Icons.delivery_dining,
                            color: isCallType ? Colors.green : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCallType ? 'Call Request' : 'Delivery Request',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Customer: ${notification['userName']}'),
                      Text('Phone: ${notification['userPhone']}'),
                      if (!isCallType) ...[
                        const SizedBox(height: 8),
                        const Text('Location provided for delivery pickup'),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isCallType)
                            ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(notification['userPhone']),
                              icon: const Icon(Icons.phone),
                              label: const Text('Call Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          if (!isCallType) ...[
                            TextButton(
                              onPressed: () => _rejectQuickOrder(context, notification['id']),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _acceptQuickOrder(context, notification['id']),
                              child: const Text('Accept'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _acceptQuickOrder(BuildContext context, String notificationId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.updateQuickOrderStatus(notificationId, 'accepted');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick order accepted')),
      );
    }
  }

  void _rejectQuickOrder(BuildContext context, String notificationId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.updateQuickOrderStatus(notificationId, 'rejected');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick order rejected')),
      );
    }
  }
}