import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/address_model.dart';
import '../../models/item_model.dart';

import '../../providers/item_provider.dart';
import '../../providers/allied_service_provider.dart';
import '../../services/order_number_service.dart';

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
        return '7 to 11 AM';
      case TimeSlot.noon:
        return '11 AM to 4 PM';
      case TimeSlot.evening:
        return '4 to 8 PM';
    }
  }

  int get startHour {
    switch (this) {
      case TimeSlot.morning:
        return 7;
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

// Theme extensions to match customer app styling
extension ThemeExtensions on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Color get surfaceColor => colorScheme.surface;
  Color get onSurfaceColor => colorScheme.onSurface;
  Color get surfaceVariant => colorScheme.surfaceContainerHighest;
  Color get onSurfaceVariant => colorScheme.onSurfaceVariant;
  Color get outlineVariant => colorScheme.outlineVariant;
  Color get primaryColor => colorScheme.primary;
}

class PlaceOrderForCustomerScreen extends StatefulWidget {
  final UserModel customer;

  const PlaceOrderForCustomerScreen({
    super.key,
    required this.customer,
  });

  @override
  State<PlaceOrderForCustomerScreen> createState() => _PlaceOrderForCustomerScreenState();
}

class _PlaceOrderForCustomerScreenState extends State<PlaceOrderForCustomerScreen> {
  final Map<String, int> _itemQuantities = {};
  final _specialInstructionsController = TextEditingController();
  
  List<AddressModel> _customerAddresses = [];
  AddressModel? _selectedAddress;
  
  // Date and time state variables - same as customer app
  DateOption selectedPickupDateOption = DateOption.today;
  DateTime? selectedPickupDate;
  TimeSlot? selectedPickupTimeSlot;

  DateOption selectedDeliveryDateOption = DateOption.tomorrow;
  DateTime? selectedDeliveryDate;
  TimeSlot? selectedDeliveryTimeSlot;

  List<TimeSlot> availablePickupSlots = TimeSlot.values;
  List<TimeSlot> availableDeliverySlots = TimeSlot.values;

  bool sameAddressForDelivery = true;
  
  bool _isLoadingAddresses = true;
  bool _isPlacingOrder = false;
  
  // Service selection similar to customer app
  String _selectedServiceType = 'all'; // 'ironing', 'allied', 'all'

  @override
  void initState() {
    super.initState();
    _loadCustomerAddresses();
    _initializeDateTimeSlots();
    // Load items and allied services when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemProvider>(context, listen: false).loadItems();
      Provider.of<AlliedServiceProvider>(context, listen: false).loadAlliedServices();
    });
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
    selectedDeliveryDate = selectedPickupDate!.add(const Duration(days: 2));

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
        date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
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
        date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
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

  DateTime _getMinimumDeliveryDate() {
    if (selectedPickupDate == null || selectedPickupTimeSlot == null) {
      return DateTime.now().add(const Duration(days: 1));
    }

    // Calculate pickup datetime
    final pickupDateTime = DateTime(
      selectedPickupDate!.year,
      selectedPickupDate!.month,
      selectedPickupDate!.day,
      selectedPickupTimeSlot!.endHour,
    );

    // Minimum delivery is 20 hours after pickup end time
    return pickupDateTime.add(const Duration(hours: 20));
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
      selectedPickupTimeSlot!.endHour,
    );

    // Add minimum processing time (20 hours)
    final minimumDeliveryDateTime = pickupDateTime.add(const Duration(hours: 20));

    if (_isSameDay(selectedDeliveryDate!, minimumDeliveryDateTime)) {
      // If delivery is on the same day as minimum requirement, filter slots
      slots = slots.where((slot) {
        final deliverySlotStart = DateTime(
          selectedDeliveryDate!.year,
          selectedDeliveryDate!.month,
          selectedDeliveryDate!.day,
          slot.startHour,
        );
        return deliverySlotStart.isAfter(minimumDeliveryDateTime) ||
               deliverySlotStart.isAtSameMomentAs(minimumDeliveryDateTime);
      }).toList();
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

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerAddresses() async {
    try {
      final addressesSnapshot = await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.customer.uid)
          .collection('addresses')
          .get();

      final addresses = addressesSnapshot.docs.map((doc) {
        final data = doc.data();
        return AddressModel.fromFirestore(data, doc.id);
      }).toList();

      // Sort by primary first
      addresses.sort((a, b) {
        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        return 0;
      });

      setState(() {
        _customerAddresses = addresses;
        _selectedAddress = addresses.isNotEmpty ? addresses.first : null;
        _isLoadingAddresses = false;
      });
    } catch (e) {
      print('Error loading customer addresses: $e');
      setState(() => _isLoadingAddresses = false);
    }
  }

  void _incrementQuantity(String itemId) {
    setState(() {
      _itemQuantities[itemId] = (_itemQuantities[itemId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(String itemId) {
    setState(() {
      if ((_itemQuantities[itemId] ?? 0) > 0) {
        _itemQuantities[itemId] = (_itemQuantities[itemId] ?? 0) - 1;
        if (_itemQuantities[itemId] == 0) {
          _itemQuantities.remove(itemId);
        }
      }
    });
  }

  double _calculateTotalAmount(List<ItemModel> items) {
    double total = 0.0;
    for (final entry in _itemQuantities.entries) {
      final item = items.firstWhere((item) => item.id == entry.key);
      final effectivePrice = item.offerPrice ?? item.price;
      total += effectivePrice * entry.value;
    }
    return total;
  }

  // Service type determination logic same as customer app
  String _determineServiceTypeFromItems(List<Map<String, dynamic>> items) {
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
      } else if (category.contains('alien') || category == 'alien' || category.contains('allied')) {
        categoryCount['alien'] = (categoryCount['alien'] ?? 0) + quantity;
        } else {
        // Everything else is considered laundry (wash & fold, dry cleaning, etc.)
        categoryCount['laundry'] = (categoryCount['laundry'] ?? 0) + quantity;
      }
    }
    
    // Determine service type based on items
    int ironingCount = categoryCount['ironing'] ?? 0;
    int alienCount = categoryCount['alien'] ?? 0;
    int laundryCount = categoryCount['laundry'] ?? 0;
    
    // Check for combinations
    List<String> serviceTypes = [];
    if (ironingCount > 0) serviceTypes.add('Ironing');
    if (alienCount > 0) serviceTypes.add('Alien');
    if (laundryCount > 0) serviceTypes.add('Laundry');
    
    if (serviceTypes.length > 1) {
      return 'Mixed Service (${serviceTypes.join(' & ')})';
    } else if (ironingCount > 0) {
      return 'Ironing Service';
    } else if (alienCount > 0) {
      return 'Alien Service';
    } else {
      return 'Laundry Service';
    }
  }

  int get _totalItems => _itemQuantities.values.fold(0, (sum, quantity) => sum + quantity);



  Future<void> _placeOrder() async {
    // Validation
    if (_itemQuantities.isEmpty) {
      _showErrorDialog('Please select at least one item');
      return;
    }

    if (_selectedAddress == null) {
      _showErrorDialog('Please select a delivery address');
      return;
    }

    if (selectedPickupDate == null || selectedPickupTimeSlot == null) {
      _showErrorDialog('Please select pickup date and time');
      return;
    }

    if (selectedDeliveryDate == null || selectedDeliveryTimeSlot == null) {
      _showErrorDialog('Please select delivery date and time');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      // Generate unique order number using the same service as customer app
      String orderNumber = await OrderNumberService.generateUniqueOrderNumber();
      
      // Get items for order (both regular items and allied services)
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final alliedServiceProvider = Provider.of<AlliedServiceProvider>(context, listen: false);
      final allItems = _getFilteredItems(itemProvider.items, alliedServiceProvider.alliedServices.cast<dynamic>());
      
      // Prepare items list in the same format as customer app
      List<Map<String, dynamic>> itemsForOrder = [];
      for (final entry in _itemQuantities.entries) {
        final item = allItems.firstWhere((item) => item.id == entry.key);
        final effectivePrice = item.offerPrice ?? item.price;
        itemsForOrder.add({
          'itemId': item.id,
          'name': item.name,
          'pricePerPiece': effectivePrice,
          'offerPrice': item.offerPrice,
          'quantity': entry.value,
          'category': item.category,
          'unit': item.unit,
        });
      }

      final totalAmount = _calculateTotalAmount(allItems);
      final totalItemCount = _itemQuantities.values.fold(0, (sum, qty) => sum + qty);

      // Determine service type using same logic as customer app
      String serviceType = _determineServiceTypeFromItems(itemsForOrder);

      // Create order data in same format as customer app
      final orderData = {
        'customerId': widget.customer.uid,
        'orderNumber': orderNumber,
        'orderTimestamp': Timestamp.now(), // Use Timestamp.now() instead of serverTimestamp
        'serviceType': serviceType,
        'items': itemsForOrder,
        'totalAmount': totalAmount,
        'totalItemCount': totalItemCount,
        'pickupDate': Timestamp.fromDate(selectedPickupDate!),
        'pickupTimeSlot': selectedPickupTimeSlot!.name,
        'deliveryDate': Timestamp.fromDate(selectedDeliveryDate!),
        'deliveryTimeSlot': selectedDeliveryTimeSlot!.name,
        'pickupAddress': {
          'addressId': _selectedAddress!.id,
          'formatted': _selectedAddress!.fullAddress,
          'details': {
          'type': _selectedAddress!.type,
          'addressLine1': _selectedAddress!.addressLine1,
          'addressLine2': _selectedAddress!.addressLine2,
          'city': _selectedAddress!.city,
          'state': _selectedAddress!.state,
          'pincode': _selectedAddress!.pincode,
          'landmark': _selectedAddress!.landmark,
          'latitude': _selectedAddress!.latitude,
          'longitude': _selectedAddress!.longitude,
        },
        },
        'deliveryAddress': {
          'addressId': _selectedAddress!.id,
          'formatted': _selectedAddress!.fullAddress,
          'details': {
            'type': _selectedAddress!.type,
            'addressLine1': _selectedAddress!.addressLine1,
            'addressLine2': _selectedAddress!.addressLine2,
            'city': _selectedAddress!.city,
            'state': _selectedAddress!.state,
            'pincode': _selectedAddress!.pincode,
            'landmark': _selectedAddress!.landmark,
            'latitude': _selectedAddress!.latitude,
            'longitude': _selectedAddress!.longitude,
          },
        },
        'sameAddressForDelivery': true,
        'specialInstructions': _specialInstructionsController.text.trim(),
        'paymentMethod': 'cod', // Admin orders default to COD
        'paymentStatus': 'pending',
        'status': 'pending',
        'orderType': 'pickup_delivery',
        'createdAt': Timestamp.now(), // Use Timestamp.now() instead of serverTimestamp
        'updatedAt': Timestamp.now(), // Use Timestamp.now() instead of serverTimestamp
        'isAdminCreated': true,
        'createdBy': 'admin',
        'statusHistory': [
          {
            'status': 'pending',
            'timestamp': Timestamp.now(), // Use Timestamp.now() instead of serverTimestamp
            'title': 'Order Placed',
            'description': 'Order placed by admin for customer',
            'updatedBy': 'admin',
          }
        ],
      };

      // Use the order number as document ID, same as customer app
      DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc(orderNumber);
      await orderRef.set(orderData);

      if (mounted) {
        setState(() => _isPlacingOrder = false);
        _showOrderSuccessDialog(false, orderNumber); // Admin orders are COD by default
      }
    } catch (e) {
      print('Error placing order: $e');
      if (mounted) {
        _showErrorDialog('Failed to place order: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              'Order has been successfully placed for ${widget.customer.name} with Cash on Delivery.',
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
                color: context.surfaceVariant,
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
                      Consumer2<ItemProvider, AlliedServiceProvider>(
                        builder: (context, itemProvider, alliedServiceProvider, child) {
                          final allItems = _getFilteredItems(itemProvider.items, alliedServiceProvider.alliedServices.cast<dynamic>());
                          final totalAmount = _calculateTotalAmount(allItems);
                          return Text(
                            'Total: ₹${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          );
                        },
                      ),
                    ],
                  ),
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
              Navigator.of(context).pop(true);
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
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Place Order for ${widget.customer.name}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer Info Card
            _buildCustomerInfoCard(),
            
            const SizedBox(height: 16),

            // Service Type Selection
            _buildServiceTypeCard(),
            
            const SizedBox(height: 16),

            // Items Selection
            _buildItemsSelectionCard(),
            
            const SizedBox(height: 24),

            // Address Section - same as customer app
            _buildLocationsSection(),
            
            const SizedBox(height: 24),

            // Pickup Section - same as customer app
            _buildPickupSection(),
            
            const SizedBox(height: 24),

            // Delivery Section - same as customer app
            _buildDeliverySection(),
            
            const SizedBox(height: 24),

            // Special Instructions - same as customer app
            _buildSpecialInstructionsSection(),
            
            const SizedBox(height: 24),

            // Place Order Button
          
            Consumer2<ItemProvider, AlliedServiceProvider>(
      builder: (context, itemProvider, alliedServiceProvider, child) {
        final allItems = _getFilteredItems(itemProvider.items, alliedServiceProvider.alliedServices.cast<dynamic>());
        final totalAmount = _calculateTotalAmount(allItems);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Items: $_totalItems',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Total Amount: ₹${totalAmount.toInt()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // SizedBox(
                //   width: 120,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       // Scroll to address selection
                //       // This is just to show the continue button functionality
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(
                //           content: Text('Please fill in the address and schedule details above'),
                //         ),
                //       );
                //     },
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Theme.of(context).colorScheme.primary,
                //       foregroundColor: Theme.of(context).colorScheme.onPrimary,
                //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //     ),
                //     child: Text(
                //       'Continue',
                //       style: Theme.of(context).textTheme.labelLarge?.copyWith(
                //             color: Theme.of(context).colorScheme.onPrimary,
                //             fontWeight: FontWeight.w600,
                //           ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    ),SizedBox(height: 16),
      _buildPlaceOrderButton(),
             
            // Add space for bottom sheet if items are selected
            const SizedBox(height: 100),
          ],
        ),
      ),
      // Show bottom sheet when items are selected, just like customer app
      // bottomSheet: _totalItems > 0 ? _buildBottomSheet() : null,
    );
  }
  
  // Bottom sheet similar to customer app
  Widget _buildBottomSheet() {
    return Consumer2<ItemProvider, AlliedServiceProvider>(
      builder: (context, itemProvider, alliedServiceProvider, child) {
        final allItems = _getFilteredItems(itemProvider.items, alliedServiceProvider.alliedServices.cast<dynamic>());
        final totalAmount = _calculateTotalAmount(allItems);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Items: $_totalItems',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Total Amount: ₹${totalAmount.toInt()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // SizedBox(
                //   width: 120,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       // Scroll to address selection
                //       // This is just to show the continue button functionality
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(
                //           content: Text('Please fill in the address and schedule details above'),
                //         ),
                //       );
                //     },
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Theme.of(context).colorScheme.primary,
                //       foregroundColor: Theme.of(context).colorScheme.onPrimary,
                //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //     ),
                //     child: Text(
                //       'Continue',
                //       style: Theme.of(context).textTheme.labelLarge?.copyWith(
                //             color: Theme.of(context).colorScheme.onPrimary,
                //             fontWeight: FontWeight.w600,
                //           ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(widget.customer.name),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 8),
                Text(widget.customer.phoneNumber),
              ],
            ),
            if (widget.customer.email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(widget.customer.email),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.miscellaneous_services, color: Colors.purple[600]),
                const SizedBox(width: 8),
                Text(
                  'Select Service Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Service type selector styled like customer app quick actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedServiceType = 'ironing'),
                  child: Container(
                      padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: _selectedServiceType == 'ironing'
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.lightBlue.shade50,
                                  Colors.white,
                                ],
                              )
                            : null,
                        color: _selectedServiceType != 'ironing' ? Colors.grey[50] : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedServiceType == 'ironing'
                              ? Colors.lightBlue.shade200
                              : Colors.grey.shade200,
                        ),
                        boxShadow: _selectedServiceType == 'ironing' ? [
                          BoxShadow(
                            color: Colors.lightBlue.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Column(
                      children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.iron, color: Colors.lightBlue, size: 28),
                          ),
                          const SizedBox(height: 12),
                        Text(
                            'Ironing',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                              color: _selectedServiceType == 'ironing' ? Colors.lightBlue[600] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select items for ironing',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedServiceType = 'allied'),
                  child: Container(
                      padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: _selectedServiceType == 'allied'
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.green.shade50,
                                  Colors.white,
                                ],
                              )
                            : null,
                        color: _selectedServiceType != 'allied' ? Colors.grey[50] : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedServiceType == 'allied'
                              ? Colors.green.shade200
                              : Colors.grey.shade200,
                        ),
                        boxShadow: _selectedServiceType == 'allied' ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Column(
                      children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.home_repair_service, color: Colors.green, size: 28),
                          ),
                          const SizedBox(height: 12),
                        Text(
                            'Allied Services',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                              color: _selectedServiceType == 'allied' ? Colors.green[600] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Washing and Ironing',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Add "All Items" option as a full-width button
            GestureDetector(
              onTap: () => setState(() => _selectedServiceType = 'all'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _selectedServiceType == 'all'
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.white,
                          ],
                        )
                      : null,
                  color: _selectedServiceType != 'all' ? Colors.grey[50] : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedServiceType == 'all'
                        ? Colors.blue.shade200
                        : Colors.grey.shade200,
                  ),
                  boxShadow: _selectedServiceType == 'all' ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.apps, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Show All Items',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: _selectedServiceType == 'all' ? Colors.blue[600] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select service type to filter items, or choose "All Items" to see everything',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section matching customer app style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Items for Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Consumer2<ItemProvider, AlliedServiceProvider>(
              builder: (context, itemProvider, alliedServiceProvider, child) {
                if (itemProvider.isLoading || alliedServiceProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final items = _getFilteredItems(itemProvider.items, alliedServiceProvider.alliedServices.cast<dynamic>());
                
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No items available for selected service type',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return _buildItemsList(items);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<ItemModel> _getFilteredItems(List<ItemModel> regularItems, List<dynamic> alliedServices) {
    // Convert allied services to ItemModel format
    List<ItemModel> convertedAlliedServices = alliedServices.map((service) {
      if (service is ItemModel) {
        return service;
        } else {
        // If it's AlliedServiceModel, convert it to ItemModel
        return ItemModel(
          id: service.id ?? '',
          name: service.name ?? '',
          category: service.category ?? 'Allied Services',
          price: service.price ?? 0.0,
          unit: service.unit ?? 'piece',
          isActive: service.isActive ?? true,
          sortOrder: service.sortOrder ?? 0,
          updatedAt: service.updatedAt ?? DateTime.now(),
          imageUrl: service.imageUrl,
          offerPrice: service.offerPrice,
        );
      }
    }).toList();
    
    List<ItemModel> allItems = [...regularItems, ...convertedAlliedServices];
    
    if (_selectedServiceType == 'all') {
      return allItems;
    } else if (_selectedServiceType == 'ironing') {
      return allItems.where((item) {
        String category = item.category.toLowerCase();
        return category.contains('iron') || category == 'ironing';
      }).toList();
    } else if (_selectedServiceType == 'allied') {
      return allItems.where((item) {
        String category = item.category.toLowerCase();
        return category.contains('allied') || category == 'allied services' || category == 'alien';
      }).toList();
    }
    return allItems;
  }

  Widget _buildItemsList(List<ItemModel> items) {
    // Exact same layout structure as customer app home screen
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildItemCard(items[index]);
      },
    );
  }



  Widget _buildItemCard(ItemModel item) {
    final quantity = _itemQuantities[item.id] ?? 0;
    
    // Exact same layout as customer app home screen
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Row(
        children: [
          // Item Image/Icon - exact same size and style as customer app
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        return Icon(_getItemIcon(item.name), color: context.onSurfaceVariant);
                      },
                    ),
                  )
                : Icon(_getItemIcon(item.name), color: context.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          
          // Item Details - exact same layout as customer app
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                // Price display with original and offer prices - exact same as customer app
                Row(
                  children: [
                    // Current/Offer Price
                    Text(
                      '₹${(item.offerPrice ?? item.price).toInt()} per piece',
                      style: TextStyle(
                        color: item.offerPrice != null
                            ? Theme.of(context).colorScheme.tertiary
                            : context.onSurfaceVariant,
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
          
          // Quantity Controls - exact same as customer app
          Row(
              children: [
                IconButton(
                  onPressed: quantity > 0 ? () => _decrementQuantity(item.id) : null,
                  icon: Icon(
                  Icons.remove,
                  color: quantity > 0
                      ? context.onSurfaceVariant
                      : context.outlineVariant,
                  ),
                ),
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _incrementQuantity(item.id),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getItemIcon(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('shirt')) return Icons.checkroom;
    if (name.contains('pant') || name.contains('trouser')) return Icons.dry_cleaning;
    if (name.contains('dress')) return Icons.woman;
    if (name.contains('towel')) return Icons.wash;
    if (name.contains('bedsheet') || name.contains('bed')) return Icons.bed;
    return Icons.local_laundry_service;
  }




  Widget _buildPlaceOrderButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isPlacingOrder ? null : _placeOrder,
        icon: _isPlacingOrder
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.shopping_cart_checkout),
        label: Text(_isPlacingOrder ? 'Placing Order...' : 'Place Order'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Customer app UI methods - Address and Time Selection
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
            color: context.surfaceVariant,
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
                    onPressed: () => _showAddressSelectionDialog(isPickup: true),
                    child: const Text('Change',
                        style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
              const SizedBox(height: 8),
              _isLoadingAddresses
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _selectedAddress != null
                          ? _selectedAddress!.fullAddress
                          : 'No address selected',
                      style: TextStyle(
                        color: _selectedAddress != null
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
            color: context.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Checkbox(
                value: sameAddressForDelivery,
                onChanged: (value) {
                  setState(() {
                    sameAddressForDelivery = value ?? true;
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
              color: context.surfaceVariant,
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showAddressSelectionDialog(isPickup: false),
                      child: const Text('Change',
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedAddress != null
                      ? _selectedAddress!.fullAddress
                      : 'No delivery address selected',
                  style: TextStyle(
                    color: _selectedAddress != null
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
              selectedDeliveryDate = _getDateFromDeliveryOption(selectedDeliveryDateOption);
              _updateAvailableDeliverySlots();

              if (availableDeliverySlots.isEmpty) {
                selectedDeliveryDateOption = DateOption.tomorrow;
                selectedDeliveryDate = _getDateFromDeliveryOption(selectedDeliveryDateOption);
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
              _updateAvailableDeliverySlots();
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
          children: [
            const Text(
              'Delivery Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            if (selectedDeliveryDate != null)
            Text(
                DateFormat('EEEE, MMM d').format(selectedDeliveryDate!),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
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

  Widget _buildDateSelector({
    required DateOption selectedOption,
    required Function(DateOption) onOptionSelected,
  }) {
    return Row(
              children: [
        _buildDateOptionButton(DateOption.today, selectedOption, onOptionSelected),
        const SizedBox(width: 12),
        _buildDateOptionButton(DateOption.tomorrow, selectedOption, onOptionSelected),
        const SizedBox(width: 12),
                Expanded(
          child: _buildDateOptionButton(DateOption.custom, selectedOption, onOptionSelected),
        ),
      ],
    );
  }

  Widget _buildDateOptionButton(
    DateOption option,
    DateOption selectedOption,
    Function(DateOption) onOptionSelected,
  ) {
    bool isSelected = option == selectedOption;
    return GestureDetector(
      onTap: () => onOptionSelected(option),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          option.displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDeliveryDateSelector() {
    return GestureDetector(
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
                  children: [
            const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
                    Text(
              selectedDeliveryDate != null
                  ? DateFormat('EEEE, MMM d').format(selectedDeliveryDate!)
                  : 'Select delivery date',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
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
              width: isSelected ? 200 : 100,
              margin: EdgeInsets.only(
                right: index != availableSlots.length - 1 ? 12 : 0,
              ),
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
                        Flexible(
                          child: Text(
                            slot.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            slot.timeRange,
                      style: const TextStyle(
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
                        style: const TextStyle(
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
            color: context.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
              controller: _specialInstructionsController,
              maxLines: 3,
              decoration: const InputDecoration(
              hintText: 'Add any special instructions for pickup or delivery...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
          ),
              ),
            ),
          ],
    );
  }

  Future<void> _showAddressSelectionDialog({required bool isPickup}) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select ${isPickup ? 'Pickup' : 'Delivery'} Address'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _customerAddresses.length + 1, // +1 for "Add new address" option
              itemBuilder: (context, index) {
                if (index == _customerAddresses.length) {
                  // "Add new address" option - same as customer app
                  return ListTile(
                    leading: const Icon(Icons.add_location_alt_outlined, color: Colors.blue),
                    title: const Text('Add a new address'),
                    subtitle: const Text('Create new address for this customer'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _navigateToAddAddress();
                    },
                  );
                }

                var address = _customerAddresses[index];
                return ListTile(
                  leading: Icon(
                    address.isPrimary ? Icons.home : Icons.location_on,
                    color: address.isPrimary ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    address.fullAddress,
                    style: const TextStyle(height: 1.4),
                  ),
                  subtitle: address.isPrimary ? const Text('Primary Address') : Text('${address.type.toUpperCase()} Address'),
                  onTap: () {
                    setState(() {
                      _selectedAddress = address;
                    });
                    Navigator.of(context).pop();
                  },
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
        );
      },
    );
  }

  Future<void> _navigateToAddAddress() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AddAddressDialog(
        customerId: widget.customer.uid,
        onAddressAdded: () {
          _loadCustomerAddresses(); // Refresh addresses
        },
      ),
    );

    if (result == true) {
      // Address was added successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Add Address Dialog for Admin to add addresses for customers
class _AddAddressDialog extends StatefulWidget {
  final String customerId;
  final VoidCallback onAddressAdded;

  const _AddAddressDialog({
    required this.customerId,
    required this.onAddressAdded,
  });

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _doorNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _apartmentNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  String _addressType = 'home';
  bool _isPrimary = false;
  bool _isSaving = false;

  final List<String> _addressTypes = ['home', 'work', 'other'];

  @override
  void dispose() {
    _doorNumberController.dispose();
    _floorNumberController.dispose();
    _apartmentNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // If setting as primary, remove primary from other addresses first
      if (_isPrimary) {
        final addressesSnapshot = await FirebaseFirestore.instance
            .collection('customer')
            .doc(widget.customerId)
            .collection('addresses')
            .where('isPrimary', isEqualTo: true)
            .get();

        for (var doc in addressesSnapshot.docs) {
          await doc.reference.update({'isPrimary': false});
        }
      }

      // Add new address with same structure as customer app
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.customerId)
          .collection('addresses')
          .add({
        'type': _addressType,
        'addressType': _addressType, // For backward compatibility
        'doorNumber': _doorNumberController.text.trim(),
        'floorNumber': _floorNumberController.text.trim(),
        'apartmentName': _apartmentNameController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'nearbyLandmark': _landmarkController.text.trim(), // For backward compatibility
        'country': 'India',
        'isPrimary': _isPrimary,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'addedBy': 'admin',
      });

      widget.onAddressAdded();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Address'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Address Type Selection
                DropdownButtonFormField<String>(
                  value: _addressType,
                  decoration: const InputDecoration(
                    labelText: 'Address Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _addressTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _addressType = value!);
                  },
                ),
                const SizedBox(height: 12),

                // Door Number and Floor Number
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _doorNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Door Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.door_front_door),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _floorNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Floor Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.layers),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Apartment/Building Name
                TextFormField(
                  controller: _apartmentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apartment/Building Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.apartment),
                  ),
                ),
                const SizedBox(height: 12),

                // Address Line 1 (Required)
                TextFormField(
                  controller: _addressLine1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 1 *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address Line 1 is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Address Line 2
                TextFormField(
                  controller: _addressLine2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 2',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Landmark
                TextFormField(
                  controller: _landmarkController,
                  decoration: const InputDecoration(
                    labelText: 'Nearby Landmark',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 12),

                // City, State, Pincode
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'State *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.map),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'State is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _pincodeController,
                        decoration: const InputDecoration(
                          labelText: 'Pincode *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin_drop),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Pincode is required';
                          }
                          if (value.trim().length != 6) {
                            return 'Invalid pincode';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Primary Address Checkbox
                CheckboxListTile(
                  title: const Text('Set as Primary Address'),
                  subtitle: const Text('This will be the default address for this customer'),
                  value: _isPrimary,
                  onChanged: (value) {
                    setState(() => _isPrimary = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : const Text('Save Address'),
        ),
      ],
    );
  }
}
