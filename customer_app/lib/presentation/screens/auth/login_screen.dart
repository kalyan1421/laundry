// lib/screens/auth/login_screen.dart
import 'package:customer_app/core/utils/validators.dart';
import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/core/theme/app_typography.dart';
import 'package:customer_app/core/constants/font_constants.dart';
import 'package:customer_app/core/utils/text_utils.dart';
import 'package:flutter/material.dart' hide TextButton;
import 'package:flutter/material.dart' as material show TextButton;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/error_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Rate limiting countdown
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isRateLimited = false;

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
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    setState(() {
      _isRateLimited = true;
      _remainingSeconds = seconds;
    });
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isRateLimited = false;
          timer.cancel();
        }
      });
    });
  }
  
  void _extractCountdownFromError(String errorMessage) {
    // Extract seconds from rate limit message
    final regex = RegExp(r'(\d+) seconds');
    final match = regex.firstMatch(errorMessage);
    if (match != null) {
      final seconds = int.tryParse(match.group(1) ?? '0') ?? 60;
      _startCountdown(seconds);
    } else {
      _startCountdown(60); // Default to 60 seconds
    }
  }

  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRateLimited) return; // Don't send if rate limited

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Remove focus from text field
    FocusScope.of(context).unfocus();

    try {
      await authProvider.sendOTP(_phoneController.text.trim());

      // Check if OTP was sent successfully and navigate
      if (mounted && authProvider.otpStatus == OTPStatus.sent) {
        // Create the full phone number with country code
        final fullPhoneNumber = '+91${_phoneController.text.trim()}';

        // Navigate using the route helper
        AppRoutes.navigateToOTP(context, fullPhoneNumber);
      }
    } catch (e) {
      // Error handling is managed by the provider
      print('Error sending OTP: $e');
      
      // Check if it's a rate limit error and start countdown
      final errorMessage = authProvider.errorMessage ?? '';
      if (errorMessage.contains('wait') && errorMessage.contains('seconds')) {
        _extractCountdownFromError(errorMessage);
      } else if (errorMessage.contains('Too many requests')) {
        _startCountdown(15 * 60); // 15 minutes for too-many-requests
      } else if (errorMessage.contains('Server rate limit')) {
        _startCountdown(5 * 60); // 5 minutes for server rate limit
      } else if (errorMessage.contains('blocked')) {
        _startCountdown(2 * 60 * 60); // 2 hours for account blocked
      }
      
      // Show snackbar for additional feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Failed to send OTP',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: AppTypography.headlineSmall.copyWith(
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF4A5568),
            ),
          ),
          actions: [
            material.TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppTypography.labelLarge.copyWith(
                  color: const Color(0xFF4299E1),
                  fontWeight: FontConstants.semibold,
                ),
              ),
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
            // Listen for OTP status changes for navigation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (authProvider.otpStatus == OTPStatus.sent && 
                  _phoneController.text.isNotEmpty) {
                final fullPhoneNumber = '+91${_phoneController.text.trim()}';
                AppRoutes.navigateToOTP(context, fullPhoneNumber);
              }
              
              // Show error dialog if there's an error (but avoid during navigation)
              if (authProvider.errorMessage != null && 
                  authProvider.errorMessage!.isNotEmpty &&
                  authProvider.otpStatus != OTPStatus.sent) {
                _showErrorDialog(authProvider.errorMessage!);
                authProvider.clearError();
              }
            });

            return SingleChildScrollView( // Fixed: Added scroll view to prevent overflow
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 48,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20), // Reduced from 40

                        // Logo and welcome text
                        _buildHeader(),

                        const SizedBox(height: 16), // Reduced from 20

                        // Phone number input
                        _buildPhoneInput(authProvider),

                        const SizedBox(height: 40), // Reduced from 60

                        // Continue button
                        _buildContinueButton(authProvider),

                        const SizedBox(height: 24), // Reduced from 35

                        // Social login section
                        _buildSocialLogin(),

                        const Spacer(),

                        // Already have account
                        _buildFooter(),
                        
                        const SizedBox(height: 16), // Add bottom spacing
                      ],
                    ),
                  ),
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
        // Iron icon - Reduced size
        Container(
          width: 200, // Reduced from 250
          height: 200, // Reduced from 250
          child: Image.asset("assets/icons/icon.png"),
        ),

        const SizedBox(height: 8),

        // App title with SF Pro Display
        AppText.appTitle('Welcome to CLOUD IRONING'),

        const SizedBox(height: 6),

        // Subtitle with SF Pro Display
        AppText.subtitle('Fresh Ironing, delivered to your doorstep'),
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
              color:
                  _phoneFocusNode.hasFocus
                      ? const Color(0xFF4299E1)
                      : Colors.grey[300]!,
              width: _phoneFocusNode.hasFocus ? 2 : 1,
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
                child: Text(
                  '+91',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontConstants.medium,
                    color: const Color(0xFF2D3748),
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
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontConstants.medium,
                    color: const Color(0xFF2D3748),
                  ),
                  decoration: InputDecoration(
                    hintText: '9876 543210',
                    hintStyle: AppTypography.bodyLarge.copyWith(
                      color: const Color(0xFFA0AEC0),
                      fontWeight: FontConstants.regular,
                    ),
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
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
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sending OTP...',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContinueButton(AuthProvider authProvider) {
    bool isValid = _phoneController.text.length == 10;
    bool isLoading =
        authProvider.isLoading || authProvider.otpStatus == OTPStatus.sending;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isValid && !isLoading && !_isRateLimited ? _sendOTP : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isValid && !isLoading && !_isRateLimited
                  ? const Color(0xFF0F3057)
                  : const Color(0xFF0F3057).withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isRateLimited
            ? Text(
                'Try again in ${_remainingSeconds}s',
                style: AppTypography.button.copyWith(color: Colors.white),
              )
            : isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Continue',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Text(
          'or login with',
          style: AppTypography.bodyMedium.copyWith(
            color: const Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 24),

        // Social login buttons
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Google Sign In coming soon!',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'G',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontConstants.bold,
                  color: const Color(0xFF4285F4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have account? ',
          style: AppTypography.bodyMedium.copyWith(
            color: const Color(0xFF718096),
          ),
        ),
        GestureDetector(
          onTap: () {
            // Handle existing user login
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Just enter your phone number to login!',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Text(
            'Login',
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF4299E1),
              fontWeight: FontConstants.medium,
            ),
          ),
        ),
      ],
    );
  }
}