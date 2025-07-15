import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      _logger.i('Attempting to sign in user: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      _logger.i('User signed in successfully: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuth sign in error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email address.');
        case 'wrong-password':
          throw Exception('Incorrect password.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many sign-in attempts. Please try again later.');
        case 'network-request-failed':
          throw Exception('Network error. Please check your connection.');
        default:
          throw Exception('Sign in failed: ${e.message}');
      }
    } catch (e) {
      _logger.e('Unexpected sign in error: $e');
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      _logger.i('Attempting to create user: $email');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      _logger.i('User created successfully: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuth create user error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'weak-password':
          throw Exception('Password is too weak. Please use at least 6 characters.');
        case 'email-already-in-use':
          throw Exception('An account already exists with this email address.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'operation-not-allowed':
          throw Exception('Email/password accounts are not enabled.');
        case 'network-request-failed':
          throw Exception('Network error. Please check your connection.');
        default:
          throw Exception('Account creation failed: ${e.message}');
      }
    } catch (e) {
      _logger.e('Unexpected create user error: $e');
      throw Exception('An unexpected error occurred during account creation.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _logger.i('Attempting to sign out user: ${_auth.currentUser?.uid}');
      await _auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.i('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      _logger.i('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuth password reset error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email address.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'network-request-failed':
          throw Exception('Network error. Please check your connection.');
        default:
          throw Exception('Failed to send password reset email: ${e.message}');
      }
    } catch (e) {
      _logger.e('Unexpected password reset error: $e');
      throw Exception('An unexpected error occurred while sending password reset email.');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      _logger.i('Updating password for user: ${user.uid}');
      await user.updatePassword(newPassword);
      _logger.i('Password updated successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuth update password error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'weak-password':
          throw Exception('Password is too weak. Please use at least 6 characters.');
        case 'requires-recent-login':
          throw Exception('Please re-authenticate before changing your password.');
        default:
          throw Exception('Failed to update password: ${e.message}');
      }
    } catch (e) {
      _logger.e('Unexpected update password error: $e');
      throw Exception('An unexpected error occurred while updating password.');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      _logger.i('Updating email for user: ${user.uid} to: $newEmail');
      await user.updateEmail(newEmail.trim());
      _logger.i('Email updated successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuth update email error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'email-already-in-use':
          throw Exception('This email address is already in use.');
        case 'requires-recent-login':
          throw Exception('Please re-authenticate before changing your email.');
        default:
          throw Exception('Failed to update email: ${e.message}');
      }
    } catch (e) {
      _logger.e('Unexpected update email error: $e');
      throw Exception('An unexpected error occurred while updating email.');
    }
  }

  // Re-authenticate user
  Future<void> reauthenticateWithCredential(AuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      _logger.i('Re-authenticating user: ${user.uid}');
      await user.reauthenticateWithCredential(credential);
      _logger.i('User re-authenticated successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuth re-authenticate error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'user-mismatch':
          throw Exception('The credential does not match the current user.');
        case 'user-not-found':
          throw Exception('User not found.');
        case 'invalid-credential':
          throw Exception('Invalid credentials provided.');
        case 'wrong-password':
          throw Exception('Incorrect password.');
        default:
          throw Exception('Re-authentication failed: ${e.message}');
      }
    } catch (e) {
      _logger.e('Unexpected re-authenticate error: $e');
      throw Exception('An unexpected error occurred during re-authentication.');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      _logger.i('Deleting user account: ${user.uid}');
      await user.delete();
      _logger.i('User account deleted successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuth delete account error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'requires-recent-login':
          throw Exception('Please re-authenticate before deleting your account.');
        default:
          throw Exception('Failed to delete account: ${e.message}');
      }
    } catch (e) {
      _logger.e('Unexpected delete account error: $e');
      throw Exception('An unexpected error occurred while deleting account.');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  // Refresh current user
  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        _logger.i('User data reloaded successfully');
      }
    } catch (e) {
      _logger.e('Error reloading user: $e');
      throw Exception('Failed to reload user data: $e');
    }
  }

  // Verify email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      if (user.emailVerified) {
        throw Exception('Email is already verified.');
      }

      _logger.i('Sending email verification to: ${user.email}');
      await user.sendEmailVerification();
      _logger.i('Email verification sent successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuth email verification error: ${e.code} - ${e.message}');
      throw Exception('Failed to send email verification: ${e.message}');
    } catch (e) {
      _logger.e('Unexpected email verification error: $e');
      throw Exception('An unexpected error occurred while sending email verification.');
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Phone Authentication Methods
  
  // Verify phone number and send OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
    int? timeout,
  }) async {
    try {
      _logger.i('Verifying phone number: $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: Duration(seconds: timeout ?? 60),
      );
      
      _logger.i('Phone number verification initiated successfully');
    } catch (e) {
      _logger.e('Phone number verification error: $e');
      throw Exception('Failed to verify phone number: $e');
    }
  }

  // Sign in with phone credential
  Future<UserCredential> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      _logger.i('Signing in with phone credential');
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      _logger.i('Phone sign in successful: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Phone sign in error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('Invalid verification code. Please check and try again.');
        case 'invalid-verification-id':
          throw Exception('Invalid verification ID. Please restart the process.');
        case 'code-expired':
          throw Exception('Verification code has expired. Please request a new code.');
        case 'session-expired':
          throw Exception('Session has expired. Please restart the verification process.');
        case 'quota-exceeded':
          throw Exception('SMS quota exceeded. Please try again later.');
        case 'too-many-requests':
          throw Exception('Too many requests. Please try again later.');
        case 'network-request-failed':
          throw Exception('Network error. Please check your connection.');
        default:
          throw Exception('Phone sign in failed: ${e.message}');
      }
    } catch (e) {
      _logger.e('Unexpected phone sign in error: $e');
      throw Exception('An unexpected error occurred during phone sign in.');
    }
  }

  // Create phone auth credential from verification ID and SMS code
  PhoneAuthCredential createPhoneAuthCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  // Format phone number for Firebase Auth (ensure it starts with +)
  String formatPhoneNumber(String phoneNumber) {
    String formatted = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (formatted.startsWith('91') && formatted.length == 12) {
      formatted = '+$formatted';
    } else if (formatted.startsWith('0')) {
      formatted = '+91${formatted.substring(1)}';
    } else if (!formatted.startsWith('+')) {
      formatted = '+91$formatted';
    }
    
    return formatted;
  }

  // Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    String formatted = formatPhoneNumber(phoneNumber);
    return RegExp(r'^\+91[6-9]\d{9}$').hasMatch(formatted);
  }

  // Get current user phone number
  String? get currentUserPhoneNumber => _auth.currentUser?.phoneNumber;

  // Check if current user has phone number
  bool get hasPhoneNumber => _auth.currentUser?.phoneNumber != null;
} 