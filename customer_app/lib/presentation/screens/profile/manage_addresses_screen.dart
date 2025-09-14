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

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  @override
  void initState() {
    super.initState();
    _startListeningToAddresses();
  }

  void _startListeningToAddresses() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    
    if (authProvider.userModel != null) {
      // Start listening to real-time address updates
      addressProvider.startListeningToAddresses(authProvider.userModel!.uid);
    }
  }

  @override
  void dispose() {
    // Stop listening when screen is disposed
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    addressProvider.stopListeningToAddresses();
    super.dispose();
  }

  Future<void> _testCoordinateSaving() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      // Test coordinates - San Francisco coordinates
      const double testLat = 37.7749;
      const double testLng = -122.4194;
      
      print('🧪 TEST: Saving test coordinates...');
      print('🧪 TEST: Latitude: $testLat (Type: ${testLat.runtimeType})');
      print('🧪 TEST: Longitude: $testLng (Type: ${testLng.runtimeType})');

      final testAddressData = {
        'type': 'test',
        'addressLine1': 'Test Address Line 1',
        'addressLine2': 'Test Address Line 2',
        'city': 'Test City',
        'state': 'Test State',
        'pincode': '123456',
        'landmark': 'Test Landmark',
        'latitude': testLat,
        'longitude': testLng,
        'isPrimary': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestData': true, // Flag to identify test data
      };

      print('🧪 TEST: Saving to Firestore...');
      final docRef = await FirebaseFirestore.instance
          .collection('customer')
          .doc(authProvider.userModel!.uid)
          .collection('addresses')
          .add(testAddressData);

      print('🧪 TEST: Document saved with ID: ${docRef.id}');

      // Verify the saved data
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        final savedData = savedDoc.data() as Map<String, dynamic>;
        print('🧪 TEST: Verification - Saved latitude: ${savedData['latitude']} (Type: ${savedData['latitude'].runtimeType})');
        print('🧪 TEST: Verification - Saved longitude: ${savedData['longitude']} (Type: ${savedData['longitude'].runtimeType})');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test coordinates saved successfully!\nLat: ${savedData['latitude']}\nLng: ${savedData['longitude']}'),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        print('🧪 TEST: ERROR - Document not found after saving');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Document not found after saving')),
        );
      }

      // Refresh the address list
      _startListeningToAddresses();

    } catch (e) {
      print('🧪 TEST: ERROR - Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving test coordinates: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Addresses'),
        // AppBar theme is handled by the theme system
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.bug_report,),
          //   onPressed: _testCoordinateSaving,
          // ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startListeningToAddresses,
          ),
        ],
      ),
      body: Consumer<AddressProvider>(
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
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No addresses found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                        'Add your first address to get started',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/add-address-screen');
                        },
                        icon: const Icon(Icons.add_location, color: Colors.white),
                        label: const Text('Add Address', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addressProvider.addresses.length,
            itemBuilder: (context, index) {
              final address = addressProvider.addresses[index];
              return _buildAddressCard(address);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-address-screen');
        },
        // FAB theme is handled by the theme system
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    final hasCoordinates = address.latitude != null && address.longitude != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Type and Primary Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    address.type.toUpperCase(),
                    style: AppTextTheme.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (address.isPrimary) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'PRIMARY',
                      style: AppTextTheme.bodySmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                // Remove test data check since it's not in AddressModel
              ],
            ),
            const SizedBox(height: 12),

            // Formatted Address Display (Door Number, Floor Number, Full Address)
            Text(
              address.fullAddress,
              style: AppTextTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            

            // Coordinates Debug Info
            // const SizedBox(height: 12),
            // Container(
            //   padding: const EdgeInsets.all(12),
            //   decoration: BoxDecoration(
            //     color: hasCoordinates ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            //     borderRadius: BorderRadius.circular(8),
            //     border: Border.all(
            //       color: hasCoordinates ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
            //     ),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(
            //         children: [
            //           Icon(
            //             hasCoordinates ? Icons.location_on : Icons.location_off,
            //             size: 16,
            //             color: hasCoordinates ? Colors.green : Colors.red,
            //           ),
            //           const SizedBox(width: 4),
            //           Text(
            //             'GPS Coordinates',
            //             style: AppTextTheme.bodySmall.copyWith(
            //               fontWeight: FontWeight.bold,
            //               color: hasCoordinates ? Colors.green : Colors.red,
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 4),
            //       if (hasCoordinates) ...[
            //         Text(
            //           'Lat: ${latitude.toString()}',
            //           style: AppTextTheme.bodySmall.copyWith(fontFamily: 'monospace'),
            //         ),
            //         Text(
            //           'Lng: ${longitude.toString()}',
            //           style: AppTextTheme.bodySmall.copyWith(fontFamily: 'monospace'),
            //         ),
            //         Text(
            //           'Type: ${latitude.runtimeType} / ${longitude.runtimeType}',
            //           style: AppTextTheme.bodySmall.copyWith(
            //             fontFamily: 'monospace',
            //             color: Colors.grey[600],
            //           ),
            //         ),
            //       ] else
            //         Text(
            //           'No coordinates saved',
            //           style: AppTextTheme.bodySmall.copyWith(color: Colors.red),
            //         ),
            //     ],
            //   ),
            // ),

            // Action buttons replaced with PopupMenuButton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Primary badge (if applicable)
                if (address.isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Primary',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Three-dot menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'set_primary':
                        _setPrimaryAddress(address.id);
                        break;
                      case 'edit':
                        _editAddress(address);
                        break;
                      case 'delete':
                        _deleteAddress(address.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!address.isPrimary)
                      const PopupMenuItem<String>(
                        value: 'set_primary',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline, size: 20, color: Colors.orange),
                            SizedBox(width: 12),
                            Text('Set as Primary'),
                          ],
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
            
            // Timestamps
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created: ${_formatTimestamp(address.createdAt)}',
                  style: AppTextTheme.bodySmall.copyWith(color: Colors.grey[600]),
                ),
                ],
              // ),
            ),
          ],
        ),)
      // ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary address updated successfully')),
      );
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
        content: const Text('Are you sure you want to delete this address? This action cannot be undone.'),
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
        final addressProvider = Provider.of<AddressProvider>(context, listen: false);
        
        if (authProvider.userModel == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
          return;
        }

        final success = await addressProvider.deleteAddress(authProvider.userModel!.uid, addressId);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting address: ${addressProvider.error ?? 'Unknown error'}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting address: $e')),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return timestamp.toString();
      }
      
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
} 