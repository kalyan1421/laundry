// screens/login/login_screen.dart - Simplified version
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.admin;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      String phoneNumber = _phoneController.text.trim();
      print('🔥 LoginScreen: Sending OTP to $phoneNumber for role: $_selectedRole');
      
      bool success = await authProvider.sendOTP(phoneNumber, roleToCheck: _selectedRole);
      
      if (success && mounted) {
        print('🔥 LoginScreen: OTP sent successfully, navigating to verification');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              phoneNumber: phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber',
              expectedRole: _selectedRole,
            ),
          ),
        );
      } else if (mounted) {
        print('🔥 LoginScreen: OTP send failed: ${authProvider.error}');
        _showMessage(authProvider.error ?? 'Failed to send OTP', isError: true);
      }
    }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Title
                      Image.asset('assests/icons/icon.png', height: 150, width: 150),
                      const SizedBox(height: 24),
                      const Text(
                        'Cloud Ironing Company',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Admin & Delivery Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // // Role Selector
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<UserRole>(
                          value: _selectedRole,
                          onChanged: (UserRole? newValue) {
                            setState(() {
                              _selectedRole = newValue!;
                            });
                          },
                          items: UserRole.values.map((UserRole role) {
                            return DropdownMenuItem<UserRole>(
                              value: role,
                              child: Row(
                                children: [
                                  Icon(
                                    role == UserRole.admin 
                                        ? Icons.admin_panel_settings 
                                        : Icons.delivery_dining,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    role == UserRole.admin ? 'Admin' : 'Delivery Partner',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          decoration: const InputDecoration(
                            labelText: 'Login as',
                            prefixIcon: Icon(Icons.person_outline),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Phone Number Field
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
                            return 'Please enter your phone number';
                          }
                          if (value.length != 10) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      
                      // Phone number help text
                      const SizedBox(height: 20),
                      // Container(
                      //   padding: const EdgeInsets.all(8),
                      //   decoration: BoxDecoration(
                      //     color: Colors.amber[50],
                      //     borderRadius: BorderRadius.circular(4),
                      //     border: Border.all(color: Colors.amber[200]!),
                      //   ),
                      //   child: Text(
                      //     _selectedRole == UserRole.admin 
                      //         ? 'Admin phone from Firebase: 9063290632\nEnter without +91 prefix'
                      //         : 'Enter your 10-digit phone number\nProvided by your admin',
                      //     style: const TextStyle(
                      //       fontSize: 11,
                      //       color: Colors.orange,
                      //       fontWeight: FontWeight.w500,
                      //     ),
                      //     textAlign: TextAlign.center,
                      //   ),
                      // ),
                      
                      // Send OTP Button
                      CustomButton(
                        text: 'Send OTP',
                        onPressed: _sendOTP,
                        isLoading: authProvider.isLoading,
                        icon: Icons.message,
                      ),
                      
                      const SizedBox(height: 24),

                      // Info text based on selected role
                      // Container(
                      //   padding: const EdgeInsets.all(16),
                      //   decoration: BoxDecoration(
                      //     color: Colors.blue[50],
                      //     borderRadius: BorderRadius.circular(8),
                      //     border: Border.all(color: Colors.blue[100]!),
                      //   ),
                      //   child: Column(
                      //     children: [
                      //       Icon(
                      //         Icons.info_outline,
                      //         color: Colors.blue[700],
                      //         size: 20,
                      //       ),
                      //       const SizedBox(height: 8),
                      //       Text(
                      //         _selectedRole == UserRole.admin
                      //             ? 'Admin: Your phone must be registered in the admin collection.\nAn OTP will be sent for verification.'
                      //             : 'Delivery Partner: Enter your phone number.\nAn OTP will be sent for verification.',
                      //         textAlign: TextAlign.center,
                      //         style: TextStyle(
                      //           fontSize: 12,
                      //           color: Colors.blue[700],
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      
                      // Error display
                      if (authProvider.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authProvider.error!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                              IconButton(
                                onPressed: authProvider.clearError,
                                icon: const Icon(Icons.close),
                                iconSize: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}