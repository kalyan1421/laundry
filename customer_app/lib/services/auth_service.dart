// lib/services/auth_service.dart
import 'package:customer_app/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/errors/app_exceptions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Send OTP to phone number with improved error handling
  Future<String> sendOTP({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      String completePhoneNumber = '+91$phoneNumber';
      
      print('Sending OTP to: $completePhoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: completePhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          print('Auto verification completed');
          verificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.code} - ${e.message}');
          _handleVerificationError(e, verificationFailed);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Code sent successfully. Verification ID: $verificationId');
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout. Verification ID: $verificationId');
          codeAutoRetrievalTimeout(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
      
      return completePhoneNumber;
    } catch (e) {
      print('Error in sendOTP: $e');
      throw AuthException('Failed to send OTP: ${e.toString()}');
    }
  }

  // Handle verification errors with specific messages
  void _handleVerificationError(
    FirebaseAuthException e, 
    Function(FirebaseAuthException) verificationFailed
  ) {
    String errorMessage;
    
    switch (e.code) {
      case 'invalid-phone-number':
        errorMessage = 'The phone number format is invalid.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many requests. Please try again later.';
        break;
      case 'quota-exceeded':
        errorMessage = 'SMS quota exceeded. Please try again later.';
        break;
      case 'app-not-authorized':
        errorMessage = 'App not authorized for SMS verification.';
        break;
      case 'missing-phone-number':
        errorMessage = 'Phone number is required.';
        break;
      case 'unknown':
        // This often happens with Play Integrity issues in debug mode
        if (kDebugMode) {
          errorMessage = 'Verification failed. This is common in debug mode. Please ensure you have proper Firebase configuration.';
        } else {
          errorMessage = 'Unknown error occurred. Please try again.';
        }
        break;
      default:
        errorMessage = e.message ?? 'Verification failed. Please try again.';
    }
    
    final customException = FirebaseAuthException(
      code: e.code,
      message: errorMessage,
    );
    
    verificationFailed(customException);
  }

  // Verify OTP and sign in with improved error handling
  Future<UserCredential> verifyOTPAndSignIn({
    required String verificationId,
    required String otp,
  }) async {
    try {
      print('Verifying OTP: $otp with verification ID: $verificationId');
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      print('OTP verification successful for user: ${userCredential.user?.uid}');
      
      // Create or update user document in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(userCredential.user!);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'invalid-verification-code':
          throw AuthException('Invalid OTP. Please check and try again.');
        case 'invalid-verification-id':
          throw AuthException('Verification session expired. Please request a new OTP.');
        case 'session-expired':
          throw AuthException('OTP session expired. Please request a new OTP.');
        case 'code-expired':
          throw AuthException('OTP has expired. Please request a new one.');
        case 'too-many-requests':
          throw AuthException('Too many verification attempts. Please try again later.');
        default:
          throw AuthException('Verification failed: ${e.message}');
      }
    } catch (e) {
      print('General exception in verifyOTPAndSignIn: $e');
      throw AuthException('Verification failed: ${e.toString()}');
    }
  }

  // Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(User user) async {
    try {
      DocumentReference userDoc = _firestore.collection('users').doc(user.uid);
      DocumentSnapshot snapshot = await userDoc.get();

      Map<String, dynamic> userData = {
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'lastSignIn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        // New user
        userData.addAll({
          'name': '',
          'email': '',
          'profileImageUrl': '',
          'addresses': [],
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Creating new user document for: ${user.uid}');
      } else {
        print('Updating existing user document for: ${user.uid}');
      }

      await userDoc.set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating user document: $e');
      // Don't throw here as auth was successful
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      throw DatabaseException('Failed to get user data: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? email,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      if (additionalData != null) updateData.addAll(additionalData);

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      throw DatabaseException('Failed to update profile: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete user account
        await user.delete();
      }
    } catch (e) {
      throw AuthException('Failed to delete account: ${e.toString()}');
    }
  }

  // Check if phone number is already registered
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      String completePhoneNumber = '+91$phoneNumber';
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: completePhoneNumber)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone number registration: $e');
      return false;
    }
  }

  // Force resend OTP (useful when the first attempt fails)
  Future<void> forceResendOTP({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    try {
      String completePhoneNumber = '+91$phoneNumber';
      
      print('Force resending OTP to: $completePhoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: completePhoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: (e) => _handleVerificationError(e, verificationFailed),
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
      );
    } catch (e) {
      print('Error in forceResendOTP: $e');
      throw AuthException('Failed to resend OTP: ${e.toString()}');
    }
  }
}