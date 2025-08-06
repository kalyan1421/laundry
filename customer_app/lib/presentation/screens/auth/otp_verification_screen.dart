// lib/screens/auth/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
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
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  int _resendCooldown = 30;
  Timer? _timer;
  bool _isAutoVerifying = false;
  bool _hasNavigated = false;
  bool _isDisposed = false;

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _showOtpUI = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showOtpUI = true;
      });
    });
    _startResendTimer();
    _listenForOtp();
  }

  void _listenForOtp() async {
    await SmsAutoFill().listenForCode();
    SmsAutoFill().code.listen((code) {
      if (code.length >= 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = code[i];
        }

        if (!_isAutoVerifying && mounted) {
          _isAutoVerifying = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_isDisposed && mounted) {
              _verifyOTP().then((_) {
                if (!_isDisposed) _isAutoVerifying = false;
              }).catchError((e) {
                if (!_isDisposed) _isAutoVerifying = false;
              });
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Cancel timer first
    _timer?.cancel();
    _timer = null;

    SmsAutoFill().unregisterListener();

    // Dispose controllers and focus nodes
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

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

  Future<void> _verifyOTP() async {
    if (_isDisposed || !mounted) return;

    String otp = '';
    try {
      otp = _otpControllers.map((controller) => controller.text).join();
    } catch (e) {
      print('Error collecting OTP: $e');
      _showMessage('Error reading OTP. Please try again.', isError: true);
      return;
    }

    if (otp.length != 6) {
      _showMessage('Please enter complete OTP', isError: true);
      return;
    }

    try {
      // Get provider safely
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Remove focus from text fields
      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      bool success = await authProvider.verifyOTP(otp);

      // Check if widget is still mounted after async operation
      if (_isDisposed || !mounted) return;

      if (success) {
        _handleSuccessfulVerification(authProvider);
      } else {
        if (authProvider.errorMessage != null) {
          _showMessage(authProvider.errorMessage!, isError: true);
        }
        _clearOTPFields();
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;
      print('Error in _verifyOTP: $e');
      _showMessage('Verification failed. Please try again.', isError: true);
      _clearOTPFields();
    }
  }

  void _handleSuccessfulVerification(AuthProvider authProvider) {
    if (_isDisposed || !mounted || _hasNavigated) return;

    _hasNavigated = true;

    // Clear OTP fields
    _clearOTPFields();

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

  void _clearOTPFields() {
    if (_isDisposed) return;

    try {
      for (var controller in _otpControllers) {
        controller.clear();
      }

      if (_focusNodes.isNotEmpty && _focusNodes[0].canRequestFocus && mounted) {
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      print('Error clearing OTP fields: $e');
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCooldown > 0 || _isDisposed || !mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Extract phone number (remove +91)
      String phoneNumber = widget.phoneNumber.replaceFirst('+91', '');

      await authProvider.sendOTP(phoneNumber);

      if (_isDisposed || !mounted) return;

      if (authProvider.otpStatus == OTPStatus.sent) {
        _startResendTimer();
        _showMessage('OTP sent successfully', isError: false);
        _clearOTPFields();
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
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 3 : 2),
        ),
      );
    } catch (e) {
      print('Error showing message: $e');
    }
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
          onPressed: () {
            if (!_isDisposed && mounted) {
              Navigator.pop(context);
            }
          },
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
      body: _showOtpUI
          ? Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // Listen for auth state changes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_isDisposed || !mounted || _hasNavigated) return;

                  if (authProvider.authStatus == AuthStatus.authenticated &&
                      authProvider.otpStatus == OTPStatus.verified) {
                    _handleSuccessfulVerification(authProvider);
                  }
                });

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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
            )
          : Lottie.asset(
              'assets/animations/Ironing People Animation.json',
              width: 200,
              height: 200,
              repeat: true,
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
            enabled: !authProvider.isVerifying && !_isDisposed,
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
              fillColor:
                  authProvider.isVerifying ? Colors.grey[100] : Colors.grey[50],
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
              if (_isDisposed || !mounted) return;

              try {
                // Clear error when user starts typing
                if (authProvider.errorMessage != null) {
                  authProvider.clearError();
                }

                // Handle focus navigation
                if (value.isNotEmpty && index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }

                // Auto verify when all fields are filled
                String otp = '';
                try {
                  otp = _otpControllers
                      .map((controller) => controller.text)
                      .join();
                } catch (e) {
                  print('Error getting OTP: $e');
                  return;
                }

                if (otp.length == 6 &&
                    !_isAutoVerifying &&
                    !_isDisposed &&
                    mounted) {
                  _isAutoVerifying = true;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (!_isDisposed && mounted) {
                      _verifyOTP().then((_) {
                        if (!_isDisposed) {
                          _isAutoVerifying = false;
                        }
                      }).catchError((e) {
                        if (!_isDisposed) {
                          _isAutoVerifying = false;
                        }
                      });
                    }
                  });
                }
              } catch (e) {
                print('Error in onChanged: $e');
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton(AuthProvider authProvider) {
    String otp = '';
    try {
      otp = _otpControllers.map((controller) => controller.text).join();
    } catch (e) {
      print('Error getting OTP for button: $e');
    }

    bool isValid = otp.length == 6;
    bool isLoading = authProvider.isVerifying || _isAutoVerifying;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isValid && !isLoading && !_isDisposed ? _verifyOTP : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid && !isLoading
              ? const Color(0xFF4A5568)
              : const Color(0xFF4A5568).withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
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
                ? 'Resend in 00:${_resendCooldown.toString().padLeft(2, '0')}'
                : 'Resend',
            style: TextStyle(
              fontSize: 14,
              color: canResend ? const Color(0xFF4299E1) : Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeNumberButton() {
    return GestureDetector(
      onTap: _isDisposed ? null : _changeNumber,
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
