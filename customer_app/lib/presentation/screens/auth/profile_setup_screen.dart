import 'dart:io';

import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';
import 'package:customer_app/core/utils/validators.dart';
import 'package:customer_app/presentation/widgets/common/custom_button.dart';
import 'package:customer_app/presentation/widgets/common/custom_text_field.dart';
import 'package:customer_app/presentation/widgets/common/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../presentation/providers/auth_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _logger = Logger();
  
  // Controllers for form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Detailed address controllers
  final _doorNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _apartmentNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _nearbyLandmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateController = TextEditingController();
  
  File? _imageFile;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = false;
  String? _locationError;
  int _currentStep = 0;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _doorNumberController.dispose();
    _floorNumberController.dispose();
    _apartmentNameController.dispose();
    _addressLine1Controller.dispose();
    _nearbyLandmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in settings.');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied. Please grant permission in settings.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Please grant permission in settings.');
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Get detailed address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        // Extract maximum details from placemark
        String street = place.street ?? '';
        String subLocality = place.subLocality ?? '';
        String locality = place.locality ?? '';
        String subAdministrativeArea = place.subAdministrativeArea ?? '';
        String administrativeArea = place.administrativeArea ?? '';
        String postalCode = place.postalCode ?? '';
        String country = place.country ?? '';
        String name = place.name ?? '';
        String thoroughfare = place.thoroughfare ?? '';
        String subThoroughfare = place.subThoroughfare ?? '';
        
        setState(() {
          _currentPosition = position;
          
          // Create a comprehensive address string for display
          List<String> addressParts = [];
          if (name.isNotEmpty && name != street) addressParts.add(name);
          if (street.isNotEmpty) addressParts.add(street);
          if (subLocality.isNotEmpty && subLocality != locality) addressParts.add(subLocality);
          if (locality.isNotEmpty) addressParts.add(locality);
          if (subAdministrativeArea.isNotEmpty && subAdministrativeArea != locality) addressParts.add(subAdministrativeArea);
          if (administrativeArea.isNotEmpty) addressParts.add(administrativeArea);
          if (postalCode.isNotEmpty) addressParts.add(postalCode);
          
          _currentAddress = addressParts.join(', ');
          
          // Pre-fill address fields with maximum available data
          // Address Line 1: Use street, thoroughfare, or name (most specific)
          if (street.isNotEmpty) {
            _addressLine1Controller.text = street;
          } else if (thoroughfare.isNotEmpty) {
            _addressLine1Controller.text = thoroughfare;
          } else if (name.isNotEmpty) {
            _addressLine1Controller.text = name;
          }
          
          // If we have subThoroughfare (house/building number), use it for door number
          if (subThoroughfare.isNotEmpty) {
            _doorNumberController.text = subThoroughfare;
          }
          
          // Use subLocality for apartment/area name if available
          if (subLocality.isNotEmpty && subLocality != locality) {
            _apartmentNameController.text = subLocality;
          }
          
          // City: Use locality or subAdministrativeArea
          if (locality.isNotEmpty) {
            _cityController.text = locality;
          } else if (subAdministrativeArea.isNotEmpty) {
            _cityController.text = subAdministrativeArea;
          }
          
          // State
          if (administrativeArea.isNotEmpty) {
            _stateController.text = administrativeArea;
          }
          
          // Pincode
          if (postalCode.isNotEmpty) {
            _pincodeController.text = postalCode;
          }
          
          // Nearby landmark: Use name if it's different from street
          if (name.isNotEmpty && name != street && name != thoroughfare) {
            _nearbyLandmarkController.text = name;
          }
          
          _isLoadingLocation = false;
        });
        
        _logger.i('Location details extracted:');
        _logger.i('Street: $street');
        _logger.i('SubLocality: $subLocality');
        _logger.i('Locality: $locality');
        _logger.i('SubAdministrativeArea: $subAdministrativeArea');
        _logger.i('AdministrativeArea: $administrativeArea');
        _logger.i('PostalCode: $postalCode');
        _logger.i('Name: $name');
        _logger.i('Thoroughfare: $thoroughfare');
        _logger.i('SubThoroughfare: $subThoroughfare');
      }
    } catch (e) {
      setState(() {
        _locationError = e.toString();
        _isLoadingLocation = false;
      });
      _logger.e('Error getting location: $e');
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate basic info step
      if (_nameController.text.trim().isEmpty) {
        _showSnackBar('Please enter your name', isError: true);
        return;
      }
      if (_emailController.text.trim().isEmpty || !Validators.isValidEmail(_emailController.text.trim())) {
        _showSnackBar('Please enter a valid email address', isError: true);
        return;
      }
    }
    
    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if location is available
    if (_currentPosition == null) {
      _showSnackBar('Please enable location services to continue', isError: true);
      return;
    }

    // Validate required address fields
    if (_addressLine1Controller.text.trim().isEmpty) {
      _showSnackBar('Please enter address line 1', isError: true);
      return;
    }
    if (_cityController.text.trim().isEmpty) {
      _showSnackBar('Please enter city', isError: true);
      return;
    }
    if (_stateController.text.trim().isEmpty) {
      _showSnackBar('Please enter state', isError: true);
      return;
    }
    if (_pincodeController.text.trim().isEmpty) {
      _showSnackBar('Please enter pincode', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Log coordinates before sending
      _logger.i('Profile Setup - Coordinates to save:');
      _logger.i('Latitude: ${_currentPosition!.latitude}');
      _logger.i('Longitude: ${_currentPosition!.longitude}');
      _logger.i('Position accuracy: ${_currentPosition!.accuracy}');
      _logger.i('Position timestamp: ${_currentPosition!.timestamp}');
      
      // Create detailed address string
      List<String> addressComponents = [];
      
      if (_doorNumberController.text.trim().isNotEmpty) {
        addressComponents.add('Door: ${_doorNumberController.text.trim()}');
      }
      if (_floorNumberController.text.trim().isNotEmpty) {
        addressComponents.add('Floor: ${_floorNumberController.text.trim()}');
      }
      if (_apartmentNameController.text.trim().isNotEmpty) {
        addressComponents.add(_apartmentNameController.text.trim());
      }
      
      String addressLine1 = _addressLine1Controller.text.trim();
      if (addressComponents.isNotEmpty) {
        addressLine1 = '${addressComponents.join(', ')}, $addressLine1';
      }

      _logger.i('Profile Setup - Address components:');
      _logger.i('Final Address Line 1: $addressLine1');
      _logger.i('Address Line 2: ${_nearbyLandmarkController.text.trim().isEmpty ? 'None' : 'Near: ${_nearbyLandmarkController.text.trim()}'}');
      _logger.i('City: ${_cityController.text.trim()}');
      _logger.i('State: ${_stateController.text.trim()}');
      _logger.i('Pincode: ${_pincodeController.text.trim()}');

      // Use the new method that saves both profile and address
      final success = await authProvider.updateProfileWithAddress(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        addressLine1: addressLine1,
        addressLine2: _nearbyLandmarkController.text.trim().isEmpty ? null : 'Near: ${_nearbyLandmarkController.text.trim()}',
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        landmark: _nearbyLandmarkController.text.trim().isEmpty ? null : _nearbyLandmarkController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      if (success) {
        _logger.i('Profile Setup - Success! Address saved with coordinates');
        _showSnackBar('Profile setup completed successfully!');
        // Navigate to home
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        _logger.e('Profile Setup - Failed to save profile/address');
        _showSnackBar(authProvider.errorMessage ?? 'Failed to complete profile setup', isError: true);
      }
    } catch (e) {
      _logger.e('Profile Setup - Exception occurred: $e');
      _showSnackBar('An error occurred. Please try again.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        backgroundColor: AppColors.primary,
        leading: _currentStep > 0 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousStep,
            )
          : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / 2,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Step ${_currentStep + 1} of 2',
                  style: AppTextTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildLocationStep(),
              ],
            ),
          ),
          
          // Bottom navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: authProvider.isLoading
                      ? const LoadingWidget()
                      : CustomButton(
                          text: _currentStep == 1 ? 'Complete Setup' : 'Next',
                          onPressed: _nextStep,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us about yourself',
              style: AppTextTheme.headlineMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Let\'s start with your basic information',
              style: AppTextTheme.bodyLarge.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Profile picture placeholder
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement image picker
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add profile picture (optional)',
              style: AppTextTheme.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            CustomTextField(
              controller: _nameController,
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline_rounded,
              validator: Validators.validateName,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _emailController,
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              prefixIcon: Icons.email_outlined,
              validator: Validators.validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your delivery address',
            style: AppTextTheme.headlineMedium.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll use this for pickup and delivery',
            style: AppTextTheme.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Current location card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentPosition != null ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _currentPosition != null ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _currentPosition != null ? Icons.location_on : Icons.location_off,
                      color: _currentPosition != null ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentPosition != null ? 'Current Location Detected' : 'Location Access Required',
                            style: AppTextTheme.titleSmall.copyWith(
                              color: _currentPosition != null ? AppColors.success : AppColors.error,
                            ),
                          ),
                          if (_currentAddress != null)
                            Text(
                              _currentAddress!,
                              style: AppTextTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          if (_locationError != null)
                            Text(
                              _locationError!,
                              style: AppTextTheme.bodySmall.copyWith(color: AppColors.error),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isLoadingLocation) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (_locationError != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Retry Location'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Building/Apartment Details Section
          _buildSectionHeader('Building Details'),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _doorNumberController,
                  labelText: 'Door Number',
                  hintText: 'e.g., 101, A-12',
                  prefixIcon: Icons.door_front_door_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _floorNumberController,
                  labelText: 'Floor Number',
                  hintText: 'e.g., Ground, 2nd',
                  prefixIcon: Icons.layers_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _apartmentNameController,
            labelText: 'Apartment/Building Name',
            hintText: 'e.g., Sunrise Apartments, Tower A',
            prefixIcon: Icons.apartment_outlined,
          ),
          const SizedBox(height: 24),
          
          // Address Details Section
          _buildSectionHeader('Address Details'),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _addressLine1Controller,
            labelText: 'Address Line 1 *',
            hintText: 'Street name, Area',
            prefixIcon: Icons.home_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _nearbyLandmarkController,
            labelText: 'Nearby Landmark',
            hintText: 'e.g., Near Metro Station, Opposite Mall',
            prefixIcon: Icons.place_outlined,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _cityController,
                  labelText: 'City *',
                  hintText: 'City',
                  prefixIcon: Icons.location_city,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _pincodeController,
                  labelText: 'Pincode *',
                  hintText: 'Pincode',
                  prefixIcon: Icons.pin_drop,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter pincode';
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
          
          CustomTextField(
            controller: _stateController,
            labelText: 'State *',
            hintText: 'State',
            prefixIcon: Icons.map_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter state';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All fields marked with * are required. Other fields help us deliver more accurately.',
                    style: AppTextTheme.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextTheme.titleMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
