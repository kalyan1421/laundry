import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/notification_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final OrderModel order;

  const TaskDetailScreen({super.key, required this.order});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  int _selectedTab = 0; // 0 for Pickups, 1 for Deliveries
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isPickup = _isPickupTask(widget.order);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filter functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          _buildTabBar(),
          
          // Task Card
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Main Task Card
                  _buildTaskCard(isPickup),
                  
                  // Customer Information
                  _buildCustomerInformation(),
                  
                  // Address & Directions
                  _buildAddressSection(),
                  
                  // Order Details
                  _buildOrderDetails(),
                  
                  // Payment Collection (if applicable)
                  if (widget.order.paymentMethod == 'cash_on_delivery')
                    _buildPaymentCollection(),
                  
                  // Action Buttons
                  _buildActionButtons(isPickup),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Pickups', 0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Deliveries', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(bool isPickup) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getTaskTime(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.order.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.order.pickupAddress ?? widget.order.deliveryAddress ?? 'Address not available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.order.customer?.name ?? 'Unknown Customer',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${widget.order.items.length} items',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _showOrderDetails();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View Details'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInformation() {
    final phoneNumber = _getCustomerPhoneNumber();
    final hasPhone = phoneNumber != null && phoneNumber.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue[100],
                child: Text(
                  _getCustomerInitials(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCustomerName(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hasPhone ? phoneNumber : 'No phone number',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasPhone ? Colors.grey[600] : Colors.red[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: hasPhone ? const Color(0xFF10B981) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: hasPhone ? () => _makePhoneCall() : null,
                  icon: const Icon(Icons.phone, color: Colors.white),
                  tooltip: hasPhone ? 'Call Customer' : 'Phone number not available',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    final address = _getTaskAddress();
    final hasCoordinates = widget.order.hasCoordinates;
    final landmark = widget.order.deliveryAddressDetails?.landmark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Address & Directions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (hasCoordinates)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gps_fixed, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'GPS Available',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Map placeholder with coordinates info
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasCoordinates ? Icons.location_on : Icons.location_off,
                    size: 32,
                    color: hasCoordinates ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  if (hasCoordinates) ...[
                    Text(
                      'Lat: ${widget.order.latitude!.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Lng: ${widget.order.longitude!.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ] else
                    Text(
                      'GPS coordinates not available',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            address,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (landmark != null && landmark.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.place, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Near $landmark',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDirections(),
                  icon: Icon(
                    hasCoordinates ? Icons.navigation : Icons.map,
                    color: Colors.white,
                  ),
                  label: Text(
                    hasCoordinates ? 'GPS Navigation' : 'Open in Maps',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (hasCoordinates) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _copyCoordinates(),
                    icon: const Icon(Icons.copy, color: Colors.white),
                    tooltip: 'Copy Coordinates',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Order ID: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                '#${widget.order.orderNumber ?? widget.order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.order.serviceType ?? 'Express Laundry',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getItemsSummary(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildAddressDetails(),
          if (widget.order.specialInstructions != null && widget.order.specialInstructions!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.order.specialInstructions!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentCollection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Collection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '₹${widget.order.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cash on Delivery',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isPickup) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _confirmAction(isPickup),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isPickup ? 'Confirm Pickup' : 'Confirm Delivery',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _reportIssue(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Report Issue',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isPickupTask(OrderModel order) {
    return ['pending', 'confirmed', 'assigned', 'ready_for_pickup'].contains(order.status);
  }

  String _getTaskTime() {
    if (widget.order.pickupDate != null && widget.order.pickupTimeSlot != null) {
      return widget.order.pickupTimeSlot!;
    }
    if (widget.order.deliveryDate != null && widget.order.deliveryTimeSlot != null) {
      return widget.order.deliveryTimeSlot!;
    }
    return DateFormat('HH:mm a').format(widget.order.orderTimestamp.toDate());
  }

  Color _getStatusColor() {
    switch (widget.order.status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
      case 'assigned':
        return const Color(0xFF3B82F6);
      case 'processing':
      case 'in_progress':
        return const Color(0xFF8B5CF6);
      case 'ready_for_pickup':
      case 'ready_for_delivery':
        return const Color(0xFF06B6D4);
      case 'out_for_delivery':
        return const Color(0xFF10B981);
      case 'delivered':
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getItemsSummary() {
    if (widget.order.items.isEmpty) return 'No items';
    
    final Map<String, int> itemCounts = {};
    for (final item in widget.order.items) {
      itemCounts[item.name] = (itemCounts[item.name] ?? 0) + item.quantity;
    }
    
    final List<String> itemSummaries = [];
    itemCounts.forEach((name, count) {
      itemSummaries.add('$count ${name}${count > 1 ? 's' : ''}');
    });
    
    return itemSummaries.join(', ');
  }

  Widget _buildAddressDetails() {
    final deliveryDetails = widget.order.deliveryAddressDetails;
    if (deliveryDetails == null) return const SizedBox.shrink();

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
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[600], size: 18),
              const SizedBox(width: 8),
              const Text(
                'Detailed Address Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (deliveryDetails.addressLine1?.isNotEmpty == true)
            _buildAddressRow('Address:', deliveryDetails.addressLine1!),
          if (deliveryDetails.addressLine2?.isNotEmpty == true)
            _buildAddressRow('Address 2:', deliveryDetails.addressLine2!),
          if (deliveryDetails.floor?.isNotEmpty == true)
            _buildAddressRow('Floor:', deliveryDetails.floor!),
          if (deliveryDetails.landmark?.isNotEmpty == true)
            _buildAddressRow('Landmark:', deliveryDetails.landmark!),
          if (deliveryDetails.city?.isNotEmpty == true)
            _buildAddressRow('City:', deliveryDetails.city!),
          if (deliveryDetails.state?.isNotEmpty == true)
            _buildAddressRow('State:', deliveryDetails.state!),
          if (deliveryDetails.pincode?.isNotEmpty == true)
            _buildAddressRow('PIN Code:', deliveryDetails.pincode!),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Order Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.order.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.order.items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Quantity: ${item.quantity}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(item.pricePerPiece * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for customer information
  String _getCustomerName() {
    return widget.order.customer?.name ?? 'Unknown Customer';
  }

  String _getCustomerInitials() {
    final name = _getCustomerName();
    if (name == 'Unknown Customer') return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String? _getCustomerPhoneNumber() {
    return widget.order.customer?.phoneNumber;
  }

  String _getTaskAddress() {
    final isPickup = _isPickupTask(widget.order);
    if (isPickup) {
      return widget.order.pickupAddress.isNotEmpty 
          ? widget.order.pickupAddress 
          : 'Pickup address not specified';
    } else {
      return widget.order.displayDeliveryAddress;
    }
  }

  void _makePhoneCall() async {
    final phoneNumber = _getCustomerPhoneNumber();
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      try {
        // Clean phone number (remove spaces, dashes, etc.)
        String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        final uri = Uri.parse('tel:$cleanNumber');
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          
          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Calling $phoneNumber...'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw 'Could not launch phone dialer';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to make call: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _openDirections() {
    try {
      if (widget.order.hasCoordinates) {
        // Use GPS coordinates for precise navigation
        final lat = widget.order.latitude!;
        final lng = widget.order.longitude!;
        
        // Try to open in Google Maps app first, then fallback to web
        final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
        final uri = Uri.parse(googleMapsUrl);
        launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening GPS navigation...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Fallback to address-based navigation
        final address = _getTaskAddress();
        if (address.isNotEmpty && address != 'Address not available') {
          final encodedAddress = Uri.encodeComponent(address);
          final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
          launchUrl(uri, mode: LaunchMode.externalApplication);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening address in maps...'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw 'No address or coordinates available';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open directions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyCoordinates() {
    if (widget.order.hasCoordinates) {
      final coordinates = '${widget.order.latitude},${widget.order.longitude}';
      // Copy to clipboard would require clipboard package
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coordinates: $coordinates'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () {
              // Share coordinates - could be enhanced with share package
              final shareText = 'Location: https://www.google.com/maps?q=${widget.order.latitude},${widget.order.longitude}';
              // For now, just show the shareable link
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share link: $shareText'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _confirmAction(bool isPickup) async {
    setState(() => _isLoading = true);
    
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      // Step 1: Update order status
      print('🔄 Updating order status to ${isPickup ? 'picked_up' : 'delivered'}...');
      await orderProvider.updateOrderStatus(
        widget.order.id,
        isPickup ? 'picked_up' : 'delivered',
      );
      print('✅ Order status updated successfully');
      
      // Step 2: Send notification to admin
      print('📢 Sending notification to admins...');
      await NotificationService.sendNotificationToAdmins(
        title: isPickup ? 'Order Picked Up' : 'Order Delivered',
        body: 'Order #${widget.order.orderNumber ?? widget.order.id.substring(0, 8)} has been ${isPickup ? 'picked up' : 'delivered'} by delivery partner',
        data: {
          'type': isPickup ? 'pickup_confirmed' : 'delivery_confirmed',
          'orderId': widget.order.id,
          'orderNumber': widget.order.orderNumber ?? '',
        },
      );
      print('✅ Notification sent to admins');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPickup ? 'Pickup confirmed successfully!' : 'Delivery confirmed successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error in _confirmAction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _reportIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please describe the issue you encountered:'),
            SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe the issue...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Issue reported successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
} 