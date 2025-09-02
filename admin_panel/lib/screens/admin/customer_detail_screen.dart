import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/address_model.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../utils/phone_formatter.dart';
import '../../services/pdf_generation_service.dart';
import 'edit_user_screen.dart';
import 'order_details_screen.dart';
import 'place_order_for_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final UserModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AddressModel> _customerAddresses = [];
  List<OrderModel> _customerOrders = [];
  bool _isLoadingAddresses = true;
  bool _isLoadingOrders = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomerAddresses();
    _loadCustomerOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper methods for service type display
  Color _getServiceTypeColor(String serviceType) {
    if (serviceType.toLowerCase().contains('iron')) {
      return Colors.orange;
    } else if (serviceType.toLowerCase().contains('laundry')) {
      return Colors.blue;
    } else if (serviceType.toLowerCase().contains('mixed')) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }

  IconData _getServiceTypeIcon(String serviceType) {
    if (serviceType.toLowerCase().contains('iron')) {
      return Icons.iron;
    } else if (serviceType.toLowerCase().contains('laundry')) {
      return Icons.local_laundry_service;
    } else if (serviceType.toLowerCase().contains('mixed')) {
      return Icons.miscellaneous_services;
    } else {
      return Icons.help_outline;
    }
  }

  Future<void> _loadCustomerAddresses() async {
    try {
      // First try to get addresses ordered by isPrimary and createdAt
      QuerySnapshot addressesSnapshot;
      try {
        addressesSnapshot = await FirebaseFirestore.instance
            .collection('customer')
            .doc(widget.customer.uid)
            .collection('addresses')
            .orderBy('isPrimary', descending: true)
            .orderBy('createdAt', descending: false)
            .get();
      } catch (orderByError) {
        // If ordering fails (e.g., missing index), get all addresses without ordering
        print('OrderBy failed, fetching all addresses: $orderByError');
        addressesSnapshot = await FirebaseFirestore.instance
            .collection('customer')
            .doc(widget.customer.uid)
            .collection('addresses')
            .get();
      }

      setState(() {
        _customerAddresses = addressesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AddressModel.fromFirestore(data, doc.id);
        }).toList();
        
        // Sort addresses manually if we couldn't order in query
        _customerAddresses.sort((a, b) {
          // Primary addresses first
          if (a.isPrimary && !b.isPrimary) return -1;
          if (!a.isPrimary && b.isPrimary) return 1;
          
          // Then by creation date (newest first if no createdAt)
          if (a.createdAt != null && b.createdAt != null) {
            return a.createdAt!.compareTo(b.createdAt!);
          } else if (a.createdAt != null) {
            return -1;
          } else if (b.createdAt != null) {
            return 1;
          }
          
          return 0;
        });
        
        _isLoadingAddresses = false;
      });
      
      print('Loaded ${_customerAddresses.length} addresses for customer ${widget.customer.uid}');
    } catch (e) {
      print('Error loading customer addresses: $e');
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  Future<void> _loadCustomerOrders() async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final orders = await orderProvider.searchOrdersByCustomerId(widget.customer.uid);
      
      setState(() {
        _customerOrders = orders;
        _isLoadingOrders = false;
      });
    } catch (e) {
      print('Error loading customer orders: $e');
      setState(() {
        _isLoadingOrders = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add debug output for customer data
    print('CustomerDetailScreen - Customer data:');
    print('  Name: ${widget.customer.name}');
    print('  Email: ${widget.customer.email}');
    print('  Phone: ${widget.customer.phoneNumber}');
    print('  UID: ${widget.customer.uid}');
    print('  Client ID: ${widget.customer.clientId}');
    print('  Role: ${widget.customer.role}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditUserScreen(user: widget.customer),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadCustomerPdf(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // _buildCustomerInfoCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildAddressesTab(),
                _buildOrdersTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Details'),
            Tab(icon: Icon(Icons.location_on), text: 'Addresses'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Orders'),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomerInfoCard(),
          const SizedBox(height: 16),
          _buildActionButtonsCard(),
          const SizedBox(height: 16),
          _buildQRCodeCard(),
          const SizedBox(height: 16),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    widget.customer.name.isNotEmpty ? widget.customer.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24,
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
                        widget.customer.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Client ID: ${PhoneFormatter.getClientId(widget.customer.phoneNumber)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(widget.customer.role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.customer.role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.badge, 'Client ID', PhoneFormatter.getClientId(widget.customer.phoneNumber)),
            _buildInfoRow(Icons.phone, 'Phone Number', widget.customer.phoneNumber),
            _buildInfoRow(Icons.email, 'Email', widget.customer.email),
            _buildInfoRow(Icons.person, 'Role', widget.customer.role.toUpperCase()),
            if (widget.customer.createdAt != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Member Since',
                DateFormat('dd MMM yyyy').format(widget.customer.createdAt!.toDate()),
              ),
            _buildInfoRow(
              Icons.verified_user,
              'Profile Status',
              widget.customer.isProfileComplete == true ? 'Complete' : 'Incomplete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Admin Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaceOrderForCustomerScreen(
                            customer: widget.customer,
                          ),
                        ),
                      );
                      
                      // Refresh orders if order was placed
                      if (result == true) {
                        _loadCustomerOrders();
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    label: const Text('Place Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditUserScreen(user: widget.customer),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Edit Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.qr_code_2, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Customer QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: QrImageView(
                  data: 'Customer ID: ${widget.customer.uid}\nName: ${widget.customer.name}\nClient ID: ${PhoneFormatter.getClientId(widget.customer.phoneNumber)}\nPhone: ${widget.customer.phoneNumber}\nEmail: ${widget.customer.email}',
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Scan for quick customer lookup',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Customer Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Orders',
                    '${_customerOrders.length}',
                    Icons.shopping_bag,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Orders',
                    '${_customerOrders.where((order) => !['completed', 'cancelled'].contains(order.status)).length}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Addresses',
                    '${_customerAddresses.length}',
                    Icons.location_on,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Account Age',
                    widget.customer.createdAt != null 
                        ? '${DateTime.now().difference(widget.customer.createdAt!.toDate()).inDays} days'
                        : 'N/A',
                    Icons.access_time,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesTab() {
    return _isLoadingAddresses
        ? const Center(child: CircularProgressIndicator())
        : _customerAddresses.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No addresses found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _customerAddresses.length,
                itemBuilder: (context, index) {
                  final address = _customerAddresses[index];
                  return _buildAddressCard(address, index);
                },
              );
  }

  Widget _buildAddressCard(AddressModel address, int index) {
    final isPrimary = address.isPrimary;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPrimary ? Icons.home : Icons.location_on,
                  color: isPrimary ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPrimary ? 'Primary Address (${address.typeDisplayName})' : '${address.typeDisplayName} Address',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Primary',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildEnhancedAddressDisplay(address),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAddressDisplay(AddressModel address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full formatted address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address.fullAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          
          // Structured address details
          if (address.doorNumber.isNotEmpty || 
              (address.floorNumber != null && address.floorNumber!.isNotEmpty) ||
              (address.apartmentName != null && address.apartmentName!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Address Details',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (address.doorNumber.isNotEmpty)
                  _buildAddressChip('Door', address.doorNumber, Icons.door_front_door),
                if (address.floorNumber != null && address.floorNumber!.isNotEmpty)
                  _buildAddressChip('Floor', address.floorNumber!, Icons.layers),
                if (address.apartmentName != null && address.apartmentName!.isNotEmpty)
                  _buildAddressChip('Building', address.apartmentName!, Icons.apartment),
              ],
            ),
          ],
          
          // Coordinates if available
          if (address.latitude != null && address.longitude != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.my_location, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 6),
                Text(
                  'GPS: ${address.latitude!.toStringAsFixed(6)}, ${address.longitude!.toStringAsFixed(6)}',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return _isLoadingOrders
        ? const Center(child: CircularProgressIndicator())
        : _customerOrders.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No orders found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _customerOrders.length,
                itemBuilder: (context, index) {
                  final order = _customerOrders[index];
                  return _buildOrderCard(order);
                },
              );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: order.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(order.orderTimestamp.toDate()),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order.items.length} items',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              // Service Type Display
              if (order.serviceType != null && order.serviceType!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getServiceTypeColor(order.serviceType!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getServiceTypeColor(order.serviceType!),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getServiceTypeIcon(order.serviceType!),
                            size: 12,
                            color: _getServiceTypeColor(order.serviceType!),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.serviceType!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getServiceTypeColor(order.serviceType!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Items: ${order.items.map((item) => '${item.name} (${item.quantity})').join(', ')}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
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
        return Colors.indigo;
      case 'processing':
        return Colors.amber;
      case 'ready_for_delivery':
        return Colors.teal;
      case 'out_for_delivery':
        return Colors.cyan;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return Colors.blue;
      case 'delivery':
        return Colors.green;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _downloadCustomerPdf(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      // Generate and download PDF
      await PdfGenerationService.downloadCustomerPdf(widget.customer);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generated for ${widget.customer.name}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Close',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Close',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }
} 