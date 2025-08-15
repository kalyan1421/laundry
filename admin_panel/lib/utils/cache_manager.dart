import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// Utility class to manage browser cache and force refresh
class CacheManager {
  
  /// Clear browser cache and force reload
  static void clearCacheAndReload() {
    if (kIsWeb) {
      try {
        // Clear localStorage
        html.window.localStorage.clear();
        
        // Clear sessionStorage
        html.window.sessionStorage.clear();
        
        // Force reload the page with cache bypass
        html.window.location.reload();
      } catch (e) {
        print('Error clearing cache: $e');
      }
    }
  }
  
  /// Force hard refresh (bypass cache)
  static void forceHardRefresh() {
    if (kIsWeb) {
      try {
        // Force reload with cache bypass
        html.window.location.assign(html.window.location.href + '?t=' + DateTime.now().millisecondsSinceEpoch.toString());
      } catch (e) {
        print('Error forcing hard refresh: $e');
      }
    }
  }
  
  /// Clear specific storage keys
  static void clearStorageKeys(List<String> keys) {
    if (kIsWeb) {
      try {
        for (String key in keys) {
          html.window.localStorage.remove(key);
          html.window.sessionStorage.remove(key);
        }
      } catch (e) {
        print('Error clearing storage keys: $e');
      }
    }
  }
  
  /// Add cache-busting parameter to URL
  static String addCacheBuster(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=$timestamp';
  }
  
  /// Check if app needs cache clear based on version
  static bool shouldClearCache(String? storedVersion, String currentVersion) {
    if (storedVersion == null || storedVersion != currentVersion) {
      return true;
    }
    return false;
  }
  
  /// Store current app version
  static void storeAppVersion(String version) {
    if (kIsWeb) {
      try {
        html.window.localStorage['app_version'] = version;
      } catch (e) {
        print('Error storing app version: $e');
      }
    }
  }
  
  /// Get stored app version
  static String? getStoredAppVersion() {
    if (kIsWeb) {
      try {
        return html.window.localStorage['app_version'];
      } catch (e) {
        print('Error getting stored app version: $e');
        return null;
      }
    }
    return null;
  }
}
