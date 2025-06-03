
// lib/config/app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _devFirebaseProjectId = 'cloud-ironing-dev';
  static const String _prodFirebaseProjectId = 'cloud-ironing-prod';
  
  static const String _devApiUrl = 'https://dev-api.cloudironing.com';
  static const String _prodApiUrl = 'https://api.cloudironing.com';
  
  // Environment detection
  static bool get isDevelopment => kDebugMode;
  static bool get isProduction => kReleaseMode;
  
  // Configuration getters
  static String get firebaseProjectId => 
      isDevelopment ? _devFirebaseProjectId : _prodFirebaseProjectId;
  
  static String get apiUrl => 
      isDevelopment ? _devApiUrl : _prodApiUrl;
  
  static bool get enableLogging => isDevelopment;
  static bool get enableCrashReporting => isProduction;
}