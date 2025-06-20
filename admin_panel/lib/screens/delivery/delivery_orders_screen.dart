import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _selectedTab = 'assigned'; // assigned, accepted, completed

  Stream<QuerySnapshot> _getOrdersStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    Query query = _firestore
        .collection('orders')
        .where('assignedDeliveryPerson', isEqualTo: currentUser.uid);

    switch (_selectedTab) {
      case 'assigned':
        query = query.where('isAcceptedByDeliveryPerson', isEqualTo: false);
        break;
      case 'accepted':
        query = query.where('isAcceptedByDeliveryPerson', isEqualTo: true)
                    .where('status', whereIn: ['assigned', 'picked_up', 'in_progress', 'out_for_delivery']);
        break;
      case 'completed':
        query = query.where('status', whereIn: ['delivered', 'completed']);
        break;
    }

    return query.orderBy('assignedAt', descending: true).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('assigned', 'Assigned', Icons.assignment),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('accepted', 'Active', Icons.work),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('completed', 'Completed', Icons.check_circle),
                ),
              ],
            ),
          ),
          
          // Orders list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final orders = snapshot.data?.docs ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getEmptyIcon(),
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyMessage(),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(orders[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, IconData icon) {
    bool isSelected = _selectedTab == tabId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (_selectedTab) {
      case 'assigned':
        return Icons.assignment_outlined;
      case 'accepted':
        return Icons.work_outline;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.inbox_outlined;
    }
  }

  String _getEmptyMessage() {
    switch (_selectedTab) {
      case 'assigned':
        return 'No new assignments';
      case 'accepted':
        return 'No active orders';
      case 'completed':
        return 'No completed orders';
      default:
        return 'No orders found';
    }
  }

  Widget _buildOrderCard(DocumentSnapshot orderDoc) {
    Map<String, dynamic> order = orderDoc.data() as Map<String, dynamic>;
    String orderId = orderDoc.id;
    
    bool isAccepted = order['isAcceptedByDeliveryPerson'] ?? false;
    String status = order['status'] ?? 'assigned';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Order value and items
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 16, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text(
                  '₹${(order['totalAmount'] ?? 0).toString()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[600],
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.shopping_bag, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${(order['items'] as List?)?.length ?? 0} items'),
              ],
            ),
            const SizedBox(height: 12),
            
            // Pickup details
            if (order['pickupDate'] != null) ...[
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Pickup: ${DateFormat('MMM d, yyyy').format((order['pickupDate'] as Timestamp).toDate())}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Time: ${order['pickupTimeSlot'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Pickup address
            if (order['pickupAddress'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatAddress(order['pickupAddress']),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Action buttons based on tab
            if (_selectedTab == 'assigned') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectOrder(orderDoc),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(orderDoc),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_selectedTab == 'accepted') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showOrderDetails(orderDoc),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(orderDoc),
                      icon: const Icon(Icons.update, size: 16),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_selectedTab == 'completed') ...[
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _showOrderDetails(orderDoc),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAddress(dynamic address) {
    if (address is String) {
      return address;
    } else if (address is Map) {
      return address['formatted'] ?? address.toString();
    }
    return 'N/A';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.orange;
      case 'in_progress':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.deepOrange;
      case 'delivered':
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _acceptOrder(DocumentSnapshot orderDoc) async {
    try {
      await _firestore.collection('orders').doc(orderDoc.id).update({
        'isAcceptedByDeliveryPerson': true,
        'acceptedAt': Timestamp.now(),
        'status': 'accepted',
        'updatedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrder(DocumentSnapshot orderDoc) async {
    // Show reason dialog
    String? rejectionReason;
    
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this order:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                rejectionReason = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('orders').doc(orderDoc.id).update({
          'assignedDeliveryPerson': null,
          'assignedDeliveryPersonName': null,
          'assignedAt': null,
          'isAcceptedByDeliveryPerson': false,
          'rejectionReason': rejectionReason ?? 'No reason provided',
          'status': 'pending',
          'updatedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected and returned to admin'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderDetails(DocumentSnapshot orderDoc) {
    Map<String, dynamic> order = orderDoc.data() as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${orderDoc.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', order['status'] ?? 'N/A'),
              _buildDetailRow('Total Amount', '₹${order['totalAmount'] ?? 0}'),
              _buildDetailRow('Payment Method', order['paymentMethod'] ?? 'N/A'),
              if (order['pickupDate'] != null)
                _buildDetailRow(
                  'Pickup Date',
                  DateFormat('MMM d, yyyy').format((order['pickupDate'] as Timestamp).toDate()),
                ),
              _buildDetailRow('Pickup Time', order['pickupTimeSlot'] ?? 'N/A'),
              _buildDetailRow('Pickup Address', _formatAddress(order['pickupAddress'])),
              if (order['deliveryAddress'] != null)
                _buildDetailRow('Delivery Address', _formatAddress(order['deliveryAddress'])),
              if (order['specialInstructions'] != null && order['specialInstructions'].toString().isNotEmpty)
                _buildDetailRow('Special Instructions', order['specialInstructions']),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (order['items'] != null)
                ...((order['items'] as List).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${item['name']} (${item['quantity']}x) - ₹${item['pricePerPiece']}/pc'),
                ))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(DocumentSnapshot orderDoc) {
    Map<String, dynamic> order = orderDoc.data() as Map<String, dynamic>;
    String currentStatus = order['status'] ?? 'accepted';
    String? selectedStatus = currentStatus;
    
    // Status progression for delivery person
    List<String> statusOptions = [
      'accepted',
      'picked_up',
      'in_progress',
      'out_for_delivery',
      'delivered',
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current status: ${currentStatus.toUpperCase().replaceAll('_', ' ')}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'New Status',
                  border: OutlineInputBorder(),
                ),
                value: selectedStatus,
                items: statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.toUpperCase().replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedStatus = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStatus != null && selectedStatus != currentStatus
                  ? () => _updateOrderStatus(orderDoc, selectedStatus!)
                  : null,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(DocumentSnapshot orderDoc, String newStatus) async {
    try {
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      };

      // If delivered, mark as completed
      if (newStatus == 'delivered') {
        updateData['completedAt'] = Timestamp.now();
        updateData['status'] = 'completed';
      }

      await _firestore.collection('orders').doc(orderDoc.id).update(updateData);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.toUpperCase().replaceAll('_', ' ')}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 