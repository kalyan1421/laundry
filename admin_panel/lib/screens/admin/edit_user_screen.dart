import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/address_model.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;

  const EditUserScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  List<AddressModel> _customerAddresses = [];
  bool _isLoadingAddresses = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _loadCustomerAddresses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerAddresses() async {
    try {
      // First try to get addresses ordered by isPrimary and createdAt
      QuerySnapshot addressesSnapshot;
      try {
        addressesSnapshot = await FirebaseFirestore.instance
            .collection('customer')
            .doc(widget.user.uid)
            .collection('addresses')
            .orderBy('isPrimary', descending: true)
            .orderBy('createdAt', descending: false)
            .get();
      } catch (orderByError) {
        // If ordering fails (e.g., missing index), get all addresses without ordering
        print('OrderBy failed, fetching all addresses: $orderByError');
        addressesSnapshot = await FirebaseFirestore.instance
            .collection('customer')
            .doc(widget.user.uid)
            .collection('addresses')
            .get();
      }

      setState(() {
        _customerAddresses = addressesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AddressModel.fromFirestore(data, doc.id);
        }).toList();
        
        // Sort addresses manually if we couldn't order in query
        _customerAddresses.sort((a, b) {
          // Primary addresses first
          if (a.isPrimary && !b.isPrimary) return -1;
          if (!a.isPrimary && b.isPrimary) return 1;
          
          // Then by creation date (newest first if no createdAt)
          if (a.createdAt != null && b.createdAt != null) {
            return a.createdAt!.compareTo(b.createdAt!);
          } else if (a.createdAt != null) {
            return -1;
          } else if (b.createdAt != null) {
            return 1;
          }
          
          return 0;
        });
        
        _isLoadingAddresses = false;
      });
      
      print('Loaded ${_customerAddresses.length} addresses for user ${widget.user.uid}');
    } catch (e) {
      print('Error loading customer addresses: $e');
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  Future<void> _saveUserDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        // Update user details in Firestore directly (phone number is read-only)
        await FirebaseFirestore.instance
            .collection('customer')
            .doc(widget.user.uid)
            .update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          // phoneNumber is not updated as it's read-only
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate successful update
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.user.uid)
          .collection('addresses')
          .doc(addressId)
          .delete();

      // Reload addresses
      await _loadCustomerAddresses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editAddress(AddressModel address) async {
    await showDialog(
      context: context,
      builder: (context) => EditAddressDialog(
        address: address,
        userId: widget.user.uid,
        onAddressUpdated: _loadCustomerAddresses,
      ),
    );
  }

  Future<void> _addNewAddress() async {
    await showDialog(
      context: context,
      builder: (context) => EditAddressDialog(
        address: null, // New address
        userId: widget.user.uid,
        onAddressUpdated: _loadCustomerAddresses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.user.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.location_on), text: 'Addresses'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildAddressesTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Read Only)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        suffixIcon: Icon(Icons.lock, color: Colors.grey),
                      ),
                      keyboardType: TextInputType.phone,
                      readOnly: true,
                      enabled: false,
                      style: TextStyle(color: Colors.grey[600]),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveUserDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressesTab() {
    return Column(
      children: [
        // Add Address Button
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addNewAddress,
              icon: const Icon(Icons.add),
              label: const Text('Add New Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // Addresses List
        Expanded(
          child: _isLoadingAddresses
              ? const Center(child: CircularProgressIndicator())
              : _customerAddresses.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No addresses found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _customerAddresses.length,
                      itemBuilder: (context, index) {
                        final address = _customerAddresses[index];
                        return _buildAddressCard(address, index);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(AddressModel address, int index) {
    final isPrimary = address.isPrimary;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPrimary ? Icons.home : Icons.location_on,
                  color: isPrimary ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPrimary ? 'Primary Address (${address.typeDisplayName})' : '${address.typeDisplayName} Address',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Primary',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editAddress(address);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(address.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAddressDetails(address),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressDetails(AddressModel address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          address.fullAddress,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if (address.latitude != null && address.longitude != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Coordinates: ${address.latitude!.toStringAsFixed(6)}, ${address.longitude!.toStringAsFixed(6)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showDeleteConfirmation(String addressId) {
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
              Navigator.pop(context);
              _deleteAddress(addressId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class EditAddressDialog extends StatefulWidget {
  final AddressModel? address;
  final String userId;
  final VoidCallback onAddressUpdated;

  const EditAddressDialog({
    Key? key,
    required this.address,
    required this.userId,
    required this.onAddressUpdated,
  }) : super(key: key);

  @override
  _EditAddressDialogState createState() => _EditAddressDialogState();
}

class _EditAddressDialogState extends State<EditAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _doorNumberController;
  late TextEditingController _floorNumberController;
  late TextEditingController _apartmentController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  String _selectedType = 'home';
  bool _isPrimary = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _doorNumberController = TextEditingController(text: address?.doorNumber ?? '');
    _floorNumberController = TextEditingController(text: address?.floorNumber ?? '');
    _apartmentController = TextEditingController(text: address?.apartmentName ?? '');
    _addressLine1Controller = TextEditingController(text: address?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: address?.addressLine2 ?? '');
    _landmarkController = TextEditingController(text: address?.landmark ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _pincodeController = TextEditingController(text: address?.pincode ?? '');
    _selectedType = address?.type ?? 'home';
    _isPrimary = address?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _doorNumberController.dispose();
    _floorNumberController.dispose();
    _apartmentController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        final addressData = {
          'type': _selectedType,
          'addressType': _selectedType, // For backward compatibility
          'doorNumber': _doorNumberController.text.trim(),
          'floorNumber': _floorNumberController.text.trim(),
          'apartmentName': _apartmentController.text.trim(),
          'addressLine1': _addressLine1Controller.text.trim(),
          'addressLine2': _addressLine2Controller.text.trim(),
          'landmark': _landmarkController.text.trim(),
          'nearbyLandmark': _landmarkController.text.trim(), // For backward compatibility
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'country': 'India',
          'isPrimary': _isPrimary,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.address == null) {
          // Add new address
          addressData['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('customer')
              .doc(widget.userId)
              .collection('addresses')
              .add(addressData);
        } else {
          // Update existing address
          await FirebaseFirestore.instance
              .collection('customer')
              .doc(widget.userId)
              .collection('addresses')
              .doc(widget.address!.id)
              .update(addressData);
        }

        widget.onAddressUpdated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.address == null 
                  ? 'Address added successfully' 
                  : 'Address updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save address: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.address == null ? 'Add New Address' : 'Edit Address',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Dialog Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                                      child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Address Type Selection
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Address Type *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'home', child: Text('Home')),
                              DropdownMenuItem(value: 'work', child: Text('Work')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value ?? 'home';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select address type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _doorNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Door Number *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.door_front_door),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter door number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _floorNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Floor Number',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.layers),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _apartmentController,
                            decoration: const InputDecoration(
                              labelText: 'Apartment/Building Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.apartment),
                            ),
                          ),
                                                  const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressLine1Controller,
                            decoration: const InputDecoration(
                              labelText: 'Street Address *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              hintText: 'Enter street name and area',
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter street address';
                              }
                              return null;
                            },
                          ),
                                                  const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressLine2Controller,
                            decoration: const InputDecoration(
                              labelText: 'Additional Address Info',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.add_location),
                              hintText: 'Optional additional address details',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _landmarkController,
                            decoration: const InputDecoration(
                              labelText: 'Nearby Landmark',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.place),
                              hintText: 'E.g., Near City Mall, Opposite Bank',
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                                              child: TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    labelText: 'City *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_city),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter city';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _pincodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Pincode *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.pin_drop),
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter pincode';
                                    }
                                    if (value.length != 6) {
                                      return 'Enter valid 6-digit pincode';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                                                  TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter state';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: CheckboxListTile(
                              title: const Text(
                                'Set as Primary Address',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: const Text(
                                'This will be used as the default address for orders',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: _isPrimary,
                              onChanged: (value) {
                                setState(() {
                                  _isPrimary = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Dialog Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}