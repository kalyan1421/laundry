import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';
import 'package:customer_app/core/utils/validators.dart';
import 'package:customer_app/presentation/providers/address_provider.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/screens/address/map_selection_screen.dart';
import 'package:customer_app/presentation/widgets/common/custom_button.dart';
import 'package:customer_app/presentation/widgets/common/custom_text_field.dart';
import 'package:customer_app/presentation/widgets/common/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import 'package:provider/provider.dart';
import 'package:customer_app/core/routes/app_routes.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _doorNoController = TextEditingController();
  final _apartmentNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _doorNoController.dispose();
    _apartmentNameController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
          setState(() => _isFetchingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
        setState(() => _isFetchingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isFetchingLocation = false;
      });
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Current location fetched: Lat: ${_latitude?.toStringAsFixed(4)}, Lon: ${_longitude?.toStringAsFixed(4)}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get current location: ${e.toString()}')));
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _selectLocationOnMap() async {
    final LatLng? selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const MapSelectionScreen()),
    );

    if (selectedLocation != null) {
      setState(() {
        _latitude = selectedLocation.latitude;
        _longitude = selectedLocation.longitude;
      });
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location selected from map: Lat: ${_latitude?.toStringAsFixed(4)}, Lon: ${_longitude?.toStringAsFixed(4)}')));
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);

    if (authProvider.userModel == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated. Please login again.')),
      );
      return;
    }

    Map<String, dynamic> addressData = {
      'type': 'Home', // TODO: Allow user to select type
      'addressLine1': _doorNoController.text.trim() + (_apartmentNameController.text.trim().isNotEmpty ? ", " + _apartmentNameController.text.trim() : ""),
      'addressLine2': _streetController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'isPrimary': false, // TODO: Logic to handle default address selection
    };

    if (_latitude != null && _longitude != null) {
      addressData['latitude'] = _latitude;
      addressData['longitude'] = _longitude;
    }

    bool success = await addressProvider.addAddress(authProvider.userModel!.uid, addressData);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added successfully!')),
      );
      AppRoutes.navigateToHome(context); // Navigate to home and clear stack
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(addressProvider.error ?? 'Failed to add address.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Address'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Locate Your Address',
                style: AppTextTheme.titleLarge.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_isFetchingLocation)
                const LoadingWidget(message: 'Fetching current location...')
              else
                CustomButton(
                  text: 'Use My Current Location',
                  onPressed: _getCurrentLocation,
                  icon: Icons.my_location,
                  backgroundColor: AppColors.secondary,
                  textColor: Colors.white, // Assuming textOnSecondary is white or similar contrast
                ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Select on Map',
                onPressed: _selectLocationOnMap,
                icon: Icons.map_outlined,
                backgroundColor: AppColors.accent,
                textColor: Colors.white, // Assuming textOnAccent is white or similar contrast
              ),
              const SizedBox(height: 12),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Selected: Lat: ${_latitude!.toStringAsFixed(4)}, Lon: ${_longitude!.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    style: AppTextTheme.bodySmall.copyWith(color: AppColors.textSuccess),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Or Enter Address Details Manually',
                style: AppTextTheme.titleMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _doorNoController,
                labelText: 'Door No / Flat No',
                hintText: 'e.g., 123A, Flat 5B',
                validator: (value) => Validators.validateGeneric(value, 'Door No.'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _apartmentNameController,
                labelText: 'Apartment / Building Name',
                hintText: 'e.g., Sunshine Apartments',
                validator: (value) => Validators.validateGeneric(value, 'Apartment Name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _streetController,
                labelText: 'Street Address / Area',
                hintText: 'e.g., Main Street, Gandhi Nagar',
                validator: (value) => Validators.validateAddress(value, fieldName: 'Street Address'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _landmarkController,
                labelText: 'Landmark (Optional)',
                hintText: 'e.g., Near City Park',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cityController,
                labelText: 'City',
                hintText: 'e.g., Hyderabad',
                validator: Validators.validateCity,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _pincodeController,
                labelText: 'Pincode',
                hintText: 'e.g., 500001',
                keyboardType: TextInputType.number,
                validator: Validators.validatePincode,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _stateController,
                labelText: 'State',
                hintText: 'e.g., Telangana',
                validator: Validators.validateState,
              ),
              const SizedBox(height: 32),
              addressProvider.isLoading && !_isFetchingLocation
                  ? const LoadingWidget()
                  : CustomButton(
                      text: 'Save Address',
                      onPressed: _saveAddress,
                      icon: Icons.save_alt_rounded,
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 