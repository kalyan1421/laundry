import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'admin_management_service.dart';
import 'admin_home.dart';

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({super.key});

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final AdminManagementService _adminService = AdminManagementService();
  
  bool _isLoading = false;
  List<String> _selectedPermissions = ['all']; // Default to all permissions
  
  final List<String> _availablePermissions = [
    'all',
    'order_management',
    'user_management',
    'item_management',
    'delivery_management',
    'workshop_management',
    'banner_management',
    'offer_management',
    'reports',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String phoneNumber = _phoneController.text.trim();
      String email = _emailController.text.trim().toLowerCase();
      String name = _nameController.text.trim();
      
      // Check if phone is available
      bool phoneAvailable = await _adminService.isPhoneNumberAvailable(phoneNumber);
      if (!phoneAvailable && mounted) {
        _showMessage('Phone number is already registered', isError: true);
        return;
      }

      // Check if email is available
      bool emailAvailable = await _adminService.isEmailAvailable(email);
      if (!emailAvailable && mounted) {
        _showMessage('Email is already registered', isError: true);
        return;
      }

      // Create the admin
      AdminModel? newAdmin = await _adminService.createAdmin(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        permissions: _selectedPermissions,
      );

      if (newAdmin != null && mounted) {
        _showMessage('Admin created successfully!');
        
        // Navigate back to admin home or admin list
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminHome()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to create admin: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove any non-digit characters for validation
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length != 10) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  Widget _buildPermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select permissions for this admin user:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availablePermissions.map((permission) {
                bool isSelected = _selectedPermissions.contains(permission);
                return FilterChip(
                  label: Text(
                    permission.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (permission == 'all') {
                        if (selected) {
                          _selectedPermissions = ['all'];
                        } else {
                          _selectedPermissions.clear();
                        }
                      } else {
                        if (selected) {
                          _selectedPermissions.remove('all');
                          _selectedPermissions.add(permission);
                        } else {
                          _selectedPermissions.remove(permission);
                        }
                        
                        // If no specific permissions selected, default to all
                        if (_selectedPermissions.isEmpty) {
                          _selectedPermissions = ['all'];
                        }
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.blue,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Admin'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Creating a new admin user. They will be able to access the admin panel with the permissions you assign.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Basic Information
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hintText: 'Enter admin\'s full name',
                      prefixIcon: Icons.person,
                      validator: _validateName,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hintText: 'Enter admin\'s email address',
                      prefixIcon: Icons.email,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hintText: 'Enter 10-digit phone number',
                      prefixIcon: Icons.phone,
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Permissions Section
                    _buildPermissionsSection(),
                    const SizedBox(height: 32),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Create Admin',
                        onPressed: _saveAdmin,
                        icon: Icons.person_add,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}