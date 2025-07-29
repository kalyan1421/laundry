
// lib/screens/profile/add_address_screen.dart
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/data/models/address_model.dart';
import 'package:customer_app/services/location_service.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/custom_button.dart';
import 'package:customer_app/core/utils/address_utils.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? address; // For editing existing address

  const AddAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers in the order specified by user
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
  bool isLoading = false;
  bool isLocationLoading = false;
  Position? currentLocation;
  String? currentAddress;

  final List<String> addressTypes = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _populateFields();
    }
    // Removed automatic location fetching - users can manually get location if needed
  }

  void _populateFields() {
    final address = widget.address!;
    _addressLine1Controller.text = address.addressLine1;
    _addressLine2Controller.text = address.addressLine2 ?? '';
    _cityController.text = address.city;
    _stateController.text = address.state;
    _pincodeController.text = address.pincode;
    _landmarkController.text = address.landmark ?? '';
    selectedAddressType = address.type;
    isPrimary = address.isPrimary;
    
    if (address.latitude != null && address.longitude != null) {
      currentLocation = Position(
        latitude: address.latitude!,
        longitude: address.longitude!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLocationLoading = true;
    });

    try {
      Position position = await LocationService.getCurrentLocation();

      setState(() {
        currentLocation = position;
        isLocationLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location fetched successfully! You can now manually fill your address.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLocationLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get current location first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel == null) {
        throw Exception('User not authenticated');
      }

      final userId = authProvider.userModel!.uid;
      final phoneNumber = authProvider.userModel!.phoneNumber;
      
      print('🏠 ADD ADDRESS: Starting address save process');
      print('🏠 ADD ADDRESS: User ID: $userId');
      print('🏠 ADD ADDRESS: Phone Number: $phoneNumber');
      print('🏠 ADD ADDRESS: Is Update: ${widget.address != null}');

      if (widget.address == null) {
        // Adding new address using standardized format
        print('🏠 ADD ADDRESS: Creating new address with standardized format');
        
        // If setting as primary, remove primary from other addresses first
        if (isPrimary) {
          await _removePrimaryFromOtherAddresses(userId);
        }
        
        final documentId = await AddressUtils.saveAddressWithStandardFormat(
          userId: userId,
          phoneNumber: phoneNumber,
          doorNumber: _doorNumberController.text.trim(),
          floorNumber: _floorNumberController.text.trim(),
          addressLine1: _addressLine1Controller.text.trim(),
          landmark: _landmarkController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          addressLine2: _addressLine2Controller.text.trim(),
          addressType: selectedAddressType,
          latitude: currentLocation!.latitude,
          longitude: currentLocation!.longitude,
          isPrimary: isPrimary,
        );

        if (documentId != null) {
          print('🏠 ADD ADDRESS: New address saved with ID: $documentId');
        } else {
          throw Exception('Failed to save address');
        }
      } else {
        // Updating existing address using standardized format
        print('🏠 ADD ADDRESS: Updating existing address with ID: ${widget.address!.id}');
        
        // If setting as primary, remove primary from other addresses first
        if (isPrimary) {
          await _removePrimaryFromOtherAddresses(userId, excludeId: widget.address!.id);
        }
        
        final success = await AddressUtils.updateAddressWithStandardFormat(
          userId: userId,
          documentId: widget.address!.id,
          doorNumber: _doorNumberController.text.trim(),
          floorNumber: _floorNumberController.text.trim(),
          addressLine1: _addressLine1Controller.text.trim(),
          landmark: _landmarkController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          addressLine2: _addressLine2Controller.text.trim(),
          addressType: selectedAddressType,
          latitude: currentLocation!.latitude,
          longitude: currentLocation!.longitude,
          isPrimary: isPrimary,
        );

        if (success) {
          print('🏠 ADD ADDRESS: Address updated successfully');
        } else {
          throw Exception('Failed to update address');
        }
      }

      Navigator.pop(context, true); // Return true to indicate success
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.address == null ? 'Address added successfully!' : 'Address updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('🏠 ADD ADDRESS: Error saving address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to remove primary status from other addresses
  Future<void> _removePrimaryFromOtherAddresses(String userId, {String? excludeId}) async {
    try {
      print('🏠 ADD ADDRESS: Removing primary status from other addresses');
      final existingAddresses = await FirebaseFirestore.instance
          .collection('customer')
          .doc(userId)
          .collection('addresses')
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in existingAddresses.docs) {
        if (excludeId == null || doc.id != excludeId) {
          batch.update(doc.reference, {'isPrimary': false});
        }
      }
      
      await batch.commit();
      print('🏠 ADD ADDRESS: Primary status removed from other addresses');
    } catch (e) {
      print('🏠 ADD ADDRESS: Error removing primary status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(AppConstants.primaryColorValue),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Location Section
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
                                  Icons.my_location,
                                  color: currentLocation != null ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Current Location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: currentLocation != null ? Colors.green : Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                if (isLocationLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  TextButton(
                                    onPressed: _getCurrentLocation,
                                    child: const Text('Refresh'),
                                  ),
                              ],
                            ),
                            if (currentLocation != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Location detected successfully',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ] else if (!isLocationLoading) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Tap refresh to get your current location',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
                        color: Color(AppConstants.textPrimaryValue),
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
                              selectedColor: const Color(AppConstants.primaryColorValue).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: selectedAddressType == type 
                                    ? const Color(AppConstants.primaryColorValue)
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
                    
                    // Door Number and Floor Number (User's requested order)
                    const Text(
                      'Building Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(AppConstants.textPrimaryValue),
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
                    
                    // Address Details (User's requested order)
                    const Text(
                      'Address Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(AppConstants.textPrimaryValue),
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
                    
                    // Landmark (User's requested order)
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
                    
                    // City, State, Pin Code (User's requested order)
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(AppConstants.textPrimaryValue),
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
                    
                    // Primary address option (User's requested feature)
                    Card(
                      elevation: 1,
                      child: CheckboxListTile(
                        title: const Text(
                          'Set as Primary Address',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text('This will be used as default for orders'),
                        value: isPrimary,
                        onChanged: (value) {
                          setState(() {
                            isPrimary = value ?? false;
                          });
                        },
                        activeColor: const Color(AppConstants.primaryColorValue),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Save button
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
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
              child: CustomButton(
                text: widget.address == null ? 'Save Address' : 'Update Address',
                onPressed: isLoading ? null : _saveAddress,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
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
}