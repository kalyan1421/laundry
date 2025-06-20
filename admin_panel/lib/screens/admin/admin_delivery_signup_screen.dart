import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/delivery_partner_service.dart';
import '../../models/delivery_partner_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/rendering.dart';
import 'admin_home.dart';

class AddDeliveryPartnerScreen extends StatefulWidget {
  const AddDeliveryPartnerScreen({super.key});

  @override
  State<AddDeliveryPartnerScreen> createState() => _AddDeliveryPartnerScreenState();
}

class _AddDeliveryPartnerScreenState extends State<AddDeliveryPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  
  final DeliveryPartnerService _deliveryService = DeliveryPartnerService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _createDeliveryPartner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check availability of phone, email, and license
      String phoneNumber = _phoneController.text.trim();
      String email = _emailController.text.trim();
      String licenseNumber = _licenseController.text.trim().toUpperCase();

      // Check if phone is available
      bool phoneAvailable = await _deliveryService.isPhoneNumberAvailable(phoneNumber);
      if (!phoneAvailable && mounted) {
        _showMessage('Phone number is already registered', isError: true);
        return;
      }

      // Check if email is available
      bool emailAvailable = await _deliveryService.isEmailAvailable(email);
      if (!emailAvailable && mounted) {
        _showMessage('Email is already registered', isError: true);
        return;
      }

      // Check if license is available
      bool licenseAvailable = await _deliveryService.isLicenseNumberAvailable(licenseNumber);
      if (!licenseAvailable && mounted) {
        _showMessage('License number is already registered', isError: true);
        return;
      }

      // Get current admin UID for tracking who created this partner
      final authProvider = context.read<AuthProvider>();
      String? createdByUid = authProvider.user?.uid;

      DeliveryPartnerModel? newPartner = await _deliveryService.createDeliveryPartnerByAdmin(
        name: _nameController.text.trim(),
        email: email,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
        createdByUid: createdByUid,
      );

      if (newPartner != null && mounted) {
        _showMessage('Delivery partner created successfully!', isError: false);
        
        // Show instructions dialog
        _showInstructionsDialog(newPartner);
        
        // Clear form
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to create delivery partner: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showInstructionsDialog(DeliveryPartnerModel partner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Partner Created Successfully',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery partner "${partner.name}" has been created successfully.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (partner.registrationToken != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'One-Time Registration Token',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SelectableText(
                            partner.registrationToken!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: partner.registrationToken!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Token copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login Instructions for ${partner.name}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildInstructionItem('1', 'Download the delivery partner app'),
                    _buildInstructionItem('2', 'Select "Delivery" role during login'),
                    _buildInstructionItem('3', 'Enter phone number: ${partner.formattedPhone}'),
                    _buildInstructionItem('4', 'Verify with the OTP received on the phone'),
                    _buildInstructionItem(
                      '5',
                      'Enter the one-time registration token shown above',
                    ),
                    _buildInstructionItem('6', 'Complete profile setup if required'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The delivery partner must have access to the registered phone number to receive OTP for login.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Add Another'),
          ),
          ElevatedButton(
            onPressed: () {
             Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const AdminHome(),
              ),
            );
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _licenseController.clear();
    _formKey.currentState?.reset();
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.delivery_dining,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Add New Delivery Partner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new delivery partner account. They will login using their phone number.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length != 10) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _licenseController,
                label: 'Delivery License Number',
                prefixIcon: Icons.card_membership,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter delivery license number';
                  }
                  if (value.trim().length < 6) {
                    return 'License number must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Create button
              CustomButton(
                text: 'Create Delivery Partner',
                onPressed: _createDeliveryPartner,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: 16),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Important Information:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• The delivery partner will login using their phone number',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• OTP will be sent to their phone for verification',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• They must have access to the registered phone number',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• All details can be updated later by the delivery partner',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}