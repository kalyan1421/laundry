import 'package:customer_app/data/models/item_model.dart';
import 'package:customer_app/presentation/screens/location/add_address_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define PaymentMethod enum
enum PaymentMethod { cod }

// Define TimeSlot enum
enum TimeSlot {
  morning, // e.g., 9 AM - 12 PM
  afternoon, // e.g., 1 PM - 5 PM
  evening; // e.g., 6 PM - 9 PM

  String get displayName {
    switch (this) {
      case TimeSlot.morning:
        return 'Morning (9 AM - 12 PM)';
      case TimeSlot.afternoon:
        return 'Afternoon (1 PM - 5 PM)';
      case TimeSlot.evening:
        return 'Evening (6 PM - 9 PM)';
    }
  }

  // Helper to get approximate start hour (24-hour format)
  int get startHour {
    switch (this) {
      case TimeSlot.morning: return 9;
      case TimeSlot.afternoon: return 13;
      case TimeSlot.evening: return 18;
    }
  }

  // Helper to get approximate end hour (24-hour format)
  int get endHour {
    switch (this) {
      case TimeSlot.morning: return 12;
      case TimeSlot.afternoon: return 17;
      case TimeSlot.evening: return 21;
    }
  }
}

class SchedulePickupDeliveryScreen extends StatefulWidget {
  final Map<ItemModel, int> selectedItems;
  final double totalAmount;

