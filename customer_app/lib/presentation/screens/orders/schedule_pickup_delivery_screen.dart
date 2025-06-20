import 'package:customer_app/data/models/item_model.dart';
import 'package:customer_app/presentation/screens/address/add_address_screen.dart';
import 'package:customer_app/presentation/screens/orders/upi_payment_screen.dart';
import 'package:customer_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define PaymentMethod enum
enum PaymentMethod { cod, upi }

// Updated TimeSlot enum with new timings
enum TimeSlot {
  morning, // 7 AM - 11 AM
  noon,    // 11 AM - 4 PM
  evening; // 4 PM - 8 PM

  String get displayName {
    switch (this) {
      case TimeSlot.morning:
        return 'Morning';
      case TimeSlot.noon:
        return 'Noon';
      case TimeSlot.evening:
        return 'Evening';
    }
  }

  String get timeRange {
    switch (this) {
      case TimeSlot.morning:
        return '7 to 11 AM';
      case TimeSlot.noon:
        return '11 AM to 4 PM';
      case TimeSlot.evening:
        return '4 to 8 PM';
    }
  }

  int get startHour {
    switch (this) {
      case TimeSlot.morning: return 7;
      case TimeSlot.noon: return 11;
      case TimeSlot.evening: return 16;
    }
  }

  int get endHour {
    switch (this) {
      case TimeSlot.morning: return 11;
      case TimeSlot.noon: return 16;
      case TimeSlot.evening: return 20;
    }
  }
}

// Date selection options
enum DateOption {
  today,
  tomorrow,
  custom;

  String get displayName {
    switch (this) {
      case DateOption.today:
        return 'Today';
      case DateOption.tomorrow:
        return 'Tomorrow';
      case DateOption.custom:
        return 'Custom';
    }
  }
}

class SchedulePickupDeliveryScreen extends StatefulWidget {
  final Map<ItemModel, int> selectedItems;
  final double totalAmount;
  final bool isAlliedServices;

  const SchedulePickupDeliveryScreen({
    Key? key,
    required this.selectedItems,
    required this.totalAmount,
    this.isAlliedServices = false,
  }) : super(key: key);

  @override
  State<SchedulePickupDeliveryScreen> createState() => _SchedulePickupDeliveryScreenState();
}

class _SchedulePickupDeliveryScreenState extends State<SchedulePickupDeliveryScreen> {
  int selectedTabIndex = 1; // Schedule tab selected by default

  // Date and time state variables
  DateOption selectedPickupDateOption = DateOption.today;
  DateTime? selectedPickupDate;
  TimeSlot? selectedPickupTimeSlot;
  
  DateOption selectedDeliveryDateOption = DateOption.tomorrow;
  DateTime? selectedDeliveryDate;
  TimeSlot? selectedDeliveryTimeSlot;

  List<TimeSlot> availablePickupSlots = TimeSlot.values;
  List<TimeSlot> availableDeliverySlots = TimeSlot.values;

  bool sameAddressForDelivery = true;
  final TextEditingController specialInstructionsController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cod;

  // Address and order saving state
  DocumentSnapshot? _selectedPickupAddress;
  DocumentSnapshot? _selectedDeliveryAddress;
  bool _isLoadingAddress = true;
  bool _isSavingOrder = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _fetchedUserAddresses = [];

  @override
  void initState() {
    super.initState();
    _initializeDateTimeSlots();
    _fetchUserAddresses();
  }

  void _initializeDateTimeSlots() {
    final now = DateTime.now();
    
    // Set initial pickup date based on selected option
    selectedPickupDate = _getDateFromOption(selectedPickupDateOption);
    selectedDeliveryDate = _getDateFromOption(selectedDeliveryDateOption);
    
    _updateAvailablePickupSlots();
    _updateAvailableDeliverySlots();
  }

  DateTime _getDateFromOption(DateOption option) {
    final now = DateTime.now();
    switch (option) {
      case DateOption.today:
        return DateTime(now.year, now.month, now.day);
      case DateOption.tomorrow:
        return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      case DateOption.custom:
        return DateTime(now.year, now.month, now.day);
    }
  }

