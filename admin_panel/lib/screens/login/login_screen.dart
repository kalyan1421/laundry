// screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../admin/admin_home.dart';
import '../delivery/delivery_home.dart';
import 'otp_verification_screen.dart';
// import 'package:admin_panel/screens/admin/first_admin_signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.admin;
  bool _isCheckingFirstAdmin = true;
  bool _isFirstAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkFirstAdmin();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstAdmin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool isFirst = await authProvider.checkIfFirstAdmin();
    
    if (mounted) {
      setState(() {
        _isFirstAdmin = isFirst;
        _isCheckingFirstAdmin = false;
      });
    }
  }

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      String phoneNumber = _phoneController.text.trim();
      
      // For delivery partners, we send OTP without role check
      // The role check happens during OTP verification
      bool success;
      if (_selectedRole == UserRole.delivery) {
        // Don't check if delivery partner exists, just send OTP
        success = await authProvider.sendOTP(phoneNumber);
      } else {
        // For admin, check if they exist
        success = await authProvider.sendOTP(phoneNumber, roleToCheck: _selectedRole);
      }
      
      if (success && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              phoneNumber: phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber',
              expectedRole: _selectedRole,
            ),
          ),
        );
      } else if (mounted) {
        _showMessage(authProvider.error ?? 'Failed to send OTP', isError: true);
      }
    }
  }

  // void _navigateToFirstAdminSignup() {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => const FirstAdminSignupScreen(),
  //     ),
  //   );
  // }

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
    if (_isCheckingFirstAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If no admin exists, show signup option
    if (_isFirstAdmin) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Laundry Management',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No admin account found. You need to create the first admin account to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Commented out - First admin signup not needed
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: _navigateToFirstAdminSignup,
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.blue,
                  //       foregroundColor: Colors.white,
                  //       padding: const EdgeInsets.symmetric(vertical: 16),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //     ),
                  //     child: const Text(
                  //       'Create First Admin',
                  //       style: TextStyle(
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                      const Icon(
                        Icons.local_laundry_service,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Laundry Management',
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

                      // Role Selector
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
                          decoration: InputDecoration(
                            labelText: 'Login as',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
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
                      const SizedBox(height: 32),
                      
                      // Send OTP Button
                      CustomButton(
                        text: 'Send OTP',
                        onPressed: _sendOTP,
                        isLoading: authProvider.isLoading,
                        icon: Icons.message,
                      ),
                      
                      const SizedBox(height: 24),

                      // Info text based on selected role
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedRole == UserRole.admin
                                  ? 'Enter your registered admin phone number. An OTP will be sent for verification.'
                                  : 'Enter the phone number provided by your admin. An OTP will be sent for verification.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (_selectedRole == UserRole.delivery) ...[
                        const SizedBox(height: 16),
                        Text(
                          'First time login? Make sure you have your phone number from the admin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
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