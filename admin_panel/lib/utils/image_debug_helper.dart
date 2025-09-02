// utils/image_debug_helper.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageDebugHelper {
  static Future<bool> testImageUrl(String imageUrl) async {
    try {
      if (kIsWeb) {
        // For web, we can't easily test CORS, so just check if URL is accessible
        print('Testing image URL: $imageUrl');
        
        // Check if it's a Firebase Storage URL
        if (imageUrl.contains('firebasestorage.googleapis.com')) {
          print('Firebase Storage URL detected');
          
          // Check if URL has proper token
          if (!imageUrl.contains('token=')) {
            print('Warning: Firebase Storage URL might be missing access token');
            return false;
          }
        }
        
        return true; // Assume it's accessible for web
      } else {
        // For mobile, actually test the HTTP request
        final response = await http.head(Uri.parse(imageUrl));
        print('Image URL test result: ${response.statusCode}');
        return response.statusCode == 200;
      }
    } catch (e) {
      print('Error testing image URL: $e');
      return false;
    }
  }

  static String getImageDebugInfo(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return 'No image URL provided';
    }

    final uri = Uri.tryParse(imageUrl);
    if (uri == null) {
      return 'Invalid URL format';
    }

    final info = StringBuffer();
    info.writeln('URL: $imageUrl');
    info.writeln('Host: ${uri.host}');
    info.writeln('Path: ${uri.path}');
    
    if (imageUrl.contains('firebasestorage.googleapis.com')) {
      info.writeln('Type: Firebase Storage');
      if (imageUrl.contains('token=')) {
        info.writeln('Has access token: Yes');
      } else {
        info.writeln('Has access token: No (This might cause CORS issues)');
      }
    }

    return info.toString();
  }

  static void logImageError(String imageUrl, dynamic error) {
    print('=== IMAGE LOADING ERROR ===');
    print('URL: $imageUrl');
    print('Error: $error');
    print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('Debug Info:');
    print(getImageDebugInfo(imageUrl));
    print('========================');
  }
}
