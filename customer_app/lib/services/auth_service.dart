// lib/services/auth_service.dart
import 'package:customer_app/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/errors/app_exceptions.dart';
import '../core/utils/id_utils.dart'; // Import IdUtils

// Added imports for QR code generation and storage
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:ui' as ui; // For ui.Image

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Added FirebaseStorage instance

  // Current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Send OTP to phone number with enhanced debugging
  Future<String> sendOTP({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      String completePhoneNumber = '+91$phoneNumber';
      
      print('🔥 Firebase Auth: Starting OTP process');
      print('🔥 Phone Number: $completePhoneNumber');
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
          _handleVerificationError(e, verificationFailed);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('🔥 ✅ Code sent successfully');
          print('🔥 Verification ID: $verificationId');
          print('🔥 Resend Token: $resendToken');
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
        errorMessage = 'Too many requests. Please try again later.';
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
        if (kDebugMode) {
          errorMessage = 'Verification failed in debug mode. This is often due to Firebase configuration issues. Please:\n'
                       '1. Check SHA-1 fingerprints in Firebase console\n'
                       '2. Ensure google-services.json is up to date\n'
                       '3. Try on a real device instead of emulator';
        } else {
          errorMessage = 'Unknown error occurred. Please try again.';
        }
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
  Future<UserCredential> verifyOTPAndSignIn({
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
        bool docCreated = await _createOrUpdateUserDocument(userCredential.user!);
        if (!docCreated) {
          await _auth.signOut();
          throw AuthException('Failed to setup user account. Please try again.');
        }
      } else {
        throw AuthException('User is null after successful credential sign-in.');
      }
      
      return userCredential;
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

  // Create or update user document in Firestore
  Future<bool> _createOrUpdateUserDocument(User user) async {
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
          // 'addresses': [], // Addresses are now a subcollection
          'isProfileComplete': false,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
          'qrCodeUrl': null, // Initialize qrCodeUrl as null
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
          userData['qrCodeUrl'] = null; // Ensure qrCodeUrl field exists if user is old
        }
      }

      await userDoc.set(userData, SetOptions(merge: true));
      print('🔥 ✅ User document saved successfully for UID: ${user.uid}');
      return true;
    } catch (e, stackTrace) {
      print('🔥 ❌ Error creating/updating user document for UID ${user.uid}: $e');
      print('🔥 Stack trace: $stackTrace');
      return false;
    }
  }

  // Method to ensure user document exists, creating with defaults if not.
  Future<bool> ensureUserDocument(User user) async {
    try {
      DocumentReference userDoc = _firestore.collection('customer').doc(user.uid);
      DocumentSnapshot snapshot = await userDoc.get();
      if (!snapshot.exists) {
        print('🔥 User document missing for ${user.uid}, creating with defaults.');
        return await _createOrUpdateUserDocument(user);
      }
      print('🔥 User document already exists for ${user.uid}.');
      return true; // Document already exists
    } catch (e, stackTrace) {
      print('🔥 ❌ Error in ensureUserDocument for UID ${user.uid}: $e');
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
        
        if (addressSnapshot.docs.isNotEmpty) {
          addresses = addressSnapshot.docs
              .map((doc) => Address.fromMap(doc.data()))
              .toList();
          print('🔥 AuthService.getUserData: Fetched ${addresses.length} addresses for UID: $uid');
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
      
      print('🔥 AuthService.getUserData: Creating UserModel with addresses and order count for UID: $uid');
      return UserModel.fromFirestore(userDoc, addresses: addresses, orderCount: orderCount);

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
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('🔥 Updating user profile for: $uid');
      
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      
      bool shouldGenerateQr = false;
      if (additionalData != null) {
        updateData.addAll(additionalData);
        if (additionalData['isProfileComplete'] == true) {
          shouldGenerateQr = true;
        }
      }

      if (shouldGenerateQr) {
        // Fetch the user document to get clientId and check existing qrCodeUrl
        DocumentSnapshot userDoc = await _firestore.collection('customer').doc(uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String? existingQrCodeUrl = userData['qrCodeUrl'] as String?;
          String? clientId = userData['clientId'] as String?;

          if (clientId != null && clientId.isNotEmpty && existingQrCodeUrl == null) {
            print('🔥 Profile complete, generating QR code for user $uid with clientId $clientId');
            String? newQrCodeUrl = await _generateAndStoreQrCode(uid, clientId);
            if (newQrCodeUrl != null) {
              updateData['qrCodeUrl'] = newQrCodeUrl;
            } else {
              print('🔥 ⚠️ Failed to generate QR code, will not update qrCodeUrl field.');
            }
          } else if (clientId == null || clientId.isEmpty) {
             print('🔥 ⚠️ Cannot generate QR code: clientId is missing for user $uid.');
          } else if (existingQrCodeUrl != null) {
             print('🔥 QR code URL already exists for user $uid. Skipping generation.');
          }
        } else {
           print('🔥 ⚠️ User document not found when trying to generate QR code for $uid.');
        }
      }

      await _firestore.collection('customer').doc(uid).update(updateData);
      print('🔥 ✅ User profile updated successfully');
    } catch (e, stackTrace) {
      print('🔥 ❌ Error updating user profile: $e');
      print('🔥 Stack trace: $stackTrace');
      throw DatabaseException('Failed to update profile: ${e.toString()}');
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
}