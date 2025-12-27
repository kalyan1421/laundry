import 'dart:async';

import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:customer_app/core/utils/validators.dart';
import 'package:customer_app/presentation/widgets/common/custom_text_field.dart';
import 'package:customer_app/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../presentation/providers/auth_provider.dart';

class MergedRegistrationScreen extends StatefulWidget {
  const MergedRegistrationScreen({super.key});

  @override
  State<MergedRegistrationScreen> createState() =>
      _MergedRegistrationScreenState();
}

class _MergedRegistrationScreenState extends State<MergedRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _personalFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();
  final _logger = Logger();

  late TabController _tabController;

  // Controllers for personal info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Controllers for address (user fills these)
  final _doorNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _apartmentNameController = TextEditingController();

  // Controllers for auto-filled address fields (now editable)
  final _streetAddressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

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
  bool _personalInfoValid = false;
  String _currentAddress = 'Move the pin to select your location';

  // Address type
  String _selectedAddressType = 'home';
  final List<Map<String, dynamic>> _addressTypes = [
    {'type': 'home', 'icon': Icons.home_outlined, 'label': 'Home'},
    {'type': 'work', 'icon': Icons.work_outline, 'label': 'Work'},
    {'type': 'other', 'icon': Icons.location_on_outlined, 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Get current location when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToCurrentLocation();
    });
  }

  void _handleTabChange() {
    if (_tabController.index == 1) {
      // Moving to Address tab - validate personal info first
      if (!_validatePersonalInfo()) {
        _tabController.animateTo(0);
        _showSnackBar('Please fill in your personal information first',
            isError: true);
      }
    }
    setState(() {});
  }

  bool _validatePersonalInfo() {
    return _personalFormKey.currentState?.validate() ?? false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _doorNumberController.dispose();
    _floorNumberController.dispose();
    _apartmentNameController.dispose();
    _streetAddressController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
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
          // Auto-fill address fields (user CAN edit these now)
          _streetAddressController.text =
              '${placemark.name ?? ''}, ${placemark.street ?? ''}, ${placemark.subLocality ?? ''}'
                  .replaceAll(RegExp(r'^, |, $|, , '), '')
                  .trim();

          _pincodeController.text = placemark.postalCode ?? '';
          _cityController.text = placemark.locality ?? '';
          _stateController.text = placemark.administrativeArea ?? '';

          _currentAddress =
              '${placemark.name}, ${placemark.street}, ${placemark.locality}, ${placemark.postalCode}';
        });
      }
    } catch (e) {
      _logger.e('Error getting address: $e');
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
      _logger.e('Error getting current location: $e');
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
      _logger.e('Error searching location: $e');
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

  Future<void> _submitRegistration() async {
    // Validate personal info
    final personalFormState = _personalFormKey.currentState;
    if (personalFormState == null || !personalFormState.validate()) {
      _tabController.animateTo(0);
      _showSnackBar('Please fill in your personal information', isError: true);
      return;
    }

    // Validate address form
    final addressFormState = _addressFormKey.currentState;
    if (addressFormState == null || !addressFormState.validate()) {
      _showSnackBar('Please fill in all address fields', isError: true);
      return;
    }

    // Check required manual fields
    if (!_canSaveAddress()) {
      _showSnackBar(
          'Please fill Door No., Floor, and Building Name to continue',
          isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      _logger.i('Submitting registration with:');
      _logger.i('Name: ${_nameController.text.trim()}');
      _logger.i('Email: ${_emailController.text.trim()}');
      _logger.i('Door Number: ${_doorNumberController.text.trim()}');
      _logger.i('Floor Number: ${_floorNumberController.text.trim()}');
      _logger.i('Building Name: ${_apartmentNameController.text.trim()}');
      _logger.i('Street Address: ${_streetAddressController.text.trim()}');
      _logger.i('City: ${_cityController.text.trim()}');
      _logger.i('State: ${_stateController.text.trim()}');
      _logger.i('Pincode: ${_pincodeController.text.trim()}');
      _logger.i('Address Type: $_selectedAddressType');
      _logger.i('Latitude: ${_selectedPosition.latitude}');
      _logger.i('Longitude: ${_selectedPosition.longitude}');

      bool success = await authProvider.updateProfileWithAddress(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        addressLine1: _streetAddressController.text.trim(),
        addressLine2: _apartmentNameController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        landmark: null,
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        doorNumber: _doorNumberController.text.trim(),
        floorNumber: _floorNumberController.text.trim(),
        apartmentName: _apartmentNameController.text.trim(),
        addressType: _selectedAddressType, // Pass the selected address type
      );

      _logger.i('Registration result: $success');

      if (!success) {
        throw Exception('Failed to update profile');
      }

      if (mounted) {
        _showSnackBar('Profile completed successfully!');
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      _logger.e('Profile completion error: $e');
      _showSnackBar('Failed to complete profile: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: context.onBackgroundColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.primaryColor,
          unselectedLabelColor: context.onBackgroundColor.withOpacity(0.6),
          indicatorColor: context.primaryColor,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: Icon(Icons.person_outline),
              text: 'Personal Info',
            ),
            Tab(
              icon: Icon(Icons.location_on_outlined),
              text: 'Address',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildPersonalInfoTab(),
          _buildAddressTab(),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return Form(
      key: _personalFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header illustration
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 60,
                  color: context.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: Text(
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.onBackgroundColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'We need your basic information to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onBackgroundColor.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Name field
            _buildSectionLabel('Full Name *'),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _nameController,
              labelText: '',
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email field
            _buildSectionLabel('Email Address *'),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _emailController,
              labelText: '',
              hintText: 'Enter your email address',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address';
                }
                if (!Validators.isValidEmail(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_personalFormKey.currentState!.validate()) {
                    setState(() {
                      _personalInfoValid = true;
                    });
                    _tabController.animateTo(1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Continue to Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTab() {
    return Stack(
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.search, color: context.primaryColor),
                                  onPressed: () {
                                    if (_searchController.text.trim().isNotEmpty) {
                                      _searchLocation(_searchController.text.trim());
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }

  Widget _buildAddressBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
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
            key: _addressFormKey,
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
                
                
                const SizedBox(height: 12),

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

                // Pincode, City, State row
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

                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || !_canSaveAddress())
                        ? null
                        : _submitRegistration,
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
                              const Text(
                                'Complete Registration',
                                style: TextStyle(
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
        prefixIcon: Icon(icon, size: 20, color: context.primaryColor.withOpacity(0.7)),
        suffixIcon: Icon(Icons.edit, size: 16, color: Colors.grey.withOpacity(0.5)),
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
