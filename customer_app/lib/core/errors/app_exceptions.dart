// lib/core/errors/app_exceptions.dart

/// Base class for all custom exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Database/Firestore related exceptions
class DatabaseException extends AppException {
  const DatabaseException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Storage related exceptions
class StorageException extends AppException {
  const StorageException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Validation related exceptions
class ValidationException extends AppException {
  const ValidationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Permission related exceptions
class PermissionException extends AppException {
  const PermissionException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Location related exceptions
class LocationException extends AppException {
  const LocationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// File handling exceptions
class FileException extends AppException {
  const FileException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Cache related exceptions
class CacheException extends AppException {
  const CacheException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Server related exceptions
class ServerException extends AppException {
  const ServerException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Generic application exception (concrete implementation)
class GenericException extends AppException {
  const GenericException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}