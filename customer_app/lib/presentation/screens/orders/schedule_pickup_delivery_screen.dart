import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:customer_app/data/models/item_model.dart';
import 'package:customer_app/presentation/screens/profile/add_address_screen.dart';

import 'package:customer_app/services/notification_service.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';
import 'package:customer_app/presentation/widgets/common/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:customer_app/services/order_number_service.dart';
import 'package:customer_app/core/utils/address_formatter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as auth_provider;
import 'package:customer_app/core/utils/address_utils.dart';
import 'package:customer_app/services/order_notification_service.dart';
import 'package:customer_app/presentation/screens/payment/upi_app_selection_screen.dart';
import '../../widgets/payment/upi_payment_widget.dart';

// Define PaymentMethod enum
enum PaymentMethod { cod, upi }

// Updated TimeSlot enum with new timings
enum TimeSlot {
  morning, // 7 AM - 11 AM
  noon, // 11 AM - 4 PM
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
        return '8 to 11 AM';
      case TimeSlot.noon:
        return '11 AM to 4 PM';
      case TimeSlot.evening:
        return '4 to 8 PM';
    }
  }

  int get startHour {
    switch (this) {
      case TimeSlot.morning:
        return 8;
      case TimeSlot.noon:
        return 11;
      case TimeSlot.evening:
        return 16;
    }
  }

  int get endHour {
    switch (this) {
      case TimeSlot.morning:
        return 11;
      case TimeSlot.noon:
        return 16;
      case TimeSlot.evening:
        return 20;
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
  State<SchedulePickupDeliveryScreen> createState() =>
      _SchedulePickupDeliveryScreenState();
}

class _SchedulePickupDeliveryScreenState
    extends State<SchedulePickupDeliveryScreen> {
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
  final TextEditingController specialInstructionsController =
      TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cod;

  // Address and order saving state
  DocumentSnapshot? _selectedPickupAddress;
  DocumentSnapshot? _selectedDeliveryAddress;
  bool _isLoadingAddress = true;
  bool _isSavingOrder = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey =
      GlobalKey<FormState>(); // Form key for address form validation
  final Logger _logger = Logger();

  List<DocumentSnapshot> _fetchedUserAddresses = [];

  // Removed unused inline address form variables - now using AddAddressScreen

  @override
  void initState() {
    super.initState();
    _initializeDateTimeSlots();
    _fetchUserAddresses();
  }

  void _initializeDateTimeSlots() {
    final now = DateTime.now();

    // Initialize pickup date
    if (now.hour >= 20) {
      selectedPickupDateOption = DateOption.tomorrow;
      selectedPickupDate = _getDateFromOption(DateOption.tomorrow);
    } else {
      selectedPickupDateOption = DateOption.today;
      selectedPickupDate = _getDateFromOption(DateOption.today);
    }

    // Initialize delivery date to 2 days from pickup by default
    selectedDeliveryDateOption = DateOption.custom;
    selectedDeliveryDate =
        _getMinimumDeliveryDate().add(const Duration(days: 1));

    // Allow Sunday scheduling - no restrictions on any day

    _updateAvailablePickupSlots();
    _updateAvailableDeliverySlots();
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  DateTime _getDateFromOption(DateOption option) {
    final now = DateTime.now();
    DateTime date;

    switch (option) {
      case DateOption.today:
        date = DateTime(now.year, now.month, now.day);
        break;
      case DateOption.tomorrow:
        date =
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        break;
      case DateOption.custom:
        return DateTime(now.year, now.month, now.day);
    }

    // Allow scheduling on all days including Sunday

    return date;
  }

  DateTime _getDateFromDeliveryOption(DateOption option) {
    final now = DateTime.now();
    DateTime date;

    switch (option) {
      case DateOption.today:
        date = DateTime(now.year, now.month, now.day);
        break;
      case DateOption.tomorrow:
        date =
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        break;
      case DateOption.custom:
        return _getMinimumDeliveryDate();
    }

    // Ensure the date meets minimum delivery requirements
    final minDate = _getMinimumDeliveryDate();
    if (date.isBefore(minDate)) {
      // If the requested date is before minimum, use the minimum date
      date = minDate;
    }

    // Allow delivery scheduling on all days including Sunday

    return date;
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
    if (!availablePickupSlots.contains(selectedPickupTimeSlot) &&
        availablePickupSlots.isNotEmpty) {
      selectedPickupTimeSlot = availablePickupSlots.first;
    } else if (availablePickupSlots.isEmpty) {
      selectedPickupTimeSlot = null;
    }
    setState(() {});
  }

  void _updateAvailableDeliverySlots() {
    if (selectedDeliveryDate == null ||
        selectedPickupDate == null ||
        selectedPickupTimeSlot == null) {
      availableDeliverySlots = TimeSlot.values.toList();
      setState(() {});
      return;
    }

    List<TimeSlot> slots = TimeSlot.values.toList();

    // Calculate pickup datetime
    final pickupDateTime = DateTime(
      selectedPickupDate!.year,
      selectedPickupDate!.month,
      selectedPickupDate!.day,
      selectedPickupTimeSlot!.startHour,
    );

    // Minimum delivery datetime (20 hours after pickup)
    final minDeliveryDateTime = pickupDateTime.add(const Duration(hours: 20));

    // If delivery is on same day as pickup, filter slots based on 20-hour constraint
    if (_isSameDay(selectedDeliveryDate!, selectedPickupDate!)) {
      // Filter slots that start at or after the minimum delivery time
      slots = slots.where((slot) {
        final slotDateTime = DateTime(
          selectedDeliveryDate!.year,
          selectedDeliveryDate!.month,
          selectedDeliveryDate!.day,
          slot.startHour,
        );
        return slotDateTime.isAfter(minDeliveryDateTime) ||
            slotDateTime.isAtSameMomentAs(minDeliveryDateTime);
      }).toList();
    }
    // If delivery is on a different day, check if it's at least 20 hours later
    else {
      final deliveryStartOfDay = DateTime(
        selectedDeliveryDate!.year,
        selectedDeliveryDate!.month,
        selectedDeliveryDate!.day,
      );

      // If the delivery date is after the minimum delivery date, allow all slots
      if (deliveryStartOfDay.isAfter(DateTime(minDeliveryDateTime.year,
          minDeliveryDateTime.month, minDeliveryDateTime.day))) {
        // All slots are available
      } else {
        // Filter based on minimum delivery time
        slots = slots.where((slot) {
          final slotDateTime = DateTime(
            selectedDeliveryDate!.year,
            selectedDeliveryDate!.month,
            selectedDeliveryDate!.day,
            slot.startHour,
          );
          return slotDateTime.isAfter(minDeliveryDateTime) ||
              slotDateTime.isAtSameMomentAs(minDeliveryDateTime);
        }).toList();
      }
    }

    availableDeliverySlots = slots;

    if (!availableDeliverySlots.contains(selectedDeliveryTimeSlot) &&
        availableDeliverySlots.isNotEmpty) {
      selectedDeliveryTimeSlot = availableDeliverySlots.first;
    } else if (availableDeliverySlots.isEmpty) {
      selectedDeliveryTimeSlot = null;
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
            primaryAddress = _fetchedUserAddresses.firstWhere((doc) =>
                (doc.data() as Map<String, dynamic>)['isPrimary'] == true);
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
    return AddressFormatter.formatAddressLayout(data);
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

  // Removed _getCurrentLocation and _fillAddressFromPlacemark methods - now using AddAddressScreen

  // Removed _saveNewAddress method - now using AddAddressScreen like profile screen

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
                      _navigateToAddAddress(); // Use the same flow as profile screen
                    },
                  );
                }

                var addressDoc = _fetchedUserAddresses[index];
                var addressData = addressDoc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(
                    _formatAddress(addressData),
                    style: const TextStyle(height: 1.4),
                  ),
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextTheme.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Removed _buildLocationStep method - now using AddAddressScreen like profile screen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        foregroundColor: context.onBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Schedule Pickup & Delivery',
          style: TextStyle(
            // color: Colors.black,
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
                    const SizedBox(height: 24),
                  ] else if (selectedTabIndex == 1) ...[
                    // Schedule Tab Content
                    _buildItemsSummary(),
                    const SizedBox(height: 24),
                    // Always show locations section - inline form removed
                    _buildLocationsSection(),
                    const SizedBox(height: 24),
                    _buildPickupSection(),
                    const SizedBox(height: 24),
                    _buildDeliverySection(),
                    const SizedBox(height: 24),
                    _buildSpecialInstructionsSection(),
                    const SizedBox(height: 24),
                  ] else if (selectedTabIndex == 2) ...[
                    // Payment Tab Content
                    _buildItemsSummary(),
                    const SizedBox(height: 24),
                    _buildOrderSummary(),
                    const SizedBox(height: 24),
                    _buildPaymentSection(),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(
                      height: 120), // Increased space for sticky cart
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildStickyCartSummary(),
    );
  }

  Widget _buildStickyCartSummary() {
    final totalItems =
        widget.selectedItems.values.fold(0, (sum, quantity) => sum + quantity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Container(
        decoration: BoxDecoration(
          color: context.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 20), // 20px from bottom
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cart Summary Row
                Row(
                  children: [
                    // Cart Icon with Badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.isAlliedServices
                                ? Icons.home_repair_service
                                : Icons.local_laundry_service,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$totalItems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Amount Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalItems item${totalItems > 1 ? 's' : ''} selected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${widget.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Button
                    _buildStickyActionButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Items', 'Schedule', 'Payment'];
    return Container(
      color: context.backgroundColor,
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
        const SnackBar(
            content: Text('Please select pickup and delivery addresses.')),
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

    // Validate 20-hour minimum constraint
    if (!_validateTwentyHourConstraint()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Delivery must be scheduled at least 20 hours after pickup.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    return true;
  }

  bool _validateTwentyHourConstraint() {
    if (selectedPickupDate == null ||
        selectedDeliveryDate == null ||
        selectedPickupTimeSlot == null ||
        selectedDeliveryTimeSlot == null) {
      return false;
    }

    // Create DateTime objects for pickup and delivery
    final pickupDateTime = DateTime(
      selectedPickupDate!.year,
      selectedPickupDate!.month,
      selectedPickupDate!.day,
      selectedPickupTimeSlot!.startHour,
    );

    final deliveryDateTime = DateTime(
      selectedDeliveryDate!.year,
      selectedDeliveryDate!.month,
      selectedDeliveryDate!.day,
      selectedDeliveryTimeSlot!.startHour,
    );

    // Calculate minimum delivery time (20 hours after pickup)
    final minDeliveryDateTime = pickupDateTime.add(const Duration(hours: 20));

    // Check if delivery is at least 20 hours after pickup
    return deliveryDateTime.isAfter(minDeliveryDateTime) ||
        deliveryDateTime.isAtSameMomentAs(minDeliveryDateTime);
  }

  Widget _buildItemsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.backgroundColor,
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
        color: context.backgroundColor,
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
            value: selectedDeliveryDate != null &&
                    selectedDeliveryTimeSlot != null
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
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
    // Prevent double submission
    if (_isSavingOrder) {
      print(
          '🔥 ORDER PLACEMENT: ⚠️ Order already being processed, ignoring duplicate UPI payment request');
      return;
    }

    // Show enhanced UPI payment widget
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: UPIPaymentWidget(
                amount: widget.totalAmount >= 1
                    ? widget.totalAmount
                    : 1.0, // Minimum ₹1 for UPI
                description: 'Laundry service - ${_totalItemCount} items',
                orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
                onPaymentResult: (result) async {
                  Navigator.pop(context); // Close the payment sheet
                  if (result['success'] == true) {
                    // Payment successful, process the order
                    await _processOrder(
                      paymentStatus: 'completed',
                      transactionId: result['transactionId'] ??
                          'UPI_${DateTime.now().millisecondsSinceEpoch}',
                    );
                  } else {
                    // Payment failed or cancelled
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Payment cancelled'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                onCancel: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to determine service type based on items
  String _determineServiceType(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return 'Laundry Service';
    }
    
    // Count items by category
    Map<String, int> categoryCount = {};
    
    for (var item in items) {
      String category = item['category']?.toString().toLowerCase() ?? '';
      int quantity = item['quantity'] ?? 1;
      
      // Normalize category names
      if (category.contains('iron') || category == 'ironing') {
        categoryCount['ironing'] = (categoryCount['ironing'] ?? 0) + quantity;
      } else if (category.contains('allied') || category == 'allied service' || category == 'allied services') {
        categoryCount['allied'] = (categoryCount['allied'] ?? 0) + quantity;
      } else {
        // Everything else is considered laundry (wash & fold, dry cleaning, etc.)
        categoryCount['laundry'] = (categoryCount['laundry'] ?? 0) + quantity;
      }
    }
    
    // Determine service type based on items
    int ironingCount = categoryCount['ironing'] ?? 0;
    int alliedCount = categoryCount['allied'] ?? 0;
    int laundryCount = categoryCount['laundry'] ?? 0;
    
    // Check for combinations
    List<String> serviceTypes = [];
    if (ironingCount > 0) serviceTypes.add('Ironing');
    if (alliedCount > 0) serviceTypes.add('Allied');
    if (laundryCount > 0) serviceTypes.add('Laundry');
    
    if (serviceTypes.length > 1) {
      return 'Mixed Service (${serviceTypes.join(' & ')})';
    } else if (ironingCount > 0) {
      return 'Ironing Service';
    } else if (alliedCount > 0) {
      return 'Allied Service';
    } else {
      return 'Laundry Service';
    }
  }

  Future<void> _processOrder(
      {required String paymentStatus, String? transactionId}) async {
    setState(() => _isSavingOrder = true);

    try {
      // Use AuthProvider instead of FirebaseAuth.instance.currentUser
      final authProvider =
          Provider.of<auth_provider.AuthProvider>(context, listen: false);

      // Add debug logging
      print('🔥 ORDER PLACEMENT: Starting order process');
      print(
          '🔥 ORDER PLACEMENT: AuthProvider status: ${authProvider.authStatus}');
      print(
          '🔥 ORDER PLACEMENT: UserModel exists: ${authProvider.userModel != null}');
      print(
          '🔥 ORDER PLACEMENT: UserModel UID: ${authProvider.userModel?.uid}');
      print(
          '🔥 ORDER PLACEMENT: Firebase currentUser: ${_auth.currentUser?.uid}');

      // Check if user is authenticated through AuthProvider
      if (authProvider.authStatus != auth_provider.AuthStatus.authenticated ||
          authProvider.userModel == null) {
        print('🔥 ORDER PLACEMENT: ❌ User not authenticated via AuthProvider');
        throw Exception('Please log in to place an order');
      }

      // Get current user from AuthProvider (more reliable than FirebaseAuth.instance.currentUser)
      final currentUser = _auth.currentUser;
      final userModel = authProvider.userModel!;

      print('🔥 ORDER PLACEMENT: ✅ User authenticated via AuthProvider');
      print('🔥 ORDER PLACEMENT: UserModel UID: ${userModel.uid}');
      print(
          '🔥 ORDER PLACEMENT: Firebase currentUser UID: ${currentUser?.uid}');

      // Double-check Firebase auth state with retry mechanism
      if (currentUser == null) {
        print(
            '🔥 ORDER PLACEMENT: ⚠️ Firebase currentUser is null, retrying...');
        // Wait a bit and try again (Firebase auth might be synchronizing)
        await Future.delayed(const Duration(milliseconds: 500));
        final retryCurrentUser = _auth.currentUser;

        print(
            '🔥 ORDER PLACEMENT: Retry currentUser: ${retryCurrentUser?.uid}');

        if (retryCurrentUser == null) {
          print('🔥 ORDER PLACEMENT: ⚠️ Still null, refreshing auth state...');
          // If still null, refresh auth state
          await authProvider.refreshUserData();
          final finalCurrentUser = _auth.currentUser;

          print(
              '🔥 ORDER PLACEMENT: Final currentUser: ${finalCurrentUser?.uid}');

          if (finalCurrentUser == null) {
            print('🔥 ORDER PLACEMENT: ❌ Firebase auth completely lost');
            throw Exception(
                'Authentication session expired. Please log in again.');
          }
        }
      }

      // Use the userModel UID as primary source of truth
      final userId = userModel.uid;

      print('🔥 ORDER PLACEMENT: ✅ Using userId: $userId');

      // Prepare order data
      List<Map<String, dynamic>> itemsForOrder = [];
      widget.selectedItems.forEach((itemModel, quantity) {
        // Use effective price (considers offer price if available)
        final effectivePrice = itemModel.offerPrice ?? itemModel.pricePerPiece;
        itemsForOrder.add({
          'itemId': itemModel.id,
          'name': itemModel.name,
          'pricePerPiece': effectivePrice,
          'offerPrice': itemModel.offerPrice, // Store offer price if exists
          'quantity': quantity,
          'category': itemModel.category,
          'unit': itemModel.unit,
        });
      });

      // Determine service type based on selected items
      String serviceType = _determineServiceType(itemsForOrder);
      
      // Generate service-specific order number
      String orderNumber = await OrderNumberService.generateUniqueOrderNumber(serviceType: serviceType);

      print('🔥 ORDER PLACEMENT: Generated order number: $orderNumber for service type: $serviceType');

      // Prepare address data
      final pickupAddressData =
          _selectedPickupAddress!.data() as Map<String, dynamic>;
      final deliveryAddressData = sameAddressForDelivery
          ? pickupAddressData
          : (_selectedDeliveryAddress!.data() as Map<String, dynamic>);

      Map<String, dynamic> orderData = {
        'customerId': userId,
        'orderNumber': orderNumber,
        'orderTimestamp': Timestamp.now(),
        'serviceType': serviceType,
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
          'addressId': sameAddressForDelivery
              ? _selectedPickupAddress!.id
              : _selectedDeliveryAddress!.id,
          'formatted': _formatAddress(deliveryAddressData),
          'details': deliveryAddressData,
        },
        'sameAddressForDelivery': sameAddressForDelivery,
        'specialInstructions': specialInstructionsController.text.trim(),
        'paymentMethod': _selectedPaymentMethod.name,
        'paymentStatus': paymentStatus,
        'status': 'pending',
        'orderType': 'pickup_delivery',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'statusHistory': [
          {
            'status': 'pending',
            'timestamp': Timestamp.now(),
            'title': 'Order Placed',
            'description': 'Your order has been placed successfully',
          }
        ],
      };

      if (transactionId != null) {
        orderData['transactionId'] = transactionId;
      }

      print(
          '🔥 ORDER PLACEMENT: ✅ Saving order to Firestore with order number as document ID...');
      // Use the 6-digit order number as the document ID
      DocumentReference orderRef =
          _firestore.collection('orders').doc(orderNumber);
      await orderRef.set(orderData);
      String orderId = orderRef.id; // This will be the 6-digit order number

      print('🔥 ORDER PLACEMENT: ✅ Order saved successfully with ID: $orderId');

      // Send notification to admin using new OrderNotificationService
      try {
        await OrderNotificationService.notifyAdminOfNewOrder(
          orderId: orderId,
          orderNumber: orderNumber,
          totalAmount: widget.totalAmount,
          itemCount: _totalItemCount,
          pickupAddress: _formatAddress(pickupAddressData),
          specialInstructions: specialInstructionsController.text.trim(),
        );
        print('🔥 ORDER PLACEMENT: ✅ Notification sent to admin');
      } catch (e) {
        print('🔥 ORDER PLACEMENT: ⚠️ Error sending notification to admin: $e');
      }

      // Set up order status listener for this customer
      OrderNotificationService.setupOrderStatusListener();

      setState(() {
        _isSavingOrder = false;
      });

      if (mounted) {
        print('🔥 ORDER PLACEMENT: ✅ Showing success dialog');
        _showOrderSuccessDialog(paymentStatus == 'completed', orderNumber);
      }
    } catch (e) {
      print('🔥 ORDER PLACEMENT: ❌ Error: $e');
      setState(() {
        _isSavingOrder = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderSuccessDialog(bool isUPIPaid, String orderNumber) {
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
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
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
            // Order Number Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Order ID: #$orderNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.backgroundColor,
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
                      const Icon(Icons.local_shipping,
                          size: 16, color: Colors.green),
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
                      const Icon(Icons.currency_rupee,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Total: ₹${widget.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  if (isUPIPaid) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.payment,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment: Completed',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.green),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
            color: context.backgroundColor,
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
                    child: const Icon(Icons.location_on,
                        color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pickup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        _showAddressSelectionDialog(isPickup: true),
                    child: const Text('Change',
                        style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _isLoadingAddress
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _selectedPickupAddress != null
                          ? _formatAddress(_selectedPickupAddress!.data()
                              as Map<String, dynamic>)
                          : 'No address selected',
                      style: TextStyle(
                        color: _selectedPickupAddress != null
                            ? Colors.grey[700]
                            : Colors.orange,
                        fontSize: 14,
                        height: 1.4,
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
            color: context.backgroundColor,
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
              color: context.backgroundColor,
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
                      child: const Icon(Icons.location_on,
                          color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Delivery',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          _showAddressSelectionDialog(isPickup: false),
                      child: const Text('Change',
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedDeliveryAddress != null
                      ? _formatAddress(_selectedDeliveryAddress!.data()
                          as Map<String, dynamic>)
                      : 'No delivery address selected',
                  style: TextStyle(
                    color: _selectedDeliveryAddress != null
                        ? Colors.grey[700]
                        : Colors.orange,
                    fontSize: 14,
                    height: 1.4,
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
        Row(
          children: [
            const Text(
              'Pickup Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            if (selectedPickupDate != null)
              Text(
                DateFormat('EEEE, MMM d').format(selectedPickupDate!),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDateSelector(
          selectedOption: selectedPickupDateOption,
          onOptionSelected: (option) {
            setState(() {
              selectedPickupDateOption = option;
              selectedPickupDate = _getDateFromOption(option);

              _updateAvailablePickupSlots();

              // Recalculate best delivery options based on new pickup date
              selectedDeliveryDateOption = DateOption.today;
              selectedDeliveryDate =
                  _getDateFromDeliveryOption(selectedDeliveryDateOption);
              _updateAvailableDeliverySlots();

              if (availableDeliverySlots.isEmpty) {
                selectedDeliveryDateOption = DateOption.tomorrow;
                selectedDeliveryDate =
                    _getDateFromDeliveryOption(selectedDeliveryDateOption);
                _updateAvailableDeliverySlots();
              }

              if (availableDeliverySlots.isNotEmpty) {
                selectedDeliveryTimeSlot = availableDeliverySlots.first;
              }
            });
          },
          onCustomDateSelected: (date) {
            setState(() {
              selectedPickupDateOption = DateOption.custom;
              selectedPickupDate = date;

              _updateAvailablePickupSlots();

              // Recalculate best delivery options based on new pickup date
              selectedDeliveryDateOption = DateOption.today;
              selectedDeliveryDate =
                  _getDateFromDeliveryOption(selectedDeliveryDateOption);
              _updateAvailableDeliverySlots();

              if (availableDeliverySlots.isEmpty) {
                selectedDeliveryDateOption = DateOption.tomorrow;
                selectedDeliveryDate =
                    _getDateFromDeliveryOption(selectedDeliveryDateOption);
                _updateAvailableDeliverySlots();
              }

              if (availableDeliverySlots.isNotEmpty) {
                selectedDeliveryTimeSlot = availableDeliverySlots.first;
              }
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
              // Update delivery slots based on new pickup time
              _updateAvailableDeliverySlots();

              // If current delivery date/time is no longer valid, reset to best option
              if (availableDeliverySlots.isEmpty ||
                  !availableDeliverySlots.contains(selectedDeliveryTimeSlot)) {
                // Try to find a better delivery date
                selectedDeliveryDateOption = DateOption.today;
                selectedDeliveryDate =
                    _getDateFromDeliveryOption(selectedDeliveryDateOption);
                _updateAvailableDeliverySlots();

                if (availableDeliverySlots.isEmpty) {
                  selectedDeliveryDateOption = DateOption.tomorrow;
                  selectedDeliveryDate =
                      _getDateFromDeliveryOption(selectedDeliveryDateOption);
                  _updateAvailableDeliverySlots();
                }

                if (availableDeliverySlots.isNotEmpty) {
                  selectedDeliveryTimeSlot = availableDeliverySlots.first;
                }
              }
            });
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Delivery Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            // const Spacer(),
            if (selectedDeliveryDate != null)
              Text(
                DateFormat('EEEE, MMM d').format(selectedDeliveryDate!),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Container(
        //   padding: const EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: Colors.blue.withOpacity(0.1),
        //     borderRadius: BorderRadius.circular(8),
        //     border: Border.all(color: Colors.blue.withOpacity(0.3)),
        //   ),
        //   child: Row(
        //     children: [
        //       const Icon(Icons.info_outline, color: Colors.blue, size: 20),
        //       const SizedBox(width: 8),
        //       Expanded(
        //         child: Text(
        //           'Choose any date and time - delivery must be at least 20 hours after pickup time',
        //           style: TextStyle(
        //             color: Colors.blue[700],
        //             fontSize: 12,
        //             fontWeight: FontWeight.w500,
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        const SizedBox(height: 16),
        _buildDeliveryDateSelector(),
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

  Widget _buildDeliveryDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Custom date selector button
        GestureDetector(
          onTap: () async {
            DateTime initialDate = _getMinimumDeliveryDate();

            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: initialDate,
              lastDate: DateTime.now().add(const Duration(days: 30)),
              helpText: 'Select Delivery Date',
              fieldLabelText: 'Must be at least 20 hours after pickup',
              selectableDayPredicate: (DateTime date) {
                // Allow all days including Sunday
                // Ensure it meets minimum requirement
                return !date.isBefore(_getMinimumDeliveryDate());
              },
            );

            if (picked != null) {
              setState(() {
                selectedDeliveryDateOption = DateOption.custom;
                selectedDeliveryDate = picked;
                _updateAvailableDeliverySlots();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDeliveryDate != null
                      ? DateFormat('EEEE, MMM d').format(selectedDeliveryDate!)
                      : 'Select Delivery Date',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DateTime _getMinimumDeliveryDate() {
    DateTime minDateTime;

    if (selectedPickupDate != null && selectedPickupTimeSlot != null) {
      // Calculate exact 20 hours from pickup time
      final pickupDateTime = DateTime(
        selectedPickupDate!.year,
        selectedPickupDate!.month,
        selectedPickupDate!.day,
        selectedPickupTimeSlot!.startHour,
      );
      minDateTime = pickupDateTime.add(const Duration(hours: 20));
    } else if (selectedPickupDate != null) {
      // If pickup date is set but no time slot, assume earliest possible pickup time
      final pickupDateTime = DateTime(
        selectedPickupDate!.year,
        selectedPickupDate!.month,
        selectedPickupDate!.day,
        7, // 7 AM - earliest pickup time
      );
      minDateTime = pickupDateTime.add(const Duration(hours: 20));
    } else {
      // If no pickup selected, use current time + 20 hours as minimum
      minDateTime = DateTime.now().add(const Duration(hours: 20));
    }

    // Return the date part of the minimum datetime (same day if possible)
    DateTime minDate =
        DateTime(minDateTime.year, minDateTime.month, minDateTime.day);

    // Allow minimum delivery date on any day including Sunday

    return minDate;
  }

// Replace the _buildDateSelector method with this updated version:

  Widget _buildDateSelector({
    required DateOption selectedOption,
    required Function(DateOption) onOptionSelected,
    required Function(DateTime) onCustomDateSelected,
    bool isDelivery = false,
  }) {
    final now = DateTime.now();
    List<DateOption> availableOptions = DateOption.values.toList();

    if (isDelivery) {
      // For delivery, only show custom date option
      availableOptions = [DateOption.custom];
    } else {
      // For pickup, remove "Today" option after 8 PM
      if (now.hour >= 20) {
        availableOptions.removeWhere((option) => option == DateOption.today);
      }
    }

    return Row(
      children: availableOptions.asMap().entries.map((entry) {
        int index = entry.key;
        DateOption option = entry.value;
        bool isSelected = option == selectedOption;

        return Expanded(
          child: GestureDetector(
            onTap: () async {
              if (option == DateOption.custom) {
                DateTime initialDate;
                DateTime firstDate;
                
                if (isDelivery) {
                  initialDate = _getMinimumDeliveryDate();
                  firstDate = _getMinimumDeliveryDate();
                } else {
                  // For pickup, check if today is available
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  
                  if (now.hour >= 20) {
                    // After 8 PM, start from tomorrow
                    initialDate = today.add(const Duration(days: 1));
                    firstDate = today.add(const Duration(days: 1));
                  } else {
                    // Before 8 PM, allow today
                    initialDate = today;
                    firstDate = today;
                  }
                }

                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  helpText: isDelivery
                      ? 'Select Delivery Date'
                      : 'Select Pickup Date',
                  fieldLabelText: isDelivery
                      ? 'Must be at least 20 hours after pickup'
                      : 'Select date',
                  selectableDayPredicate: (DateTime date) {
                    // Allow all days including Sunday

                    // For delivery, ensure it meets minimum requirement
                    if (isDelivery) {
                      return !date.isBefore(_getMinimumDeliveryDate());
                    }

                    // For pickup, allow today and future dates
                    // But if it's late in the day (after 8 PM), don't allow today
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    if (date.isAtSameMomentAs(today) && now.hour >= 20) {
                      return false; // Can't schedule pickup for today if it's after 8 PM
                    }

                    return !date.isBefore(today);
                  },
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
                right: index < availableOptions.length - 1 ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
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
                  color:
                      isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
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
                            ),
                            textAlign: TextAlign.center,
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
            color: context.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: specialInstructionsController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Any specific requirements for ironing? (e.g., starch, delicate handling)',
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
        color: context.backgroundColor,
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
              final effectivePrice = item.offerPrice ?? item.pricePerPiece;
              final itemTotal = effectivePrice * quantity;

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
                        Row(
                          children: [
                            // Original Price (strikethrough) - Show first if there's an offer
                            if (item.offerPrice != null && item.offerPrice! < item.pricePerPiece)
                              Text(
                                '₹${item.pricePerPiece.toInt()}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            // Add spacing between original and offer price
                            if (item.offerPrice != null && item.offerPrice! < item.pricePerPiece)
                              const SizedBox(width: 8),
                            // Current/Offer Price
                            Text(
                              '₹${(item.offerPrice ?? item.pricePerPiece).toInt()} per piece',
                              style: TextStyle(
                                color: item.offerPrice != null
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: item.offerPrice != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
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
            color: context.backgroundColor,
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
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
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
        //     color: context.backgroundColor,
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
                // UPI Badge
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //   decoration: BoxDecoration(
                //     color: Colors.green.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: Colors.green.withOpacity(0.3)),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Icon(Icons.flash_on, color: Colors.green, size: 14),
                //       const SizedBox(width: 4),
                //       Text(
                //         'Instant',
                //         style: TextStyle(
                //           color: Colors.green,
                //           fontSize: 12,
                //           fontWeight: FontWeight.w600,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
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

        // UPI Payment Details (shown when UPI is selected)
        if (_selectedPaymentMethod == PaymentMethod.upi) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'UPI Payment Details',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildUpiInfoRow('UPI ID', '7396674546-3@ybl'),
                const SizedBox(height: 8),
                _buildUpiInfoRow('Merchant', 'Cloud Ironing Factory'),
                const SizedBox(height: 8),
                _buildUpiInfoRow('Amount', '₹${widget.totalAmount.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Secure payment via UPI. Multiple payment options available after order confirmation.',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Payment Info
        // Container(
        //   padding: const EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: Colors.blue.withOpacity(0.1),
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   child: Row(
        //     children: [
        //       const Icon(Icons.info_outline, color: Colors.blue, size: 20),
        //       const SizedBox(width: 12),
        //       Expanded(
        //         child: Text(
        //           _selectedPaymentMethod == PaymentMethod.upi
        //               ? 'Complete UPI payment to confirm your order. Your payment is secure and encrypted.'
        //               : 'Your order will be confirmed. Payment will be collected at delivery.',
        //           style: const TextStyle(color: Colors.blue, fontSize: 14),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildUpiInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          ': ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // New method to build inline action buttons
  Widget _buildInlineActionButton(String text, VoidCallback? onPressed,
      {bool isLoading = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    // Prevent double submission
    if (_isSavingOrder) {
      print(
          '🔥 ORDER PLACEMENT: ⚠️ Order already being processed, ignoring duplicate request');
      return;
    }

    // Use the comprehensive validation method
    if (!_validateScheduleDetails()) {
      return; // Validation failed, error message already shown
    }

    // If UPI payment is selected, navigate to UPI payment screen
    if (_selectedPaymentMethod == PaymentMethod.upi) {
      await _processUPIPayment();
      return;
    }

    // Process COD order directly
    await _processOrder(paymentStatus: 'pending', transactionId: null);
  }

  Widget _buildStickyActionButton() {
    if (selectedTabIndex == 0) {
      // Items tab - Continue to Schedule
      return ElevatedButton(
        onPressed: () {
          setState(() {
            selectedTabIndex = 1;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 18),
            SizedBox(width: 8),
            Text(
              'Schedule',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (selectedTabIndex == 1) {
      // Schedule tab - Continue to Payment
      return ElevatedButton(
        onPressed: () {
          if (_validateScheduleDetails()) {
            setState(() {
              selectedTabIndex = 2;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment, size: 18),
            SizedBox(width: 8),
            Text(
              'Payment',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      // Payment tab - Confirm Order
      return ElevatedButton(
        onPressed: _isSavingOrder ? null : _saveOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSavingOrder
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      );
    }
  }

  @override
  void dispose() {
    specialInstructionsController.dispose();
    super.dispose();
  }
}
