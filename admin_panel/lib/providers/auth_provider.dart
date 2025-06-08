// providers/auth_provider.dart - Updated with session locking
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

enum UserRole { admin, delivery }
enum AuthStatus { loading, authenticated, unauthenticated }
enum OTPStatus { idle, sending, sent, verifying, verified, failed }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  Map<String, dynamic>? _userData;
  UserRole? _userRole;
  AuthStatus _authStatus = AuthStatus.loading;
  OTPStatus _otpStatus = OTPStatus.idle;
  bool _isLoading = false;
  String? _error;
  String? _verificationId;
  String? _phoneNumber;
  StreamSubscription<User?>? _authSubscription;
  bool _hasCheckedFirstAdmin = false;
  bool _isFirstAdmin = false;
  
  // Session lock to prevent auth state changes during admin operations
  bool _sessionLocked = false;
  
  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  UserRole? get userRole => _userRole;
  AuthStatus get authStatus => _authStatus;
  OTPStatus get otpStatus => _otpStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;
  String? get verificationId => _verificationId;
  String? get phoneNumber => _phoneNumber;
  bool get isFirstAdmin => _isFirstAdmin;
  bool get hasCheckedFirstAdmin => _hasCheckedFirstAdmin;
  bool get isSessionLocked => _sessionLocked;
  
  AuthProvider() {
    _initAuth();
  }
  
  // Lock the current session (prevents auth state changes)
  void lockSession() {
    _sessionLocked = true;
    print('🔥 Session locked for role: $_userRole');
    notifyListeners();
  }
  
  // Unlock the session
  void unlockSession() {
    _sessionLocked = false;
    print('🔥 Session unlocked');
    notifyListeners();
  }
  
  void _initAuth() {
    _authSubscription = _auth.authStateChanges().listen(
      (User? user) async {
        print('🔥 Auth state changed: ${user?.uid}');
        print('🔥 Session locked: $_sessionLocked');
        print('🔥 Current role: $_userRole');
        
        // If session is locked and we have a user, don't process auth changes
        if (_sessionLocked && _user != null && _userRole != null) {
          print('🔥 Session is locked, ignoring auth state change');
          return;
        }
        
        _user = user;
        
        if (user != null) {
          // A user is authenticated with Firebase, now load their app-specific data.
          await _loadUserData(user.uid);
        } else {
          // User is signed out.
          _userData = null;
          _userRole = null;
          _authStatus = AuthStatus.unauthenticated;
        }
        
        notifyListeners();
      },
      onError: (error) {
        print('🔥 Auth stream error: $error');
        _authStatus = AuthStatus.unauthenticated;
        notifyListeners();
      },
    );
  }

  // Load user data from Firestore with better error handling
  Future<void> _loadUserData(String uid) async {
    print('🔥 Loading user data for: $uid');
    try {
      // Check admins collection
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists && adminDoc.data() != null) {
        final data = adminDoc.data() as Map<String, dynamic>;
        if (data['isActive'] == true) {
          _userData = data;
          _userRole = UserRole.admin;
          _authStatus = AuthStatus.authenticated;
          print('🔥 Admin user authenticated: $uid');
          return; // Exit after finding the user
        }
      }

      // Check delivery_personnel collection
      DocumentSnapshot deliveryDoc = await _firestore.collection('delivery_personnel').doc(uid).get();
      if (deliveryDoc.exists && deliveryDoc.data() != null) {
        final data = deliveryDoc.data() as Map<String, dynamic>;
        if (data['isActive'] == true) {
          _userData = data;
          _userRole = UserRole.delivery;
          _authStatus = AuthStatus.authenticated;
          print('🔥 Delivery user authenticated: $uid');
          return; // Exit after finding the user
        }
      }
      
      // If we reach here, the user is authenticated with Firebase but has no
      // active, valid document in our database. This is the expected state
      // for a delivery partner on their very first login.
      // We set them as unauthenticated for app purposes so they are sent to the linking/login flow.
      print('🔥 User data not found or inactive for UID: $uid. Treating as Unauthenticated for app flow.');
      _authStatus = AuthStatus.unauthenticated;
      _userRole = null;
      _userData = null;

    } catch (e) {
      print('🔥 Error loading user data: $e');
      _error = 'Failed to load user profile.';
      _authStatus = AuthStatus.unauthenticated; // On error, default to unauthenticated
    }
  }

  // Check if any admin exists in the system
  Future<bool> checkIfFirstAdmin() async {
    if (_hasCheckedFirstAdmin) {
      return _isFirstAdmin;
    }
    
    try {
      print('🔥 Checking if first admin exists...');
      
      final QuerySnapshot adminSnapshot = await _firestore
          .collection('admins')
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('🔥 Admin check timeout - assuming not first admin');
              throw TimeoutException('Admin check timeout');
            },
          );
      
      _isFirstAdmin = adminSnapshot.docs.isEmpty;
      _hasCheckedFirstAdmin = true;
      
      print('🔥 Admin check result: isEmpty=${adminSnapshot.docs.isEmpty}, isFirstAdmin=$_isFirstAdmin');
      return _isFirstAdmin;
      
    } catch (e) {
      print('🔥 Error checking for first admin: $e');
      _hasCheckedFirstAdmin = true;
      _isFirstAdmin = false;
      return false;
    }
  }

  // Create first admin (signup)
  Future<bool> createFirstAdmin({
    required String phoneNumber,
    required String name,
    required String email,
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      print('🔥 Creating first admin...');
      _isLoading = true;
      _otpStatus = OTPStatus.verifying;
      notifyListeners();

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw Exception('Authentication failed');
      }

      final adminData = {
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': 'admin',
        'isActive': true,
        'permissions': ['all'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'createdBy': 'system',
      };

      await _firestore.collection('admins').doc(userCredential.user!.uid).set(adminData);

      _userData = adminData;
      _userRole = UserRole.admin;
      _authStatus = AuthStatus.authenticated;
      _otpStatus = OTPStatus.verified;
      _error = null;
      _isLoading = false;
      _isFirstAdmin = false;
      _hasCheckedFirstAdmin = true;
      
      print('🔥 First admin created successfully');
      notifyListeners();
      return true;

    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Auth Error: ${e.code} - ${e.message}');
      _error = _getAuthErrorMessage(e);
      _otpStatus = OTPStatus.failed;
    } catch (e) {
      print('🔥 Error creating first admin: $e');
      _error = 'Failed to create admin account: ${e.toString()}';
      _otpStatus = OTPStatus.failed;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Send OTP for phone verification
  Future<bool> sendOTP(String phoneNumber, {UserRole? roleToCheck}) async {
    try {
      print('🔥 Sending OTP to: $phoneNumber');
      _isLoading = true;
      _otpStatus = OTPStatus.sending;
      _error = null;
      notifyListeners();

      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      _phoneNumber = formattedPhone;

      // If roleToCheck is provided, verify user exists in that role
      if (roleToCheck != null) {
        try {
          String collection = roleToCheck == UserRole.admin ? 'admins' : 'delivery';
          
          // For delivery partners, check both with formatted phone
          final QuerySnapshot querySnapshot = await _firestore
              .collection(collection)
              .where('phoneNumber', isEqualTo: formattedPhone)
              .limit(1)
              .get();

          if (querySnapshot.docs.isEmpty && roleToCheck == UserRole.admin) {
            // Only show error for admin, not for delivery partners
            _error = 'No admin account found with this phone number';
            _otpStatus = OTPStatus.failed;
            _isLoading = false;
            notifyListeners();
            return false;
          }
          
          // For delivery partners, we proceed even if not found
          // They might be logging in for the first time
          if (querySnapshot.docs.isEmpty && roleToCheck == UserRole.delivery) {
            print('🔥 Delivery partner not found, but proceeding - might be first login');
          }
          
        } catch (e) {
          print('🔥 Warning: Could not verify user existence, proceeding with OTP: $e');
          // Continue with OTP even if verification fails
        }
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('🔥 Auto-verification completed');
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('🔥 Verification failed: ${e.code} - ${e.message}');
          _error = _getAuthErrorMessage(e);
          _otpStatus = OTPStatus.failed;
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          print('🔥 OTP sent successfully');
          _verificationId = verificationId;
          _otpStatus = OTPStatus.sent;
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('🔥 Auto-retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );

      return true;
    } catch (e) {
      print('🔥 Error sending OTP: $e');
      _error = 'Failed to send OTP: ${e.toString()}';
      _otpStatus = OTPStatus.failed;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP and sign in
  Future<bool> verifyOTP(String otpCode, {UserRole? expectedRole}) async {
    if (_verificationId == null) {
      _error = 'No verification ID found. Please request OTP again.';
      return false;
    }

    try {
      print('🔥 Verifying OTP: $otpCode');
      _isLoading = true;
      _otpStatus = OTPStatus.verifying;
      _error = null;
      notifyListeners();

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      await _signInWithCredential(credential, expectedRole: expectedRole);
      return true;

    } on FirebaseAuthException catch (e) {
      print('🔥 OTP verification failed: ${e.code} - ${e.message}');
      _error = _getAuthErrorMessage(e);
      _otpStatus = OTPStatus.failed;
    } catch (e) {
      print('🔥 Error verifying OTP: $e');
      _error = 'Verification failed: ${e.toString()}';
      _otpStatus = OTPStatus.failed;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign in with credential
  Future<void> _signInWithCredential(PhoneAuthCredential credential, {UserRole? expectedRole}) async {
    try {
      print('🔥 Signing in with credential...');
      print('🔥 Expected role: $expectedRole');
      print('🔥 Phone number: $_phoneNumber');
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw Exception('Authentication failed');
      }

      // Store the phone number for delivery partner lookup
      String? phoneToUse = _phoneNumber ?? userCredential.user!.phoneNumber;
      if (phoneToUse != null && expectedRole == UserRole.delivery) {
        _phoneNumber = phoneToUse;
      }

      await _loadUserData(userCredential.user!.uid);
      
      if (_userData != null) {
        _authStatus = AuthStatus.authenticated;
        _otpStatus = OTPStatus.verified;
        _error = null;
        
        // If it's a delivery partner logging in for the first time, mark as registered
        if (_userRole == UserRole.delivery && _userData!['isRegistered'] == false) {
          await _markDeliveryPartnerAsRegistered(userCredential.user!.uid);
        }
        
        print('🔥 Sign in successful');
      } else {
        await _auth.signOut();
        throw Exception('User data not found or inactive');
      }

    } catch (e) {
      print('🔥 Sign in error: $e');
      _authStatus = AuthStatus.unauthenticated;
      _otpStatus = OTPStatus.failed;
      throw e;
    }
  }

  // Mark delivery partner as registered on first login
  Future<void> _markDeliveryPartnerAsRegistered(String uid) async {
    try {
      await _firestore.collection('delivery').doc(uid).update({
        'isRegistered': true,
        'lastLoginAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      // Update local data
      if (_userData != null) {
        _userData!['isRegistered'] = true;
        _userData!['lastLoginAt'] = Timestamp.now();
        _userData!['updatedAt'] = Timestamp.now();
      }
      
      print('🔥 Delivery partner marked as registered');
    } catch (e) {
      print('🔥 Error marking delivery partner as registered: $e');
      // Don't throw error, this is not critical for authentication
    }
  }

  // Get error message from FirebaseAuthException
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'invalid-verification-code':
        return 'Invalid OTP code';
      case 'session-expired':
        return 'OTP session expired. Please request a new code';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset OTP state
  void resetOTPState() {
    _otpStatus = OTPStatus.idle;
    _verificationId = null;
    _phoneNumber = null;
    _error = null;
    notifyListeners();
  }

  // Reset first admin check
  void resetFirstAdminCheck() {
    _hasCheckedFirstAdmin = false;
    _isFirstAdmin = false;
    notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🔥 Signing out...');
      
      // Update online status for delivery partners
      if (_userRole == UserRole.delivery && _user != null) {
        try {
          await _firestore.collection('delivery').doc(_user!.uid).update({
            'isOnline': false,
            'updatedAt': Timestamp.now(),
          });
        } catch (e) {
          print('🔥 Warning: Could not update online status: $e');
        }
      }
      
      await _auth.signOut();
      _user = null;
      _userData = null;
      _userRole = null;
      _authStatus = AuthStatus.unauthenticated;
      _otpStatus = OTPStatus.idle;
      _verificationId = null;
      _phoneNumber = null;
      _error = null;
      _sessionLocked = false;
      notifyListeners();
    } catch (e) {
      print('🔥 Error signing out: $e');
    }
  } 

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}