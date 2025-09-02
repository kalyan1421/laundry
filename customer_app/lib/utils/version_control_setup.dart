import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

/// Utility class to help set up version control in Firebase
/// This can be used by admins to initialize and manage app versions
class VersionControlSetup {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize version control document with current app version
  static Future<void> initializeVersionControl({
    required String currentVersion,
    required int currentBuildNumber,
    String? playStoreUrl,
    String? appStoreUrl,
  }) async {
    try {
      await _firestore
          .collection('app_config')
          .doc('version_control')
          .set({
        'min_required_version': currentVersion,
        'min_required_build_number': currentBuildNumber,
        'latest_version': currentVersion,
        'latest_build_number': currentBuildNumber,
        'force_update': false,
        'update_message': 'A new version of Cloud Ironing is available with improved features and bug fixes.',
        'play_store_url': playStoreUrl ?? 'https://play.google.com/store/apps/details?id=com.cloudironingfactory.customer',
        'app_store_url': appStoreUrl ?? 'https://apps.apple.com/app/cloud-ironing/id123456789',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      _logger.i('Version control initialized successfully');
      print('✅ Version control document created successfully!');
      print('📱 Current version: $currentVersion ($currentBuildNumber)');
      print('🔄 Minimum required version: $currentVersion ($currentBuildNumber)');
      
    } catch (e) {
      _logger.e('Error initializing version control: $e');
      print('❌ Error initializing version control: $e');
      rethrow;
    }
  }

  /// Force an app update for all users
  static Future<void> forceAppUpdate({
    required String minVersion,
    required int minBuildNumber,
    String? updateMessage,
  }) async {
    try {
      await _firestore
          .collection('app_config')
          .doc('version_control')
          .update({
        'min_required_version': minVersion,
        'min_required_build_number': minBuildNumber,
        'force_update': true,
        'update_message': updateMessage ?? 'This update is mandatory. Please update to continue using the app.',
        'updated_at': FieldValue.serverTimestamp(),
      });

      _logger.i('Forced update set: $minVersion ($minBuildNumber)');
      print('🚨 FORCED UPDATE ACTIVATED!');
      print('📱 Minimum required version: $minVersion ($minBuildNumber)');
      print('💬 Message: ${updateMessage ?? "This update is mandatory. Please update to continue using the app."}');
      print('⚠️  All users with older versions will be required to update');
      
    } catch (e) {
      _logger.e('Error setting forced update: $e');
      print('❌ Error setting forced update: $e');
      rethrow;
    }
  }

  /// Set latest version (optional update)
  static Future<void> setLatestVersion({
    required String latestVersion,
    required int latestBuildNumber,
    String? updateMessage,
  }) async {
    try {
      await _firestore
          .collection('app_config')
          .doc('version_control')
          .update({
        'latest_version': latestVersion,
        'latest_build_number': latestBuildNumber,
        'update_message': updateMessage ?? 'A new version is available with exciting new features!',
        'updated_at': FieldValue.serverTimestamp(),
      });

      _logger.i('Latest version updated: $latestVersion ($latestBuildNumber)');
      print('✨ Latest version updated!');
      print('📱 Latest version: $latestVersion ($latestBuildNumber)');
      print('💬 Message: ${updateMessage ?? "A new version is available with exciting new features!"}');
      print('ℹ️  Users will see optional update notification');
      
    } catch (e) {
      _logger.e('Error updating latest version: $e');
      print('❌ Error updating latest version: $e');
      rethrow;
    }
  }

  /// Disable forced update
  static Future<void> disableForceUpdate() async {
    try {
      await _firestore
          .collection('app_config')
          .doc('version_control')
          .update({
        'force_update': false,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _logger.i('Force update disabled');
      print('✅ Force update disabled');
      print('ℹ️  Users will no longer be forced to update');
      
    } catch (e) {
      _logger.e('Error disabling force update: $e');
      print('❌ Error disabling force update: $e');
      rethrow;
    }
  }

  /// Get current version control status
  static Future<void> getVersionControlStatus() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('version_control')
          .get();

      if (!doc.exists) {
        print('❌ Version control document does not exist');
        print('💡 Run initializeVersionControl() first');
        return;
      }

      final data = doc.data()!;
      print('📊 VERSION CONTROL STATUS');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📱 Minimum Required: ${data['min_required_version']} (${data['min_required_build_number']})');
      print('✨ Latest Version: ${data['latest_version']} (${data['latest_build_number']})');
      print('🚨 Force Update: ${data['force_update'] ? 'ENABLED' : 'Disabled'}');
      print('💬 Update Message: ${data['update_message']}');
      print('🛒 Play Store: ${data['play_store_url']}');
      print('🍎 App Store: ${data['app_store_url']}');
      print('🕐 Last Updated: ${data['updated_at']}');
      
    } catch (e) {
      _logger.e('Error getting version control status: $e');
      print('❌ Error getting version control status: $e');
      rethrow;
    }
  }

  /// Example usage for testing
  static Future<void> runExample() async {
    print('🚀 Version Control Setup Example');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Initialize version control
    await initializeVersionControl(
      currentVersion: '1.6.0',
      currentBuildNumber: 15,
    );
    
    // Get status
    await getVersionControlStatus();
    
    // Set latest version (optional update)
    await setLatestVersion(
      latestVersion: '1.6.0',
      latestBuildNumber: 16,
      updateMessage: 'New features: Enhanced UI and better performance!',
    );
    
    // Force update example (uncomment to test)
    // await forceAppUpdate(
    //   minVersion: '1.4.0',
    //   minBuildNumber: 15,
    //   updateMessage: 'Critical security update required!',
    // );
    
    print('✅ Example completed!');
  }
}

