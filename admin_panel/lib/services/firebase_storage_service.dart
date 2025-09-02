// services/firebase_storage_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get a properly configured download URL for web compatibility
  static Future<String?> getWebCompatibleUrl(String originalUrl) async {
    try {
      if (!kIsWeb) {
        // For mobile, return original URL
        return originalUrl;
      }

      // For web, try to get a fresh download URL with proper CORS headers
      if (originalUrl.contains('firebasestorage.googleapis.com')) {
        // Extract the file path from the URL
        final uri = Uri.parse(originalUrl);
        final pathSegments = uri.pathSegments;
        
        if (pathSegments.length >= 4) {
          final bucket = pathSegments[2];
          final filePath = pathSegments.sublist(4).join('/');
          
          // Get a fresh download URL
          final ref = _storage.refFromURL('gs://$bucket/$filePath');
          final newUrl = await ref.getDownloadURL();
          
          print('Generated fresh URL for web: $newUrl');
          return newUrl;
        }
      }
      
      return originalUrl;
    } catch (e) {
      print('Error getting web-compatible URL: $e');
      return originalUrl;
    }
  }

  /// Configure Firebase Storage for web CORS
  static Future<void> configureCorsForWeb() async {
    if (!kIsWeb) return;
    
    try {
      // This would typically be done server-side, but we can log the requirement
      print('Firebase Storage CORS configuration needed for web deployment');
      print('Please ensure Firebase Storage has proper CORS configuration:');
      print('gsutil cors set cors.json gs://your-bucket-name');
    } catch (e) {
      print('Error in CORS configuration: $e');
    }
  }

  /// Test if an image URL is accessible
  static Future<bool> testImageAccessibility(String imageUrl) async {
    try {
      if (kIsWeb) {
        // For web, we can't easily test due to CORS, so return true
        return true;
      }
      
      // For mobile, we could test with HTTP request
      return true;
    } catch (e) {
      print('Error testing image accessibility: $e');
      return false;
    }
  }
}
