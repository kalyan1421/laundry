// lib/screens/auth/login_screen.dart
import 'package:customer_app/core/utils/validators.dart';
import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/presentation/screens/auth/otp_verification_screen.dart';
import 'package:customer_app/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart' hide TextButton;
import 'package:flutter/material.dart' as material show TextButton;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Listen to auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Clear any previous errors
      authProvider.clearError();
      
      // Reset OTP state when coming to login screen
      authProvider.resetOTPState();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Remove focus from text field
    FocusScope.of(context).unfocus();
    
    try {
      await authProvider.sendOTP(_phoneController.text.trim());
       AppRoutes.navigateToOTP(context, _phoneController.text.trim());
        // Navigator.push(context, MaterialPageRoute(builder: (context) =>  HomeScreen()));
      // Navigate to OTP screen if OTP was sent successfully
      if (authProvider.otpStatus == OTPStatus.sent) {
        // Create the full phone number with country code
        final fullPhoneNumber = '+91${_phoneController.text.trim()}';
        print(authProvider.otpStatus.toString());
        // Navigate using the route helper
        // AppRoutes.navigateToOTP(context, fullPhoneNumber);
      }
    } catch (e) {
      // Error handling is managed by the provider
      // Show snackbar for additional feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to send OTP'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            material.TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Show error dialog if there's an error
            if (authProvider.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (authProvider.errorMessage!.isNotEmpty) {
                  _showErrorDialog(authProvider.errorMessage!);
                  authProvider.clearError();
                }
              });
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    
                    // Logo and welcome text
                    _buildHeader(),
                    
                    const SizedBox(height: 80),
                    
                    // Phone number input
                    _buildPhoneInput(authProvider),
                    
                    const SizedBox(height: 24),
                    
                    // Continue button
                    _buildContinueButton(authProvider),
                    
                    const SizedBox(height: 40),
                    
                    // Social login section
                    _buildSocialLogin(),
                    
                    const Spacer(),
                    
                    // Already have account
                    _buildFooter(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Iron icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              // Iron body
              Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7B8A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Iron handle
              Positioned(
                top: 20,
                left: 25,
                child: Container(
                  width: 30,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7B8A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Steam lines
              Positioned(
                top: 12,
                left: 20,
                child: Column(
                  children: [
                    _buildSteamLine(),
                    const SizedBox(height: 2),
                    _buildSteamLine(),
                    const SizedBox(height: 2),
                    _buildSteamLine(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome to CLOUD IRONING',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Fresh Ironing, delivered to your doorstep',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _phoneFocusNode.hasFocus 
                  ? const Color(0xFF4299E1) 
                  : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              // Country code
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  enabled: !authProvider.isLoading,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: '9876 543210',
                    hintStyle: TextStyle(
                      color: Color(0xFFA0AEC0),
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 16,
                    ),
                  ),
                  validator: Validators.validatePhoneNumber,
                  onChanged: (value) {
                    setState(() {});
                    // Clear error when user starts typing
                    if (authProvider.errorMessage != null) {
                      authProvider.clearError();
                    }
                  },
                  onFieldSubmitted: (_) {
                    if (_phoneController.text.length == 10) {
                      _sendOTP();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Show loading indicator below input when sending
        if (authProvider.otpStatus == OTPStatus.sending)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: InlineLoadingWidget(
              message: 'Sending OTP...',
              size: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildContinueButton(AuthProvider authProvider) {
    bool isValid = _phoneController.text.length == 10;
    bool isLoading = authProvider.isLoading || authProvider.otpStatus == OTPStatus.sending;
    
    return CustomButton(
      text: 'Continue',
      onPressed: isValid && !isLoading ? _sendOTP : null,
      isLoading: isLoading,
      backgroundColor: const Color(0xFF4A5568),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        const Text(
          'or login with',
          style: TextStyle(
            color: Color(0xFF718096),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        // Social login buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // More options button
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.more_horiz,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(width: 16),
            // Google login button
            GestureDetector(
              onTap: () {
                // TODO: Implement Google Sign In
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Google Sign In coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have account? ',
          style: TextStyle(
            color: Color(0xFF718096),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            // Handle existing user login
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Just enter your phone number to login!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text(
            'Login',
            style: TextStyle(
              color: Color(0xFF4299E1),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSteamLine() {
    return Container(
      width: 10,
      height: 1.5,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}