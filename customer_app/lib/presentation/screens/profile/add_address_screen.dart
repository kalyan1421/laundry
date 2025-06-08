
// lib/screens/profile/add_address_screen.dart
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/data/models/address_model.dart';
import 'package:customer_app/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/common/custom_button.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? address; // For editing existing address

  const AddAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  String selectedAddressType = 'home';
  bool isPrimary = false;
  bool isLoading = false;
  Position? currentLocation;

  final List<String> addressTypes = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final address = widget.address!;
    _addressLine1Controller.text = address.addressLine1;
    _addressLine2Controller.text = address.addressLine2!;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _pincodeController.text = address.pincode;
    _landmarkController.text = address.landmark!;
    selectedAddressType = address.type;
    isPrimary = address.isPrimary;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      Position position = await LocationService.getCurrentLocation();
      String address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        currentLocation = position;
        // Parse address and populate fields
        _parseAndFillAddress(address);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location fetched successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _parseAndFillAddress(String address) {
    // Simple address parsing - can be improved
    List<String> parts = address.split(', ');
    if (parts.isNotEmpty) {
      _addressLine1Controller.text = parts[0];
      if (parts.length > 1) {
        _cityController.text = parts[parts.length - 3] ?? '';
        _stateController.text = parts[parts.length - 2] ?? '';
        _pincodeController.text = parts[parts.length - 1] ?? '';
      }
    }
  }

  void _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final addressModel = AddressModel(
        id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: selectedAddressType,
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        landmark: _landmarkController.text.trim(),
        latitude: currentLocation?.latitude,
        longitude: currentLocation?.longitude,
        isPrimary: isPrimary,
        updatedAt: DateTime.now(),
      );

      // TODO: Save to Firestore
      
      Navigator.pop(context, addressModel);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
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
                    // Use current location button
                    CustomButton(
                      text: 'Use Current Location',
                      icon: Icons.my_location,
                      onPressed: isLoading ? null : _getCurrentLocation,
                      isLoading: isLoading,
                      backgroundColor: Colors.white,
                      textColor: const Color(AppConstants.primaryColorValue),
                      border: Border.all(
                        color: const Color(AppConstants.primaryColorValue),
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingL),
                    
                    // Address Type
                    const Text(
                      'Address Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(AppConstants.textPrimaryValue),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Row(
                      children: addressTypes.map((type) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppConstants.spacingS),
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
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingL),
                    
                    // Address Line 1
                    TextFormField(
                      controller: _addressLine1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 1 *',
                        hintText: 'House/Flat/Building No., Street',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address Line 1 is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.spacingM),
                    
                    // Address Line 2
                    TextFormField(
                      controller: _addressLine2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 2',
                        hintText: 'Area, Colony, Sector',
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingM),
                    
                    // City and State
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'City is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State *',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'State is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.spacingM),
                    
                    // Pincode and Landmark
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            decoration: const InputDecoration(
                              labelText: 'Pincode *',
                            ),
                            keyboardType: TextInputType.number,
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
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: TextFormField(
                            controller: _landmarkController,
                            decoration: const InputDecoration(
                              labelText: 'Landmark',
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.spacingL),
                    
                    // Primary address checkbox
                    CheckboxListTile(
                      title: const Text('Set as primary address'),
                      subtitle: const Text('This will be used as default delivery address'),
                      value: isPrimary,
                      onChanged: (value) {
                        setState(() {
                          isPrimary = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            
            // Save button
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
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
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }
}