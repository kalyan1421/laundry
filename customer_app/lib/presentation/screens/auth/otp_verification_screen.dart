// lib/screens/auth/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  int _resendCooldown = 30;
  Timer? _timer;
  bool _isAutoVerifying = false;
  bool _hasNavigated = false;
  bool _isDisposed = false;
  bool _showLoading = true;
  String _currentOTP = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _initializeOTPScreen();
  }

  Future<void> _initializeOTPScreen() async {
    // Show loading animation for 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted && !_isDisposed) {
        setState(() {
          _showLoading = false;
          isLoading = false;
        });
      }
    });
  }



  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _resendCooldown = 30;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

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

  Future<void> _verifyOTP(String otp) async {
    if (_isDisposed || !mounted || otp.length != 6) return;

    // Prevent multiple simultaneous verifications
    if (_isAutoVerifying) return;

    setState(() {
      _isAutoVerifying = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Remove focus from any active field
      FocusScope.of(context).unfocus();

      bool success = await authProvider.verifyOTP(otp);

      if (_isDisposed || !mounted) return;

      if (success) {
        _handleSuccessfulVerification(authProvider);
      } else {
        setState(() {
          _isAutoVerifying = false;
        });

        if (authProvider.errorMessage != null) {
          _showMessage(authProvider.errorMessage!, isError: true);
        }
        _clearOTPField();
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;

      setState(() {
        _isAutoVerifying = false;
      });

      print('Error in _verifyOTP: $e');
      _showMessage('Verification failed. Please try again.', isError: true);
      _clearOTPField();
    }
  }

  void _handleSuccessfulVerification(AuthProvider authProvider) {
    if (_isDisposed || !mounted || _hasNavigated) return;

    _hasNavigated = true;

    _showMessage('Verification successful!', isError: false);

    // Navigate based on user status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;

      try {
        if (authProvider.isNewUser || !authProvider.isProfileComplete) {
          Navigator.pushReplacementNamed(context, '/profile-setup');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        print('Navigation error: $e');
      }
    });
  }

  void _clearOTPField() {
    if (_isDisposed || !mounted) return;

    try {
      _pinController.clear();
      _currentOTP = '';
      setState(() {});
    } catch (e) {
      print('Error clearing OTP field: $e');
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCooldown > 0 || _isDisposed || !mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      String phoneNumber = widget.phoneNumber.replaceFirst('+91', '');

      await authProvider.sendOTP(phoneNumber);

      if (_isDisposed || !mounted) return;

      if (authProvider.otpStatus == OTPStatus.sent) {
        _startResendTimer();
        _showMessage('OTP sent successfully', isError: false);
        _clearOTPField();
      } else if (authProvider.errorMessage != null) {
        _showMessage(authProvider.errorMessage!, isError: true);
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;
      _showMessage('Failed to resend OTP. Please try again.', isError: true);
    }
  }

  void _changeNumber() {
    if (_isDisposed || !mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.resetOTPState();
      Navigator.pop(context);
    } catch (e) {
      print('Error changing number: $e');
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (_isDisposed || !mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? Colors.red[600] : Colors.green[600],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 4 : 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          elevation: 4,
        ),
      );
    } catch (e) {
      print('Error showing message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () {
            if (!_isDisposed && mounted) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Verify Your Number',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: LottieBuilder.asset(
                  fit: BoxFit.contain,
                  height: 200,
                  'assets/Ironing People Animation (1).json'),
            )
          : Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // Listen for auth state changes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_isDisposed || !mounted || _hasNavigated) return;

                  if (authProvider.authStatus == AuthStatus.authenticated &&
                      authProvider.otpStatus == OTPStatus.verified) {
                    _handleSuccessfulVerification(authProvider);
                  }
                });

                // Show loading animation
                if (_showLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFF4299E1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4299E1)),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Setting up verification...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF2D3748),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // const SizedBox(height: 8),
                        // Text(
                        //   'Preparing SMS auto-detection',
                        //   style: TextStyle(
                        //     fontSize: 14,
                        //     color: Colors.grey[500],
                        //   ),
                        // ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Instructions with auto-fill status
                      _buildInstructions(),

                      const SizedBox(height: 50),

                      // OTP Input Field using OTPTextField
                      _buildOTPField(authProvider),

                      const SizedBox(height: 40),

                      // Verify button
                      _buildVerifyButton(authProvider),

                      const SizedBox(height: 30),

                      // Resend section
                      _buildResendSection(authProvider),

                      const SizedBox(height: 20),

                      // Change number
                      _buildChangeNumberButton(),

                      const SizedBox(height: 20),

                      // Show verification status
                      if (authProvider.otpStatus == OTPStatus.verifying ||
                          _isAutoVerifying)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFF4299E1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Color(0xFF4299E1).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF4299E1)),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Verifying your code...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4299E1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 40),
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFF2D3748).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.phoneNumber,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sms,
                color: Colors.green.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'SMS Auto-detection enabled',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPField(AuthProvider authProvider) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3748),
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFF4299E1), width: 2),
        color: Colors.white,
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFF4299E1)),
        color: Colors.blue.shade50,
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.red),
        color: Colors.red.shade50,
      ),
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Pinput(
            controller: _pinController,
            focusNode: _pinFocusNode,
            length: 6,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            submittedPinTheme: submittedPinTheme,
            errorPinTheme: errorPinTheme,
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            cursor: Container(
              height: 20,
              width: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF4299E1),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            onChanged: (pin) {
              _currentOTP = pin;

              // Clear error when user starts typing
              if (authProvider.errorMessage != null) {
                authProvider.clearError();
              }

              setState(() {});
            },
            onCompleted: (pin) {
              _currentOTP = pin;
              HapticFeedback.lightImpact();

              // Auto-verify when 6 digits are entered
              if (pin.length == 6 && !_isAutoVerifying) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (!_isDisposed && mounted) {
                    _verifyOTP(pin);
                  }
                });
              }
            },
            // Enable SMS autofill
            androidSmsAutofillMethod:
                AndroidSmsAutofillMethod.smsUserConsentApi,
            listenForMultipleSmsOnAndroid: true,
          ),
        ),

        const SizedBox(height: 16),

        // Auto-fill status indicator
        if (_currentOTP.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.blue.shade600,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Code entered',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVerifyButton(AuthProvider authProvider) {
    bool isValid = _currentOTP.length == 6;
    bool isLoading = authProvider.isVerifying || _isAutoVerifying;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isValid && !isLoading && !_isDisposed
            ? () => _verifyOTP(_currentOTP)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid && !isLoading
              ? const Color(0xFF4299E1)
              : const Color(0xFF4299E1).withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: isValid ? 3 : 0,
          shadowColor: Color(0xFF4299E1).withOpacity(0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Verifying...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text(
                'Verify Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResendSection(AuthProvider authProvider) {
    bool canResend =
        _resendCooldown == 0 && !authProvider.isLoading && !_isDisposed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: canResend ? _resendOTP : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: canResend
                  ? Color(0xFF4299E1).withOpacity(0.1)
                  : Colors.transparent,
              border: canResend
                  ? Border.all(color: Color(0xFF4299E1).withOpacity(0.3))
                  : null,
            ),
            child: Text(
              _resendCooldown > 0
                  ? 'Resend in 00:${_resendCooldown.toString().padLeft(2, '0')}'
                  : 'Resend Code',
              style: TextStyle(
                fontSize: 14,
                color: canResend ? const Color(0xFF4299E1) : Colors.grey[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeNumberButton() {
    return GestureDetector(
      onTap: _isDisposed ? null : _changeNumber,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF4299E1).withOpacity(0.5)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 16, color: Color(0xFF4299E1)),
            SizedBox(width: 8),
            Text(
              'Change Number',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4299E1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
