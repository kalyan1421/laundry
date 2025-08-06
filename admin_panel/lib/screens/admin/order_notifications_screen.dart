import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'order_details_screen.dart';

class OrderNotificationsScreen extends StatefulWidget {
  const OrderNotificationsScreen({super.key});

  @override
  State<OrderNotificationsScreen> createState() => _OrderNotificationsScreenState();
}

class _OrderNotificationsScreenState extends State<OrderNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';
  
  final Map<String, String> _filterOptions = {
    'all': '📋 All Notifications',
    'new_order': '🆕 New Orders',
    'order_edit': '✏️ Order Edits',
    'order_cancellation': '❌ Cancellations',
    'status_change': '🔄 Status Changes',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.notifications_active, color: Colors.blue[600], size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Order Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Filter:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filterOptions.entries.map((entry) {
                            final isSelected = _selectedFilter == entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = entry.key;
                                  });
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: Colors.blue[100],
                                checkmarkColor: Colors.blue[600],
                                side: BorderSide(
                                  color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Notifications List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text('Error loading notifications', style: TextStyle(color: Colors.red[600])),
                        const SizedBox(height: 8),
                        Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];
                
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No notifications found', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getNotificationsStream() {
    Query query = _firestore.collectionGroup('notifications');
    
    // Filter by forAdmin = true to only show admin notifications
    query = query.where('forAdmin', isEqualTo: true);
    
    // Apply type filter if not 'all'
    if (_selectedFilter != 'all') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }
    
    // Order by creation time
    query = query.orderBy('createdAt', descending: true);
    
    // Limit to recent notifications
    query = query.limit(100);
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'orderId': doc.reference.parent.parent?.id,
          ...data,
        };
      }).toList();
    });
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] as String;
    final title = notification['title'] as String;
    final body = notification['body'] as String;
    final orderId = notification['orderId'] as String?;
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final createdAt = notification['createdAt'] as Timestamp?;
    final isRead = notification['read'] as bool? ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isRead ? Colors.grey[200]! : _getNotificationColor(type).withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getNotificationIcon(type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                  color: isRead ? Colors.grey[700] : Colors.black87,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              createdAt != null ? _formatTimestamp(createdAt) : 'Just now',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (orderId != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.receipt_long, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Order #${orderId.substring(0, 8)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Body
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  color: isRead ? Colors.grey[600] : Colors.grey[800],
                  height: 1.4,
                ),
              ),
              
              // Additional Info
              if (data.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildAdditionalInfo(type, data),
              ],
              
              // Actions
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (orderId != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        onPressed: () => _navigateToOrder(orderId),
                        icon: Icon(Icons.visibility, size: 16, color: Colors.blue[600]),
                        label: Text(
                          'View Order',
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ),
                  if (!isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        onPressed: () => _markAsRead(notification),
                        icon: Icon(Icons.check, size: 16, color: Colors.green[600]),
                        label: Text(
                          'Mark Read',
                          style: TextStyle(color: Colors.green[600]),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'new_order':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.add_shopping_cart, color: Colors.green[600], size: 20),
        );
      case 'order_edit':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.edit, color: Colors.orange[600], size: 20),
        );
      case 'order_cancellation':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.cancel, color: Colors.red[600], size: 20),
        );
      case 'status_change':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.sync, color: Colors.blue[600], size: 20),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.notifications, color: Colors.grey[600], size: 20),
        );
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_order':
        return Colors.green;
      case 'order_edit':
        return Colors.orange;
      case 'order_cancellation':
        return Colors.red;
      case 'status_change':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAdditionalInfo(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'new_order':
        return _buildOrderInfo(data);
      case 'order_edit':
        return _buildEditInfo(data);
      case 'order_cancellation':
        return _buildCancellationInfo(data);
      case 'status_change':
        return _buildStatusChangeInfo(data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOrderInfo(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['orderNumber'] != null)
            Text('Order #${data['orderNumber']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (data['customerName'] != null)
            Text('Customer: ${data['customerName']}'),
          if (data['customerPhone'] != null)
            Text('Phone: ${data['customerPhone']}'),
          if (data['totalAmount'] != null)
            Text('Amount: ₹${data['totalAmount']}'),
          if (data['itemCount'] != null)
            Text('Items: ${data['itemCount']}'),
        ],
      ),
    );
  }

  Widget _buildEditInfo(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Changes:', style: TextStyle(fontWeight: FontWeight.bold)),
          if (data['itemCount'] != null)
            Text('• Items: ${data['itemCount']}'),
          if (data['totalAmount'] != null)
            Text('• Total: ₹${data['totalAmount']}'),
        ],
      ),
    );
  }

  Widget _buildCancellationInfo(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['reason'] != null)
            Text('Reason: ${data['reason']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (data['customerName'] != null)
            Text('Customer: ${data['customerName']}'),
        ],
      ),
    );
  }

  Widget _buildStatusChangeInfo(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['oldStatus'] != null && data['newStatus'] != null)
            Text('${data['oldStatus']} → ${data['newStatus']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read when tapped
    _markAsRead(notification);
    
    // Navigate to order if available
    final orderId = notification['orderId'] as String?;
    if (orderId != null) {
      _navigateToOrder(orderId);
    }
  }

  void _navigateToOrder(String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(orderId: orderId),
      ),
    );
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    try {
      final orderId = notification['orderId'] as String?;
      final notificationId = notification['id'] as String?;
      
      if (orderId != null && notificationId != null) {
        await _firestore
            .collection('orders')
            .doc(orderId)
            .collection('notifications')
            .doc(notificationId)
            .update({
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
} 