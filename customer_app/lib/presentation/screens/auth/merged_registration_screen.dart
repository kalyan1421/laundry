import 'dart:io';

import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/core/utils/validators.dart';
import 'package:customer_app/presentation/widgets/common/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../presentation/providers/auth_provider.dart';

class MergedRegistrationScreen extends StatefulWidget {
  const MergedRegistrationScreen({super.key});

  @override
  State<MergedRegistrationScreen> createState() => _MergedRegistrationScreenState();
}

class _MergedRegistrationScreenState extends State<MergedRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _logger = Logger();
  
  // Controllers for form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Address controllers
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
  bool _isSubmitting = false;
  String? _locationError;
  
  @override
  void initState() {
    super.initState();
    _pincodeController.addListener(_onPincodeChanged);
    // Automatically get location when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocationAndFillAddress();
    });
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
    super.dispose();
  }
  
  // Auto-fill address based on pincode
  void _onPincodeChanged() async {
    String pincode = _pincodeController.text.trim();
    if (pincode.length == 6) {
      await _fetchAddressFromPincode(pincode);
    }
  }
  
  Future<void> _fetchAddressFromPincode(String pincode) async {
    try {
      // Using Indian Postal API
      final response = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/$pincode'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];
          setState(() {
            _cityController.text = postOffice['District'] ?? '';
            _stateController.text = postOffice['State'] ?? '';
          });
        }
      }
    } catch (e) {
      _logger.e('Error fetching address from pincode: $e');
    }
  }
  
  // Automatically get location and fill address details
  Future<void> _getCurrentLocationAndFillAddress() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _logger.i('GPS Position obtained:');
      _logger.i('Latitude: ${position.latitude}');
      _logger.i('Longitude: ${position.longitude}');
      
      // Perform reverse geocoding to get address details
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _logger.i('Address details obtained:');
        _logger.i('Locality: ${place.locality}');
        _logger.i('SubLocality: ${place.subLocality}');
        _logger.i('AdministrativeArea: ${place.administrativeArea}');
        _logger.i('PostalCode: ${place.postalCode}');
        _logger.i('Country: ${place.country}');
        
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isLoadingLocation = false;
            
            // Auto-fill address fields
            if (place.locality != null && place.locality!.isNotEmpty) {
              _cityController.text = place.locality!;
            }
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
              _stateController.text = place.administrativeArea!;
            }
            if (place.postalCode != null && place.postalCode!.isNotEmpty) {
              _pincodeController.text = place.postalCode!;
            }
            
            // Create a readable address string
            List<String> addressParts = [];
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              addressParts.add(place.subLocality!);
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              addressParts.add(place.locality!);
            }
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
              addressParts.add(place.administrativeArea!);
            }
            
            _currentAddress = addressParts.join(', ');
          });
        }
        
        _showSnackBar('Location and address details detected automatically!');
      } else {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isLoadingLocation = false;
            _currentAddress = 'Location coordinates saved. Please fill your address details.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocation = false;
        });
      }
      _logger.e('Error getting location: $e');
      _showSnackBar('Could not get location automatically. You can fill address manually.', isError: true);
    }
  }

  // Manual location getter (for button press)
  Future<void> _getCurrentLocation() async {
    await _getCurrentLocationAndFillAddress();
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

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if location is available
    if (_currentPosition == null) {
      _showSnackBar('Please enable location services to continue', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      bool success = await authProvider.updateProfileWithAddress(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _apartmentNameController.text.trim().isNotEmpty 
            ? _apartmentNameController.text.trim() 
            : null,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        landmark: _nearbyLandmarkController.text.trim().isNotEmpty 
            ? _nearbyLandmarkController.text.trim() 
            : null,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        doorNumber: _doorNumberController.text.trim().isNotEmpty 
            ? _doorNumberController.text.trim() 
            : null,
        floorNumber: _floorNumberController.text.trim().isNotEmpty 
            ? _floorNumberController.text.trim() 
            : null,
        apartmentName: _apartmentNameController.text.trim().isNotEmpty 
            ? _apartmentNameController.text.trim() 
            : null,
      );
      
      if (!success) {
        throw Exception('Failed to update profile');
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      _logger.e('Profile completion error: $e');
      _showSnackBar('Failed to complete profile. Please try again.', isError: true);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name *',
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
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _emailController,
                labelText: 'Email Address *',
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
              
              const SizedBox(height: 32),
              
              // Address Information Section
              _buildSectionTitle('Address Information'),
              const SizedBox(height: 16),
              
              // Location button
              _buildLocationButton(),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _doorNumberController,
                      labelText: 'Door/House No.',
                      hintText: 'e.g., 123',
                      prefixIcon: Icons.home_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _floorNumberController,
                      labelText: 'Floor',
                      hintText: 'e.g., 2nd Floor',
                      prefixIcon: Icons.layers_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _apartmentNameController,
                labelText: 'Apartment/Building Name',
                hintText: 'Enter apartment or building name',
                prefixIcon: Icons.apartment_outlined,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _addressLine1Controller,
                labelText: 'Street Address *',
                hintText: 'Enter your street address',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your street address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _nearbyLandmarkController,
                labelText: 'Nearby Landmark',
                hintText: 'e.g., Near Metro Station',
                prefixIcon: Icons.place_outlined,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _pincodeController,
                labelText: 'Pincode *',
                hintText: 'Enter 6-digit pincode',
                prefixIcon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your pincode';
                  }
                  if (value.trim().length != 6) {
                    return 'Pincode must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      labelText: 'City *',
                      hintText: 'City will auto-fill',
                      prefixIcon: Icons.location_city_outlined,
                      readOnly: true,
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
                    child: CustomTextField(
                      controller: _stateController,
                      labelText: 'State *',
                      hintText: 'State will auto-fill',
                      prefixIcon: Icons.map_outlined,
                      readOnly: true,
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
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5568),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Complete Registration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3748),
      ),
    );
  }
  
  Widget _buildLocationButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.my_location,
                color: _currentPosition != null ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _currentPosition != null ? Colors.green : Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: _getCurrentLocation,
                  child: Text(
                    _currentPosition != null ? 'Update' : 'Get Location',
                    style: const TextStyle(
                      color: Color(0xFF4A5568),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (_currentAddress != null) ...[
            const SizedBox(height: 8),
            Text(
              _currentAddress!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (_locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}