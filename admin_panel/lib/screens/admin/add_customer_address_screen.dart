import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/customer_creation_service.dart';
import '../../models/address_model.dart';

class AddCustomerAddressScreen extends StatefulWidget {
  final Map<String, String> customerData;

  const AddCustomerAddressScreen({
    super.key,
    required this.customerData,
  });

  @override
  State<AddCustomerAddressScreen> createState() => _AddCustomerAddressScreenState();
}

class _AddCustomerAddressScreenState extends State<AddCustomerAddressScreen> {
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
  bool _isPrimary = true;
  bool _isLoading = false;

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

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customerCreationService = CustomerCreationService();
      
      // Prepare address data
      final addressData = {
        'type': _addressType,
        'doorNumber': _doorNumberController.text.trim(),
        'floorNumber': _floorNumberController.text.trim(),
        'apartmentName': _apartmentNameController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'country': 'India',
        'isPrimary': _isPrimary,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create customer with address
      final result = await customerCreationService.createCustomerWithAddress(
        customerData: widget.customerData,
        addressData: addressData,
      );

      if (result['success'] == true) {
        // Show success dialog
        if (mounted) {
          await _showSuccessDialog(result['customerId'], result['qrCodeUrl']);
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to create customer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSuccessDialog(String customerId, String? qrCodeUrl) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Customer Created Successfully'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer has been created with ID: $customerId'),
            const SizedBox(height: 12),
            if (qrCodeUrl != null) ...[
              const Text('QR Code has been generated and saved.'),
              const SizedBox(height: 8),
            ],
            const Text(
              'The customer can now login using their mobile number to access their account.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to customer list
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Customer Address'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Info Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                          Icon(Icons.person, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(widget.customerData['name'] ?? ''),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(widget.customerData['phoneNumber'] ?? ''),
                        ],
                      ),
                      if (widget.customerData['email']?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(widget.customerData['email'] ?? ''),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Address Type
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address Type *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _addressType,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Door Number & Floor Number
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Building Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _doorNumberController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.door_front_door),
                                labelText: 'Door Number',
                                hintText: 'e.g., 101, A-2',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Door number is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _floorNumberController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.stairs),
                                labelText: 'Floor Number',
                                hintText: 'e.g., Ground, 2nd',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apartmentNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.apartment),
                          labelText: 'Building/Apartment Name',
                          hintText: 'e.g., Green Valley Apartments',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Address Lines
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Street Address *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressLine1Controller,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.home_rounded),
                          labelText: 'Street Address',
                          hintText: 'Enter street name and area',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Street address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressLine2Controller,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.add_location),
                          labelText: 'Additional Address Info (Optional)',
                          hintText: 'Near landmark, cross street, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // City, State, Pincode
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Details *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _cityController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.location_city),
                                labelText: 'City',
                                hintText: 'e.g., Hyderabad',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'City is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.pin_drop),
                                labelText: 'Pincode',
                                hintText: '500001',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                counterText: '',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Pincode is required';
                                }
                                if (value.length != 6) {
                                  return 'Invalid pincode';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _stateController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.map),
                          labelText: 'State',
                          hintText: 'e.g., Telangana',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'State is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Landmark
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Landmark (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _landmarkController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.place),
                          labelText: 'Nearby Landmark',
                          hintText: 'e.g., Near Metro Station, Shopping Mall',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Primary Address Checkbox
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CheckboxListTile(
                    title: const Text('Set as Primary Address'),
                    subtitle: const Text('This will be the default address for deliveries'),
                    value: _isPrimary,
                    onChanged: (value) {
                      setState(() => _isPrimary = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Create Customer Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createCustomer,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.person_add_rounded),
                  label: Text(_isLoading ? 'Creating Customer...' : 'Create Customer'),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

