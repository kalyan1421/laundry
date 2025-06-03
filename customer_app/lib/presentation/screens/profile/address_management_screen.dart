
// lib/screens/profile/address_management_screen.dart
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/data/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/common/custom_button.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({Key? key}) : super(key: key);

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  List<AddressModel> addresses = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    // TODO: Load addresses from Firestore
    setState(() {
      addresses = [];
    });
  }

  void _addNewAddress() {
    Navigator.pushNamed(context, '/add-address').then((_) {
      _loadAddresses();
    });
  }

  void _editAddress(AddressModel address) {
    Navigator.pushNamed(
      context, 
      '/edit-address',
      arguments: address,
    ).then((_) {
      _loadAddresses();
    });
  }

  void _deleteAddress(AddressModel address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete address from Firestore
              Navigator.pop(context);
              _loadAddresses();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Addresses'),
      ),
      body: Column(
        children: [
          // Add new address button
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: CustomButton(
              text: 'Add New Address',
              icon: Icons.add_location_alt,
              onPressed: _addNewAddress,
            ),
          ),
          
          // Address list
          Expanded(
            child: addresses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                    ),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      return _buildAddressCard(addresses[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.spacingM),
          const Text(
            'No addresses found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(AppConstants.textSecondaryValue),
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          const Text(
            'Add your first address to get started',
            style: TextStyle(
              color: Color(AppConstants.textSecondaryValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: address.isPrimary 
                        ? const Color(AppConstants.primaryColorValue)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    address.typeDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: address.isPrimary 
                          ? Colors.white 
                          : const Color(AppConstants.textSecondaryValue),
                    ),
                  ),
                ),
                if (address.isPrimary) ...[
                  const SizedBox(width: AppConstants.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppConstants.accentColorValue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Primary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editAddress(address);
                        break;
                      case 'delete':
                        _deleteAddress(address);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              address.fullAddress,
              style: const TextStyle(
                fontSize: 14,
                color: Color(AppConstants.textPrimaryValue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