  const SchedulePickupDeliveryScreen({
    Key? key,
    required this.selectedItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<SchedulePickupDeliveryScreen> createState() => _SchedulePickupDeliveryScreenState();
}

class _SchedulePickupDeliveryScreenState extends State<SchedulePickupDeliveryScreen> {
  int selectedTabIndex = 1; // Schedule tab selected by default

  // Updated state variables for date and time
  DateTime? selectedPickupDate;
  TimeSlot? selectedPickupTimeSlot;
  DateTime? selectedDeliveryDate;
  TimeSlot? selectedDeliveryTimeSlot;

  List<TimeSlot> availablePickupSlots = [];
  List<TimeSlot> availableDeliverySlots = TimeSlot.values.toList(); // Initially all slots

  bool sameAddressForDelivery = true;
  final TextEditingController specialInstructionsController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cod;

  // Address and order saving state
  String? _pickupAddressString;
  String? _deliveryAddressString; // For when sameAddressForDelivery is false
  bool _isLoadingAddress = true;
  bool _isSavingOrder = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _fetchedUserAddresses = []; // To store all fetched addresses

  @override
  void initState() {
    super.initState();
    _initializeDateTimeSlots();
    _fetchUserAddress();
  }

  Future<void> _fetchUserAddress() async {
    setState(() {
      _isLoadingAddress = true;
      _pickupAddressString = null;
      _deliveryAddressString = null;
      _fetchedUserAddresses = []; // Clear previous list
    });
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot addressQuery = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('addresses')
            .get();

        _fetchedUserAddresses = addressQuery.docs;

        if (_fetchedUserAddresses.isNotEmpty) {
          DocumentSnapshot? primaryAddressDoc;
          try {
            primaryAddressDoc = _fetchedUserAddresses.firstWhere((doc) => (doc.data() as Map<String, dynamic>)['isPrimary'] == true);
          } catch (e) {
            primaryAddressDoc = _fetchedUserAddresses.first;
          }

          if (primaryAddressDoc != null && primaryAddressDoc.exists) {
            _pickupAddressString = _formatAddress(primaryAddressDoc.data() as Map<String, dynamic>);
          } else {
            _pickupAddressString = 'No suitable pickup address found.';
          }
        } else {
          _pickupAddressString = 'No addresses found for this user.';
        }
      } else {
        _pickupAddressString = 'User not logged in.';
      }
    } catch (e) {
      _pickupAddressString = 'Error fetching address.';
      print('Error fetching address: $e');
    }
    
    if (sameAddressForDelivery) {
      _deliveryAddressString = _pickupAddressString;
    } else {
      // If not same address, and only one address exists, prompt to add new one for delivery
      if (_fetchedUserAddresses.length <= 1) {
        _deliveryAddressString = null; // Or a specific prompt message if needed
      } else {
        // If multiple addresses exist, try to find a different one or prompt selection
        // For now, just nullify, user needs to "Change"
         _deliveryAddressString = null; 
      }
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
    String landmark = data['landmark'] ?? '';
    String type = data['type'] ?? 'Address';

    StringBuffer addressBuffer = StringBuffer();
    if (line1.isNotEmpty) addressBuffer.write(line1);
    if (line2.isNotEmpty) addressBuffer.write(', $line2');
    if (city.isNotEmpty) addressBuffer.write(', $city');
    if (state.isNotEmpty) addressBuffer.write(', $state');
    if (pincode.isNotEmpty) addressBuffer.write(' - $pincode');
    if (landmark.isNotEmpty) addressBuffer.write(' (Landmark: $landmark)');
    
    return addressBuffer.isNotEmpty ? '[$type] ${addressBuffer.toString()}' : 'Address details incomplete.';
  }

  void _initializeDateTimeSlots() {
    final now = DateTime.now();
    DateTime initialPickupDate = DateTime(now.year, now.month, now.day);

    // If it's too late for any slots today, default pickup to tomorrow
    // This is a simplified check. More robust check in _updateAvailablePickupSlots
    if (now.hour >= TimeSlot.evening.endHour) { // Assuming evening is the last slot
      initialPickupDate = initialPickupDate.add(const Duration(days: 1));
    }
    
    selectedPickupDate = initialPickupDate;
    selectedDeliveryDate = selectedPickupDate!.add(const Duration(days: 1));
    
    _updateAvailablePickupSlots();
    _updateAvailableDeliverySlots(); // Delivery slots depend on pickup
  }

  void _updateAvailablePickupSlots() {
    if (selectedPickupDate == null) {
      availablePickupSlots = [];
      setState(() {});
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<TimeSlot> allSlots = TimeSlot.values.toList();
    List<TimeSlot> slots = [];

    const int leadTimeForSlotStart = 1; // hours before slot starts, you can still order
    const int minTimeLeftInSlot = 2;    // hours left in current slot to be able to order

    if (selectedPickupDate!.isAtSameMomentAs(today)) { // Scheduling for today
      for (var slot in allSlots) {
        bool canOrderBeforeSlotStarts = now.hour < (slot.startHour - leadTimeForSlotStart);
        bool canOrderDuringSlot = now.hour >= slot.startHour && now.hour < (slot.endHour - minTimeLeftInSlot);

        if (canOrderBeforeSlotStarts || canOrderDuringSlot) {
          slots.add(slot);
        }
      }
    } else if (selectedPickupDate!.isAfter(today)) { // Scheduling for a future date
      slots.addAll(allSlots);
      bool isNextDay = selectedPickupDate!.difference(today).inDays == 1;
      
      // Rule 1: If order placed after 8 PM (20:00), next day's "Morning" slot is disabled.
      if (isNextDay && now.hour >= 20) {
        slots.remove(TimeSlot.morning);
      }
      // Rule 2: If order placed in "afternoon" (12 PM to 7:59 PM), next day's "Morning" slot is also disabled.
      // This rule is additive to the 8 PM rule.
      else if (isNextDay && (now.hour >= 12 && now.hour < 20)) { 
        slots.remove(TimeSlot.morning);
      }
    }

    availablePickupSlots = slots;
    if (!availablePickupSlots.contains(selectedPickupTimeSlot) && availablePickupSlots.isNotEmpty) {
      selectedPickupTimeSlot = availablePickupSlots.first;
    } else if (availablePickupSlots.isEmpty) {
      selectedPickupTimeSlot = null;
    }
    // If pickup time becomes null due to slot unavailability, ensure dependent logic handles it.
    // For example, if this causes delivery date/time to become invalid, they might need resetting or revalidating.
    // _updateAvailableDeliverySlots(); // Call if pickup time changes might affect delivery options significantly
    setState(() {});
  }

  void _updateAvailableDeliverySlots() {
    // For now, all delivery slots are available if the date is valid.
    // This can be expanded if there are specific rules for delivery times.
    availableDeliverySlots = TimeSlot.values.toList();
    if (selectedDeliveryDate != null && selectedPickupDate != null && selectedDeliveryDate!.isBefore(selectedPickupDate!.add(const Duration(days: 1)))) {
        // This case should be prevented by the date picker for delivery date
        selectedDeliveryDate = selectedPickupDate!.add(const Duration(days: 1));
    }

    if (availableDeliverySlots.isNotEmpty && !availableDeliverySlots.contains(selectedDeliveryTimeSlot)) {
        selectedDeliveryTimeSlot = availableDeliverySlots.first;
    } else if (availableDeliverySlots.isEmpty) {
        selectedDeliveryTimeSlot = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    specialInstructionsController.dispose();
    super.dispose();
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
                  _buildItemsSummary(),
                  const SizedBox(height: 24),
                  _buildLocationsSection(),
                  const SizedBox(height: 24),
                  _buildPickupDateSection(),
                  const SizedBox(height: 24),
                  _buildPickupTimeSection(),
                  const SizedBox(height: 24),
                  _buildDeliveryDateSection(),
                  const SizedBox(height: 24),
                  _buildDeliveryTimeSection(),
                  const SizedBox(height: 24),
                  _buildSpecialInstructionsSection(),
                  // Add Payment Section conditionally based on tab
                  if (selectedTabIndex == 2) ...[
                    const SizedBox(height: 24),
                    _buildPaymentSection(),
                  ],
                  const SizedBox(height: 100), // Space for button
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
                setState(() {
                  selectedTabIndex = index;
                });
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

  Widget _buildItemsSummary() {
    if (widget.selectedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [ BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2)) ],
        ),
        child: const Text(
          'No items selected. Please go back to add items.',
          style: TextStyle(fontSize: 16, color: Colors.orange),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2)) ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.iron, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_totalItemCount Items for ${_totalItemCount == 1 ? "service" : "services"}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Pop with the current selected items, HomeScreen should handle this to allow editing.
                  // This assumes HomeScreen can receive and re-initialize its quantities based on this.
                  Navigator.of(context).pop(widget.selectedItems);
                },
                child: const Text('Edit Items', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
              )
            ],
          ),
          const Divider(height: 20, thickness: 1),
          // Detailed item list - only shown if the "Items" tab is NOT active (i.e., on Schedule or Payment tab)
          // Or always show if you prefer, but it makes more sense on Schedule/Payment review.
          if (selectedTabIndex != 0) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.selectedItems.length,
              itemBuilder: (context, index) {
                final item = widget.selectedItems.keys.elementAt(index);
                final quantity = widget.selectedItems[item]!;
                final itemTotal = item.pricePerPiece * quantity;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${item.name} (x$quantity)', style: const TextStyle(fontSize: 15)),
                      ),
                      Text(
                        '₹${itemTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 20, thickness: 1),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F3057))),
              Text(
                '₹${widget.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [ BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2)) ],
          ),
          child: Column(
            children: [
              // Pickup Address Row
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text('Pickup Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      // TODO: Navigate to an address selection screen that allows picking any address for pickup
                      // For now, re-fetching might refresh if primary changed elsewhere, but ideally a selection UI
                      final result = await Navigator.pushNamed(context, '/manage_addresses_screen', arguments: { 'isSelecting': true });
                      if (result is Map<String, dynamic>) { // Assuming address selection returns the chosen address data
                        setState(() {
                          _pickupAddressString = _formatAddress(result);
                          if (sameAddressForDelivery) {
                            _deliveryAddressString = _pickupAddressString;
                          }
                        });
                      } else {
                        _fetchUserAddress(); // Fallback to re-fetch if no explicit selection
                      }
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _isLoadingAddress 
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2))) 
                : Text(_pickupAddressString ?? 'Select pickup address.', style: TextStyle(color: _pickupAddressString == null || _pickupAddressString!.startsWith('Error') ? Colors.red : Colors.grey[700], fontSize: 14)),
              const Divider(height: 24, thickness: 1),
              // Deliver to same address Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Deliver to same address', style: TextStyle(fontSize: 15)),
                  Switch(
                    value: sameAddressForDelivery,
                    onChanged: (value) {
                      setState(() {
                        sameAddressForDelivery = value;
                        if (sameAddressForDelivery) {
                          _deliveryAddressString = _pickupAddressString;
                        } else {
                           // When toggled to false, decide initial state for delivery address
                           if (_fetchedUserAddresses.length > 1) {
                             // Attempt to find a different address than pickup, or nullify to prompt selection
                             DocumentSnapshot? differentAddress = _fetchedUserAddresses.firstWhere(
                               (doc) => _formatAddress(doc.data() as Map<String, dynamic>) != _pickupAddressString,
                               orElse: () => _fetchedUserAddresses.first // Fallback, though ideally user should pick
                             );
                             if (_formatAddress(differentAddress.data() as Map<String, dynamic>) != _pickupAddressString) {
                               _deliveryAddressString = _formatAddress(differentAddress.data() as Map<String, dynamic>);
                             } else {
                               _deliveryAddressString = null; // Prompt user to select a different one via "Change"
                             }
                           } else {
                             _deliveryAddressString = null; // Only one or no address, prompt to add
                           }
                        }
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              // Delivery Address Section (Conditional)
              if (!sameAddressForDelivery)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        if (_fetchedUserAddresses.length <= 1)
                          TextButton(
                            onPressed: () async {
                              // Navigate to AddAddressScreen and refresh addresses on return
                              final newAddressAdded = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddAddressScreen()),
                              );
                              if (newAddressAdded == true) { // Assuming AddAddressScreen returns true if address was added
                                await _fetchUserAddress(); // Re-fetch addresses
                                // Potentially try to set the new address as delivery address if logic allows
                              }
                            },
                            child: const Text('Add New Address'),
                          )
                        else
                          TextButton(
                            onPressed: () async {
                              // TODO: Navigate to address selection screen for delivery, passing _fetchedUserAddresses (excluding pickup one)
                              // For now, allows re-selecting from all, user must pick a different one manually if desired
                               final result = await Navigator.pushNamed(context, '/manage_addresses_screen', arguments: { 'isSelecting': true, 'excludeAddress': _pickupAddressString });
                                if (result is Map<String, dynamic>) {
                                  setState(() {
                                    _deliveryAddressString = _formatAddress(result);
                                  });
                                }
                            },
                            child: const Text('Change'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _deliveryAddressString ?? (_fetchedUserAddresses.length <= 1 ? 'Please add a new delivery address.' : 'Please select a delivery address.'), 
                      style: TextStyle(color: _deliveryAddressString == null ? Colors.orange : Colors.grey[700], fontSize: 14)
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildDateChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  Widget _buildPickupDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup Date',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F3057)),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedPickupDate ?? DateTime.now(),
              firstDate: DateTime.now(), // Can pick from today onwards
              lastDate: DateTime.now().add(const Duration(days: 30)), // Allow scheduling up to 30 days in advance
            );
            if (picked != null && picked != selectedPickupDate) {
              setState(() {
                selectedPickupDate = picked;
                // If pickup date changes, delivery date might need to be adjusted if it's no longer valid
                if (selectedDeliveryDate != null && selectedDeliveryDate!.isBefore(selectedPickupDate!.add(const Duration(days: 1)))) {
                  selectedDeliveryDate = selectedPickupDate!.add(const Duration(days: 1));
                }
                _updateAvailablePickupSlots();
                _updateAvailableDeliverySlots(); // Delivery slots might change if delivery date was auto-adjusted
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedPickupDate != null ? DateFormat('EEE, dd MMM').format(selectedPickupDate!) : 'Select Date',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF0F3057)),
                ),
                const Icon(Icons.calendar_today_outlined, color: Colors.blue, size: 20),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTimeSlotChip(TimeSlot slot, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(slot.displayName),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onTap();
        }
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? Colors.blue : Colors.grey[300]!)
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 14
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildPickupTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup Time',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F3057)),
        ),
        const SizedBox(height: 12),
        if (availablePickupSlots.isEmpty && selectedPickupDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No pickup slots available for the selected date. Please choose another date.',
              style: TextStyle(color: Colors.orange[700], fontSize: 15),
            ),
          )
        else if (selectedPickupDate == null)
           Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Please select a pickup date first.',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: availablePickupSlots.map((slot) {
              return _buildTimeSlotChip(
                slot,
                selectedPickupTimeSlot == slot,
                () {
                  setState(() {
                    selectedPickupTimeSlot = slot;
                    // Potentially update delivery slots if pickup time affects them
                    // _updateAvailableDeliverySlots(); 
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDeliveryDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Date',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F3057)),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            if (selectedPickupDate == null) {
              // Optionally show a message that pickup date must be selected first
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a pickup date first.')),
              );
              return;
            }
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDeliveryDate ?? selectedPickupDate!.add(const Duration(days: 1)),
              firstDate: selectedPickupDate!.add(const Duration(days: 1)), // Delivery must be after pickup
              lastDate: selectedPickupDate!.add(const Duration(days: 30)), // Allow scheduling up to 30 days after pickup
            );
            if (picked != null && picked != selectedDeliveryDate) {
              setState(() {
                selectedDeliveryDate = picked;
                _updateAvailableDeliverySlots();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDeliveryDate != null ? DateFormat('EEE, dd MMM').format(selectedDeliveryDate!) : 'Select Date',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF0F3057)),
                ),
                const Icon(Icons.calendar_today_outlined, color: Colors.blue, size: 20),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDeliveryTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Time',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F3057)),
        ),
        const SizedBox(height: 12),
        if (availableDeliverySlots.isEmpty && selectedDeliveryDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No delivery slots available for the selected date. Please choose another date or pickup slot.',
              style: TextStyle(color: Colors.orange[700], fontSize: 15),
            ),
          )
        else if (selectedDeliveryDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Please select a delivery date first.',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: availableDeliverySlots.map((slot) {
              return _buildTimeSlotChip(
                slot,
                selectedDeliveryTimeSlot == slot,
                () {
                  setState(() {
                    selectedDeliveryTimeSlot = slot;
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSpecialInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Special Instructions (Optional)'),
        const SizedBox(height: 12),
        TextField(
          controller: specialInstructionsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., Please handle delicates with care, specific folding instructions.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  // New method to build the payment selection UI
  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
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
            children: <Widget>[
              RadioListTile<PaymentMethod>(
                title: const Text('Cash on Delivery (COD)',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                value: PaymentMethod.cod,
                groupValue: _selectedPaymentMethod,
                onChanged: (PaymentMethod? value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: Colors.blue,
                contentPadding: EdgeInsets.zero,
              ),
              // const Divider(height: 1, indent: 16, endIndent: 16), // Keep or remove based on single option look
              // RadioListTile<PaymentMethod>(
              //   title: const Text('UPI / Online Payment',
              //       style: TextStyle(fontWeight: FontWeight.w500)),
              //   value: PaymentMethod.upi,
              //   groupValue: _selectedPaymentMethod,
              //   onChanged: (PaymentMethod? value) {
              //     setState(() {
              //       _selectedPaymentMethod = value!;
              //     });
              //   },
              //   activeColor: Colors.blue,
              //   contentPadding: EdgeInsets.zero,
              // ), // Removed UPI RadioListTile
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProceedButton() {
    String buttonText = 'Proceed to Schedule';
    VoidCallback? onPressedAction = () {
      // Basic validation before proceeding between tabs
      if (selectedTabIndex == 0) { // Items tab
        // No specific validation needed to move from items, assuming items are selected on home
      } else if (selectedTabIndex == 1) { // Schedule tab
        if (selectedPickupDate == null || selectedPickupTimeSlot == null || 
            selectedDeliveryDate == null || selectedDeliveryTimeSlot == null ||
            _pickupAddressString == null || _pickupAddressString!.startsWith('No') || _pickupAddressString!.startsWith('Error') || _pickupAddressString!.startsWith('User') ||
            (!sameAddressForDelivery && (_deliveryAddressString == null || _deliveryAddressString!.startsWith('Please')))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select pickup/delivery dates, times, and valid addresses.')),
          );
          return; // Stop advancement
        }
      }
      // else if (selectedTabIndex == 2) { // Payment tab - validation handled by button type }

      setState(() {
        if (selectedTabIndex < 2) {
          selectedTabIndex++;
        }
      });
    };

    if (_isSavingOrder) {
      buttonText = 'Placing Order...';
      onPressedAction = null; // Disable button while saving
    } else if (selectedTabIndex == 1) { // Schedule tab
      buttonText = 'Proceed to Payment';
    } else if (selectedTabIndex == 2) { // Payment tab
      // Since UPI is removed, this will always be for COD
      buttonText = 'Confirm Order (COD)';
      onPressedAction = _confirmOrderAndNavigate; 
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 5,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressedAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: _isSavingOrder 
               ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
               : Text(buttonText, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _confirmOrderAndNavigate() async {
    // Validate essential fields before attempting to save
    if (selectedPickupDate == null || selectedPickupTimeSlot == null || 
        selectedDeliveryDate == null || selectedDeliveryTimeSlot == null ||
        _pickupAddressString == null || _pickupAddressString!.startsWith('No') || _pickupAddressString!.startsWith('Error') || _pickupAddressString!.startsWith('User') ||
        (!sameAddressForDelivery && (_deliveryAddressString == null || _deliveryAddressString!.startsWith('Please')))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing critical information. Please complete all schedule and address details.')),
      );
      return;
    }

    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Cannot place order.')),
      );
      return;
    }

    setState(() {
      _isSavingOrder = true;
    });

    // Prepare items data
    List<Map<String, dynamic>> itemsForOrder = [];
    widget.selectedItems.forEach((itemModel, quantity) {
      itemsForOrder.add({
        'itemId': itemModel.id,
        'name': itemModel.name,
        'pricePerPiece': itemModel.pricePerPiece,
        'quantity': quantity,
        'category': itemModel.category,
        'iconUrl': itemModel.iconUrl,
      });
    });

    Map<String, dynamic> orderData = {
      'userId': currentUser.uid,
      'orderTimestamp': FieldValue.serverTimestamp(), // Current server time
      'items': itemsForOrder,
      'totalAmount': widget.totalAmount,
      'totalItemCount': _totalItemCount,
      'pickupDate': Timestamp.fromDate(selectedPickupDate!),
      'pickupTimeSlot': selectedPickupTimeSlot!.name, // Store enum name as string
      'deliveryDate': Timestamp.fromDate(selectedDeliveryDate!),
      'deliveryTimeSlot': selectedDeliveryTimeSlot!.name, // Store enum name as string
      'pickupAddress': _pickupAddressString,
      'deliveryAddress': sameAddressForDelivery ? _pickupAddressString : _deliveryAddressString,
      'sameAddressForDelivery': sameAddressForDelivery,
      'specialInstructions': specialInstructionsController.text.trim(),
      'paymentMethod': _selectedPaymentMethod.name, // Store enum name as string
      'orderStatus': 'Pending', // Initial status
      // Add other relevant fields like user name, phone if available/needed
      // 'userName': currentUser.displayName, (Might need to fetch from user profile)
      // 'userPhone': currentUser.phoneNumber, (Might need to fetch from user profile)
    };

    try {
      await _firestore.collection('orders').add(orderData);
      
      setState(() {
        _isSavingOrder = false;
      });

      // Show success dialog
      if (mounted) { // Check if the widget is still in the tree
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap button to close
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Order Placed!'),
            content: Text('Your order has been successfully placed with ${_selectedPaymentMethod == PaymentMethod.cod ? "Cash on Delivery" : "Online Payment"}.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).popUntil((route) => route.isFirst); // Go back to home screen
                },
              ),
            ],
          ),
        );
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
      print('Error saving order: $e');
    }
  }
}