import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/providers/address_provider.dart';
import 'package:customer_app/data/models/address_model.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:customer_app/core/utils/address_formatter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  late final AddressProvider _addressProvider;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _addressProvider = Provider.of<AddressProvider>(context, listen: false);
    _startListeningToAddresses();
    _getCurrentLocation();
  }

  void _startListeningToAddresses() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      // Start listening to real-time address updates
      _addressProvider.startListeningToAddresses(authProvider.userModel!.uid);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {});
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  void dispose() {
    // Stop listening when screen is disposed
    _addressProvider.stopListeningToAddresses();
    super.dispose();
  }

  // Calculate distance between two points
  String _calculateDistance(AddressModel address) {
    if (_currentPosition == null || address.latitude == null || address.longitude == null) {
      return '';
    }

    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      address.latitude!,
      address.longitude!,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            _buildHeader(),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.outlineVariant),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for area, street name...',
                    hintStyle: TextStyle(
                      color: context.onSurfaceColor.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.primaryColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Use current location option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.outlineVariant),
                ),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final currentAddress = authProvider.userModel?.primaryAddress;
                    return ListTile(
                      leading: Icon(
                        Icons.my_location,
                        color: context.primaryColor,
                      ),
                      title: Text(
                        'Use current location',
                        style: TextStyle(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: currentAddress != null
                          ? Text(
                              '${currentAddress.addressLine1}, ${currentAddress.city}',
                              style: TextStyle(
                                color: context.onSurfaceColor.withOpacity(0.6),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        // Navigate to add address with current location
                        Navigator.pushNamed(context, '/add-address-screen');
                      },
                    );
                  },
                ),
              ),
            ),

            // Add Address option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.outlineVariant),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.add,
                    color: context.primaryColor,
                  ),
                  title: Text(
                    'Add Address',
                    style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pushNamed(context, '/add-address-screen');
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Saved addresses section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SAVED ADDRESSES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceColor.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Address list
            Expanded(
              child: Consumer<AddressProvider>(
                builder: (context, addressProvider, child) {
                  if (addressProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (addressProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${addressProvider.error}',
                            style: const TextStyle(fontSize: 16, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _startListeningToAddresses,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (addressProvider.addresses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off,
                              size: 64, color: context.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No addresses found',
                            style: context.titleLarge
                                ?.copyWith(color: context.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first address to get started',
                            style: context.bodyMedium
                                ?.copyWith(color: context.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: addressProvider.addresses.length,
                    itemBuilder: (context, index) {
                      final address = addressProvider.addresses[index];
                      return _buildAddressCard(address);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.expand_more,
              size: 28,
              color: context.onBackgroundColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Select a location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.onBackgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    final hasCoordinates = address.latitude != null && address.longitude != null;
    final distance = _calculateDistance(address);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return GestureDetector(
      onTap: () async {
        // Tap to set as primary and go back
        await _setPrimaryAddress(address.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: address.isPrimary
              ? context.primaryColor.withOpacity(0.05)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: address.isPrimary
                ? context.primaryColor.withOpacity(0.3)
                : context.outlineVariant,
            width: address.isPrimary ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and distance column
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAddressTypeIcon(address.type),
                    color: context.primaryColor,
                    size: 20,
                  ),
                ),
                if (distance.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    distance,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.onSurfaceColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 12),

            // Address content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.typeDisplayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      if (address.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRIMARY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.successColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.onSurfaceColor.withOpacity(0.7),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone number: +91-${authProvider.userModel?.phoneNumber.replaceAll('+91', '') ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.onSurfaceColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action buttons row
                  Row(
                    children: [
                      // Options button (three dots)
                      GestureDetector(
                        onTap: () => _showAddressOptions(address),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.more_horiz,
                            size: 18,
                            color: context.onSurfaceColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Share button
                      GestureDetector(
                        onTap: () {
                          // Share functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share feature coming soon')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: context.onSurfaceColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  void _showAddressOptions(AddressModel address) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Address options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.onSurfaceColor,
                    ),
                  ),
                ),
              ),

              // Edit option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: context.onSurfaceColor,
                  ),
                ),
                title: const Text('Edit Address'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  _editAddress(address);
                },
              ),

              // Delete option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: context.onSurfaceColor,
                  ),
                ),
                title: const Text('Delete Address'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAddress(address.id);
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setPrimaryAddress(String addressId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);

      if (authProvider.userModel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // First, remove primary status from all addresses
      final batch = FirebaseFirestore.instance.batch();
      final addressesRef = FirebaseFirestore.instance
          .collection('customer')
          .doc(authProvider.userModel!.uid)
          .collection('addresses');

      for (var address in addressProvider.addresses) {
        batch.update(addressesRef.doc(address.id), {'isPrimary': false});
      }

      // Then set the selected address as primary
      batch.update(addressesRef.doc(addressId), {
        'isPrimary': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Refresh user data in AuthProvider to reflect the change globally
      await authProvider.refreshUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address set as primary'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to previous screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating primary address: $e')),
      );
    }
  }

  Future<void> _editAddress(AddressModel address) async {
    // Navigate to edit address screen
    Navigator.pushNamed(
      context,
      '/edit-address',
      arguments: {
        'addressId': address.id,
        'addressData': address.toMap(),
      },
    );
  }

  Future<void> _deleteAddress(String addressId) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text(
            'Are you sure you want to delete this address? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final addressProvider =
            Provider.of<AddressProvider>(context, listen: false);

        if (authProvider.userModel == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
          return;
        }

        final success = await addressProvider.deleteAddress(
            authProvider.userModel!.uid, addressId);

        if (success) {
          // Refresh user data
          await authProvider.refreshUserData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error deleting address: ${addressProvider.error ?? 'Unknown error'}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting address: $e')),
        );
      }
    }
  }
}
