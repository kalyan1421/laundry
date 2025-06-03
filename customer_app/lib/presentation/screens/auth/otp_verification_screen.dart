// lib/screens/auth/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  
  const OTPVerificationScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  // Static method to extract phone number from route arguments
  static Widget fromRoute(BuildContext context) {
    final phoneNumber = ModalRoute.of(context)?.settings.arguments as String?;
    
    if (phoneNumber == null) {
      // If no phone number is provided, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return OTPVerificationScreen(phoneNumber: phoneNumber);
  }

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = 
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = 
      List.generate(6, (index) => FocusNode());
  
  int _resendCooldown = 30;
  Timer? _timer;
  bool _isAutoVerifying = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    
    // Listen to auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Navigate to welcome/home screen if verification is successful
      authProvider.addListener(_handleAuthStateChange);
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    
    // Remove listener
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_handleAuthStateChange);
    
    super.dispose();
  }

  void _handleAuthStateChange() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.authStatus == AuthStatus.authenticated && 
        authProvider.otpStatus == OTPStatus.verified) {
      
      // Clear OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      
      // Navigate based on user status
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authProvider.isNewUser || !authProvider.isProfileComplete) {
          Navigator.pushReplacementNamed(context, '/welcome');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    }
  }

  void _startResendTimer() {
    _resendCooldown = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCooldown > 0) {
            _resendCooldown--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      _showErrorSnackBar('Please enter complete OTP');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Remove focus from text fields
    FocusScope.of(context).unfocus();
    
    try {
      bool success = await authProvider.verifyOTP(otp);
      
      if (!success && authProvider.errorMessage != null) {
        _showErrorSnackBar(authProvider.errorMessage!);
        // Clear OTP fields on error
        _clearOTPFields();
      }
    } catch (e) {
      _showErrorSnackBar('Verification failed. Please try again.');
      _clearOTPFields();
    }
  }

  void _clearOTPFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOTP() async {
    if (_resendCooldown > 0) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Extract phone number (remove +91)
      String phoneNumber = widget.phoneNumber.replaceFirst('+91', '');
      
      await authProvider.resendOTP();
      
      if (authProvider.otpStatus == OTPStatus.sent) {
        _startResendTimer();
        _showSuccessSnackBar('OTP sent successfully');
        _clearOTPFields();
      } else if (authProvider.errorMessage != null) {
        _showErrorSnackBar(authProvider.errorMessage!);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to resend OTP. Please try again.');
    }
  }

  void _changeNumber() {
    // Clear auth state and go back to login
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.resetOTPState();
    
    Navigator.pop(context);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF2D3748),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Your Number',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Instructions
                _buildInstructions(),
                
                const SizedBox(height: 50),
                
                // OTP Input Fields
                _buildOTPFields(authProvider),
                
                const SizedBox(height: 40),
                
                // Verify button
                _buildVerifyButton(authProvider),
                
                const SizedBox(height: 30),
                
                // Resend section
                _buildResendSection(authProvider),
                
                const SizedBox(height: 20),
                
                // Change number
                _buildChangeNumberButton(),
                
                // Show verification status
                if (authProvider.otpStatus == OTPStatus.verifying)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Verifying...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        Text(
          "We've sent a 6-digit verification code to",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.phoneNumber,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPFields(AuthProvider authProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            enabled: !authProvider.isVerifying,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: authProvider.isVerifying 
                  ? Colors.grey[100] 
                  : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4299E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: (value) {
              // Clear error when user starts typing
              if (authProvider.errorMessage != null) {
                authProvider.clearError();
              }
              
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              
              // Auto verify when all fields are filled
              String otp = _otpControllers.map((controller) => controller.text).join();
              if (otp.length == 6 && !_isAutoVerifying) {
                _isAutoVerifying = true;
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _verifyOTP().then((_) {
                      _isAutoVerifying = false;
                    });
                  }
                });
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton(AuthProvider authProvider) {
    String otp = _otpControllers.map((controller) => controller.text).join();
    bool isValid = otp.length == 6;
    bool isLoading = authProvider.isVerifying || _isAutoVerifying;
    
    return CustomButton(
      text: 'Verify Code',
      onPressed: isValid && !isLoading ? _verifyOTP : null,
      isLoading: isLoading,
      backgroundColor: const Color(0xFF4A5568),
    );
  }

  Widget _buildResendSection(AuthProvider authProvider) {
    bool canResend = _resendCooldown == 0 && !authProvider.isLoading;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive code? ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: canResend ? _resendOTP : null,
          child: Text(
            _resendCooldown > 0 
                ? 'Resend 00:${_resendCooldown.toString().padLeft(2, '0')}'
                : 'Resend',
            style: TextStyle(
              fontSize: 14,
              color: canResend 
                  ? const Color(0xFF4299E1)
                  : Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeNumberButton() {
    return GestureDetector(
      onTap: _changeNumber,
      child: const Text(
        'Change Number',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF4299E1),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}