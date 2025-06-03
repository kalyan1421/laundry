
// screens/delivery/quick_order_notifications.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';

class QuickOrderNotifications extends StatelessWidget {
  final String userId;

  const QuickOrderNotifications({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: databaseService.getQuickOrderNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final deliveryNotifications = snapshot.data?.where((notification) {
            return notification['orderType'] == 'delivery' && 
                   notification['status'] == 'pending';
          }).toList() ?? [];

          if (deliveryNotifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No quick order requests',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: deliveryNotifications.length,
            itemBuilder: (context, index) {
              final notification = deliveryNotifications[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Quick Order Request',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Customer: ${notification['userName']}'),
                      Text('Phone: ${notification['userPhone']}'),
                      const SizedBox(height: 8),
                      const Text(
                        'Customer location available for pickup',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _rejectNotification(context, notification['id']),
                            child: const Text('Ignore'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _acceptNotification(context, notification['id']),
                            child: const Text('Accept'),
                          ),
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

  void _acceptNotification(BuildContext context, String notificationId) async {
    // Here you would typically create an order and assign it to the delivery person
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    await databaseService.updateQuickOrderStatus(notificationId, 'accepted');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick order accepted')),
      );
    }
  }

  void _rejectNotification(BuildContext context, String notificationId) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    await databaseService.updateQuickOrderStatus(notificationId, 'ignored');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick order ignored')),
      );
    }
  }
}