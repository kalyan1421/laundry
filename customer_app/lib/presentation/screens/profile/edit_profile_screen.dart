// lib/screens/auth/profile_setup_screen.dart
import 'package:customer_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _doorNumberController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  Position? _currentPosition;
  String? _currentAddress;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _doorNumberController.dispose();
    _landmarkController.dispose();
    _addressController.dispose();
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
        setState(() {
          _locationError = 'Location services are disabled. Please enable them.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permissions are permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += '${place.locality}, ';
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          address += '${place.administrativeArea}, ';
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address += place.postalCode!;
        }

        setState(() {
          _currentAddress = address.endsWith(', ') 
              ? address.substring(0, address.length - 2) 
              : address;
          _addressController.text = _currentAddress!;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please allow location access to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Prepare address data
      Map<String, dynamic> addressData = {
        'fullAddress': _addressController.text.trim(),
        'buildingName': _buildingController.text.trim(),
        'floor': _floorController.text.trim(),
        'doorNumber': _doorNumberController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'isDefault': true,
        'type': 'Home',
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Update user profile
      bool success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        additionalData: {
          'isProfileComplete': true,
          'addresses': [addressData],
          'defaultAddress': addressData,
        },
      );

      if (success && mounted) {
        // Navigate to home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to save profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Complete Your Profile',
          style: AppTypography.headlineSmall.copyWith(
            color: const Color(0xFF0F3057),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: 0.5,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A8E8)),
                ),
                const SizedBox(height: 24),

                // Welcome message
                Text(
                  'Welcome to Cloud Ironing!',
                  style: AppTypography.headlineMedium.copyWith(
                    color: const Color(0xFF0F3057),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please complete your profile to get started',
                  style: AppTypography.bodyMedium.copyWith(
                    color: const Color(0xFF6E7A8A),
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 16),

                // Name field
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Location Section
                _buildSectionTitle('Delivery Address'),
                const SizedBox(height: 16),

                // Current location
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _locationError != null 
                          ? Colors.red.shade300 
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: _locationError != null 
                                ? Colors.red 
                                : const Color(0xFF00A8E8),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Location',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: const Color(0xFF0F3057),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (_isLoadingLocation)
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Getting location...',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: const Color(0xFF6E7A8A),
                                        ),
                                      ),
                                    ],
                                  )
                                else if (_locationError != null)
                                  Text(
                                    _locationError!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.red,
                                    ),
                                  )
                                else if (_currentAddress != null)
                                  Text(
                                    _currentAddress!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: const Color(0xFF6E7A8A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (_locationError != null)
                            IconButton(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(
                                Icons.refresh,
                                color: Color(0xFF00A8E8),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Address field
                _buildTextField(
                  controller: _addressController,
                  label: 'Complete Address',
                  hintText: 'Enter your complete address',
                  prefixIcon: Icons.home_outlined,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Building/Apartment details
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _buildingController,
                        label: 'Building/Apartment',
                        hintText: 'Building name',
                        prefixIcon: Icons.apartment,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _floorController,
                        label: 'Floor',
                        hintText: 'Floor number',
                        prefixIcon: Icons.stairs,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Door number and landmark
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _doorNumberController,
                        label: 'Door/Flat Number',
                        hintText: 'Door number',
                        prefixIcon: Icons.door_front_door,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _landmarkController,
                        label: 'Landmark',
                        hintText: 'Nearby landmark',
                        prefixIcon: Icons.place,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading || _isLoadingLocation ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3057),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Save & Continue',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skip for now
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Skip for now',
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF6E7A8A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: const Color(0xFF0F3057),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: const Color(0xFF0F3057),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          validator: validator,
          style: AppTypography.bodyMedium.copyWith(
            color: const Color(0xFF0F3057),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFFA0AEC0),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: const Color(0xFF6E7A8A),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF00A8E8),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// Updated main.dart - Add profile setup screen route
// Add this to your AppRoutes.generateRoute method:

/*
case '/profile-setup':
  return MaterialPageRoute(
    builder: (_) => const ProfileSetupScreen(),
  );
*/

// Updated login_screen.dart - Navigate to profile setup for new users
// Modify the OTP verification success callback:

/*
// In your OTP verification screen, after successful verification:
if (authProvider.isNewUser || !authProvider.isProfileComplete) {
  Navigator.pushReplacementNamed(context, '/profile-setup');
} else {
  Navigator.pushReplacementNamed(context, '/home');
}
*/

// Add these dependencies to pubspec.yaml:
/*
dependencies:
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
# For iOS, add to Info.plist:
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to provide accurate delivery services.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location to provide accurate delivery services.</string>

# For Android, add to AndroidManifest.xml:
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
*/