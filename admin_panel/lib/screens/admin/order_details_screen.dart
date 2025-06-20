import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/fcm_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  OrderModel? _order;
  List<DocumentSnapshot> _deliveryPersons = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  
  final List<String> _orderStatuses = [
    'pending',
    'confirmed', 
    'assigned',
    'picked_up',
    'processing',
    'ready_for_delivery',
    'out_for_delivery',
    'delivered',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _loadDeliveryPersons();
  }

  Future<void> _loadOrderDetails() async {
    try {
      DocumentSnapshot orderDoc = await _firestore
          .collection('orders')
          .doc(widget.orderId)
          .get();
      
      if (orderDoc.exists) {
        setState(() {
          _order = OrderModel.fromFirestore(orderDoc as DocumentSnapshot<Map<String, dynamic>>);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading order: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeliveryPersons() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('delivery')
          .where('isActive', isEqualTo: true)
          .get();
      
      setState(() {
        _deliveryPersons = snapshot.docs;
      });
    } catch (e) {
      print('Error loading delivery persons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Order not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            const SizedBox(height: 16),
            _buildOrderStatus(),
            const SizedBox(height: 16),
            _buildCustomerInfo(),
            const SizedBox(height: 16),
            _buildItemsList(),
            const SizedBox(height: 16),
            _buildAddressInfo(),
            const SizedBox(height: 16),
            _buildDeliveryAssignment(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order!.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _order!.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${DateFormat('MMM d, yyyy • h:mm a').format(_order!.orderTimestamp.toDate())}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 20, color: Colors.green[600]),
                Text(
                  '₹${_order!.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _order!.status,
                    decoration: const InputDecoration(
                      labelText: 'Current Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _orderStatuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null && newStatus != _order!.status) {
                        _updateOrderStatus(newStatus);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('Customer ID: ${_order!.userId}'),
            if (_order!.specialInstructions != null && _order!.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Special Instructions: ${_order!.specialInstructions}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue[700],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text('Payment Method: ${_order!.paymentMethod}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${_order!.items.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._order!.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name'] ?? 'Unknown Item'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text('Qty: ${item['quantity'] ?? 1}'),
                    const SizedBox(width: 16),
                    Text(
                      '₹${(item['price'] ?? 0).toString()}',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pickup: ${_order!.pickupAddress}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delivery: ${_order!.deliveryAddress}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'Pickup: ${_order!.pickupDate != null ? DateFormat('MMM d, yyyy').format(_order!.pickupDate!.toDate()) : 'TBD'} (${_order!.pickupTimeSlot ?? 'TBD'})',
                ),
              ],
            ),
            if (_order!.deliveryDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.purple[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery: ${DateFormat('MMM d, yyyy').format(_order!.deliveryDate!.toDate())} (${_order!.deliveryTimeSlot ?? 'TBD'})',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAssignment() {
    bool isAssigned = _order!.assignedDeliveryPerson != null;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Assignment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isAssigned) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Assigned to: ${_order!.assignedDeliveryPersonName ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_order!.assignedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Assigned on: ${DateFormat('MMM d, yyyy • h:mm a').format(_order!.assignedAt!.toDate())}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    Row(
                      children: [
                        Icon(
                          _order!.isAcceptedByDeliveryPerson 
                              ? Icons.check_circle 
                              : Icons.schedule,
                          color: _order!.isAcceptedByDeliveryPerson 
                              ? Colors.green[600] 
                              : Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _order!.isAcceptedByDeliveryPerson 
                              ? 'Accepted by delivery person'
                              : 'Waiting for acceptance',
                          style: TextStyle(
                            color: _order!.isAcceptedByDeliveryPerson 
                                ? Colors.green[600] 
                                : Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showReassignDialog,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Reassign Delivery Person'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'No delivery person assigned',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showAssignDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Assign Delivery Person'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _order!.notificationSentToAdmin 
                ? null 
                : () => _sendNotificationToAdmin(),
            icon: Icon(_order!.notificationSentToAdmin 
                ? Icons.notifications_active 
                : Icons.notifications),
            label: Text(_order!.notificationSentToAdmin 
                ? 'Notification Sent' 
                : 'Send Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _order!.notificationSentToAdmin 
                  ? Colors.grey 
                  : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showStatusHistoryDialog(),
            icon: const Icon(Icons.history),
            label: const Text('View History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
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
      case 'processing':
        return Colors.indigo;
      case 'ready_for_delivery':
        return Colors.amber[700]!;
      case 'out_for_delivery':
        return Colors.deepOrange;
      case 'delivered':
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    
    try {
      await _firestore.collection('orders').doc(widget.orderId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
      
      // Reload order details
      await _loadOrderDetails();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showAssignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Delivery Person'),
        content: SizedBox(
          width: double.maxFinite,
          child: _deliveryPersons.isEmpty
              ? const Text('No delivery persons available')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _deliveryPersons.length,
                  itemBuilder: (context, index) {
                    final person = _deliveryPersons[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (person['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(person['name'] ?? 'Unknown'),
                      subtitle: Text(person['phoneNumber'] ?? 'No phone'),
                      onTap: () => _assignDeliveryPerson(_deliveryPersons[index]),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReassignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Delivery Person'),
        content: SizedBox(
          width: double.maxFinite,
          child: _deliveryPersons.isEmpty
              ? const Text('No delivery persons available')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _deliveryPersons.length,
                  itemBuilder: (context, index) {
                    final person = _deliveryPersons[index].data() as Map<String, dynamic>;
                    final isCurrentlyAssigned = _deliveryPersons[index].id == _order!.assignedDeliveryPerson;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrentlyAssigned ? Colors.green : null,
                        child: Text(
                          (person['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(person['name'] ?? 'Unknown'),
                      subtitle: Text(
                        isCurrentlyAssigned 
                            ? 'Currently assigned' 
                            : (person['phoneNumber'] ?? 'No phone'),
                      ),
                      trailing: isCurrentlyAssigned 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: isCurrentlyAssigned 
                          ? null 
                          : () => _assignDeliveryPerson(_deliveryPersons[index]),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignDeliveryPerson(DocumentSnapshot deliveryPersonDoc) async {
    Navigator.pop(context); // Close dialog
    setState(() => _isUpdating = true);
    
    try {
      final person = deliveryPersonDoc.data() as Map<String, dynamic>;
      
      await _firestore.collection('orders').doc(widget.orderId).update({
        'assignedDeliveryPerson': deliveryPersonDoc.id,
        'assignedDeliveryPersonName': person['name'] ?? 'Unknown',
        'assignedBy': _auth.currentUser?.uid,
        'assignedAt': Timestamp.now(),
        'isAcceptedByDeliveryPerson': false,
        'status': 'assigned',
        'updatedAt': Timestamp.now(),
      });
      
      // Send notification to delivery person
      await _sendNotificationToDeliveryPerson(deliveryPersonDoc.id, person['name'] ?? 'Unknown');
      
      // Reload order details
      await _loadOrderDetails();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order assigned to ${person['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning delivery person: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _sendNotificationToAdmin() async {
    // This would call the Cloud Function to resend admin notification
    // For now, just mark as sent
    try {
      await _firestore.collection('orders').doc(widget.orderId).update({
        'notificationSentToAdmin': true,
        'updatedAt': Timestamp.now(),
      });
      
      await _loadOrderDetails();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin notification sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _order!.statusHistory.isEmpty
              ? const Center(child: Text('No status history available'))
              : ListView.builder(
                  itemCount: _order!.statusHistory.length,
                  itemBuilder: (context, index) {
                    final history = _order!.statusHistory[index];
                    return ListTile(
                      leading: Icon(
                        Icons.circle,
                        color: _getStatusColor(history['status'] ?? ''),
                        size: 12,
                      ),
                      title: Text((history['status'] ?? 'Unknown').toUpperCase()),
                      subtitle: history['timestamp'] != null
                          ? Text(DateFormat('MMM d, yyyy • h:mm a').format(
                              (history['timestamp'] as Timestamp).toDate(),
                            ))
                          : null,
                    );
                  },
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

  Future<void> _sendNotificationToDeliveryPerson(String deliveryPartnerId, String deliveryPartnerName) async {
    try {
      await FcmService.sendNotificationToDeliveryPartner(
        deliveryPartnerId: deliveryPartnerId,
        title: 'New Order Assignment',
        body: 'You have been assigned to Order #${_order!.orderNumber ?? _order!.id.substring(0, 8)}',
        data: {
          'type': 'order_assignment',
          'orderId': widget.orderId,
          'orderNumber': _order!.orderNumber ?? _order!.id.substring(0, 8),
          'customerName': _order!.customer?.name ?? 'Unknown',
          'amount': _order!.totalAmount.toString(),
        },
      );
      print('Notification sent to delivery partner: $deliveryPartnerName');
    } catch (e) {
      print('Error sending notification to delivery partner: $e');
    }
  }
} 