  void _updateAvailablePickupSlots() {
    if (selectedPickupDate == null) {
      availablePickupSlots = [];
      setState(() {});
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<TimeSlot> slots = TimeSlot.values.toList();

    if (selectedPickupDate!.isAtSameMomentAs(today)) {
      // Filter slots based on current time
      slots = slots.where((slot) {
        return now.hour < slot.endHour - 1; // 1 hour buffer
      }).toList();
    }

    availablePickupSlots = slots;
    if (!availablePickupSlots.contains(selectedPickupTimeSlot) && availablePickupSlots.isNotEmpty) {
      selectedPickupTimeSlot = availablePickupSlots.first;
    } else if (availablePickupSlots.isEmpty) {
      selectedPickupTimeSlot = null;
    }
    setState(() {});
  }

  void _updateAvailableDeliverySlots() {
    availableDeliverySlots = TimeSlot.values.toList();
    if (availableDeliverySlots.isNotEmpty && !availableDeliverySlots.contains(selectedDeliveryTimeSlot)) {
        selectedDeliveryTimeSlot = availableDeliverySlots.first;
    }
    setState(() {});
  }

  Future<void> _fetchUserAddresses() async {
    setState(() {
      _isLoadingAddress = true;
      _selectedPickupAddress = null;
      _selectedDeliveryAddress = null;
      _fetchedUserAddresses = [];
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot addressQuery = await _firestore
            .collection('customer')
            .doc(currentUser.uid)
            .collection('addresses')
            .get();

        _fetchedUserAddresses = addressQuery.docs;

        if (_fetchedUserAddresses.isNotEmpty) {
          DocumentSnapshot? primaryAddress;
          try {
            primaryAddress = _fetchedUserAddresses.firstWhere(
              (doc) => (doc.data() as Map<String, dynamic>)['isPrimary'] == true
            );
          } catch (e) {
            primaryAddress = _fetchedUserAddresses.first;
          }

          _selectedPickupAddress = primaryAddress;
          
          if (sameAddressForDelivery) {
            _selectedDeliveryAddress = primaryAddress;
          }
        }
      }
    } catch (e) {
      print('Error fetching addresses: $e');
    }
    
    setState(() {
      _isLoadingAddress = false;
    });
  }

  String _formatAddress(Map<String, dynamic> data) {
    String line1 = data['addressLine1'] ?? '';
    String line2 = data['addressLine2'] ?? '';
    String city = data['city'] ?? '';
    String state = data['state'] ?? '';
    String pincode = data['pincode'] ?? '';

    StringBuffer addressBuffer = StringBuffer();
    if (line1.isNotEmpty) addressBuffer.write(line1);
    if (line2.isNotEmpty) addressBuffer.write(', $line2');
    if (city.isNotEmpty) addressBuffer.write(', $city');
    if (state.isNotEmpty) addressBuffer.write(', $state');
    if (pincode.isNotEmpty) addressBuffer.write(' - $pincode');
    
    return addressBuffer.toString();
  }

  Future<void> _navigateToAddAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAddressScreen()),
    );

    if (result == true) {
      _fetchUserAddresses();
    }
  }

  Future<void> _showAddressSelectionDialog({required bool isPickup}) async {
    if (_fetchedUserAddresses.isEmpty) {
      await _navigateToAddAddress();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select ${isPickup ? 'Pickup' : 'Delivery'} Address'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _fetchedUserAddresses.length + 1,
              itemBuilder: (context, index) {
                if (index == _fetchedUserAddresses.length) {
                  return ListTile(
                    leading: const Icon(Icons.add_location_alt_outlined),
                    title: const Text('Add a new address'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _navigateToAddAddress();
                    },
                  );
                }
                
                var addressDoc = _fetchedUserAddresses[index];
                var addressData = addressDoc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(_formatAddress(addressData)),
                  onTap: () {
                    setState(() {
                      if (isPickup) {
                        _selectedPickupAddress = addressDoc;
                        if (sameAddressForDelivery) {
                          _selectedDeliveryAddress = addressDoc;
                        }
                      } else {
                        _selectedDeliveryAddress = addressDoc;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  int get _totalItemCount {
    return widget.selectedItems.values.fold(0, (sum, count) => sum + count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Schedule Pickup & Delivery',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildTabBar(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedTabIndex == 0) ...[
                    // Items Tab Content
                    _buildItemsSummary(),
                    const SizedBox(height: 24),
                    _buildItemsDetails(),
                  ] else if (selectedTabIndex == 1) ...[
                    // Schedule Tab Content
                  _buildItemsSummary(),
                  const SizedBox(height: 24),
                  _buildLocationsSection(),
                  const SizedBox(height: 24),
                    _buildPickupSection(),
                  const SizedBox(height: 24),
                    _buildDeliverySection(),
                  const SizedBox(height: 24),
                  _buildSpecialInstructionsSection(),
                  ] else if (selectedTabIndex == 2) ...[
                    // Payment Tab Content
                    _buildItemsSummary(),
                    const SizedBox(height: 24),
                    _buildOrderSummary(),
                    const SizedBox(height: 24),
                    _buildPaymentSection(),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildProceedButton(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Items', 'Schedule', 'Payment'];
    return Container(
      color: Colors.white,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          int index = entry.key;
          String tab = entry.value;
          bool isSelected = index == selectedTabIndex;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                // Validate before allowing tab navigation
                if (index > selectedTabIndex) {
                  if (index == 1 && selectedTabIndex == 0) {
                    // Moving from Items to Schedule - no validation needed
                setState(() {
                  selectedTabIndex = index;
                });
                  } else if (index == 2 && selectedTabIndex == 1) {
                    // Moving from Schedule to Payment - validate schedule details
                    if (_validateScheduleDetails()) {
                      setState(() {
                        selectedTabIndex = index;
                      });
                    }
                  }
                } else {
                  // Allow backward navigation
                  setState(() {
                    selectedTabIndex = index;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _validateScheduleDetails() {
    if (_selectedPickupAddress == null || 
        (!sameAddressForDelivery && _selectedDeliveryAddress == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and delivery addresses.')),
      );
      return false;
    }
    
    if (selectedPickupDate == null || selectedPickupTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup date and time.')),
      );
      return false;
    }
    
    if (selectedDeliveryDate == null || selectedDeliveryTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select delivery date and time.')),
      );
      return false;
    }
    
    return true;
  }

  Widget _buildItemsSummary() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.iron, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$_totalItemCount items for ironing',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '₹${widget.totalAmount.toInt()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
        ),
      );
    }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Pickup Details
          _buildSummaryRow(
            icon: Icons.location_on,
            iconColor: Colors.blue,
            title: 'Pickup',
            value: selectedPickupDate != null && selectedPickupTimeSlot != null
                ? '${_formatDate(selectedPickupDate!)} at ${selectedPickupTimeSlot!.displayName}'
                : 'Not selected',
          ),
          
          const SizedBox(height: 12),
          
          // Delivery Details
          _buildSummaryRow(
            icon: Icons.location_on_outlined,
            iconColor: Colors.green,
            title: 'Delivery',
            value: selectedDeliveryDate != null && selectedDeliveryTimeSlot != null
                ? '${_formatDate(selectedDeliveryDate!)} at ${selectedDeliveryTimeSlot!.displayName}'
                : 'Not selected',
          ),
          
          const SizedBox(height: 12),
          
          // Items Count
          _buildSummaryRow(
            icon: Icons.iron,
            iconColor: Colors.orange,
            title: 'Items',
            value: '$_totalItemCount items',
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${widget.totalAmount.toInt()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
                children: [
                  Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
                  ),
                  const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == today) {
      return 'Today';
    } else if (selectedDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _processUPIPayment() async {
    // Navigate to UPI payment screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UPIPaymentScreen(
          amount: widget.totalAmount,
          orderDetails: {
            'itemCount': _totalItemCount,
            'pickupDate': selectedPickupDate,
            'deliveryDate': selectedDeliveryDate,
            'pickupTimeSlot': selectedPickupTimeSlot?.displayName,
            'deliveryTimeSlot': selectedDeliveryTimeSlot?.displayName,
          },
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      // Payment successful, process the order
      await _processOrder(
        paymentStatus: 'completed',
        transactionId: result['transactionId'],
      );
    }
  }

  Future<void> _processOrder({required String paymentStatus, String? transactionId}) async {
    setState(() => _isSavingOrder = true);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Prepare order data
      List<Map<String, dynamic>> itemsForOrder = [];
      widget.selectedItems.forEach((itemModel, quantity) {
        itemsForOrder.add({
          'itemId': itemModel.id,
          'name': itemModel.name,
          'pricePerPiece': itemModel.pricePerPiece,
          'quantity': quantity,
          'category': itemModel.category,
          'unit': itemModel.unit,
        });
      });

      // Prepare address data
      final pickupAddressData = _selectedPickupAddress!.data() as Map<String, dynamic>;
      final deliveryAddressData = sameAddressForDelivery 
          ? pickupAddressData 
          : (_selectedDeliveryAddress!.data() as Map<String, dynamic>);

      Map<String, dynamic> orderData = {
        'customerId': currentUser.uid,
        'orderTimestamp': FieldValue.serverTimestamp(),
        'items': itemsForOrder,
        'totalAmount': widget.totalAmount,
        'totalItemCount': _totalItemCount,
        'pickupDate': Timestamp.fromDate(selectedPickupDate!),
        'pickupTimeSlot': selectedPickupTimeSlot!.name,
        'deliveryDate': Timestamp.fromDate(selectedDeliveryDate!),
        'deliveryTimeSlot': selectedDeliveryTimeSlot!.name,
        'pickupAddress': {
          'addressId': _selectedPickupAddress!.id,
          'formatted': _formatAddress(pickupAddressData),
          'details': pickupAddressData,
        },
        'deliveryAddress': {
          'addressId': sameAddressForDelivery ? _selectedPickupAddress!.id : _selectedDeliveryAddress!.id,
          'formatted': _formatAddress(deliveryAddressData),
          'details': deliveryAddressData,
        },
        'sameAddressForDelivery': sameAddressForDelivery,
        'specialInstructions': specialInstructionsController.text.trim(),
        'paymentMethod': _selectedPaymentMethod.name,
        'paymentStatus': paymentStatus,
        'status': 'pending',
        'orderType': 'pickup_delivery',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (transactionId != null) {
        orderData['transactionId'] = transactionId;
      }

      DocumentReference orderRef = await _firestore.collection('orders').add(orderData);
      String orderId = orderRef.id;
      
      // Send notification to admin
      try {
        await NotificationService.sendNewOrderNotificationToAdmin(orderId);
      } catch (e) {
        print('Error sending notification to admin: $e');
      }
      
      setState(() {
        _isSavingOrder = false;
      });

      if (mounted) {
        _showOrderSuccessDialog(paymentStatus == 'completed');
      }
    } catch (e) {
      setState(() {
        _isSavingOrder = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: ${e.toString()}')),
        );
      }
    }
  }

  void _showOrderSuccessDialog(bool isUPIPaid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Order Placed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            Text(
              isUPIPaid
                  ? 'Your order has been successfully placed and payment is confirmed.'
                  : 'Your order has been successfully placed with Cash on Delivery.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Pickup: ${DateFormat('EEE, MMM d').format(selectedPickupDate!)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedPickupTimeSlot!.displayName} (${selectedPickupTimeSlot!.timeRange})',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery: ${DateFormat('EEE, MMM d').format(selectedDeliveryDate!)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedDeliveryTimeSlot!.displayName} (${selectedDeliveryTimeSlot!.timeRange})',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
            children: [
                      const Icon(Icons.currency_rupee, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
              Text(
                        'Total: ₹${widget.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  if (isUPIPaid) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.payment, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment: Completed',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('View Orders'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
              // Navigate to orders screen if you have one
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Locations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Pickup Address
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pickup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showAddressSelectionDialog(isPickup: true),
                    child: const Text('Change', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _isLoadingAddress 
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _selectedPickupAddress != null 
                      ? _formatAddress(_selectedPickupAddress!.data() as Map<String, dynamic>)
                          : 'No address selected',
                    style: TextStyle(
                      color: _selectedPickupAddress != null ? Colors.grey[700] : Colors.orange, 
                        fontSize: 14,
                      ),
                    ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Same address checkbox
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
                children: [
              Checkbox(
                    value: sameAddressForDelivery,
                    onChanged: (value) {
                      setState(() {
                    sameAddressForDelivery = value ?? true;
                        if (sameAddressForDelivery) {
                          _selectedDeliveryAddress = _selectedPickupAddress;
                        } else {
                          _selectedDeliveryAddress = null;
                        }
                      });
                    },
                    activeColor: Colors.blue,
                  ),
              const Text(
                'Same address for delivery',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        
        // Delivery Address (if different)
        if (!sameAddressForDelivery) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Delivery',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _showAddressSelectionDialog(isPickup: false),
                      child: const Text('Change', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedDeliveryAddress != null
                        ? _formatAddress(_selectedDeliveryAddress!.data() as Map<String, dynamic>)
                      : 'No delivery address selected',
                      style: TextStyle(
                        color: _selectedDeliveryAddress != null ? Colors.grey[700] : Colors.orange, 
                    fontSize: 14,
                    ),
                ),
            ],
          ),
        ),
        ],
      ],
    );
  }

  Widget _buildPickupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup Date',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDateSelector(
          selectedOption: selectedPickupDateOption,
          onOptionSelected: (option) {
              setState(() {
              selectedPickupDateOption = option;
              selectedPickupDate = _getDateFromOption(option);
                _updateAvailablePickupSlots();
            });
          },
          onCustomDateSelected: (date) {
            setState(() {
              selectedPickupDateOption = DateOption.custom;
              selectedPickupDate = date;
              _updateAvailablePickupSlots();
            });
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Pickup Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildTimeSlotSelector(
          availableSlots: availablePickupSlots,
          selectedSlot: selectedPickupTimeSlot,
          onSlotSelected: (slot) {
                  setState(() {
                    selectedPickupTimeSlot = slot;
                  });
                },
          ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
      children: [
        const Text(
          'Delivery Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (selectedDeliveryDate != null)
              Text(
                DateFormat('EEEE, MMM d').format(selectedDeliveryDate!),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Delivery Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildTimeSlotSelector(
          availableSlots: availableDeliverySlots,
          selectedSlot: selectedDeliveryTimeSlot,
          onSlotSelected: (slot) {
            setState(() {
              selectedDeliveryTimeSlot = slot;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required DateOption selectedOption,
    required Function(DateOption) onOptionSelected,
    required Function(DateTime) onCustomDateSelected,
  }) {
    return Row(
      children: DateOption.values.asMap().entries.map((entry) {
        int index = entry.key;
        DateOption option = entry.value;
        bool isSelected = option == selectedOption;
        
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              if (option == DateOption.custom) {
            final DateTime? picked = await showDatePicker(
              context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  onCustomDateSelected(picked);
                }
              } else {
                onOptionSelected(option);
            }
          },
          child: Container(
              margin: EdgeInsets.only(
                right: index < DateOption.values.length - 1 ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    option.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlotSelector({
    required List<TimeSlot> availableSlots,
    required TimeSlot? selectedSlot,
    required Function(TimeSlot) onSlotSelected,
  }) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableSlots.length,
        itemBuilder: (context, index) {
          final slot = availableSlots[index];
          bool isSelected = slot == selectedSlot;
          
          return GestureDetector(
            onTap: () => onSlotSelected(slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isSelected ? 200 : 100, // Expand width when selected
              margin: EdgeInsets.only(
                right: index != availableSlots.length - 1 ? 12 : 0,
              ),
              // padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
                ),
              ),
              child: isSelected 
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main category
                      Flexible(
                     child: Text(
                        slot.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,  
                          fontSize: 16,
                          overflow: TextOverflow.ellipsis,
                          ),textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time range
                      Flexible(
                        child: Text(
                          slot.timeRange,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      slot.displayName,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecialInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Instructions (Optional)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: specialInstructionsController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Any specific requirements for ironing? (e.g., starch, delicate handling)',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          ),
      ],
    );
  }

  Widget _buildItemsDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
            'Order Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.selectedItems.length,
            separatorBuilder: (context, index) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final item = widget.selectedItems.keys.elementAt(index);
              final quantity = widget.selectedItems[item]!;
              final itemTotal = item.pricePerPiece * quantity;
              
              return Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.checkroom, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${item.pricePerPiece.toInt()} per piece',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'x$quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${itemTotal.toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Cash on Delivery Option
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedPaymentMethod == PaymentMethod.cod 
                  ? Colors.blue 
                  : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: RadioListTile<PaymentMethod>(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.money, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
          child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash on Delivery',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        'Pay when your order is delivered',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
                value: PaymentMethod.cod,
                groupValue: _selectedPaymentMethod,
                onChanged: (PaymentMethod? value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: Colors.blue,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        
        // UPI Payment Option
        // Container(
        //   margin: const EdgeInsets.only(bottom: 12),
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(
        //       color: _selectedPaymentMethod == PaymentMethod.upi 
        //           ? Colors.blue 
        //           : Colors.grey[300]!,
        //       width: 2,
        //     ),
        //   ),
        //   child: RadioListTile<PaymentMethod>(
        //     title: Row(
        //       children: [
        //         Container(
        //           padding: const EdgeInsets.all(8),
        //           decoration: BoxDecoration(
        //             color: Colors.blue.withOpacity(0.1),
        //             shape: BoxShape.circle,
        //           ),
        //           child: const Icon(Icons.payment, color: Colors.blue, size: 20),
        //         ),
        //         const SizedBox(width: 12),
        //         const Expanded(
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               Text(
        //                 'UPI Payment',
        //                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        //               ),
        //               Text(
        //                 'Pay using Google Pay, PhonePe, Paytm, etc.',
        //                 style: TextStyle(color: Colors.grey, fontSize: 14),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ],
        //     ),
        //     value: PaymentMethod.upi,
        //     groupValue: _selectedPaymentMethod,
        //     onChanged: (PaymentMethod? value) {
        //       setState(() {
        //         _selectedPaymentMethod = value!;
        //       });
        //     },
        //     activeColor: Colors.blue,
        //     contentPadding: const EdgeInsets.all(16),
        //   ),
        // ),
        
        const SizedBox(height: 16),
        
        // Payment Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your order will be confirmed once you complete the payment process.',
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProceedButton() {
    String buttonText = 'Continue';

    if (_isSavingOrder) {
      buttonText = 'Placing Order...';
    } else {
      switch (selectedTabIndex) {
        case 0:
          buttonText = 'Continue to Schedule';
          break;
        case 1:
          buttonText = 'Continue to Payment';
          break;
        case 2:
          buttonText = 'Confirm Order';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSavingOrder ? null : () {
            if (selectedTabIndex < 2) {
              // Navigate to next tab
              if (selectedTabIndex == 0) {
                setState(() {
                  selectedTabIndex = 1;
                });
              } else if (selectedTabIndex == 1) {
                if (_validateScheduleDetails()) {
                  setState(() {
                    selectedTabIndex = 2;
                  });
                }
              }
            } else {
              // Final confirmation and order placement
              _saveOrder();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSavingOrder 
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    // Validation
    if (_selectedPickupAddress == null || 
        (!sameAddressForDelivery && _selectedDeliveryAddress == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and delivery addresses.')),
      );
      return;
    }

    if (selectedPickupDate == null || selectedPickupTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup date and time.')),
      );
      return;
    }

    if (selectedDeliveryDate == null || selectedDeliveryTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select delivery date and time.')),
      );
      return;
    }

    // If UPI payment is selected, navigate to UPI payment screen
    // if (_selectedPaymentMethod == PaymentMethod.upi) {
    //   await _processUPIPayment();
    //   return;
    // }

    // Process COD order directly
    await _processOrder(paymentStatus: 'pending', transactionId: null);
  }

  @override
  void dispose() {
    specialInstructionsController.dispose();
    super.dispose();
  }
}