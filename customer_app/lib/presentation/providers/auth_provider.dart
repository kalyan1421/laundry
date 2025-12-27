// lib/presentation/providers/auth_provider.dart
import 'package:customer_app/data/models/user_model.dart';
import 'package:customer_app/services/auth_service.dart';
import 'package:customer_app/services/notification_service.dart';
import 'package:customer_app/services/order_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import '../../core/errors/error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/core/utils/address_utils.dart';
import 'package:flutter/material.dart';

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
      // Only log significant state changes to reduce noise
      if (_authStatus == AuthStatus.authenticated || 
          _authStatus == AuthStatus.unauthenticated ||
          _authStatus == AuthStatus.failed) {
        _logger.d("Notifying listeners. AuthStatus: $_authStatus, Current UserModel: ${_userModel != null}");
      }
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
      _clearUserData();
      _safeNotifyListeners();
    } else {
      _logger.i("Auth state changed: User found with UID: ${firebaseUser.uid}. Loading data.");
      _firebaseUser = firebaseUser;
      _authStatus = AuthStatus.authenticating;
      _safeNotifyListeners();
      
      // Attempt to load user data with enhanced error handling
      final success = await _loadUserDataWithRetry(firebaseUser.uid);
      if (!success && !_isDisposed) {
        // If loading fails persistently, trigger automatic logout
        _logger.e("Persistent failure to load user data. Triggering automatic logout.");
        await _handlePersistentAuthFailure();
      }
    }
  }

  // FIXED: Load user data with retry mechanism to handle Firestore eventual consistency
  Future<bool> _loadUserDataWithRetry(String uid) async {
    if (_isDisposed) return false;
    
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
        
        if (_isDisposed) return false;
        
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
          
          // Set up order status listener after successful authentication
          OrderNotificationService.setupOrderStatusListener();
          
          _safeNotifyListeners();
          return true;
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
                  
                  // Set up order status listener after successful authentication
                  OrderNotificationService.setupOrderStatusListener();
                  
                  _safeNotifyListeners();
                  return true;
                }
              }
            }
            
            // If all attempts failed, return false to trigger logout
            _logger.e("AuthProvider: All attempts to load user data failed for UID $uid");
            _setError('Unable to load your profile. Logging out for fresh start.');
            _authStatus = AuthStatus.failed;
            _safeNotifyListeners();
            return false;
          }
        }
      } catch (e) {
        _logger.e("AuthProvider: Error loading user data for UID $uid on attempt ${attempt + 1}: $e");
        
        // If this is the last attempt, handle the error
        if (attempt == maxRetries - 1) {
          _authStatus = AuthStatus.failed;
          _setError('Failed to load your profile. Logging out for fresh start.');
          _safeNotifyListeners();
          return false;
        }
      }
    }
    
    return false;
  }

  // Handle persistent authentication failures
  Future<void> _handlePersistentAuthFailure() async {
    if (_isDisposed) return;
    
    _logger.w("Handling persistent authentication failure - forcing logout");
    
    // Set error message before logout
    _setError('Authentication failed. Please login again.');
    
    // Force logout with error state preserved
    await signOut(isErrorState: true, isForced: true);
  }
  
  // Clear all user-related data
  void _clearUserData() {
    _userModel = null;
    _firebaseUser = null;
    _phoneNumber = null;
    _verificationId = null;
    isNewUser = false;
  }
  
  // Public method to check and handle authentication inconsistencies
  Future<void> validateAuthenticationState() async {
    if (_isDisposed) return;
    
    final firebaseUser = _authService.currentUser;
    
    // Check for authentication inconsistencies
    if (firebaseUser == null && _authStatus == AuthStatus.authenticated) {
      _logger.w("Authentication inconsistency detected: Firebase user is null but status is authenticated");
      await _handlePersistentAuthFailure();
      return;
    }
    
    if (firebaseUser != null && _userModel == null && _authStatus == AuthStatus.authenticated) {
      _logger.w("Authentication inconsistency detected: Firebase user exists but UserModel is null");
      // Try to reload user data
      final success = await _loadUserDataWithRetry(firebaseUser.uid);
      if (!success) {
        await _handlePersistentAuthFailure();
      }
      return;
    }
    
    // Check for UID mismatch
    if (firebaseUser != null && _userModel != null && firebaseUser.uid != _userModel!.uid) {
      _logger.e("UID mismatch detected: Firebase UID (${firebaseUser.uid}) != UserModel UID (${_userModel!.uid})");
      await _handlePersistentAuthFailure();
      return;
    }
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
      
      // Set up order status listener after successful authentication
      OrderNotificationService.setupOrderStatusListener();
      
      _isVerifying = false;
      _safeNotifyListeners();
      return true;

    } on FirebaseAuthException catch (e) { 
      if (_isDisposed) return false;
      _logger.w('FirebaseAuthException: ${e.message}');
      _setError(e.message ?? 'Authentication failed'); 
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

  // Enhanced sign out with better error handling
  Future<void> signOut({bool isErrorState = false, bool isForced = false}) async {
    if (_isDisposed) return;
    
    if (isForced) {
      _logger.w("Forced sign out due to persistent authentication issues.");
    } else {
      _logger.i("User initiated sign out.");
    }
    
    try {
      // Clear user data first
      _clearUserData();
      
      // Sign out from Firebase
      await _authService.signOut();
      
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
      _clearUserData();
      _authStatus = AuthStatus.unauthenticated;
      _safeNotifyListeners();
    }
  }

  Future<void> loadInitialUser(User user) async {
    final doc = await FirebaseFirestore.instance.collection('customer').doc(user.uid).get();
    isNewUser = !doc.exists;
    await _loadUserDataWithRetry(user.uid);
  }

  // Method to refresh user data (useful after address changes)
  Future<void> refreshUserData() async {
    if (_userModel != null) {
      _logger.i("Refreshing user data for UID: ${_userModel!.uid}");
      await _loadUserDataWithRetry(_userModel!.uid);
    }
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

  // New method to update profile with address
  Future<bool> updateProfileWithAddress({
    required String name,
    required String email,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String pincode,
    String? landmark,
    required double latitude,
    required double longitude,
    String? doorNumber,
    String? floorNumber,
    String? apartmentName,
    String addressType = 'home', // Added addressType parameter
  }) async {
    if (_userModel == null) return false;

    _setLoading(true);
    try {
      _logger.i('Starting profile update with address using standardized format');
      _logger.i('User ID: ${_userModel!.uid}');
      _logger.i('Phone Number: ${_userModel!.phoneNumber}');
      _logger.i('Latitude: $latitude, Longitude: $longitude');
      
      // First update the user profile
      final updatedData = {
        'name': name,
        'email': email,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _authService.updateProfile(_userModel!.uid, updatedData);
      _logger.i('User profile updated successfully');

      // Parse the addressLine1 to extract door number, floor number, and apartment name if not provided
      String extractedDoorNumber = doorNumber ?? '';
      String extractedFloorNumber = floorNumber ?? '';
      String extractedApartmentName = apartmentName ?? '';
      String cleanAddressLine1 = addressLine1;

      // If door/floor/apartment not provided, try to extract from addressLine1
      if (extractedDoorNumber.isEmpty || extractedFloorNumber.isEmpty) {
        // Extract door number
        if (addressLine1.contains('Door:')) {
          RegExp doorRegex = RegExp(r'Door:\s*([^,]+)');
          Match? doorMatch = doorRegex.firstMatch(addressLine1);
          if (doorMatch != null) {
            extractedDoorNumber = doorMatch.group(1)?.trim() ?? '';
          }
        }

        // Extract floor number
        if (addressLine1.contains('Floor:')) {
          RegExp floorRegex = RegExp(r'Floor:\s*([^,]+)');
          Match? floorMatch = floorRegex.firstMatch(addressLine1);
          if (floorMatch != null) {
            extractedFloorNumber = floorMatch.group(1)?.trim() ?? '';
          }
        }

        // Extract apartment name (between Floor and the remaining address)
        if (addressLine1.contains('Floor:') && addressLine1.contains(',')) {
          RegExp apartmentRegex = RegExp(r'Floor:\s*[^,]+,\s*([^,]+)');
          Match? apartmentMatch = apartmentRegex.firstMatch(addressLine1);
          if (apartmentMatch != null) {
            extractedApartmentName = apartmentMatch.group(1)?.trim() ?? '';
          }
        }

        // Clean the address line by removing the extracted structured info
        cleanAddressLine1 = addressLine1
            .replaceAll(RegExp(r'Door:\s*[^,]+,?\s*'), '')
            .replaceAll(RegExp(r'Floor:\s*[^,]+,?\s*'), '')
            .replaceAll(RegExp(r'^\s*,\s*'), '') // Remove leading comma
            .replaceAll(RegExp(r',\s*,'), ',') // Remove double commas
            .trim();
      }

      _logger.i('Standardized address data to be saved:');
      _logger.i('Door Number: $extractedDoorNumber');
      _logger.i('Floor Number: $extractedFloorNumber');
      _logger.i('Apartment Name: $extractedApartmentName');
      _logger.i('Address Line 1: $cleanAddressLine1');
      _logger.i('Address Line 2: ${addressLine2 ?? ''}');
      _logger.i('Landmark: ${landmark ?? ''}');
      _logger.i('City: $city');
      _logger.i('State: $state');
      _logger.i('Pincode: $pincode');
      _logger.i('Address Type: $addressType');
      _logger.i('Latitude: $latitude (Type: ${latitude.runtimeType})');
      _logger.i('Longitude: $longitude (Type: ${longitude.runtimeType})');

      // Save address using standardized format and phone number-based document ID
      final documentId = await AddressUtils.saveAddressWithStandardFormat(
        userId: _userModel!.uid,
        phoneNumber: _userModel!.phoneNumber,
        doorNumber: extractedDoorNumber,
        floorNumber: extractedFloorNumber,
        addressLine1: cleanAddressLine1,
        landmark: landmark ?? '',
        city: city,
        state: state,
        pincode: pincode,
        addressLine2: addressLine2,
        apartmentName: extractedApartmentName,
        addressType: addressType, // Use the passed addressType parameter
        latitude: latitude,
        longitude: longitude,
        isPrimary: true, // First address is always primary
      );

      if (documentId != null) {
        _logger.i('Address saved successfully with standardized format and ID: $documentId');
        
        // Verify the saved data by reading it back
        try {
          final savedDoc = await FirebaseFirestore.instance
              .collection('customer')
              .doc(_userModel!.uid)
              .collection('addresses')
              .doc(documentId)
              .get();
          
          if (savedDoc.exists) {
            final savedData = savedDoc.data();
            _logger.i('Verified saved address data:');
            _logger.i('Document ID: $documentId');
            _logger.i('Saved Door Number: ${savedData?['doorNumber']}');
            _logger.i('Saved Floor Number: ${savedData?['floorNumber']}');
            _logger.i('Saved Apartment Name: ${savedData?['apartmentName']}');
            _logger.i('Saved Address Line 1: ${savedData?['addressLine1']}');
            _logger.i('Saved Landmark: ${savedData?['landmark']}');
            _logger.i('Saved City: ${savedData?['city']}');
            _logger.i('Saved State: ${savedData?['state']}');
            _logger.i('Saved Pincode: ${savedData?['pincode']}');
            _logger.i('Saved Latitude: ${savedData?['latitude']} (Type: ${savedData?['latitude'].runtimeType})');
            _logger.i('Saved Longitude: ${savedData?['longitude']} (Type: ${savedData?['longitude'].runtimeType})');
          } else {
            _logger.e('Document was not saved properly - does not exist');
          }
        } catch (e) {
          _logger.e('Error verifying saved data: $e');
        }
      } else {
        _logger.e('Failed to save address with standardized format');
        throw Exception('Failed to save address');
      }

      // Optimistically update the local user model
      _userModel = _userModel!.copyWith(
        name: name,
        email: email,
        isProfileComplete: true,
      );
      
      // Notify admin of new customer registration
      await _notifyAdminOfNewCustomer();
      
      return true;
    } catch (e) {
      _logger.e('Error updating profile with address: $e');
      _setError(ErrorHandler.getUserFriendlyMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to build full address string
  String _buildFullAddress(String addressLine1, String? addressLine2, String city, String state, String pincode) {
    List<String> parts = [addressLine1];
    if (addressLine2 != null && addressLine2.isNotEmpty) {
      parts.add(addressLine2);
    }
    parts.addAll([city, state, pincode]);
    return parts.join(', ');
  }

  // Helper method to build searchable text for better address search
  String _buildSearchableText(String addressLine1, String? addressLine2, String city, String state, String pincode, String? landmark) {
    List<String> searchTerms = [
      addressLine1.toLowerCase(),
      city.toLowerCase(),
      state.toLowerCase(),
      pincode,
    ];
    
    if (addressLine2 != null && addressLine2.isNotEmpty) {
      searchTerms.add(addressLine2.toLowerCase());
    }
    
    if (landmark != null && landmark.isNotEmpty) {
      searchTerms.add(landmark.toLowerCase());
    }
    
    return searchTerms.join(' ');
  }

  // Notify admin of new customer registration
  Future<void> _notifyAdminOfNewCustomer() async {
    if (_userModel == null) return;
    
    try {
      _logger.i('Notifying admin of new customer registration: ${_userModel!.name}');
      
      // Call a cloud function or service to notify admin
      await FirebaseFirestore.instance
          .collection('customerRegistrationNotifications')
          .add({
        'customerId': _userModel!.uid,
        'customerName': _userModel!.name,
        'customerPhone': _userModel!.phoneNumber,
        'customerEmail': _userModel!.email,
        'notifiedAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'notificationType': 'new_registration',
      });
      
      _logger.i('Admin notification sent successfully for new customer');
    } catch (e) {
      _logger.e('Error notifying admin of new customer: $e');
      // Don't throw error as this is not critical for user flow
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

      // Set up order status listener after successful authentication
      OrderNotificationService.setupOrderStatusListener();

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
    bool hasChanges = false;
    
    if (_otpStatus != OTPStatus.initial) {
      _otpStatus = OTPStatus.initial;
      hasChanges = true;
    }
    
    if (_verificationId != null) {
      _verificationId = null;
      hasChanges = true;
    }
    
    if (_errorMessage != null) {
      _errorMessage = null;
      hasChanges = true;
    }
    
    // Only notify listeners if there were actual changes
    if (hasChanges) {
      _safeNotifyListeners();
    }
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