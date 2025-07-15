// lib/services/auth_service.dart
import 'package:customer_app/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/errors/app_exceptions.dart';
import '../core/utils/id_utils.dart'; // Import IdUtils
import 'throttle_service.dart'; // Import ThrottleService

// Added imports for QR code generation and storage
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:ui' as ui; // For ui.Image
import 'dart:io' as io;
import 'qr_code_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Rate limiting variables
  static DateTime? _lastOtpRequest;
  static const Duration _otpCooldownDuration = Duration(minutes: 1);
  static String? _lastPhoneNumber; // Added FirebaseStorage instance

  // Current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Send OTP to phone number with enhanced debugging and dual-layer rate limiting
  Future<String> sendOTP({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      String completePhoneNumber = '+91$phoneNumber';
      
      // 🔒 LAYER 1: Client-side rate limiting
      final now = DateTime.now();
      if (_lastOtpRequest != null && 
          _lastPhoneNumber == completePhoneNumber &&
          now.difference(_lastOtpRequest!) < _otpCooldownDuration) {
        final remainingTime = _otpCooldownDuration - now.difference(_lastOtpRequest!);
        final remainingSeconds = remainingTime.inSeconds;
        print('🔥 ⏱️ Client-side rate limit hit. Please wait ${remainingSeconds} seconds before requesting another OTP.');
        final rateLimitException = FirebaseAuthException(
          code: 'rate-limit', 
          message: 'Please wait ${remainingSeconds} seconds before requesting another OTP for this number.'
        );
        verificationFailed(rateLimitException);
        return completePhoneNumber;
      }
      
      // 🔒 LAYER 2: Server-side throttling check
      print('🔒 Checking server-side throttling...');
      final throttleResult = await ThrottleService.checkThrottle(completePhoneNumber);
      print('🔒 Throttle result: $throttleResult');
      
      if (!throttleResult.isAllowed) {
        print('🔒 ❌ Server-side throttling blocked the request');
        final serverThrottleException = FirebaseAuthException(
          code: throttleResult.isBlocked ? 'account-blocked' : 'server-rate-limit',
          message: throttleResult.reason ?? 'Request blocked by server-side throttling.'
        );
        verificationFailed(serverThrottleException);
        return completePhoneNumber;
      }
      
      print('🔥 Firebase Auth: Starting OTP process');
      print('🔥 Phone Number: $completePhoneNumber');
      
      // Record this request for client-side rate limiting
      _lastOtpRequest = now;
      _lastPhoneNumber = completePhoneNumber;
      print('🔥 Firebase App: ${_auth.app.name}');
      print('🔥 Current User: ${_auth.currentUser?.uid ?? 'None'}');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: completePhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          print('🔥 ✅ Auto verification completed');
          verificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('🔥 ❌ Verification failed: ${e.code} - ${e.message}');
          print('🔥 Stack trace: ${e.stackTrace}');
          
          // Record failed attempt in server-side throttling
          ThrottleService.recordAttempt(completePhoneNumber, isSuccessful: false);
          
          _handleVerificationError(e, verificationFailed);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('🔥 ✅ Code sent successfully');
          print('🔥 Verification ID: $verificationId');
          print('🔥 Resend Token: $resendToken');
          
          // Record successful OTP request in server-side throttling
          ThrottleService.recordAttempt(completePhoneNumber, isSuccessful: true);
          
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('🔥 ⏰ Auto retrieval timeout');
          print('🔥 Verification ID: $verificationId');
          codeAutoRetrievalTimeout(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
      
      print('🔥 Firebase verifyPhoneNumber call completed');
      return completePhoneNumber;
    } catch (e, stackTrace) {
      print('🔥 ❌ Exception in sendOTP: $e');
      print('🔥 Stack trace: $stackTrace');
      throw AuthException('Failed to send OTP: ${e.toString()}');
    }
  }

  // Handle verification errors with specific messages
  void _handleVerificationError(
    FirebaseAuthException e, 
    Function(FirebaseAuthException) verificationFailed
  ) {
    String errorMessage;
    
    print('🔥 Handling verification error: ${e.code}');
    
    switch (e.code) {
      case 'invalid-phone-number':
        errorMessage = 'The phone number format is invalid.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many requests. Please try again later (15-30 minutes).';
        break;
      case 'rate-limit':
        errorMessage = e.message ?? 'Please wait before requesting another OTP.';
        break;
      case 'server-rate-limit':
        errorMessage = e.message ?? 'Server rate limit exceeded. Please try again later.';
        break;
      case 'account-blocked':
        errorMessage = e.message ?? 'Your account has been temporarily blocked due to excessive requests.';
        break;
      case 'quota-exceeded':
        errorMessage = 'SMS quota exceeded. Please try again later.';
        break;
      case 'app-not-authorized':
        errorMessage = 'App not authorized for SMS verification. Please check Firebase configuration.';
        break;
      case 'missing-phone-number':
        errorMessage = 'Phone number is required.';
        break;
      case 'captcha-check-failed':
        errorMessage = 'Captcha verification failed. Please try again.';
        break;
      case 'unknown':
        // This often happens with Play Integrity issues in debug mode
        errorMessage = 'Authentication verification failed. This could be due to:\n'
                     '1. Network connectivity issues\n'
                     '2. Firebase configuration mismatch\n'
                     '3. Rate limiting - please wait a few minutes\n'
                     '4. App verification issues\n\n'
                     'Please try again in a few minutes.';
        break;
      case 'network-request-failed':
        errorMessage = 'Network error. Please check your internet connection.';
        break;
      default:
        errorMessage = e.message ?? 'Verification failed. Please try again.';
    }
    
    print('🔥 Error message: $errorMessage');
    
    final customException = FirebaseAuthException(
      code: e.code,
      message: errorMessage,
    );
    
    verificationFailed(customException);
  }

  // Verify OTP and sign in with enhanced debugging
  Future<UserModel> verifyOTPAndSignIn({
    required String verificationId,
    required String otp,
  }) async {
    try {
      print('🔥 Starting OTP verification');
      print('🔥 Verification ID: $verificationId');
      print('🔥 OTP: $otp');
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      print('🔥 Created PhoneAuthCredential');

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      print('🔥 ✅ OTP verification successful');
      print('🔥 User ID: ${userCredential.user?.uid}');
      print('🔥 Phone: ${userCredential.user?.phoneNumber}');
      
      if (userCredential.user != null) {
        UserModel userModel = await _createOrUpdateUserDocument(userCredential.user!);
        return userModel;
      } else {
        throw AuthException('User is null after successful credential sign-in.');
      }
      
    } on FirebaseAuthException catch (e) {
      print('🔥 ❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      print('🔥 Stack trace: ${e.stackTrace}');
      
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
    } catch (e, stackTrace) {
      print('🔥 ❌ General exception in verifyOTPAndSignIn: $e');
      print('🔥 Stack trace: $stackTrace');
      if (e is AuthException) rethrow;
      throw AuthException('Verification or user setup failed: ${e.toString()}');
    }
  }

  // Sign in with phone credential and return UserModel
  Future<UserModel> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      print('🔥 Signing in with phone credential.');
      final userCredential = await _auth.signInWithCredential(credential);
      
      print('🔥 ✅ Signed in with credential successful');
      print('🔥 User ID: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        final userModel = await _createOrUpdateUserDocument(userCredential.user!);
        return userModel;
      } else {
        throw AuthException('User is null after successful credential sign-in.');
      }
    } on FirebaseAuthException catch (e) {
      print('🔥 ❌ Firebase Auth Exception during credential sign-in: ${e.code} - ${e.message}');
      throw AuthException('Failed to sign in with credential: ${e.message}');
    } catch (e) {
      print('🔥 ❌ General exception during credential sign-in: $e');
      if (e is AuthException) rethrow;
      throw AuthException('An unknown error occurred during credential sign-in.');
    }
  }

  // Create or update user document in Firestore and return UserModel
  Future<UserModel> _createOrUpdateUserDocument(User user) async {
    try {
      print('🔥 Creating/updating user document for: ${user.uid}');
      DocumentReference userDoc = _firestore.collection('customer').doc(user.uid);
      DocumentSnapshot snapshot = await userDoc.get();
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'lastSignIn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        String clientId = IdUtils.generateClientId();
        print('🔥 New user. Generating Client ID: $clientId');
        userData.addAll({
          'clientId': clientId,
          'name': '',
          'email': user.email ?? '',
          'profileImageUrl': user.photoURL ?? '',
          'isProfileComplete': false,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
          'qrCodeUrl': null,
        });
        print('🔥 Creating new user document with data: $userData');
      } else {
        print('🔥 Updating existing user document.');
        Map<String, dynamic> existingData = snapshot.data() as Map<String, dynamic>? ?? {};
        if (!existingData.containsKey('role')) {
          userData['role'] = 'customer';
        }
        if (!existingData.containsKey('clientId')) {
          String clientId = IdUtils.generateClientId();
          userData['clientId'] = clientId;
          print('🔥 Adding missing Client ID to existing user: $clientId');
        }
        if (!existingData.containsKey('qrCodeUrl')) {
          userData['qrCodeUrl'] = null;
        }
      }

      await userDoc.set(userData, SetOptions(merge: true));
      print('🔥 ✅ User document saved successfully for UID: ${user.uid}');
      
      // Auto-generate QR code if it doesn't exist
      try {
        String userName = userData['name'] ?? user.displayName ?? 'Unknown User';
        String phoneNumber = userData['phoneNumber'] ?? user.phoneNumber ?? '';
        
        await QRCodeService.ensureUserQRCodeExists(user.uid, userName, phoneNumber);
        print('🔥 ✅ QR code auto-generated/verified for user: ${user.uid}');
      } catch (e) {
        print('🔥 ⚠️ Failed to auto-generate QR code for user ${user.uid}: $e');
        // Continue without failing the entire authentication process
      }
      
      // Add a small delay and retry mechanism to handle Firestore eventual consistency
      int retryCount = 0;
      const maxRetries = 3;
      const retryDelay = Duration(milliseconds: 500);
      
      while (retryCount < maxRetries) {
        try {
          // Small delay to allow Firestore to propagate the write
          if (retryCount > 0) {
            await Future.delayed(retryDelay);
          }
          
          DocumentSnapshot newSnapshot = await userDoc.get();
          if (newSnapshot.exists) {
            print('🔥 ✅ User document successfully fetched after ${retryCount} retries for UID: ${user.uid}');
            return UserModel.fromFirestore(newSnapshot as DocumentSnapshot<Map<String, dynamic>>);
          } else {
            print('🔥 ⚠️ User document still not found, retry ${retryCount + 1}/${maxRetries}');
          }
        } catch (e) {
          print('🔥 ⚠️ Error fetching user document on retry ${retryCount + 1}: $e');
        }
        retryCount++;
      }
      
      // If all retries failed, throw an exception
      throw AuthException('Failed to fetch user document after creation. Please try signing in again.');

    } catch (e, stackTrace) {
      print('🔥 ❌ Error creating/updating user document for UID ${user.uid}: $e');
      print('🔥 Stack trace: $stackTrace');
      throw AuthException('Failed to create or update user profile.');
    }
  }

  // Method to ensure user document exists, creating with defaults if not.
  Future<bool> ensureUserDocument(User user) async {
    try {
      DocumentReference userDoc = _firestore.collection('customer').doc(user.uid);
      DocumentSnapshot snapshot = await userDoc.get();

      if (!snapshot.exists) {
        print('🔥 User document missing for ${user.uid}, creating with defaults.');
        await _createOrUpdateUserDocument(user);
        return true;
      }
      print('🔥 User document already exists for ${user.uid}.');
      return true;
    } catch (e, stackTrace) {
      print('🔥 ❌ Error ensuring user document for ${user.uid}: $e');
      print('🔥 Stack trace: $stackTrace');
      return false;
    }
  }

  // Get user data from Firestore, including addresses subcollection and order count
  Future<UserModel?> getUserData(String uid) async {
    try {
      print('🔥 AuthService.getUserData: Fetching user document for UID: $uid');
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('customer').doc(uid).get();

      if (!userDoc.exists) {
        print('🔥 AuthService.getUserData: User document does not exist for UID: $uid');
        return null;
      }
      print('🔥 AuthService.getUserData: User document fetched for UID: $uid');

      // Fetch addresses from subcollection
      List<Address> addresses = [];
      try {
        print('🔥 AuthService.getUserData: Fetching addresses subcollection for UID: $uid');
        final QuerySnapshot<Map<String, dynamic>> addressSnapshot =
            await _firestore.collection('customer').doc(uid).collection('addresses').get();
        
        print('🔥 AuthService.getUserData: Found ${addressSnapshot.docs.length} address documents');
        
        if (addressSnapshot.docs.isNotEmpty) {
          for (int i = 0; i < addressSnapshot.docs.length; i++) {
            final doc = addressSnapshot.docs[i];
            final data = doc.data();
            print('🔥 AuthService.getUserData: Address $i - Document ID: ${doc.id}');
            print('🔥 AuthService.getUserData: Address $i - Data fields: ${data.keys.toList()}');
            print('🔥 AuthService.getUserData: Address $i - Type: ${data['type']}');
            print('🔥 AuthService.getUserData: Address $i - AddressLine1: ${data['addressLine1']}');
            print('🔥 AuthService.getUserData: Address $i - DoorNumber: ${data['doorNumber']}');
            print('🔥 AuthService.getUserData: Address $i - FloorNumber: ${data['floorNumber']}');
            print('🔥 AuthService.getUserData: Address $i - ApartmentName: ${data['apartmentName']}');
            print('🔥 AuthService.getUserData: Address $i - City: ${data['city']}');
            print('🔥 AuthService.getUserData: Address $i - IsPrimary: ${data['isPrimary']}');
            print('🔥 AuthService.getUserData: Address $i - Latitude: ${data['latitude']}');
            print('🔥 AuthService.getUserData: Address $i - Longitude: ${data['longitude']}');
            
            try {
              final address = Address.fromMap({...data, 'id': doc.id});
              addresses.add(address);
              print('🔥 AuthService.getUserData: Address $i - Successfully created Address object');
              print('🔥 AuthService.getUserData: Address $i - Full address: "${address.fullAddress}"');
            } catch (e) {
              print('🔥 AuthService.getUserData: Address $i - Error creating Address object: $e');
            }
          }
          
          print('🔥 AuthService.getUserData: Successfully processed ${addresses.length} addresses');
          
          // Log address summary
          for (int i = 0; i < addresses.length; i++) {
            final addr = addresses[i];
            print('🔥 AuthService.getUserData: Address $i Summary - Type: ${addr.type}, Primary: ${addr.isPrimary}');
            print('🔥 AuthService.getUserData: Address $i Summary - AddressLine1: "${addr.addressLine1}"');
            print('🔥 AuthService.getUserData: Address $i Summary - AddressLine2: "${addr.addressLine2}"');
            print('🔥 AuthService.getUserData: Address $i Summary - City: "${addr.city}"');
            print('🔥 AuthService.getUserData: Address $i Summary - Full: "${addr.fullAddress}"');
          }
        } else {
          print('🔥 AuthService.getUserData: No addresses found in subcollection for UID: $uid');
        }
      } catch (e, stackTrace) {
        print('🔥 ❌ AuthService.getUserData: Error fetching addresses for UID $uid: $e');
        print('🔥 Stack trace: $stackTrace');
        // Continue without addresses if subcollection fetch fails, or handle as critical error
      }

      // Fetch order count
      int orderCount = 0;
      try {
        print('🔥 AuthService.getUserData: Fetching order count for UID: $uid');
        final QuerySnapshot<Map<String, dynamic>> orderSnapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: uid)
            .get();
        orderCount = orderSnapshot.docs.length;
        print('🔥 AuthService.getUserData: Fetched order count: $orderCount for UID: $uid');
      } catch (e, stackTrace) {
        print('🔥 ❌ AuthService.getUserData: Error fetching order count for UID $uid: $e');
        print('🔥 Stack trace: $stackTrace');
        // Continue with orderCount = 0 if fetch fails
      }
      
      print('🔥 AuthService.getUserData: Creating UserModel with ${addresses.length} addresses and $orderCount orders for UID: $uid');
      final userModel = UserModel.fromFirestore(userDoc, addresses: addresses, orderCount: orderCount);
      
      print('🔥 AuthService.getUserData: UserModel created successfully');
      print('🔥 AuthService.getUserData: UserModel addresses count: ${userModel.addresses.length}');
      print('🔥 AuthService.getUserData: UserModel primary address: ${userModel.primaryAddress?.fullAddress ?? 'None'}');
      
      return userModel;

    } catch (e, stackTrace) {
      print('🔥 ❌ AuthService.getUserData: Error fetching user data for UID $uid: $e');
      print('🔥 Stack trace: $stackTrace');
      throw AuthException('Failed to get user data: ${e.toString()}');
    }
  }

  // New private method to generate and store QR code
  Future<String?> _generateAndStoreQrCode(String userId, String clientId) async {
    try {
      print('🔥 Generating QR code for clientId: $clientId');
      final QrPainter painter = QrPainter(
        data: clientId,
        version: QrVersions.auto,
        gapless: false,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      // Convert QrPainter to image data
      final ui.Image image = await painter.toImage(200); // size of the image
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        print('🔥 ❌ Failed to convert QR painter to byte data.');
        return null;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Upload to Firebase Storage
      final String filePath = 'user_qrs/$userId/qr_code.png';
      final Reference storageRef = _storage.ref().child(filePath);
      
      print('🔥 Uploading QR code to: $filePath');
      await storageRef.putData(pngBytes, SettableMetadata(contentType: 'image/png'));
      final String downloadUrl = await storageRef.getDownloadURL();
      
      print('🔥 ✅ QR code uploaded. URL: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      print('🔥 ❌ Error generating or uploading QR code for $userId: $e');
      print('🔥 Stack trace: $stackTrace');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? email,
    String? profilePhotoUrl,
  }) async {
    try {
      print('🔥 Updating user profile for: $uid');
      
      Map<String, dynamic> dataToUpdate = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) dataToUpdate['name'] = name;
      if (email != null) dataToUpdate['email'] = email;
      if (profilePhotoUrl != null) dataToUpdate['profileImageUrl'] = profilePhotoUrl;
      
      // Check if profile is now complete
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore.collection('customer').doc(uid).get();
      if (userDoc.exists) {
        final currentData = userDoc.data()!;
        final newName = name ?? currentData['name'];
        final newEmail = email ?? currentData['email'];

        if (newName.isNotEmpty && newEmail.isNotEmpty) {
          dataToUpdate['isProfileComplete'] = true;
        }
      }

      await _firestore.collection('customer').doc(uid).update(dataToUpdate);
      print('🔥 ✅ User profile updated successfully');
    } catch (e, stackTrace) {
      print('🔥 ❌ Error updating user profile: $e');
      print('🔥 Stack trace: $stackTrace');
      throw DatabaseException('Failed to update profile: ${e.toString()}');
    }
  }

  // Upload profile photo and get URL
  Future<String> uploadProfilePhoto(String filePath, String uid) async {
    try {
      final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
      final uploadTask = await ref.putFile(io.File(filePath));
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      throw StorageException('Failed to upload profile photo: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🔥 Signing out user');
      await _auth.signOut();
      print('🔥 ✅ Sign out successful');
    } catch (e, stackTrace) {
      print('🔥 ❌ Error signing out: $e');
      print('🔥 Stack trace: $stackTrace');
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        print('🔥 Deleting account for: ${user.uid}');
        
        // Delete user document from Firestore
        await _firestore.collection('customer').doc(user.uid).delete();
        
        // Delete user account
        await user.delete();
        
        print('🔥 ✅ Account deleted successfully');
      }
    } catch (e, stackTrace) {
      print('🔥 ❌ Error deleting account: $e');
      print('🔥 Stack trace: $stackTrace');
      throw AuthException('Failed to delete account: ${e.toString()}');
    }
  }

  // Check if phone number is already registered
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      String completePhoneNumber = '+91$phoneNumber';
      print('🔥 Checking if phone number is registered: $completePhoneNumber');
      
      QuerySnapshot query = await _firestore
          .collection('customer')
          .where('phoneNumber', isEqualTo: completePhoneNumber)
          .limit(1)
          .get();
      
      bool isRegistered = query.docs.isNotEmpty;
      print('🔥 Phone number registered: $isRegistered');
      
      return isRegistered;
    } catch (e, stackTrace) {
      print('🔥 ❌ Error checking phone number registration: $e');
      print('🔥 Stack trace: $stackTrace');
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
      
      print('🔥 Force resending OTP to: $completePhoneNumber');
      print('🔥 Force resending token: $forceResendingToken');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: completePhoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: (e) => _handleVerificationError(e, verificationFailed),
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
      );
      
      print('🔥 ✅ Force resend OTP completed');
    } catch (e, stackTrace) {
      print('🔥 ❌ Error in forceResendOTP: $e');
      print('🔥 Stack trace: $stackTrace');
      throw AuthException('Failed to resend OTP: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('customer').doc(uid).update(data);
    } catch (e) {
      // Handle errors, maybe throw a custom exception
      throw AuthException('Failed to update profile.');
    }
  }
}