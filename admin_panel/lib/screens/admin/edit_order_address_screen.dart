import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_address_service.dart';

class EditOrderAddressScreen extends StatefulWidget {
  final String orderId;
  final String customerId;
  final String addressId;
  final Map<String, dynamic>? initialAddressData;

  const EditOrderAddressScreen({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.addressId,
    this.initialAddressData,
  });

  @override
  State<EditOrderAddressScreen> createState() => _EditOrderAddressScreenState();
}

class _EditOrderAddressScreenState extends State<EditOrderAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _isSaving = false;

  // Controllers for form fields (matching customer app order)
  final _doorNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  String selectedAddressType = 'home';
  bool isPrimary = false;

  final List<String> addressTypes = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  @override
  void dispose() {
    _doorNumberController.dispose();
    _floorNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _loadAddressData() async {
    setState(() => isLoading = true);

    try {
      Map<String, dynamic>? addressData;
      
      if (widget.initialAddressData != null) {
        addressData = widget.initialAddressData;
      } else {
        addressData = await AdminAddressService.getCustomerAddress(
          customerId: widget.customerId,
          addressId: widget.addressId,
        );
      }

      if (addressData != null && mounted) {
        // Handle nested structure: if data comes from DeliveryAddress.toMap(), 
        // the actual address fields are in the 'details' object
        Map<String, dynamic> details = addressData['details'] ?? addressData;
        
        setState(() {
          _doorNumberController.text = details['doorNumber']?.toString() ?? '';
          _floorNumberController.text = details['floorNumber']?.toString() ?? '';
          _addressLine1Controller.text = details['addressLine1']?.toString() ?? '';
          _addressLine2Controller.text = details['addressLine2']?.toString() ?? '';
          _landmarkController.text = details['landmark']?.toString() ?? '';
          _cityController.text = details['city']?.toString() ?? '';
          _stateController.text = details['state']?.toString() ?? '';
          _pincodeController.text = details['pincode']?.toString() ?? '';
          selectedAddressType = details['type']?.toString() ?? addressData?['type']?.toString() ?? 'home';
          isPrimary = details['isPrimary'] == true || addressData?['isPrimary'] == true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading address: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> updatedAddressData = {
        'doorNumber': _doorNumberController.text.trim(),
        'floorNumber': _floorNumberController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'type': selectedAddressType,
        'addressType': selectedAddressType,
        'isPrimary': isPrimary,
      };

      // Validate the address data
      if (!AdminAddressService.validateAddressData(updatedAddressData)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields correctly')),
        );
        return;
      }

      // Update both order and customer address
      bool success = await AdminAddressService.updateOrderAndCustomerAddress(
        orderId: widget.orderId,
        customerId: widget.customerId,
        addressId: widget.addressId,
        updatedAddressData: updatedAddressData,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address updated successfully in order pickup, delivery, and customer records'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Order Address'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Order Address Editing',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Editing this address will update the order pickup address, delivery address, and the customer\'s saved address',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Address Type Selection
                    const Text(
                      'Address Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: addressTypes.map((type) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type.toUpperCase()),
                              selected: selectedAddressType == type,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedAddressType = type;
                                  });
                                }
                              },
                              selectedColor: Colors.blue.shade100,
                              labelStyle: TextStyle(
                                color: selectedAddressType == type 
                                    ? Colors.blue.shade700
                                    : Colors.grey[600],
                                fontWeight: selectedAddressType == type 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Door Number and Floor Number
                    const Text(
                      'Building Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _doorNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Door Number',
                              hintText: 'e.g., 101, A-12',
                              prefixIcon: Icon(Icons.door_front_door),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _floorNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Floor Number',
                              hintText: 'e.g., Ground, 2nd',
                              prefixIcon: Icon(Icons.layers),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Address Details
                    const Text(
                      'Address Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressLine1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 1 *',
                        hintText: 'Building, Street name, Area',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressLine2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 2',
                        hintText: 'Colony, Sector (Optional)',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Landmark
                    TextFormField(
                      controller: _landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'Landmark',
                        hintText: 'e.g., Near Metro Station, Opposite Mall',
                        prefixIcon: Icon(Icons.place),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // City, State, Pin Code
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        prefixIcon: Icon(Icons.map),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'State is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pin Code *',
                        prefixIcon: Icon(Icons.pin_drop),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pin code is required';
                        }
                        if (value.length != 6) {
                          return 'Pin code must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Primary address option
                    Card(
                      elevation: 1,
                      child: CheckboxListTile(
                        title: const Text(
                          'Set as Primary Address',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text('This will be used as default for the customer'),
                        value: isPrimary,
                        onChanged: (value) {
                          setState(() {
                            isPrimary = value ?? false;
                          });
                        },
                        activeColor: Colors.blue.shade700,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16 * 3), 
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Update Address',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
