// screens/tasks/task_detail_screen.dart - Task Detail for Delivery Partners
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/item_service.dart';
import 'edit_order_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final OrderModel order;

  const TaskDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = false;
  final ItemService _itemService = ItemService();
  Map<String, Map<String, dynamic>> _itemDetails = {};

  bool get _isPickupTask {
    // Match the same statuses used in OrderProvider.getPickupTasksStream
    final pickupStatuses = ['assigned', 'confirmed', 'ready_for_pickup'];
    return pickupStatuses.contains(widget.order.status);
  }

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    // Extract item IDs from order
    final itemIds = widget.order.items
        .map((item) => item['itemId']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    if (itemIds.isNotEmpty) {
      print('📋 TaskDetail: Loading details for ${itemIds.length} items');
      final itemDetails = await _itemService.getItemsByIds(itemIds);
      
      if (mounted) {
        setState(() {
          _itemDetails = itemDetails;
        });
        print('📋 TaskDetail: Loaded ${itemDetails.length} item details');
      }
    }
  }

  bool _hasCoordinatesForAddress(dynamic address) {
    if (address is DeliveryAddress && address.latitude != null && address.longitude != null) {
      return true;
    }
    return widget.order.hasCoordinates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Text(
          _isPickupTask ? 'Pickup Task' : 'Delivery Task',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'SFProDisplay',
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info card
            _buildOrderInfoCard(),
            
            const SizedBox(height: 20),
            
            // Customer info card
            _buildCustomerInfoCard(),
            
            const SizedBox(height: 20),
            
            // Address card
            _buildAddressCard(),
            
            const SizedBox(height: 20),
            
            // Items card
            _buildItemsCard(),
            
            const SizedBox(height: 20),
            
            // Payment info (if COD)
            if (widget.order.paymentMethod == 'cash_on_delivery')
              _buildPaymentCard(),
            
            const SizedBox(height: 30),
            
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.order.orderNumber ?? 'N/A',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SFProDisplay',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isPickupTask ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isPickupTask ? 'PICKUP' : 'DELIVERY',
                  style: TextStyle(
                    color: _isPickupTask ? Colors.orange[800] : Colors.green[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Status', widget.order.status.replaceAll('_', ' ').toUpperCase()),
          _buildInfoRow('Order Date', DateFormat('MMM dd, yyyy - hh:mm a').format((widget.order.createdAt ?? widget.order.orderTimestamp).toDate())),
          if (widget.order.pickupDate != null)
            _buildInfoRow('Pickup Date', DateFormat('MMM dd, yyyy').format(widget.order.pickupDate!.toDate())),
          if (widget.order.deliveryDate != null)
            _buildInfoRow('Delivery Date', DateFormat('MMM dd, yyyy').format(widget.order.deliveryDate!.toDate())),
          _buildInfoRow('Total Amount', '₹${widget.order.totalAmount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 16),
          
          // Customer Name
          _buildInfoRow('Name', widget.order.customerName),
          
          // Customer Phone
          _buildInfoRow('Phone', widget.order.customerPhone),
          
          // Customer Email (if available)
          if (widget.order.customer?.email?.isNotEmpty == true)
            _buildInfoRow('Email', widget.order.customer!.email!),
          
          // Customer ID for reference
          if (widget.order.customerId?.isNotEmpty == true)
            _buildInfoRow('Customer ID', widget.order.customerId!),
          
          // Profile completion status
          if (widget.order.customer?.isProfileComplete != null)
            _buildInfoRow('Profile Status', 
                widget.order.customer!.isProfileComplete! ? 'Complete' : 'Incomplete'),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(widget.order.customerPhone),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final address = _isPickupTask ? widget.order.pickupAddress : widget.order.deliveryAddressDetails;
    final addressTitle = _isPickupTask ? 'Pickup Address' : 'Delivery Address';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            addressTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 16),
          if (address is DeliveryAddress) ...[
            Text(
              '${address.addressLine1}\n${address.addressLine2}\n${address.city}, ${address.state} - ${address.pincode}',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontFamily: 'SFProDisplay',
              ),
            ),
                         if (address.landmark != null && address.landmark!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Landmark: ${address.landmark}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ] else ...[
            Text(
              address.toString(),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontFamily: 'SFProDisplay',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openMaps(address),
                  icon: Icon(
                    _hasCoordinatesForAddress(address) ? Icons.navigation : Icons.map,
                    size: 16,
                  ),
                  label: Text(
                    _hasCoordinatesForAddress(address) 
                        ? 'Navigate (GPS)' 
                        : 'Open in Maps',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasCoordinatesForAddress(address) 
                        ? Colors.green 
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          // Show coordinates info if available
          if (_hasCoordinatesForAddress(address)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.gps_fixed,
                  size: 14,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'GPS coordinates available for precise navigation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
                 boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
           ),
         ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 16),
          ...widget.order.items.map((item) {
            // Get item details from ItemService if available
            final itemId = item['itemId']?.toString();
            final itemDetails = itemId != null ? _itemDetails[itemId] : null;
            
            // Use resolved name from ItemService or fallback to stored name
            final itemName = itemDetails?['name'] ?? 
                           item['itemName'] ?? 
                           item['name'] ?? 
                           'Unknown Item';
            
            final category = itemDetails?['category'] ?? item['category'];
            final unit = itemDetails?['unit'] ?? item['unit'] ?? 'piece';
            final originalPrice = itemDetails?['price'];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Qty: ${item['quantity'] ?? 0} $unit',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontFamily: 'SFProDisplay',
                              ),
                            ),
                            if (category != null) ...[
                              Text(
                                ' • $category',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontFamily: 'SFProDisplay',
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (originalPrice != null && originalPrice != (item['price'] ?? 0)) ...[
                          Text(
                            'Original: ₹${originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              fontFamily: 'SFProDisplay',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(item['price'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                      Text(
                        'per $unit',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SFProDisplay',
                ),
              ),
              Text(
                '₹${widget.order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.money,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Cash on Delivery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Collect ₹${widget.order.totalAmount.toStringAsFixed(2)} from the customer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange[700],
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isPickupTask) ...[
          // Edit order button (for pickup tasks only)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _editOrder,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Pickup completion button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _markPickupComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Mark Pickup Complete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
            ),
          ),
        ] else ...[
          // Delivery completion button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _markDeliveryComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Mark Delivery Complete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Report issue button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _reportIssue,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Report Issue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'SFProDisplay',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'SFProDisplay',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'SFProDisplay',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openMaps(dynamic address) async {
    Uri uri;
    
    // Check if we have coordinates available
    if (address is DeliveryAddress && address.latitude != null && address.longitude != null) {
      // Use coordinates for precise navigation
      print('🗺️ Opening Google Maps with coordinates: ${address.latitude}, ${address.longitude}');
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${address.latitude},${address.longitude}');
    } else if (widget.order.hasCoordinates) {
      // Use order-level coordinates if available
      print('🗺️ Opening Google Maps with order coordinates: ${widget.order.latitude}, ${widget.order.longitude}');
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${widget.order.latitude},${widget.order.longitude}');
    } else {
      // Fall back to address search
      String addressString = '';
      if (address is DeliveryAddress) {
        addressString = '${address.addressLine1}, ${address.addressLine2}, ${address.city}, ${address.state} ${address.pincode}';
      } else {
        addressString = address.toString();
      }
      
      print('🗺️ Opening Google Maps with address search: $addressString');
      final encodedAddress = Uri.encodeComponent(addressString);
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    }
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('🗺️ ✅ Successfully opened Google Maps');
      } else {
        throw Exception('Cannot launch URL: $uri');
      }
    } catch (e) {
      print('🗺️ ❌ Error opening Google Maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Could not open Google Maps: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _editOrder() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditOrderScreen(order: widget.order),
      ),
    );

    if (result == true && mounted) {
      // Order was modified, show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the current screen by popping and letting the parent refresh
      Navigator.pop(context);
    }
  }

  Future<void> _markPickupComplete() async {
    setState(() {
      _isLoading = true;
    });

    final orderProvider = context.read<OrderProvider>();
    bool success = await orderProvider.markPickupComplete(widget.order.id);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup marked as complete'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to mark pickup complete'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markDeliveryComplete() async {
    setState(() {
      _isLoading = true;
    });

    final orderProvider = context.read<OrderProvider>();
    bool success = await orderProvider.markDeliveryComplete(widget.order.id);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery marked as complete'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to mark delivery complete'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reportIssue() async {
    final TextEditingController notesController = TextEditingController();
    String selectedIssue = 'Customer not available';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select issue type:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedIssue,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Customer not available', child: Text('Customer not available')),
                  DropdownMenuItem(value: 'Wrong address', child: Text('Wrong address')),
                  DropdownMenuItem(value: 'Vehicle breakdown', child: Text('Vehicle breakdown')),
                  DropdownMenuItem(value: 'Weather conditions', child: Text('Weather conditions')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  selectedIssue = value!;
                },
              ),
              const SizedBox(height: 16),
              const Text('Additional notes (optional):'),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Provide additional details...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      final orderProvider = context.read<OrderProvider>();
      bool success = await orderProvider.reportOrderIssue(
        widget.order.id,
        selectedIssue,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.error ?? 'Failed to report issue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 