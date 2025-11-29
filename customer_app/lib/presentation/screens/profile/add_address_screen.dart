// lib/screens/profile/add_address_screen.dart
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/data/models/address_model.dart';
import 'package:customer_app/services/location_service.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/custom_button.dart';
import 'package:customer_app/core/utils/address_utils.dart';

import 'map_picker_screen.dart';

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
      // If editing an existing address, populate fields from it
      _populateFields();
    } else {
      // If adding a new address, fetch current location and populate
      _fetchAndPopulateCurrentAddress();
    }
  }

  void _populateFields() {
    final address = widget.address!;
    _doorNumberController.text = address.doorNumber ?? '';
    _floorNumberController.text = address.floorNumber ?? '';
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
          content: Text(
              'Location fetched successfully! You can now manually fill your address.'),
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

  Future<void> _fetchAndPopulateCurrentAddress() async {
    setState(() {
      isLocationLoading = true;
    });

    try {
      // 1. Get current position
      Position position = await LocationService.getCurrentLocation();

      // 2. Get placemark from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark placemark = placemarks.first;

        // 3. Update state and populate fields
        setState(() {
          currentLocation = position;

          // _addressLine1Controller.text =
          //     '${placemark.name}, ${placemark.street}';
          // _addressLine2Controller.text = placemark.subLocality ?? '';
          _cityController.text = placemark.locality ?? '';
          _stateController.text = placemark.administrativeArea ?? '';
          _pincodeController.text = placemark.postalCode ?? '';
          _landmarkController.text = placemark.subThoroughfare ?? '';

          isLocationLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current address auto-filled.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLocationLoading = false;
      });
      // Error is handled by the UI showing the refresh button
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialPosition: currentLocation,
        ),
      ),
    );

    if (result != null &&
        result.containsKey('placemark') &&
        result.containsKey('position')) {
      final Placemark placemark = result['placemark'];
      final LatLng position = result['position'] as LatLng;

      setState(() {
        // Update location data
        currentLocation = Position(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        // Populate fields
        _addressLine1Controller.text = '${placemark.name}, ${placemark.street}';
        _addressLine2Controller.text = placemark.subLocality ?? '';
        _cityController.text = placemark.locality ?? '';
        _stateController.text = placemark.administrativeArea ?? '';
        _pincodeController.text = placemark.postalCode ?? '';
        _landmarkController.text =
            placemark.subThoroughfare ?? ''; // Or other relevant field
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address details filled from map selection.'),
          backgroundColor: Colors.green,
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
        print(
            '🏠 ADD ADDRESS: Updating existing address with ID: ${widget.address!.id}');

        // If setting as primary, remove primary from other addresses first
        if (isPrimary) {
          await _removePrimaryFromOtherAddresses(userId,
              excludeId: widget.address!.id);
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
          content: Text(widget.address == null
              ? 'Address added successfully!'
              : 'Address updated successfully!'),
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
  Future<void> _removePrimaryFromOtherAddresses(String userId,
      {String? excludeId}) async {
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
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        elevation: 1,
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
                    Container(
                      decoration: BoxDecoration(
                          border: currentLocation != null
                              ? Border.all(color: Colors.green)
                              : Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(24)),
                      child: Card(
                        borderOnForeground: currentLocation != null,
                        color: context.surfaceColor,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    color: currentLocation != null
                                        ? Colors.green
                                        : context.onSurfaceColor
                                            .withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Current Location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight
                                          .w600, // color will be inherited
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isLocationLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  else
                                    TextButton(
                                      onPressed:
                                          _fetchAndPopulateCurrentAddress,
                                      child: Text(
                                        'Refresh',
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? context.secondaryColor
                                                    : context.primaryColor),
                                      ),
                                    ),
                                ],
                              ),
                              if (currentLocation != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Location detected successfully',
                                  style: TextStyle(
                                    color:
                                        context.onSurfaceColor.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ] else if (!isLocationLoading) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tap refresh to get your current location',
                                  style: TextStyle(
                                    color:
                                        context.onSurfaceColor.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Map Picker Section
                    Card(
                      color: context.surfaceColor,
                      elevation: 1,
                      child: ListTile(
                        leading: Icon(
                          Icons.map_outlined,
                          color: context.primaryColor,
                        ),
                        title: const Text(
                          'Select Location on Map',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                            'Pinpoint your address for better accuracy'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _openMapPicker,
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                          child: Text("OR",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ),

                    const SizedBox(height: 24),

                    // Address Type Selection
                    const Text(
                      'Address Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                              selectedColor:
                                  // context.primaryColor.withOpacity(0.2),se
                                  context.secondaryColor,
                              labelStyle: TextStyle(
                                color: selectedAddressType == type
                                    ? context.primaryColor
                                    : context.onSurfaceColor.withOpacity(0.7),
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
                      color: context.surfaceColor,
                      elevation: 1,
                      child: CheckboxListTile(
                        title: const Text(
                          'Set as Primary Address',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                            'This will be used as default for orders'),
                        value: isPrimary,
                        onChanged: (value) {
                          setState(() {
                            isPrimary = value ?? false;
                          });
                        },
                        activeColor: context.primaryColor,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  // Use surface color for dark mode
                  color: Colors.transparent,
                ),
                child: CustomButton(
                  textStyle: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),
                  elevation: 0,
                  text: widget.address == null
                      ? 'Save Address'
                      : 'Update Address',
                  onPressed: isLoading ? null : _saveAddress,
                  isLoading: isLoading,
                ),
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
