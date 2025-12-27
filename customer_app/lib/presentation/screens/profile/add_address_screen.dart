// lib/screens/profile/add_address_screen.dart
import 'dart:async';
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
import 'package:customer_app/core/utils/address_utils.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? address; // For editing existing address

  const AddAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Manual input controllers
  final _doorNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _apartmentNameController = TextEditingController();

  // Auto-filled controllers (editable)
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Map related
  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  // Location state
  LatLng _selectedPosition = const LatLng(17.3850, 78.4867); // Default Hyderabad
  bool _isMapLoading = true;
  bool _isAddressLoading = false;
  bool _isSearching = false;
  bool _isSubmitting = false;
  String _currentAddress = 'Move the pin to select your location';

  String _selectedAddressType = 'home';
  bool isPrimary = false;
  Position? currentLocation;

  final List<Map<String, dynamic>> _addressTypes = [
    {'type': 'home', 'icon': Icons.home_outlined, 'label': 'Home'},
    {'type': 'work', 'icon': Icons.work_outline, 'label': 'Work'},
    {'type': 'other', 'icon': Icons.location_on_outlined, 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();

    if (widget.address != null) {
      _populateFields();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToCurrentLocation();
      });
    }
  }

  void _populateFields() {
    final address = widget.address!;
    _doorNumberController.text = address.doorNumber ?? '';
    _floorNumberController.text = address.floorNumber ?? '';
    _apartmentNameController.text = address.apartmentName ?? '';
    _streetAddressController.text = address.addressLine1;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _pincodeController.text = address.pincode;
    _selectedAddressType = address.type.toLowerCase();
    isPrimary = address.isPrimary;

    if (address.latitude != null && address.longitude != null) {
      _selectedPosition = LatLng(address.latitude!, address.longitude!);
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

  @override
  void dispose() {
    _doorNumberController.dispose();
    _floorNumberController.dispose();
    _apartmentNameController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Map methods
  void _onMapCreated(GoogleMapController controller) {
    _mapCompleter.complete(controller);
    _mapController = controller;
    setState(() {
      _isMapLoading = false;
    });
  }

  void _onCameraMove(CameraPosition position) {
    _selectedPosition = position.target;
  }

  Future<void> _onCameraIdle() async {
    await _getAddressFromCoordinates();
  }

  Future<void> _getAddressFromCoordinates() async {
    setState(() {
      _isAddressLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;

        setState(() {
          // Auto-fill address fields (user can edit these)
          _streetAddressController.text =
              '${placemark.name ?? ''}, ${placemark.street ?? ''}, ${placemark.subLocality ?? ''}'
                  .replaceAll(RegExp(r'^, |, $|, , '), '')
                  .trim();

          _pincodeController.text = placemark.postalCode ?? '';
          _cityController.text = placemark.locality ?? '';
          _stateController.text = placemark.administrativeArea ?? '';

          _currentAddress =
              '${placemark.name}, ${placemark.street}, ${placemark.subLocality}, ${placemark.locality}';

          // Update current location
          currentLocation = Position(
            latitude: _selectedPosition.latitude,
            longitude: _selectedPosition.longitude,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      if (mounted) {
        setState(() {
          _currentAddress = 'Could not get address for this location';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddressLoading = false;
        });
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isMapLoading = true;
    });

    try {
      Position position = await LocationService.getCurrentLocation();

      final newPosition = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = newPosition;
        currentLocation = position;
      });

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPosition,
              zoom: 17.0,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        _showSnackBar('Could not get current location: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
        });
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);

        setState(() {
          _selectedPosition = newPosition;
        });

        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPosition,
              zoom: 17.0,
            ),
          ),
        );
      } else {
        _showSnackBar('Location not found', isError: true);
      }
    } catch (e) {
      print('Error searching location: $e');
      _showSnackBar('Error searching for location', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _canSaveAddress() {
    return _doorNumberController.text.trim().isNotEmpty &&
        _floorNumberController.text.trim().isNotEmpty &&
        _apartmentNameController.text.trim().isNotEmpty &&
        _streetAddressController.text.trim().isNotEmpty &&
        _pincodeController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _stateController.text.trim().isNotEmpty;
  }

  Future<void> _saveAddress() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    if (currentLocation == null) {
      _showSnackBar('Please select a location on the map', isError: true);
      return;
    }

    if (!_canSaveAddress()) {
      _showSnackBar('Please fill Door No., Floor, and Building Name',
          isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel == null) {
        throw Exception('User not authenticated');
      }

      final userId = authProvider.userModel!.uid;
      final phoneNumber = authProvider.userModel!.phoneNumber;

      if (widget.address == null) {
        // Adding new address
        if (isPrimary) {
          await _removePrimaryFromOtherAddresses(userId);
        }

        final documentId = await AddressUtils.saveAddressWithStandardFormat(
          userId: userId,
          phoneNumber: phoneNumber,
          doorNumber: _doorNumberController.text.trim(),
          floorNumber: _floorNumberController.text.trim(),
          addressLine1: _streetAddressController.text.trim(),
          landmark: '',
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          addressLine2: '',
          apartmentName: _apartmentNameController.text.trim(),
          addressType: _selectedAddressType,
          latitude: currentLocation!.latitude,
          longitude: currentLocation!.longitude,
          isPrimary: isPrimary,
        );

        if (documentId == null) {
          throw Exception('Failed to save address');
        }
      } else {
        // Updating existing address
        if (isPrimary) {
          await _removePrimaryFromOtherAddresses(userId,
              excludeId: widget.address!.id);
        }

        final success = await AddressUtils.updateAddressWithStandardFormat(
          userId: userId,
          documentId: widget.address!.id,
          doorNumber: _doorNumberController.text.trim(),
          floorNumber: _floorNumberController.text.trim(),
          addressLine1: _streetAddressController.text.trim(),
          landmark: '',
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          addressLine2: '',
          apartmentName: _apartmentNameController.text.trim(),
          addressType: _selectedAddressType,
          latitude: currentLocation!.latitude,
          longitude: currentLocation!.longitude,
          isPrimary: isPrimary,
        );

        if (!success) {
          throw Exception('Failed to update address');
        }
      }

      // Refresh user data to update home screen
      await authProvider.refreshUserData();

      Navigator.pop(context, true);

      _showSnackBar(widget.address == null
          ? 'Address added successfully!'
          : 'Address updated successfully!');
    } catch (e) {
      print('Error saving address: $e');
      _showSnackBar('Failed to save address: $e', isError: true);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _removePrimaryFromOtherAddresses(String userId,
      {String? excludeId}) async {
    try {
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
    } catch (e) {
      print('Error removing primary status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:  Icon(Icons.arrow_back, color: context.onBackgroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.address == null ? 'Add New Address' : 'Edit Address',
          style: TextStyle(
            color: context.onBackgroundColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.49,
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _selectedPosition,
                    zoom: 16.0,
                  ),
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

                // Center Pin
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, -25),
                    child: const Icon(
                      Icons.location_pin,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                ),

                // Search Bar at top
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for a location...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.search,
                                        color: context.primaryColor),
                                    onPressed: () {
                                      if (_searchController.text
                                          .trim()
                                          .isNotEmpty) {
                                        _searchLocation(
                                            _searchController.text.trim());
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                ],
                              ),
                        filled: true,
                        fillColor: context.surfaceColor,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _searchLocation,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ),

                // Use current location button
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _goToCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.my_location,
                              color: context.primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Use current location',
                              style: TextStyle(
                                color: context.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Loading overlay
                if (_isMapLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Sheet with address form
          _buildAddressBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildAddressBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selected address preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: context.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isAddressLoading
                            ? const LinearProgressIndicator()
                            : Text(
                                _currentAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.onSurfaceColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Manual fields section
                _buildSectionLabel('✏️ Please fill these details'),
                const SizedBox(height: 8),
                Text(
                  'Required to save your address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Door No. and Floor row
                Row(
                  children: [
                    Expanded(
                      child: _buildManualField(
                        controller: _doorNumberController,
                        label: 'Door No. *',
                        hint: 'e.g., 101',
                        icon: Icons.door_front_door_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildManualField(
                        controller: _floorNumberController,
                        label: 'Floor *',
                        hint: 'e.g., 2nd',
                        icon: Icons.layers_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Apartment/Building Name
                _buildManualField(
                  controller: _apartmentNameController,
                  label: 'Apartment / Building Name *',
                  hint: 'Enter apartment or building name',
                  icon: Icons.apartment_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Building name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Street Address (editable)
                _buildEditableField(
                  controller: _streetAddressController,
                  label: 'Street Address *',
                  icon: Icons.location_on_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Street address is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Pincode, City row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildEditableField(
                        controller: _pincodeController,
                        label: 'Pincode *',
                        icon: Icons.pin_drop_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildEditableField(
                        controller: _cityController,
                        label: 'City *',
                        icon: Icons.location_city_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildEditableField(
                  controller: _stateController,
                  label: 'State *',
                  icon: Icons.map_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Address type selection
                _buildSectionLabel('Save address as'),
                const SizedBox(height: 12),
                Row(
                  children: _addressTypes.map((type) {
                    final isSelected = _selectedAddressType == type['type'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAddressType = type['type'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.primaryColor.withOpacity(0.1)
                                : context.surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? context.primaryColor
                                  : context.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? context.primaryColor
                                    : context.onSurfaceColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? context.primaryColor
                                      : context.onSurfaceColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Primary address checkbox
                Container(
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? context.primaryColor.withOpacity(0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPrimary
                          ? context.primaryColor.withOpacity(0.3)
                          : context.outlineVariant,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isPrimary,
                    onChanged: (value) {
                      setState(() {
                        isPrimary = value ?? false;
                      });
                    },
                    activeColor: context.primaryColor,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    title: Text(
                      'Set as primary address',
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontWeight:
                            isPrimary ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      'This will be your default delivery address',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.onSurfaceColor.withOpacity(0.6),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),

                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        (_isSubmitting || !_canSaveAddress()) ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.address == null
                                    ? 'Save Address'
                                    : 'Update Address',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // Helper text
                if (!_canSaveAddress()) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Fill Door No., Floor, and Building Name to continue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.onSurfaceColor,
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        color: context.onSurfaceColor,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: context.onSurfaceColor.withOpacity(0.7),
          fontSize: 12,
        ),
        prefixIcon:
            Icon(icon, size: 20, color: context.primaryColor.withOpacity(0.7)),
        suffixIcon:
            Icon(Icons.edit, size: 16, color: Colors.grey.withOpacity(0.5)),
        filled: true,
        fillColor: context.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildManualField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        color: context.onSurfaceColor,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: context.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: context.onSurfaceColor.withOpacity(0.4),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 20, color: context.primaryColor),
        filled: true,
        fillColor: context.primaryColor.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
