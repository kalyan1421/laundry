// providers/auth_provider.dart - Delivery Partner Authentication
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_partner_model.dart';
import 'dart:async';

enum AuthStatus { loading, authenticated, unauthenticated }
enum OTPStatus { idle, sending, sent, verifying, verified, failed }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  DeliveryPartnerModel? _deliveryPartner;
  AuthStatus _authStatus = AuthStatus.loading;
  OTPStatus _otpStatus = OTPStatus.idle;
  bool _isLoading = false;
  String? _error;
  String? _verificationId;
  String? _phoneNumber;
  StreamSubscription<User?>? _authSubscription;
  
  // Getters
  User? get user => _user;
  DeliveryPartnerModel? get deliveryPartner => _deliveryPartner;
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
        print('🚚 Delivery Auth state changed: ${user?.uid}');
        
        _user = user;
        
        if (user != null) {
          await _loadDeliveryPartnerData(user.uid);
        } else {
          _deliveryPartner = null;
          _authStatus = AuthStatus.unauthenticated;
        }
        
        notifyListeners();
      },
      onError: (error) {
        print('🚚 Auth stream error: $error');
        _authStatus = AuthStatus.unauthenticated;
        notifyListeners();
      },
    );
  }

  // Load delivery partner data from Firestore
  Future<void> _loadDeliveryPartnerData(String uid) async {
    print('🚚 Loading delivery partner data for UID: $uid');
    try {
      // Check delivery collection by UID first
      DocumentSnapshot deliveryDoc = await _firestore.collection('delivery').doc(uid).get();
      if (deliveryDoc.exists && deliveryDoc.data() != null) {
        final data = deliveryDoc.data() as Map<String, dynamic>;
        print('🚚 Delivery doc found for UID: $data');
        if (data['isActive'] == true) {
          _deliveryPartner = DeliveryPartnerModel.fromMap({
            ...data,
            'id': deliveryDoc.id,
          });
          _authStatus = AuthStatus.authenticated;
          print('🚚 ✅ Delivery partner authenticated with UID: $uid');
          return;
        }
      }

      // If not found by UID, search by phone number and link the account
      print('🚚 Delivery partner not found by UID, searching by phone...');
      final currentUserPhone = _auth.currentUser?.phoneNumber;
      
      if (currentUserPhone != null) {
        print('🚚 Current user phone: $currentUserPhone');
        
        // First try the phone index for faster lookup
        String phoneKey = currentUserPhone.replaceAll('+', '');
        final indexDoc = await _firestore
            .collection('delivery_phone_index')
            .doc(phoneKey)
            .get();
        
        String? deliveryPartnerId;
        
        if (indexDoc.exists && indexDoc.data()?['isActive'] == true) {
          deliveryPartnerId = indexDoc.data()!['deliveryPartnerId'];
          print('🚚 Found delivery partner ID from index: $deliveryPartnerId');
        } else {
          // Fallback: search by phone in delivery collection
          print('🚚 Searching delivery collection by phone...');
          final QuerySnapshot phoneQuery = await _firestore
              .collection('delivery')
              .where('isActive', isEqualTo: true)
              .where('phoneNumber', isEqualTo: currentUserPhone)
              .limit(1)
              .get();
          
          if (phoneQuery.docs.isNotEmpty) {
            deliveryPartnerId = phoneQuery.docs.first.id;
            print('🚚 Found delivery partner in main collection: $deliveryPartnerId');
          }
        }
        
        if (deliveryPartnerId != null) {
          // Get the delivery partner data
          final deliveryDoc = await _firestore.collection('delivery').doc(deliveryPartnerId).get();
          
          if (deliveryDoc.exists && deliveryDoc.data()?['isActive'] == true) {
            final data = deliveryDoc.data()!;
            
            // Link Firebase Auth UID to delivery partner record
            print('🚚 Linking Firebase Auth UID to delivery partner record...');
            
            Map<String, dynamic> updateData = {
              'uid': uid,
              'isRegistered': true,
              'authenticationStatus': 'verified',
              'firstLoginRequired': false,
              'updatedAt': Timestamp.now(),
              'metadata.firstLoginCompleted': true,
              'metadata.linkedToFirebaseAuth': true,
              'metadata.linkedAt': Timestamp.now(),
            };
            
            // If this is their first login, mark it
            if (data['firstLoginRequired'] == true) {
              updateData['firstLoginAt'] = Timestamp.now();
              print('🚚 Recording first login for delivery partner');
            }
            
            try {
              await _firestore.collection('delivery').doc(deliveryPartnerId).update(updateData);
              
              // Update the phone index if it exists
              if (indexDoc.exists) {
                await _firestore.collection('delivery_phone_index').doc(phoneKey).update({
                  'linkedToUID': uid,
                  'linkedAt': Timestamp.now(),
                });
              }
              
              _deliveryPartner = DeliveryPartnerModel.fromMap({
                ...data,
                ...updateData,
                'id': deliveryPartnerId,
              });
              _authStatus = AuthStatus.authenticated;
              print('🚚 ✅ Delivery partner linked and authenticated: $deliveryPartnerId');
              return;
              
            } catch (updateError) {
              print('🚚 ⚠️ Failed to update delivery partner record: $updateError');
              print('🚚 🔄 Proceeding with authentication using existing data...');
              
              // Even if the update fails, we can still authenticate the user
              // with the existing data and retry the linking later
              _deliveryPartner = DeliveryPartnerModel.fromMap({
                ...data,
                'id': deliveryPartnerId,
                // Don't include the uid update if it failed
              });
              _authStatus = AuthStatus.authenticated;
              _error = 'Authentication successful, but profile sync may be pending. Please contact support if issues persist.';
              print('🚚 ⚠️ Delivery partner authenticated with fallback mode: $deliveryPartnerId');
              return;
            }
          }
        }
      }
      
      // Delivery partner not found
      print('🚚 ❌ Delivery partner data not found for UID: $uid');
      _authStatus = AuthStatus.unauthenticated;
      _deliveryPartner = null;

    } catch (e) {
      print('🚚 Error loading delivery partner data: $e');
      _error = 'Failed to load delivery partner profile.';
      _authStatus = AuthStatus.unauthenticated;
    }
  }

  // Send OTP for delivery partner login
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      print('🚚 Sending OTP to delivery partner: $phoneNumber');
      _isLoading = true;
      _otpStatus = OTPStatus.sending;
      _error = null;
      notifyListeners();

      String formattedPhone = phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';
      _phoneNumber = formattedPhone;
      print('🚚 Formatted phone: $formattedPhone');

      // Check if delivery partner exists with this phone number using the phone index
      try {
        print('🚚 Checking delivery partner in phone index: $formattedPhone');
        
        // First check the phone index for faster lookup
        String phoneKey = formattedPhone.replaceAll('+', '');
        final indexDoc = await _firestore
            .collection('delivery_phone_index')
            .doc(phoneKey)
            .get();
        
        if (indexDoc.exists && indexDoc.data()?['isActive'] == true) {
          String deliveryPartnerId = indexDoc.data()!['deliveryPartnerId'];
          print('🚚 Found delivery partner ID from index: $deliveryPartnerId');
          
          // Verify the delivery partner record exists and is active
          final deliveryDoc = await _firestore
              .collection('delivery')
              .doc(deliveryPartnerId)
              .get();
          
          if (!deliveryDoc.exists || deliveryDoc.data()?['isActive'] != true) {
            print('🚚 ❌ Delivery partner record not found or inactive');
            _error = 'Delivery partner account is inactive. Contact administrator.';
            _otpStatus = OTPStatus.failed;
            _isLoading = false;
            notifyListeners();
            return false;
          }
          
          final deliveryData = deliveryDoc.data()!;
          print('🚚 ✅ Valid delivery partner found: ${deliveryData['name']}');
          
          // Update login attempt metadata
          await _firestore.collection('delivery').doc(deliveryPartnerId).update({
            'metadata.lastLoginAttempt': Timestamp.now(),
            'metadata.loginAttempts': FieldValue.increment(1),
          });
          
        } else {
          // Fallback: check all delivery documents (for backward compatibility)
          print('🚚 Phone not found in index, checking all delivery documents...');
          
          final QuerySnapshot deliveryQuery = await _firestore
              .collection('delivery')
              .where('isActive', isEqualTo: true)
              .where('phoneNumber', isEqualTo: formattedPhone)
              .limit(1)
              .get();
          
          if (deliveryQuery.docs.isEmpty) {
            print('🚚 ❌ No active delivery partner found with phone: $formattedPhone');
            _error = 'No delivery partner account found with this phone number. Contact administrator to create your account.';
            _otpStatus = OTPStatus.failed;
            _isLoading = false;
            notifyListeners();
            return false;
          }
          
          print('🚚 ✅ Delivery partner found in main collection');
        }
        
      } catch (e) {
        print('🚚 Error checking delivery partner: $e');
        _error = 'Error verifying delivery partner account. Please try again.';
        _otpStatus = OTPStatus.failed;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Send OTP via Firebase Auth
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('🚚 Auto verification completed');
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('🚚 Verification failed: ${e.message}');
          _error = e.message ?? 'OTP verification failed';
          _otpStatus = OTPStatus.failed;
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          print('🚚 OTP sent successfully');
          _verificationId = verificationId;
          _otpStatus = OTPStatus.sent;
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('🚚 Auto retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );

      return true;
      
    } catch (e) {
      print('🚚 Error sending OTP: $e');
      _error = 'Failed to send OTP. Please try again.';
      _otpStatus = OTPStatus.failed;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String otp) async {
    try {
      print('🚚 Verifying OTP: $otp');
      _isLoading = true;
      _otpStatus = OTPStatus.verifying;
      _error = null;
      notifyListeners();

      if (_verificationId == null) {
        _error = 'Verification ID not found. Please request OTP again.';
        _otpStatus = OTPStatus.failed;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      
      _otpStatus = OTPStatus.verified;
      _isLoading = false;
      notifyListeners();
      
      print('🚚 ✅ OTP verified successfully');
      return true;

    } catch (e) {
      print('🚚 Error verifying OTP: $e');
      _error = 'Invalid OTP. Please try again.';
      _otpStatus = OTPStatus.failed;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _deliveryPartner = null;
      _authStatus = AuthStatus.unauthenticated;
      _otpStatus = OTPStatus.idle;
      _error = null;
      _verificationId = null;
      _phoneNumber = null;
      notifyListeners();
      print('🚚 Delivery partner signed out');
    } catch (e) {
      print('🚚 Error signing out: $e');
    }
  }

  // Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
} 