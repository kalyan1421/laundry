// // screens/admin/first_admin_signup_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import '../../providers/auth_provider.dart';
// import '../../widgets/custom_text_field.dart';
// import '../../widgets/custom_button.dart';

// class FirstAdminSignupScreen extends StatefulWidget {
//   const FirstAdminSignupScreen({super.key});

//   @override
//   State<FirstAdminSignupScreen> createState() => _FirstAdminSignupScreenState();
// }

// class _FirstAdminSignupScreenState extends State<FirstAdminSignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final List<TextEditingController> _otpControllers = 
//       List.generate(6, (index) => TextEditingController());
//   final List<FocusNode> _focusNodes = 
//       List.generate(6, (index) => FocusNode());
  
//   bool _showOTPFields = false;
//   String? _verificationId;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     for (var controller in _otpControllers) {
//       controller.dispose();
//     }
//     for (var focusNode in _focusNodes) {
//       focusNode.dispose();
//     }
//     super.dispose();
//   }

//   Future<void> _sendOTP() async {
//     if (_formKey.currentState!.validate()) {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
//       String phoneNumber = _phoneController.text.trim();
//       if (!phoneNumber.startsWith('+91')) {
//         phoneNumber = '+91$phoneNumber';
//       }

//       bool success = await authProvider.sendOTP(phoneNumber);
      
//       if (success && mounted) {
//         setState(() {
//           _showOTPFields = true;
//           _verificationId = authProvider.verificationId;
//         });
//         _showMessage('OTP sent to $phoneNumber', isError: false);
//       } else if (mounted) {
//         _showMessage(authProvider.error ?? 'Failed to send OTP', isError: true);
//       }
//     }
//   }

//   Future<void> _verifyAndCreateAdmin() async {
//     String otp = _otpControllers.map((controller) => controller.text).join();
    
//     if (otp.length != 6) {
//       _showMessage('Please enter complete OTP', isError: true);
//       return;
//     }

//     if (_verificationId == null) {
//       _showMessage('Verification ID not found. Please request OTP again.', isError: true);
//       return;
//     }

//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
//     String phoneNumber = _phoneController.text.trim();
//     if (!phoneNumber.startsWith('+91')) {
//       phoneNumber = '+91$phoneNumber';
//     }

//     bool success = await authProvider.createFirstAdmin(
//       phoneNumber: phoneNumber,
//       name: _nameController.text.trim(),
//       email: _emailController.text.trim(),
//       verificationId: _verificationId!,
//       otpCode: otp,
//     );

//     if (success && mounted) {
//       _showMessage('Admin account created successfully!', isError: false);
//       // Navigation will be handled by AuthWrapper based on auth state
//     } else if (mounted) {
//       _showMessage(authProvider.error ?? 'Failed to create admin account', isError: true);
//       _clearOTPFields();
//     }
//   }

//   void _clearOTPFields() {
//     for (var controller in _otpControllers) {
//       controller.clear();
//     }
//     if (_focusNodes.isNotEmpty) {
//       _focusNodes[0].requestFocus();
//     }
//   }

//   void _showMessage(String message, {required bool isError}) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: isError ? Colors.red : Colors.green,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Consumer<AuthProvider>(
//             builder: (context, authProvider, _) {
//               return Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const SizedBox(height: 40),
                    
//                     // Header
//                     const Icon(
//                       Icons.admin_panel_settings,
//                       size: 80,
//                       color: Colors.blue,
//                     ),
//                     const SizedBox(height: 24),
//                     const Text(
//                       'Setup First Admin',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Create the first admin account for your laundry management system',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 48),

//                     // Form fields
//                     if (!_showOTPFields) ...[
//                       CustomTextField(
//                         controller: _nameController,
//                         label: 'Full Name',
//                         prefixIcon: Icons.person,
//                         textCapitalization: TextCapitalization.words,
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'Please enter your full name';
//                           }
//                           if (value.trim().length < 2) {
//                             return 'Name must be at least 2 characters';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),
                      
//                       CustomTextField(
//                         controller: _emailController,
//                         label: 'Email Address',
//                         prefixIcon: Icons.email,
//                         keyboardType: TextInputType.emailAddress,
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'Please enter your email';
//                           }
//                           if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                             return 'Please enter a valid email';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),
                      
//                       CustomTextField(
//                         controller: _phoneController,
//                         label: 'Phone Number',
//                         prefixIcon: Icons.phone,
//                         keyboardType: TextInputType.phone,
//                         inputFormatters: [
//                           FilteringTextInputFormatter.digitsOnly,
//                           LengthLimitingTextInputFormatter(10),
//                         ],
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your phone number';
//                           }
//                           if (value.length != 10) {
//                             return 'Please enter a valid 10-digit phone number';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 32),
                      
//                       CustomButton(
//                         text: 'Send OTP',
//                         onPressed: _sendOTP,
//                         isLoading: authProvider.isLoading && !_showOTPFields,
//                       ),
//                     ],

//                     // OTP Fields
//                     if (_showOTPFields) ...[
//                       const Text(
//                         'Enter OTP',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'OTP sent to +91${_phoneController.text}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
                      
//                       // OTP Input Fields
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: List.generate(6, (index) {
//                           return SizedBox(
//                             width: 45,
//                             height: 55,
//                             child: TextField(
//                               controller: _otpControllers[index],
//                               focusNode: _focusNodes[index],
//                               textAlign: TextAlign.center,
//                               enabled: !authProvider.isLoading,
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               keyboardType: TextInputType.number,
//                               inputFormatters: [
//                                 FilteringTextInputFormatter.digitsOnly,
//                                 LengthLimitingTextInputFormatter(1),
//                               ],
//                               decoration: InputDecoration(
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(color: Colors.blue),
//                                 ),
//                               ),
//                               onChanged: (value) {
//                                 if (value.isNotEmpty && index < 5) {
//                                   _focusNodes[index + 1].requestFocus();
//                                 } else if (value.isEmpty && index > 0) {
//                                   _focusNodes[index - 1].requestFocus();
//                                 }
                                
//                                 // Auto-verify when all fields are filled
//                                 String otp = _otpControllers.map((controller) => controller.text).join();
//                                 if (otp.length == 6) {
//                                   Future.delayed(const Duration(milliseconds: 500), () {
//                                     _verifyAndCreateAdmin();
//                                   });
//                                 }
//                               },
//                             ),
//                           );
//                         }),
//                       ),
//                       const SizedBox(height: 32),
                      
//                       CustomButton(
//                         text: 'Create Admin Account',
//                         onPressed: _verifyAndCreateAdmin,
//                         isLoading: authProvider.isLoading && _showOTPFields,
//                       ),
//                       const SizedBox(height: 16),
                      
//                       TextButton(
//                         onPressed: () {
//                           setState(() {
//                             _showOTPFields = false;
//                             _verificationId = null;
//                           });
//                           _clearOTPFields();
//                           authProvider.resetOTPState();
//                         },
//                         child: const Text('Change Phone Number'),
//                       ),
//                     ],
                    
//                     const SizedBox(height: 24),
                    
//                     // Footer
//                     const Text(
//                       'This will create the first admin account. After this, you can add more admins and delivery partners from the admin panel.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }