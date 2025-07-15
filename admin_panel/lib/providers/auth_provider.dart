// providers/auth_provider.dart - Simplified version with fixes
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fcm_service.dart';
import 'dart:async';

enum UserRole { admin, delivery, supervisor }
enum AuthStatus { loading, authenticated, unauthenticated }
enum OTPStatus { idle, sending, sent, verifying, verified, failed }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FcmService _fcmService = FcmService();
  
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
  
  AuthProvider() {
    _initAuth();
  }
  
  void _initAuth() {
    _authSubscription = _auth.authStateChanges().listen(
      (User? user) async {
        print('🔥 Auth state changed: ${user?.uid}');
        
        _user = user;
        
        if (user != null) {
          await _loadUserData(user.uid);
        } else {
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

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    print('🔥 Loading user data for UID: $uid');
    try {
      // Check admins collection first
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists && adminDoc.data() != null) {
        final data = adminDoc.data() as Map<String, dynamic>;
        print('🔥 Admin doc found for UID: $data');
        if (data['isActive'] == true) {
          _userData = data;
          // Set role based on the role field in the document
          String roleString = data['role'] ?? 'admin';
          if (roleString == 'supervisor') {
            _userRole = UserRole.supervisor;
          } else {
            _userRole = UserRole.admin;
          }
          _authStatus = AuthStatus.authenticated;
          print('🔥 ✅ Admin/Supervisor user authenticated with UID: $uid, Role: $roleString');
          return;
        }
      }

      // If not found by UID, search through all admin documents
      print('🔥 Admin not found by UID, searching all admin documents...');
      final QuerySnapshot allAdmins = await _firestore.collection('admins').get();
      
      for (var doc in allAdmins.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('🔥 Checking admin doc ${doc.id}: $data');
          
          // Check if this document's UID matches OR phone matches the current Firebase user's phone
          final docUid = data['uid']?.toString();
          final docPhone = data['phoneNumber']?.toString();
          final currentUserPhone = _auth.currentUser?.phoneNumber;
          
          print('🔥 Admin - Doc UID: $docUid, Current UID: $uid');
          print('🔥 Admin - Doc Phone: $docPhone, Current Phone: $currentUserPhone');
          
          bool uidMatch = docUid == uid;
          
          // Enhanced phone matching for admin - try multiple formats
          bool phoneMatch = false;
          if (currentUserPhone != null && docPhone != null) {
            List<String> phoneFormats = [
              currentUserPhone,                                // +919063290632
              currentUserPhone.replaceAll('+91', ''),          // 9063290632
              '+91${currentUserPhone.replaceAll('+91', '')}',  // +919063290632
            ];
            
            List<String> docPhoneFormats = [
              docPhone,                                        // Could be 9063290632 or +919063290632
              docPhone.replaceAll('+91', ''),                  // 9063290632
              '+91${docPhone.replaceAll('+91', '')}',          // +919063290632
            ];
            
            // Check if any format matches
            for (String userFormat in phoneFormats) {
              for (String docFormat in docPhoneFormats) {
                if (userFormat == docFormat) {
                  phoneMatch = true;
                  print('🔥 📞 ADMIN PHONE MATCH! User: "$userFormat" matches Doc: "$docFormat"');
                  break;
                }
              }
              if (phoneMatch) break;
            }
          }
          
          if ((uidMatch || phoneMatch) && data['isActive'] == true) {
            // Update the document with correct UID if it was matched by phone
            if (phoneMatch && docUid != uid) {
              print('🔥 Updating admin doc ${doc.id} with correct UID: $uid');
              await _firestore.collection('admins').doc(doc.id).update({'uid': uid});
              data['uid'] = uid; // Update local data too
            }
            
            _userData = data;
            // Set role based on the role field in the document
            String roleString = data['role'] ?? 'admin';
            if (roleString == 'supervisor') {
              _userRole = UserRole.supervisor;
            } else {
              _userRole = UserRole.admin;
            }
            _authStatus = AuthStatus.authenticated;
            print('🔥 ✅ Admin/Supervisor user found and authenticated: ${doc.id}, Role: $roleString');
            return;
          }
        } catch (e) {
          print('🔥 Error checking admin doc ${doc.id}: $e');
        }
      }

      // Check delivery collection
      DocumentSnapshot deliveryDoc = await _firestore.collection('delivery').doc(uid).get();
      if (deliveryDoc.exists && deliveryDoc.data() != null) {
        final data = deliveryDoc.data() as Map<String, dynamic>;
        print('🔥 Delivery doc found for UID: $data');
        if (data['isActive'] == true) { // Fixed: was checking == false
          _userData = data;
          _userRole = UserRole.delivery;
          _authStatus = AuthStatus.authenticated;
          print('🔥 ✅ Delivery user authenticated with UID: $uid');
          return;
        }
      }

      // If not found by UID, search through all delivery documents
      print('🔥 Delivery not found by UID, searching all delivery documents...');
      final QuerySnapshot allDelivery = await _firestore.collection('delivery').get();
      
      for (var doc in allDelivery.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('🔥 Checking delivery doc ${doc.id}: $data');
          
          // Check if this document's UID matches OR phone matches
          final docUid = data['uid']?.toString();
          final docPhone = data['phoneNumber']?.toString();
          final currentUserPhone = _auth.currentUser?.phoneNumber;
          
          bool uidMatch = docUid == uid;
          bool phoneMatch = currentUserPhone != null && docPhone == currentUserPhone;
          
          if ((uidMatch || phoneMatch) && data['isActive'] == true) {
            // Update the document with correct UID if it was matched by phone
            if (phoneMatch && docUid != uid) {
              print('🔥 Updating delivery doc ${doc.id} with correct UID: $uid');
              await _firestore.collection('delivery').doc(doc.id).update({'uid': uid});
              data['uid'] = uid; // Update local data too
            }
            
            _userData = data;
            _userRole = UserRole.delivery;
            _authStatus = AuthStatus.authenticated;
            print('🔥 ✅ Delivery user found and authenticated: ${doc.id}');
            return;
          }
        } catch (e) {
          print('🔥 Error checking delivery doc ${doc.id}: $e');
        }
      }
      
      // User not found in our collections
      print('🔥 ❌ User data not found for UID: $uid');
      _authStatus = AuthStatus.unauthenticated;
      _userRole = null;
      _userData = null;

    } catch (e) {
      print('🔥 Error loading user data: $e');
      _error = 'Failed to load user profile.';
      _authStatus = AuthStatus.unauthenticated;
    }
  }

  // Send OTP - Simple version
  Future<bool> sendOTP(String phoneNumber, {required UserRole roleToCheck}) async {
    try {
      print('🔥 Sending OTP to: $phoneNumber for role: $roleToCheck');
      _isLoading = true;
      _otpStatus = OTPStatus.sending;
      _error = null;
      notifyListeners();

      String formattedPhone = phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';
      _phoneNumber = formattedPhone;
      print('🔥 Formatted phone: $formattedPhone');

      // For ADMIN or SUPERVISOR: Check if admin/supervisor exists with this phone number
      if (roleToCheck == UserRole.admin || roleToCheck == UserRole.supervisor) {
        try {
          print('🔥 Checking if admin/supervisor exists with phone: $formattedPhone');
          
          // Get ALL documents from admins collection and check each one
          final QuerySnapshot allAdmins = await _firestore
              .collection('admins')
              .get();
          
          print('🔥 Total admin documents found: ${allAdmins.docs.length}');
          
          // Try different phone formats to match against
          List<String> phoneFormats = [
            formattedPhone,                          // +919063290632
            phoneNumber.replaceAll('+91', ''),       // 9063290632
            phoneNumber,                             // Original input
          ];
          
          bool adminFound = false;
          String? foundRole;
          
          // Check each admin document
          for (var doc in allAdmins.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final docPhone = data['phoneNumber']?.toString();
              final docRole = data['role']?.toString() ?? 'admin';
              
              print('🔥 Checking admin doc ${doc.id}: Phone=$docPhone, Role=$docRole, Active=${data['isActive']}');
              
              if (docPhone != null && data['isActive'] == true) {
                // Check if phone matches in any format
                bool phoneMatches = phoneFormats.any((format) => 
                  docPhone == format || 
                  docPhone.replaceAll('+91', '') == format.replaceAll('+91', '')
                );
                
                if (phoneMatches) {
                  print('🔥 📞 ADMIN/SUPERVISOR PHONE MATCH! Doc Phone: "$docPhone", Role: "$docRole"');
                  
                  // Check if the role matches what we're looking for
                  if ((roleToCheck == UserRole.admin && docRole == 'admin') ||
                      (roleToCheck == UserRole.supervisor && docRole == 'supervisor')) {
                    adminFound = true;
                    foundRole = docRole;
                    break;
                  }
                }
              }
            } catch (e) {
              print('🔥 Error checking admin doc ${doc.id}: $e');
            }
          }
          
          if (!adminFound) {
            String roleText = roleToCheck == UserRole.admin ? 'admin' : 'supervisor';
            print('🔥 ❌ No active $roleText found with phone: $formattedPhone');
            _error = 'No active $roleText account found with this phone number';
            _otpStatus = OTPStatus.failed;
            _isLoading = false;
            notifyListeners();
            return false;
          }
          
          print('🔥 ✅ ${foundRole?.toUpperCase()} account found with phone: $formattedPhone');
          
        } catch (e) {
          print('🔥 Error checking admin/supervisor: $e');
          _error = 'Error checking account: $e';
          _otpStatus = OTPStatus.failed;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // For DELIVERY: Don't check existence, just send OTP
      // They might be logging in for the first time

      // Send OTP via Firebase Auth
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('🔥 Auto-verification completed');
          await _signInWithCredential(credential, expectedRole: roleToCheck);
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
  Future<bool> verifyOTP(String otpCode, {required UserRole expectedRole}) async {
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
  Future<void> _signInWithCredential(PhoneAuthCredential credential, {required UserRole expectedRole}) async {
    try {
      print('🔥 Signing in with credential for role: $expectedRole');
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw Exception('Authentication failed');
      }

      print('🔥 Firebase auth successful, UID: ${userCredential.user!.uid}');

      await _loadUserData(userCredential.user!.uid);
      
      if (_userData != null && _userRole == expectedRole) {
        _authStatus = AuthStatus.authenticated;
        _otpStatus = OTPStatus.verified;
        _error = null;
        print('🔥 Sign in successful for role: $_userRole');
        
        // Save FCM token after successful login
        await _saveFCMTokenAfterLogin();
      } else {
        // User authenticated with Firebase but not found in our collections for the expected role
        await _auth.signOut();
        if (expectedRole == UserRole.admin) {
          throw Exception('Admin account not found or inactive');
        } else {
          throw Exception('Delivery account not found or inactive');
        }
      }

    } catch (e) {
      print('🔥 Sign in error: $e');
      _authStatus = AuthStatus.unauthenticated;
      _otpStatus = OTPStatus.failed;
      _error = e.toString();
      throw e;
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

  // Save FCM token after login
  Future<void> _saveFCMTokenAfterLogin() async {
    try {
      print('🔥 Saving FCM token after login for role: $_userRole');
      
      if (_userRole == UserRole.delivery) {
        // For delivery partners, use the enhanced method
        await _fcmService.ensureDeliveryPartnerTokenSaved();
      } else {
        // For admins, use the standard method
        await _fcmService.saveFCMTokenAfterLogin();
      }
      
      print('🔥 FCM token saved successfully');
    } catch (e) {
      print('🔥 Error saving FCM token after login: $e');
      // Don't throw error as FCM is not critical for login flow
    }
  }

  // Method to manually refresh FCM token (can be called from UI)
  Future<void> refreshFCMToken() async {
    try {
      await _fcmService.saveFCMTokenAfterLogin();
      print('🔥 FCM token refreshed successfully');
    } catch (e) {
      print('🔥 Error refreshing FCM token: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🔥 Signing out...');
      
      // Delete FCM token before signing out
      try {
        await _fcmService.deleteTokenForCurrentUser();
        print('🔥 FCM token deleted successfully');
      } catch (e) {
        print('🔥 Error deleting FCM token: $e');
        // Continue with sign out even if token deletion fails
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