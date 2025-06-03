// lib/providers/auth_provider.dart
import 'package:customer_app/data/models/user_model.dart';
import 'package:customer_app/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  authenticating,
}

enum OTPStatus {
  initial,
  sending,
  sent,
  verifying,
  verified,
  failed,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  // Auth state
  AuthStatus _authStatus = AuthStatus.unknown;
  AuthStatus get authStatus => _authStatus;

  // OTP state
  OTPStatus _otpStatus = OTPStatus.initial;
  OTPStatus get otpStatus => _otpStatus;

  // User data
  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  // Current phone number and verification ID
  String? _phoneNumber;
  String? get phoneNumber => _phoneNumber;

  String? _verificationId;
  String? get verificationId => _verificationId;

  // Error handling
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // OTP resend
  bool _canResend = false;
  bool get canResend => _canResend;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  // Constructor
  AuthProvider() {
    _initializeAuthState();
  }

  // Initialize auth state
  void _initializeAuthState() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;
      
      if (user != null) {
        _authStatus = AuthStatus.authenticated;
        await _loadUserData(user.uid);
      } else {
        _authStatus = AuthStatus.unauthenticated;
        _userModel = null;
      }
      
      notifyListeners();
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _authService.getUserData(uid);
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      _setLoading(true);
      _clearError();
      _otpStatus = OTPStatus.sending;
      _phoneNumber = phoneNumber;
      notifyListeners();

      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      _setError(e.toString());
      _otpStatus = OTPStatus.failed;
    } finally {
      _setLoading(false);
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _setError('Verification ID not found. Please restart the process.');
      return false;
    }

    try {
      _isVerifying = true;
      _otpStatus = OTPStatus.verifying;
      _clearError();
      notifyListeners();

      UserCredential userCredential = await _authService.verifyOTPAndSignIn(
        verificationId: _verificationId!,
        otp: otp,
      );

      if (userCredential.user != null) {
        _otpStatus = OTPStatus.verified;
        _authStatus = AuthStatus.authenticated;
        await _loadUserData(userCredential.user!.uid);
        return true;
      }
      
      return false;
    } catch (e) {
      _setError(e.toString());
      _otpStatus = OTPStatus.failed;
      return false;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  // Resend OTP
  Future<void> resendOTP() async {
    if (_phoneNumber != null && _canResend) {
      _canResend = false;
      await sendOTP(_phoneNumber!);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _resetState();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_firebaseUser == null) return false;

    try {
      _setLoading(true);
      _clearError();

      await _authService.updateUserProfile(
        uid: _firebaseUser!.uid,
        name: name,
        email: email,
        profileImageUrl: profileImageUrl,
        additionalData: additionalData,
      );

      // Reload user data
      await _loadUserData(_firebaseUser!.uid);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user profile is complete
  bool get isProfileComplete {
    return _userModel?.isProfileComplete ?? false;
  }

  // Check if user is new (just registered)
  bool get isNewUser {
    if (_userModel == null) return false;
    
    DateTime? createdAt = _userModel!.createdAt;
    DateTime? lastSignIn = _userModel!.lastSignIn;
    
    if (createdAt == null || lastSignIn == null) return false;
    
    // Consider user as new if account was created within last 5 minutes
    return lastSignIn.difference(createdAt).inMinutes <= 5;
  }

  // Firebase Auth event handlers
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    try {
      // Auto-verification completed
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        _otpStatus = OTPStatus.verified;
        _authStatus = AuthStatus.authenticated;
        await _loadUserData(userCredential.user!.uid);
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    String errorMessage;
    
    switch (e.code) {
      case 'invalid-phone-number':
        errorMessage = 'Invalid phone number format.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many requests. Please try again later.';
        break;
      case 'quota-exceeded':
        errorMessage = 'SMS quota exceeded. Please try again later.';
        break;
      default:
        errorMessage = 'Verification failed: ${e.message}';
    }
    
    _setError(errorMessage);
    _otpStatus = OTPStatus.failed;
    notifyListeners();
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    _verificationId = verificationId;
    _otpStatus = OTPStatus.sent;
    
    // Enable resend after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      _canResend = true;
      notifyListeners();
    });
    
    notifyListeners();
  }

  void _onCodeAutoRetrievalTimeout(String verificationId) {
    _verificationId = verificationId;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _resetState() {
    _authStatus = AuthStatus.unauthenticated;
    _otpStatus = OTPStatus.initial;
    _firebaseUser = null;
    _userModel = null;
    _phoneNumber = null;
    _verificationId = null;
    _errorMessage = null;
    _canResend = false;
    _isLoading = false;
    _isVerifying = false;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Reset OTP state
  void resetOTPState() {
    _otpStatus = OTPStatus.initial;
    _verificationId = null;
    _canResend = false;
    _isVerifying = false;
    notifyListeners();
  }
}