// lib/presentation/providers/auth_provider.dart
import 'package:customer_app/data/models/user_model.dart';
import 'package:customer_app/services/auth_service.dart';
import 'package:customer_app/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/errors/error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  failed,
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
  final Logger _logger = Logger();
  
  // Auth state
  AuthStatus _authStatus = AuthStatus.unknown;
  AuthStatus get authStatus => _authStatus;

  // OTP state
  OTPStatus _otpStatus = OTPStatus.initial;
  OTPStatus get otpStatus => _otpStatus;

  // User data
  User? _firebaseUser;
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

  // New user flag
  bool isNewUser = false;

  // Profile completion status
  bool get isProfileComplete => _userModel?.isProfileComplete ?? false;

  // Method to clear the error message
  void clearError() {
    if (_errorMessage != null) {
      _logger.d("Clearing error message.");
      _errorMessage = null;
      _safeNotifyListeners();
    }
  }

  // OTP resend
  bool _canResend = false;
  bool get canResend => _canResend;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  // Stream subscription for auth state
  StreamSubscription<User?>? _authStateSubscription;

  // Disposal flag
  bool _isDisposed = false;

  // Constructor
  AuthProvider() {
    _logger.i("AuthProvider initialized. Listening to auth state changes.");
    _authService.authStateChanges.listen(_onAuthStateChanged, onError: (error) {
      _logger.e("Error in auth state stream: $error");
      _authStatus = AuthStatus.failed;
      _setError("An unexpected error occurred. Please restart the app.");
      _safeNotifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _logger.w("AuthProvider disposed.");
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Safe notify listeners
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      _logger.d("Notifying listeners. AuthStatus: $_authStatus, Current UserModel: ${_userModel != null}");
      notifyListeners();
    } else {
      _logger.w("Attempted to notify listeners after dispose.");
    }
  }

  // Handle auth state changes from Firebase
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (_isDisposed) return;

    if (firebaseUser == null) {
      _logger.i("Auth state changed: User is null. Setting to Unauthenticated.");
      _authStatus = AuthStatus.unauthenticated;
      _userModel = null;
      _safeNotifyListeners();
    } else {
      _logger.i("Auth state changed: User found with UID: ${firebaseUser.uid}. Loading data.");
      _authStatus = AuthStatus.authenticating;
      _safeNotifyListeners();
      await _loadUserDataWithRetry(firebaseUser.uid);
    }
  }

  // FIXED: Load user data with retry mechanism to handle Firestore eventual consistency
  Future<UserModel?> _loadUserDataWithRetry(String uid) async {
    if (_isDisposed) return null;
    
    const int maxRetries = 5;
    const Duration baseDelay = Duration(milliseconds: 300);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        _logger.d("AuthProvider: Loading user data for UID: $uid (attempt ${attempt + 1}/$maxRetries)");
        
        // Add exponential backoff delay for retries
        if (attempt > 0) {
          final delay = Duration(milliseconds: baseDelay.inMilliseconds * (attempt * 2));
          _logger.d("Waiting ${delay.inMilliseconds}ms before retry...");
          await Future.delayed(delay);
        }

        final userModel = await _authService.getUserData(uid);
        
        if (_isDisposed) return null;
        
        if (userModel != null) {
          _userModel = userModel;
          _authStatus = AuthStatus.authenticated;
          _logger.d("AuthProvider: User data loaded successfully on attempt ${attempt + 1}. Final status: Authenticated.");
          
          // Save FCM token for notifications
          try {
            await NotificationService.saveTokenToFirestore();
          } catch (e) {
            _logger.w("Failed to save FCM token: $e");
          }
          
          _safeNotifyListeners();
          return _userModel;
        } else {
          _logger.w("AuthProvider: User document not found for UID $uid on attempt ${attempt + 1}");
          
          // If this is the last attempt, handle the error
          if (attempt == maxRetries - 1) {
            _logger.e("AuthProvider: Failed to load user data after $maxRetries attempts for UID $uid");
            
            // Try to ensure the document exists
            final currentUser = _authService.currentUser;
            if (currentUser != null) {
              _logger.i("Attempting to ensure user document exists...");
              bool documentCreated = await _authService.ensureUserDocument(currentUser);
              
              if (documentCreated && !_isDisposed) {
                // One final attempt to load the data
                _logger.i("Document created, making final attempt to load user data...");
                await Future.delayed(const Duration(milliseconds: 1000));
                final finalUserModel = await _authService.getUserData(uid);
                
                if (finalUserModel != null) {
                  _userModel = finalUserModel;
                  _authStatus = AuthStatus.authenticated;
                  _logger.d("AuthProvider: User data loaded successfully after document creation.");
                  _safeNotifyListeners();
                  return _userModel;
                }
              }
            }
            
            // If all attempts failed, show error but don't immediately sign out
            _setError('Unable to load your profile. Please check your connection and try again.');
            _authStatus = AuthStatus.failed;
            _safeNotifyListeners();
            return null;
          }
        }
      } catch (e) {
        _logger.e("AuthProvider: Error loading user data for UID $uid on attempt ${attempt + 1}: $e");
        
        // If this is the last attempt, handle the error
        if (attempt == maxRetries - 1) {
          _authStatus = AuthStatus.failed;
          _setError(ErrorHandler.getUserFriendlyMessage(e));
          _safeNotifyListeners();
          return null;
        }
      }
    }
    
    return null;
  }

  // DEPRECATED: Keep for backward compatibility but use _loadUserDataWithRetry instead
  Future<UserModel?> _loadUserData(String uid) async {
    return _loadUserDataWithRetry(uid);
  }

  // Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    if (_isDisposed) return;
    
    try {
      _setLoading(true);
      clearError();
      _setOTPStatus(OTPStatus.sending);
      _phoneNumber = phoneNumber;
      
      _logger.d('Starting OTP send process for: $phoneNumber');

      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
      );
      
      _logger.d('OTP send process completed for $phoneNumber');
    } catch (e) {
      if (_isDisposed) return;
      _logger.e('Error in sendOTP for $phoneNumber: $e');
      _setError(e.toString());
      _setOTPStatus(OTPStatus.failed);
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String otp) async {
    if (_isDisposed || _verificationId == null) {
      if (_verificationId == null) {
        _setError('Verification ID not found. Please restart the process.');
      }
      _setOTPStatus(OTPStatus.failed);
      return false;
    }

    try {
      _isVerifying = true;
      _setOTPStatus(OTPStatus.verifying);
      clearError();
      _safeNotifyListeners();
      _logger.d("Verifying OTP for $_verificationId");

      final userModel = await _authService.verifyOTPAndSignIn(
        verificationId: _verificationId!,
        otp: otp,
      );
      _logger.d("OTP verified. User: ${userModel.uid}");

      if (_isDisposed) return false;

      _userModel = userModel;
      _firebaseUser = _authService.currentUser;
      _authStatus = AuthStatus.authenticated;
      _setOTPStatus(OTPStatus.verified);
      
      _isVerifying = false;
      _safeNotifyListeners();
      return true;

    } on AuthException catch (e) { 
      if (_isDisposed) return false;
      _logger.w('AuthException: ${e.message}');
      _setError(e.message); 
      _setOTPStatus(OTPStatus.failed);
      _isVerifying = false;
      _safeNotifyListeners();
      return false;
    } catch (e) { 
      if (_isDisposed) return false;
      _logger.e('Generic error during OTP verification: $e');
      _setError('An unexpected error occurred during OTP verification. Please try again.');
      _setOTPStatus(OTPStatus.failed);
      _isVerifying = false;
      _safeNotifyListeners();
      return false;
    }
  }

  // Resend OTP
  Future<void> resendOTP() async {
    if (_isDisposed || _phoneNumber == null || !_canResend) return;
    
    _canResend = false;
    await sendOTP(_phoneNumber!);
  }

  // FIXED: Modified sign out to be less aggressive
  Future<void> signOut({bool isErrorState = false}) async {
    if (_isDisposed) return;
    _logger.i("Signing out user.");
    
    try {
      await _authService.signOut();
      _userModel = null;
      _firebaseUser = null;
      _authStatus = AuthStatus.unauthenticated;
      
      if (!isErrorState) {
        clearError();
      } else {
        _logger.w("Signed out due to error. Error message preserved.");
      }
      _safeNotifyListeners();
    } catch (e) {
      _logger.e("Error during sign out: $e");
      // Even if sign out fails, reset local state
      _userModel = null;
      _firebaseUser = null;
      _authStatus = AuthStatus.unauthenticated;
      _safeNotifyListeners();
    }
  }

  Future<void> loadInitialUser(User user) async {
    final doc = await FirebaseFirestore.instance.collection('customer').doc(user.uid).get();
    isNewUser = !doc.exists;
    await _loadUserDataWithRetry(user.uid);
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    if (_userModel == null) return false;

    _setLoading(true);
    try {
      final updatedData = {
        'name': name,
        'email': email,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _authService.updateProfile(_userModel!.uid, updatedData);

      // Optimistically update the local user model
      _userModel = _userModel!.copyWith(
        name: name,
        email: email,
        isProfileComplete: true,
      );
      
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _setError(ErrorHandler.getUserFriendlyMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserData(UserModel user) async {
    _userModel = user;
    _safeNotifyListeners();
  }

  // FIXED: Retry mechanism for authentication completion
  Future<void> _onVerificationCompleted(PhoneAuthCredential credential) async {
    if (_isDisposed) return;
    _logger.i("Auto verification completed: ${credential.smsCode}");
    
    try {
      _setOTPStatus(OTPStatus.verifying);
      _isVerifying = true;
      _safeNotifyListeners();

      final userModel = await _authService.signInWithPhoneCredential(credential);
      _logger.d("User signed in with credential, user data available for ${userModel.uid}");
      
      if (_isDisposed) return;

      _userModel = userModel;
      _firebaseUser = _authService.currentUser;
      _authStatus = AuthStatus.authenticated;
      _setOTPStatus(OTPStatus.verified);

    } catch (e) {
      _logger.e("Error on verification completed: $e");
      _setError(ErrorHandler.getUserFriendlyMessage(e));
      _setOTPStatus(OTPStatus.failed);
    } finally {
      if (!_isDisposed) {
        _isVerifying = false;
        _safeNotifyListeners();
      }
    }
  }

  // Callback for when verification fails
  void _onVerificationFailed(FirebaseAuthException e) {
    if (_isDisposed) return;
    _logger.w('Verification failed: ${e.code} - ${e.message}');
    _setError(e.message ?? 'Verification failed');
    _setOTPStatus(OTPStatus.failed);
    _isVerifying = false; 
    _setLoading(false); 
    _safeNotifyListeners();
  }

  // Callback for when code is sent
  void _onCodeSent(String verificationId, int? resendToken) {
    if (_isDisposed) return;
    _logger.i("Code sent, verification ID: $verificationId");
    _verificationId = verificationId;
    _setOTPStatus(OTPStatus.sent);
    _setLoading(false);
    
    _canResend = false;
    Future.delayed(const Duration(seconds: 30), () {
      if (!_isDisposed) {
        _canResend = true;
        _safeNotifyListeners();
      }
    });
  }
  
  // Callback for auto retrieval timeout
  void _onCodeAutoRetrievalTimeout(String verificationId) {
    if (_isDisposed) return;
    _logger.w("Auto-retrieval timed out for verification ID: $verificationId");
  }

  // Helper to set OTP status and notify listeners
  void _setOTPStatus(OTPStatus status) {
    if (_otpStatus != status) {
      _logger.d("OTP status changed from $_otpStatus to $status");
      _otpStatus = status;
      _safeNotifyListeners();
    }
  }

  // Helper to set error message and notify listeners
  void _setError(String message) {
    _logger.e("Setting error message: $message");
    _errorMessage = message;
    _safeNotifyListeners();
  }

  // Helper to set loading state and notify listeners
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _logger.d("Setting loading state to $value");
      _isLoading = value;
      _safeNotifyListeners();
    }
  }

  // Reset OTP state
  void resetOTPState() {
    _otpStatus = OTPStatus.initial;
    _verificationId = null;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  // ADDED: Method to manually retry loading user data
  Future<void> retryLoadUserData() async {
    if (_isDisposed || _authService.currentUser == null) return;
    
    _authStatus = AuthStatus.authenticating;
    clearError();
    _safeNotifyListeners();
    
    await _loadUserDataWithRetry(_authService.currentUser!.uid);
  }
}