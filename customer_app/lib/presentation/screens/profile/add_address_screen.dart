import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/data/models/address_model.dart';
import 'package:customer_app/services/location_service.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/custom_button.dart';
import 'package:customer_app/core/utils/address_utils.dart';
import 'package:logger/logger.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? address; // For editing existing address

  const AddAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _logger = Logger();

  // Controllers
  final _doorNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // State variables
  String _selectedAddressType = 'home';
  bool _isPrimary = false;
  bool _isLoading = false;

  // Location-related state
  bool _isLocationLoading = false;
  Position? _currentLocation;
  String? _currentAddressString;
  String? _locationError;

  final List<String> _addressTypes = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _populateFields();
    } else {
      // For a new address, fetch location automatically
      _getCurrentLocation();
    }
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

  void _populateFields() {
    final address = widget.address!;
    // _doorNumberController.text = AddressUtils.extractDoorNumber(address.addressLine1);
    // _floorNumberController.text = AddressUtils.extractFloorNumber(address.addressLine1);
    // _addressLine1Controller.text = AddressUtils.extractMainAddress(address.addressLine1);
    // _addressLine2Controller.text = address.addressLine2 ?? '';
    _cityController.text = address.city;
    _stateController.text = address.state;
    _pincodeController.text = address.pincode;
    // _landmarkController.text = address.landmark ?? '';
    _selectedAddressType = address.type;
    _isPrimary = address.isPrimary;

    if (address.latitude != null && address.longitude != null) {
      _currentLocation = Position(
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
      _currentAddressString =
          'Saved location: ${address.latitude!.toStringAsFixed(4)}, ${address.longitude!.toStringAsFixed(4)}';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
      _currentAddressString = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      setState(() {
        _currentLocation = position;
      });
      await _getAddressFromLatLng(position);
    } catch (e) {
      _logger.e("Error getting location: $e");
      setState(() {
        _locationError = e.toString();
      });
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _addressLine1Controller.text = place.street ?? '';
          _cityController.text = place.locality ?? '';
          _stateController.text = place.administrativeArea ?? '';
          _pincodeController.text = place.postalCode ?? '';
          _currentAddressString =
              '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
          _locationError = null;
        });
        _showSnackBar('Address auto-filled successfully!', isError: false);
      } else {
        setState(() {
          _locationError = 'Could not determine address from location.';
        });
      }
    } catch (e) {
      _logger.e("Error getting address from latlng: $e");
      setState(() {
        _locationError = 'Failed to get address. Please fill manually.';
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentLocation == null) {
      _showSnackBar('Could not get your location. Please try refreshing.',
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.uid;
      final phoneNumber = authProvider.userModel?.phoneNumber;

      if (userId == null || phoneNumber == null) {
        throw Exception('User not authenticated');
      }

      if (_isPrimary) {
        await _removePrimaryFromOtherAddresses(userId,
            excludeId: widget.address?.id);
      }

      if (widget.address == null) {
        // Add new address
        await AddressUtils.saveAddressWithStandardFormat(
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
          addressType: _selectedAddressType,
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          isPrimary: _isPrimary,
        );
      } else {
        // Update existing address
        await AddressUtils.updateAddressWithStandardFormat(
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
          addressType: _selectedAddressType,
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          isPrimary: _isPrimary,
        );
      }

      Navigator.pop(context, true);
      _showSnackBar(
        widget.address == null
            ? 'Address added successfully!'
            : 'Address updated successfully!',
        isError: false,
      );
    } catch (e) {
      _logger.e("Error saving address: $e");
      _showSnackBar('Failed to save address: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removePrimaryFromOtherAddresses(String userId,
      {String? excludeId}) async {
    final query = FirebaseFirestore.instance
        .collection('customer')
        .doc(userId)
        .collection('addresses')
        .where('isPrimary', isEqualTo: true);

    final snapshot = await query.get();
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      if (doc.id != excludeId) {
        batch.update(doc.reference, {'isPrimary': false});
      }
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
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
                    // --- Location Card ---
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
                                  color: _currentLocation != null
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Current Location',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                if (_isLocationLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                else
                                  TextButton(
                                    onPressed: _getCurrentLocation,
                                    child: const Text('Refresh'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_currentAddressString != null)
                              Text(
                                _currentAddressString!,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                            if (_locationError != null)
                              Text(
                                _locationError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 14),
                              ),
                            if (_currentAddressString == null &&
                                _locationError == null &&
                                !_isLocationLoading)
                              Text(
                                'Tap refresh to get your current location and auto-fill address details.',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- Address Type ---
                    const Text('Address Type',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: _addressTypes.map((type) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type.toUpperCase()),
                              selected: _selectedAddressType == type,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedAddressType = type;
                                  });
                                }
                              },
                              selectedColor:
                                  const Color(AppConstants.primaryColorValue)
                                      .withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: _selectedAddressType == type
                                    ? const Color(
                                        AppConstants.primaryColorValue)
                                    : Colors.grey[600],
                                fontWeight: _selectedAddressType == type
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // --- Building Details ---
                    const Text('Building Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
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
                                    border: OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextFormField(
                                controller: _floorNumberController,
                                decoration: const InputDecoration(
                                    labelText: 'Floor Number',
                                    hintText: 'e.g., Ground, 2nd',
                                    prefixIcon: Icon(Icons.layers),
                                    border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // --- Address Details ---
                    const Text('Address Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressLine1Controller,
                      decoration: const InputDecoration(
                          labelText: 'Address Line 1 *',
                          hintText: 'Building, Street name, Area',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Address is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _addressLine2Controller,
                        decoration: const InputDecoration(
                            labelText: 'Address Line 2',
                            hintText: 'Colony, Sector (Optional)',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _landmarkController,
                        decoration: const InputDecoration(
                            labelText: 'Landmark',
                            hintText: 'e.g., Near Metro Station',
                            prefixIcon: Icon(Icons.place),
                            border: OutlineInputBorder())),
                    const SizedBox(height: 24),
                    // --- Location Details ---
                    const Text('Location Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                          labelText: 'City *',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'City is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                          labelText: 'State *',
                          prefixIcon: Icon(Icons.map),
                          border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'State is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                          labelText: 'Pin Code *',
                          prefixIcon: Icon(Icons.pin_drop),
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Pin code is required';
                        if (v.length != 6) return 'Pin code must be 6 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // --- Primary Address ---
                    Card(
                      elevation: 1,
                      child: CheckboxListTile(
                        title: const Text('Set as Primary Address',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: const Text(
                            'This will be used as default for orders'),
                        value: _isPrimary,
                        onChanged: (value) {
                          setState(() {
                            _isPrimary = value ?? false;
                          });
                        },
                        activeColor:
                            const Color(AppConstants.primaryColorValue),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // --- Save Button ---
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, -2))
                ],
              ),
              child: CustomButton(
                text:
                    widget.address == null ? 'Save Address' : 'Update Address',
                onPressed: _isLoading ? null : _saveAddress,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
