import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageCustomerAddressScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const ManageCustomerAddressScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<ManageCustomerAddressScreen> createState() => _ManageCustomerAddressScreenState();
}

class _ManageCustomerAddressScreenState extends State<ManageCustomerAddressScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('customer')
          .doc(widget.customerId)
          .collection('addresses')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _addresses = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load addresses');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      await _firestore
          .collection('customer')
          .doc(widget.customerId)
          .collection('addresses')
          .doc(addressId)
          .delete();

      _showSuccessSnackBar('Address deleted successfully');
      _loadAddresses(); // Refresh the list
    } catch (e) {
      print('Error deleting address: $e');
      _showErrorSnackBar('Failed to delete address');
    }
  }

  void _showDeleteConfirmation(String addressId, String addressText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this address?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                addressText,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(addressId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAddressDialog(
        customerId: widget.customerId,
        onAddressAdded: () {
          _loadAddresses();
          _showSuccessSnackBar('Address added successfully');
        },
      ),
    );
  }

  void _showEditAddressDialog(Map<String, dynamic> address) {
    showDialog(
      context: context,
      builder: (context) => EditAddressDialog(
        customerId: widget.customerId,
        address: address,
        onAddressUpdated: () {
          _loadAddresses();
          _showSuccessSnackBar('Address updated successfully');
        },
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    List<String> parts = [];
    
    if (address['doorNumber'] != null && address['doorNumber'].toString().isNotEmpty) {
      parts.add(address['doorNumber'].toString());
    }
    if (address['apartmentName'] != null && address['apartmentName'].toString().isNotEmpty) {
      parts.add(address['apartmentName'].toString());
    }
    if (address['addressLine1'] != null && address['addressLine1'].toString().isNotEmpty) {
      parts.add(address['addressLine1'].toString());
    }
    if (address['addressLine2'] != null && address['addressLine2'].toString().isNotEmpty) {
      parts.add(address['addressLine2'].toString());
    }
    if (address['nearbyLandmark'] != null && address['nearbyLandmark'].toString().isNotEmpty) {
      parts.add('Near ${address['nearbyLandmark']}');
    }
    if (address['city'] != null && address['pincode'] != null) {
      parts.add('${address['city']} - ${address['pincode']}');
    }
    if (address['state'] != null && address['state'].toString().isNotEmpty) {
      parts.add(address['state'].toString());
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Address details not available';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Addresses - ${widget.customerName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with customer info and add button
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Customer ID: ${widget.customerId}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddAddressDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Address'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Addresses list
                Expanded(
                  child: _addresses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No addresses found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add an address to get started',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            final addressText = _formatAddress(address);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Address header with actions
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.blue[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Address ${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _showEditAddressDialog(address),
                                          icon: const Icon(Icons.edit, size: 20),
                                          color: Colors.blue[600],
                                          tooltip: 'Edit Address',
                                        ),
                                        IconButton(
                                          onPressed: () => _showDeleteConfirmation(
                                            address['id'],
                                            addressText,
                                          ),
                                          icon: const Icon(Icons.delete, size: 20),
                                          color: Colors.red[600],
                                          tooltip: 'Delete Address',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Address details
                                    Text(
                                      addressText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                    
                                    // Additional info
                                    if (address['createdAt'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Added: ${DateFormat('MMM d, yyyy').format(address['createdAt'].toDate())}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// Add Address Dialog
class AddAddressDialog extends StatefulWidget {
  final String customerId;
  final VoidCallback onAddressAdded;

  const AddAddressDialog({
    super.key,
    required this.customerId,
    required this.onAddressAdded,
  });

  @override
  State<AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _doorNumberController = TextEditingController();
  final _apartmentNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  bool _isSaving = false;

  @override
  void dispose() {
    _doorNumberController.dispose();
    _apartmentNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.customerId)
          .collection('addresses')
          .add({
        'doorNumber': _doorNumberController.text.trim(),
        'apartmentName': _apartmentNameController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'nearbyLandmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': 'admin',
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onAddressAdded();
      }
    } catch (e) {
      print('Error saving address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Address'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _doorNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Door Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.door_front_door),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _apartmentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Apartment/Building',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.apartment),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _addressLine1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 1',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address Line 1 is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _addressLine2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 2',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_work),
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _landmarkController,
                  decoration: const InputDecoration(
                    labelText: 'Nearby Landmark',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pincodeController,
                        decoration: const InputDecoration(
                          labelText: 'Pincode',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin_drop),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Pincode is required';
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
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Add Address'),
        ),
      ],
    );
  }
}

// Edit Address Dialog
class EditAddressDialog extends StatefulWidget {
  final String customerId;
  final Map<String, dynamic> address;
  final VoidCallback onAddressUpdated;

  const EditAddressDialog({
    super.key,
    required this.customerId,
    required this.address,
    required this.onAddressUpdated,
  });

  @override
  State<EditAddressDialog> createState() => _EditAddressDialogState();
}

class _EditAddressDialogState extends State<EditAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _doorNumberController;
  late TextEditingController _apartmentNameController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _doorNumberController = TextEditingController(text: widget.address['doorNumber']?.toString() ?? '');
    _apartmentNameController = TextEditingController(text: widget.address['apartmentName']?.toString() ?? '');
    _addressLine1Controller = TextEditingController(text: widget.address['addressLine1']?.toString() ?? '');
    _addressLine2Controller = TextEditingController(text: widget.address['addressLine2']?.toString() ?? '');
    _landmarkController = TextEditingController(text: widget.address['nearbyLandmark']?.toString() ?? '');
    _cityController = TextEditingController(text: widget.address['city']?.toString() ?? '');
    _stateController = TextEditingController(text: widget.address['state']?.toString() ?? '');
    _pincodeController = TextEditingController(text: widget.address['pincode']?.toString() ?? '');
  }

  @override
  void dispose() {
    _doorNumberController.dispose();
    _apartmentNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.customerId)
          .collection('addresses')
          .doc(widget.address['id'])
          .update({
        'doorNumber': _doorNumberController.text.trim(),
        'apartmentName': _apartmentNameController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'nearbyLandmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin',
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onAddressUpdated();
      }
    } catch (e) {
      print('Error updating address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Address'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _doorNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Door Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.door_front_door),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _apartmentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Apartment/Building',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.apartment),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _addressLine1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 1',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address Line 1 is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _addressLine2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 2',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_work),
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _landmarkController,
                  decoration: const InputDecoration(
                    labelText: 'Nearby Landmark',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pincodeController,
                        decoration: const InputDecoration(
                          labelText: 'Pincode',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin_drop),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Pincode is required';
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
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _updateAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Update Address'),
        ),
      ],
    );
  }
} 