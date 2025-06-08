// screens/auth/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final UserRole expectedRole;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.expectedRole,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  Timer? _timer;
  int _timerSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Focus on first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timerSeconds = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      _showMessage('Please enter complete OTP', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    bool success = await authProvider.verifyOTP(
      _otpCode,
      expectedRole: widget.expectedRole,
    );

    if (success && mounted) {
      // Navigate to appropriate home screen based on role
      if (authProvider.userRole == UserRole.admin) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/admin-home',
          (route) => false,
        );
      } else if (authProvider.userRole == UserRole.delivery) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/delivery-home',
          (route) => false,
        );
      }
    } else if (mounted) {
      _showMessage(authProvider.error ?? 'Invalid OTP', isError: true);
      // Clear OTP fields on error
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Reset OTP state before resending
    authProvider.resetOTPState();
    
    bool success = await authProvider.sendOTP(
      widget.phoneNumber.replaceAll('+91', ''),
      roleToCheck: widget.expectedRole == UserRole.admin ? widget.expectedRole : null,
    );

    if (success && mounted) {
      _showMessage('OTP sent successfully', isError: false);
      _startTimer();
      // Clear fields and focus on first
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    } else if (mounted) {
      _showMessage(authProvider.error ?? 'Failed to resend OTP', isError: true);
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

  void _onOtpFieldChanged(String value, int index) {
    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field filled, verify OTP
        _focusNodes[index].unfocus();
        _verifyOTP();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.phone_iphone,
                    size: 60,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'OTP Verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to\n${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 45,
                        height: 55,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onChanged: (value) => _onOtpFieldChanged(value, index),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Timer and Resend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_canResend) ...[
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${_timerSeconds}s',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: authProvider.isLoading ? () {} : _resendOTP,
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Verify Button
                  CustomButton(
                    text: 'Verify OTP',
                    onPressed: _verifyOTP,
                    isLoading: authProvider.isLoading && 
                              authProvider.otpStatus == OTPStatus.verifying,
                  ),

                  const SizedBox(height: 24),

                  // Info based on role
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.expectedRole == UserRole.delivery
                          ? Colors.orange[50]
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.expectedRole == UserRole.delivery
                            ? Colors.orange[200]!
                            : Colors.blue[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: widget.expectedRole == UserRole.delivery
                              ? Colors.orange[700]
                              : Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.expectedRole == UserRole.delivery
                                ? 'First time login? Your account will be set up after verification.'
                                : 'Verifying as Admin',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.expectedRole == UserRole.delivery
                                  ? Colors.orange[700]
                                  : Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}