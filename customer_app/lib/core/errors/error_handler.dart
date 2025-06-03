// lib/core/errors/error_handler.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'app_exceptions.dart';

class ErrorHandler {
  /// Handle Firebase Auth exceptions
  static AppException handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException('No user found with this phone number.');
      
      case 'wrong-password':
        return const AuthException('Incorrect password.');
      
      case 'user-disabled':
        return const AuthException('This account has been disabled.');
      
      case 'too-many-requests':
        return const AuthException('Too many requests. Please try again later.');
      
      case 'operation-not-allowed':
        return const AuthException('Phone authentication is not enabled.');
      
      case 'invalid-phone-number':
        return const AuthException('Invalid phone number format.');
      
      case 'invalid-verification-code':
        return const AuthException('Invalid OTP. Please check and try again.');
      
      case 'invalid-verification-id':
        return const AuthException('Invalid verification ID. Please restart the process.');
      
      case 'session-expired':
        return const AuthException('OTP session expired. Please request a new OTP.');
      
      case 'quota-exceeded':
        return const AuthException('SMS quota exceeded. Please try again later.');
      
      case 'network-request-failed':
        return const NetworkException('Network error. Please check your connection.');
      
      case 'app-not-authorized':
        return const AuthException('App not authorized for Firebase Authentication.');
      
      case 'captcha-check-failed':
        return const AuthException('Captcha verification failed. Please try again.');
      
      case 'web-context-already-presented':
        return const AuthException('Authentication already in progress.');
      
      case 'web-context-cancelled':
        return const AuthException('Authentication was cancelled.');
      
      default:
        return AuthException('Authentication failed: ${e.message ?? e.code}');
    }
  }

  /// Handle Firestore exceptions
  static AppException handleFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const DatabaseException('Permission denied. Please check your access rights.');
      
      case 'not-found':
        return const DatabaseException('Document not found.');
      
      case 'already-exists':
        return const DatabaseException('Document already exists.');
      
      case 'resource-exhausted':
        return const DatabaseException('Database quota exceeded. Please try again later.');
      
      case 'failed-precondition':
        return const DatabaseException('Operation failed due to conflicting state.');
      
      case 'aborted':
        return const DatabaseException('Operation was aborted. Please try again.');
      
      case 'out-of-range':
        return const DatabaseException('Invalid data range.');
      
      case 'unimplemented':
        return const DatabaseException('Operation not supported.');
      
      case 'internal':
        return const DatabaseException('Internal server error. Please try again.');
      
      case 'unavailable':
        return const DatabaseException('Service temporarily unavailable.');
      
      case 'data-loss':
        return const DatabaseException('Data loss detected. Please contact support.');
      
      case 'unauthenticated':
        return const AuthException('Authentication required.');
      
      case 'deadline-exceeded':
        return const DatabaseException('Request timeout. Please try again.');
      
      case 'cancelled':
        return const DatabaseException('Operation was cancelled.');
      
      default:
        return DatabaseException('Database error: ${e.message ?? e.code}');
    }
  }

  /// Handle Firebase Storage exceptions
  static AppException handleStorageException(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        return const StorageException('File not found.');
      
      case 'bucket-not-found':
        return const StorageException('Storage bucket not found.');
      
      case 'project-not-found':
        return const StorageException('Project not found.');
      
      case 'quota-exceeded':
        return const StorageException('Storage quota exceeded.');
      
      case 'unauthenticated':
        return const AuthException('Authentication required for storage access.');
      
      case 'unauthorized':
        return const StorageException('Unauthorized storage access.');
      
      case 'retry-limit-exceeded':
        return const StorageException('Upload failed. Please try again.');
      
      case 'invalid-checksum':
        return const StorageException('File upload corrupted. Please try again.');
      
      case 'canceled':
        return const StorageException('Upload was cancelled.');
      
      default:
        return StorageException('Storage error: ${e.message ?? e.code}');
    }
  }

  /// Handle general exceptions
  static AppException handleGeneralException(dynamic error) {
    if (error is FirebaseAuthException) {
      return handleFirebaseAuthException(error);
    } else if (error is FirebaseException) {
      if (error.plugin == 'cloud_firestore') {
        return handleFirestoreException(error);
      } else if (error.plugin == 'firebase_storage') {
        return handleStorageException(error);
      }
    } else if (error is AppException) {
      return error;
    }
    
    // Generic error - now using concrete class
    return GenericException('An unexpected error occurred: ${error.toString()}');
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    try {
      AppException appException = handleGeneralException(error);
      return appException.message;
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Check if error is network related
  static bool isNetworkError(dynamic error) {
    if (error is NetworkException) return true;
    
    String errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('network') ||
           errorMessage.contains('connection') ||
           errorMessage.contains('internet') ||
           errorMessage.contains('timeout') ||
           errorMessage.contains('host lookup failed');
  }

  /// Check if error requires user action
  static bool requiresUserAction(dynamic error) {
    if (error is AuthException) {
      String message = error.message.toLowerCase();
      return message.contains('invalid') ||
             message.contains('expired') ||
             message.contains('permission');
    }
    
    return false;
  }

  /// Check if error is retryable
  static bool isRetryableError(dynamic error) {
    if (error is NetworkException) return true;
    if (error is DatabaseException) {
      String message = error.message.toLowerCase();
      return message.contains('timeout') ||
             message.contains('unavailable') ||
             message.contains('internal') ||
             message.contains('aborted');
    }
    return false;
  }

  /// Get retry delay for retryable errors
  static Duration getRetryDelay(dynamic error, int retryCount) {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s (max)
    int delaySeconds = 1 << (retryCount.clamp(0, 4));
    return Duration(seconds: delaySeconds);
  }

  /// Log error for debugging
  static void logError(dynamic error, {String? context, StackTrace? stackTrace}) {
    print('Error${context != null ? ' in $context' : ''}: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}