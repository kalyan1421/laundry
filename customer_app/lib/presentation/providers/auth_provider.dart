// lib/providers/auth_provider.dart
import 'package:customer_app/data/models/user_model.dart';
import 'package:customer_app/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../core/errors/app_exceptions.dart';

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

  // Stream subscription for auth state
  StreamSubscription<User?>? _authStateSubscription;

  // Disposal flag
  bool _isDisposed = false;

  // Constructor
  AuthProvider() {
    _initializeAuthState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Safe notify listeners
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      print("AuthProvider: Notifying listeners. AuthStatus: $_authStatus, Current UserModel: ${_userModel?.toJson()}, isProfileComplete: ${_userModel?.isProfileComplete}");
      notifyListeners();
    }
  }

  // Initialize auth state
  void _initializeAuthState() {
    _authStatus = AuthStatus.unknown;
    _safeNotifyListeners();

    _authStateSubscription = _authService.authStateChanges.listen((User? user) async {
      if (_isDisposed) return;
      print("AuthProvider: Auth state stream received. Firebase user: ${user?.uid}.");
      
      if (user == null) {
        // User is logged out.
        print("AuthProvider: User is null. Setting state to Unauthenticated.");
        _authStatus = AuthStatus.unauthenticated;
        _firebaseUser = null;
        _userModel = null;
        _safeNotifyListeners();
      } else {
        // User is logged in. Set as authenticating while we fetch data.
        print("AuthProvider: User ${user.uid} exists. Setting state to Authenticating.");
        _firebaseUser = user;
        _authStatus = AuthStatus.authenticating;
        _safeNotifyListeners(); // Notify UI that we are fetching data
        
        // Now load user data.
        await _loadUserData(user.uid);
      }
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    if (_isDisposed) return;
    print("AuthProvider: Loading user data for UID: $uid.");

    try {
      final userModel = await _authService.getUserData(uid);
      
      if (userModel != null) {
        // Data loaded successfully.
        _userModel = userModel;
        _authStatus = AuthStatus.authenticated;
        print("AuthProvider: User data loaded. Final status: Authenticated.");
      } else {
        // This can happen if the user is authenticated with Firebase,
        // but their document in Firestore was deleted. This is a critical error state.
        print("AuthProvider: CRITICAL - User authenticated but no data in Firestore for UID $uid.");
        _setError('Your user profile could not be found. Please contact support.');
        await signOut(isErrorState: true); // Force sign out to prevent being stuck.
      }
    } catch (e) {
      print('AuthProvider: Error loading user data for UID $uid: $e');
      // On error, we don't want to log the user out immediately.
      // We keep their authenticated state but show an error.
      // This allows them to retry or use parts of the app that don't need user data.
      _setError('Could not load your profile. Please check your connection and try again.');
      _authStatus = AuthStatus.authenticated; // Keep them logged in but with an error.
    } finally {
      _safeNotifyListeners();
    }
  }

  // Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    if (_isDisposed) return;
    
    try {
      _setLoading(true);
      _clearError();
      _setOTPStatus(OTPStatus.sending);
      _phoneNumber = phoneNumber;
      
      print('AuthProvider: Starting OTP send process for: $phoneNumber');

      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
      );
      
      print('AuthProvider: OTP send process completed for $phoneNumber');
    } catch (e) {
      if (_isDisposed) return;
      print('AuthProvider: Error in sendOTP for $phoneNumber: $e');
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
      _clearError();
      _safeNotifyListeners();
      print("AuthProvider.verifyOTP: Verifying OTP for $_verificationId");

      UserCredential userCredential = await _authService.verifyOTPAndSignIn(
        verificationId: _verificationId!,
        otp: otp,
      );
      print("AuthProvider.verifyOTP: OTP verified. User: ${userCredential.user?.uid}");

      if (_isDisposed) return false;

      _firebaseUser = userCredential.user;
      _setOTPStatus(OTPStatus.verified);
      print("AuthProvider.verifyOTP: User signed in with Firebase, loading user data for ${userCredential.user!.uid}");
      await _loadUserData(userCredential.user!.uid);
      _isVerifying = false;
      _safeNotifyListeners();
      return true;

    } on AuthException catch (e) { 
      if (_isDisposed) return false;
      print('AuthProvider.verifyOTP: AuthException: ${e.message}');
      _setError(e.message); 
      _setOTPStatus(OTPStatus.failed);
      _isVerifying = false;
      _safeNotifyListeners();
      return false;
    } catch (e) { 
      if (_isDisposed) return false;
      print('AuthProvider.verifyOTP: Generic error: $e');
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

  // Sign out
  Future<void> signOut({bool isErrorState = false}) async {
    if (_isDisposed) return;
    print('AuthProvider: Signing out.');
    
    // In a critical error state, we might not want to make a server call that could fail.
    // However, for a standard sign-out, calling the service is correct.
    if (!isErrorState) {
      try {
        await _authService.signOut();
      } catch (e) {
        print('AuthProvider: Error during sign out from service: $e');
        // Even if the service call fails, we must clear the local state.
      }
    }

    // Clear all local user state
    _firebaseUser = null;
    _userModel = null;
    _verificationId = null;
    _phoneNumber = null;
    _errorMessage = null;
    _authStatus = AuthStatus.unauthenticated;
    
    print('AuthProvider: State cleared. Notifying listeners of Unauthenticated state.');
    _safeNotifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_isDisposed || _firebaseUser == null) return false;
    print("AuthProvider.updateProfile: Updating for UID: ${_firebaseUser!.uid}. AdditionalData: $additionalData");

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
      print("AuthProvider.updateProfile: Auth service update complete for UID: ${_firebaseUser!.uid}. Reloading user data.");
      if (_isDisposed) return false;
      await _loadUserData(_firebaseUser!.uid);
      print("AuthProvider.updateProfile: User data reloaded for UID: ${_firebaseUser!.uid}. isProfileComplete: $isProfileComplete, AuthStatus: $_authStatus");
      return true;
    } catch (e) {
      if (!_isDisposed) {
        print("AuthProvider.updateProfile: Error updating profile for UID: ${_firebaseUser!.uid}: $e");
        _setError(e.toString());
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // Check if user profile is complete
  bool get isProfileComplete {
    print("AuthProvider: get isProfileComplete called. Value: ${_userModel?.isProfileComplete ?? false}, UserModel: ${_userModel?.toJson()}");
    if (_userModel == null) return false;
    return _userModel!.isProfileComplete;
  }

  // Check if user is new (just registered)
  bool get isNewUser {
    if (_userModel == null) return false;
    
    DateTime? createdAt = _userModel!.createdAt?.toDate();
    DateTime? lastSignIn = _userModel!.lastSignIn?.toDate();
    
    if (createdAt == null || lastSignIn == null) return false;
    
    // Consider user as new if account was created within last 5 minutes
    return lastSignIn.difference(createdAt).inMinutes <= 5;
  }

  // Firebase Auth event handlers
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    if (_isDisposed) return;
    print('AuthProvider: Auto-verification completed.');
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (_isDisposed) return;
      if (userCredential.user != null) {
        _firebaseUser = userCredential.user;
        _setOTPStatus(OTPStatus.verified);
        await _loadUserData(userCredential.user!.uid);
      }
    } catch (e) {
      if (!_isDisposed) {
        print('AuthProvider: Error in auto-verification: $e');
        _setError(e.toString());
      }
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    if (_isDisposed) return;
    print('AuthProvider: Verification failed: ${e.code} - ${e.message}');
    String errorMessage;
    switch (e.code) {
      case 'invalid-phone-number': errorMessage = 'Invalid phone number format.'; break;
      case 'too-many-requests': errorMessage = 'Too many requests. Please try again later.'; break;
      case 'quota-exceeded': errorMessage = 'SMS quota exceeded. Please try again later.'; break;
      case 'app-not-authorized': errorMessage = 'App not authorized for verification.'; break;
      case 'unknown': errorMessage = 'Verification failed. Please check your network and try again.'; break;
      default: errorMessage = 'Verification failed: ${e.message}';
    }
    _setError(errorMessage);
    _setOTPStatus(OTPStatus.failed);
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    if (_isDisposed) return;
    print('AuthProvider: Code sent. Verification ID: $verificationId');
    _verificationId = verificationId;
    _setOTPStatus(OTPStatus.sent);
    Future.delayed(const Duration(seconds: 30), () {
      if (!_isDisposed) {
        _canResend = true;
        _safeNotifyListeners();
      }
    });
  }

  void _onCodeAutoRetrievalTimeout(String verificationId) {
    if (_isDisposed) return;
    print('AuthProvider: Auto retrieval timeout. Verification ID: $verificationId');
    _verificationId = verificationId;
    _safeNotifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setOTPStatus(OTPStatus status) {
    if (_isDisposed) return;
    _otpStatus = status;
    print('AuthProvider: OTP Status changed to: $status');
    _safeNotifyListeners();
  }

  void _setError(String error) {
    if (_isDisposed) return;
    _errorMessage = error;
    print('AuthProvider: Auth Error set: $error');
    _safeNotifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Reset OTP state
  void resetOTPState() {
    if (_isDisposed) return;
    _otpStatus = OTPStatus.initial;
    _verificationId = null;
    _canResend = false;
    _isVerifying = false;
    _safeNotifyListeners();
  }

  // Example of where the conversion might be needed if you are directly using DateTime types
  // in your AuthProvider from _userModel
  Future<void> _someMethodUsingUserTimestamps() async {
    if (_userModel != null) {
      // Correct conversion from Timestamp to DateTime
      DateTime? createdAt = _userModel!.createdAt?.toDate();
      DateTime? lastSignIn = _userModel!.lastSignIn?.toDate();
      DateTime? updatedAt = _userModel!.updatedAt?.toDate(); // Assuming UserModel has updatedAt as Timestamp

      // Use these DateTime objects
      print('User created at: $createdAt');
      print('User last signed in at: $lastSignIn');
      print('User updated at: $updatedAt');
    }
  }
}