import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _selectedFilter = 'all';
  List<DocumentSnapshot> _deliveryPersons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryPersons();
  }

  Future<void> _loadDeliveryPersons() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'delivery')
          .get();
      
      setState(() {
        _deliveryPersons = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading delivery persons: $e');
      setState(() => _isLoading = false);
    }
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    Query query = _firestore.collection('orders');
    
    switch (_selectedFilter) {
      case 'pending':
        query = query.where('status', isEqualTo: 'pending');
        break;
      case 'assigned':
        query = query.where('assignedDeliveryPerson', isNotEqualTo: null);
        break;
      case 'unassigned':
        query = query.where('assignedDeliveryPerson', isEqualTo: null);
        break;
      case 'completed':
        query = query.where('status', isEqualTo: 'completed');
        break;
      // 'all' case - no additional filter
    }
    
    return query.orderBy('updatedAt', descending: true).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Orders')),
              const PopupMenuItem(value: 'pending', child: Text('Pending Orders')),
              const PopupMenuItem(value: 'unassigned', child: Text('Unassigned Orders')),
              const PopupMenuItem(value: 'assigned', child: Text('Assigned Orders')),
              const PopupMenuItem(value: 'completed', child: Text('Completed Orders')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Filter: ${_getFilterDisplayName(_selectedFilter)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
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
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
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

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all': return 'All Orders';
      case 'pending': return 'Pending Orders';
      case 'unassigned': return 'Unassigned Orders';
      case 'assigned': return 'Assigned Orders';
      case 'completed': return 'Completed Orders';
      default: return 'All Orders';
    }
  }

  Widget _buildOrderCard(DocumentSnapshot orderDoc) {
    Map<String, dynamic> order = orderDoc.data() as Map<String, dynamic>;
    String orderId = orderDoc.id;
    
    bool isAssigned = order['assignedDeliveryPerson'] != null;
    bool isAccepted = order['isAcceptedByDeliveryPerson'] ?? false;
    
    Color statusColor = _getStatusColor(order['status'] ?? 'pending');
    Color assignmentColor = isAssigned 
        ? (isAccepted ? Colors.green : Colors.orange)
        : Colors.red;

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
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (order['status'] ?? 'pending').toUpperCase(),
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
            
            // Order details
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '₹${(order['totalAmount'] ?? 0).toString()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.shopping_bag, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('${(order['items'] as List?)?.length ?? 0} items'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Pickup date and time
            if (order['pickupDate'] != null) ...[
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Pickup: ${DateFormat('MMM d, yyyy').format((order['pickupDate'] as Timestamp).toDate())}',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${order['pickupTimeSlot'] ?? 'N/A'})',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Assignment status
            Row(
              children: [
                Icon(
                  isAssigned ? Icons.person : Icons.person_off,
                  size: 16,
                  color: assignmentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isAssigned 
                      ? 'Assigned to ${order['assignedDeliveryPersonName'] ?? 'Unknown'}'
                      : 'Not assigned',
                  style: TextStyle(
                    color: assignmentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isAssigned && isAccepted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Accepted',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            // Action buttons
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
                if (!isAssigned) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAssignDialog(orderDoc),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Assign'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(orderDoc),
                      icon: const Icon(Icons.update, size: 16),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'picked_up':
        return Colors.teal;
      case 'in_progress':
        return Colors.indigo;
      case 'ready_for_delivery':
        return Colors.amber;
      case 'out_for_delivery':
        return Colors.deepOrange;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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
              _buildDetailRow('Payment Status', order['paymentStatus'] ?? 'N/A'),
              if (order['pickupDate'] != null)
                _buildDetailRow(
                  'Pickup Date',
                  DateFormat('MMM d, yyyy').format((order['pickupDate'] as Timestamp).toDate()),
                ),
              _buildDetailRow('Pickup Time', order['pickupTimeSlot'] ?? 'N/A'),
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
                  child: Text('• ${item['name']} (${item['quantity']}x)'),
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

  void _showAssignDialog(DocumentSnapshot orderDoc) {
    String? selectedDeliveryPersonId;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Delivery Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a delivery person for this order:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Delivery Person',
                  border: OutlineInputBorder(),
                ),
                value: selectedDeliveryPersonId,
                items: _deliveryPersons.map((person) {
                  Map<String, dynamic> data = person.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: person.id,
                    child: Text(data['name'] ?? data['email'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedDeliveryPersonId = value;
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
              onPressed: selectedDeliveryPersonId != null
                  ? () => _assignOrder(orderDoc, selectedDeliveryPersonId!)
                  : null,
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignOrder(DocumentSnapshot orderDoc, String deliveryPersonId) async {
    try {
      // Get delivery person details
      DocumentSnapshot deliveryPersonDoc = await _firestore
          .collection('users')
          .doc(deliveryPersonId)
          .get();
      
      Map<String, dynamic> deliveryPersonData = deliveryPersonDoc.data() as Map<String, dynamic>;
      String deliveryPersonName = deliveryPersonData['name'] ?? deliveryPersonData['email'] ?? 'Unknown';
      
      // Update order with assignment
      await _firestore.collection('orders').doc(orderDoc.id).update({
        'assignedDeliveryPerson': deliveryPersonId,
        'assignedDeliveryPersonName': deliveryPersonName,
        'assignedBy': _auth.currentUser?.uid,
        'assignedAt': Timestamp.now(),
        'status': 'assigned',
        'updatedAt': Timestamp.now(),
      });
      
      // Send notification to delivery person (you can implement this)
      // await NotificationService.sendOrderAssignmentNotification(...);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order assigned to $deliveryPersonName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusUpdateDialog(DocumentSnapshot orderDoc) {
    Map<String, dynamic> order = orderDoc.data() as Map<String, dynamic>;
    String currentStatus = order['status'] ?? 'pending';
    String? selectedStatus = currentStatus;
    
    List<String> statusOptions = [
      'pending',
      'confirmed',
      'assigned',
      'picked_up',
      'in_progress',
      'ready_for_delivery',
      'out_for_delivery',
      'delivered',
      'completed',
      'cancelled',
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current status: ${currentStatus.toUpperCase()}'),
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
      await _firestore.collection('orders').doc(orderDoc.id).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
      
      // Send notification to customer (you can implement this)
      // await NotificationService.sendStatusUpdateNotification(...);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.toUpperCase()}'),
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