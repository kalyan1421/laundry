import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';

class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if app update is required
  Future<UpdateInfo> checkForUpdate() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      _logger.i('Current app version: $currentVersion ($currentBuildNumber)');

      // Get minimum required version from Firebase
      final versionDoc = await _firestore
          .collection('app_config')
          .doc('version_control')
          .get();

      if (!versionDoc.exists) {
        _logger.w('Version control document not found in Firebase');
        return UpdateInfo(
          isUpdateRequired: false,
          isUpdateAvailable: false,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
        );
      }

      final data = versionDoc.data()!;
      final minRequiredVersion = data['min_required_version'] as String?;
      final minRequiredBuildNumber = data['min_required_build_number'] as int?;
      final latestVersion = data['latest_version'] as String?;
      final latestBuildNumber = data['latest_build_number'] as int?;
      final forceUpdate = data['force_update'] as bool? ?? false;
      final updateMessage = data['update_message'] as String?;
      final playStoreUrl = data['play_store_url'] as String?;
      final appStoreUrl = data['app_store_url'] as String?;

      _logger.i('Min required version: $minRequiredVersion ($minRequiredBuildNumber)');
      _logger.i('Latest version: $latestVersion ($latestBuildNumber)');
      _logger.i('Force update: $forceUpdate');

      // Check if update is required
      bool isUpdateRequired = false;
      bool isUpdateAvailable = false;

      if (minRequiredBuildNumber != null && currentBuildNumber < minRequiredBuildNumber) {
        isUpdateRequired = true;
      }

      if (latestBuildNumber != null && currentBuildNumber < latestBuildNumber) {
        isUpdateAvailable = true;
      }

      // Force update overrides everything
      if (forceUpdate) {
        isUpdateRequired = true;
      }

      return UpdateInfo(
        isUpdateRequired: isUpdateRequired,
        isUpdateAvailable: isUpdateAvailable,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        minRequiredVersion: minRequiredVersion,
        minRequiredBuildNumber: minRequiredBuildNumber,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuildNumber,
        forceUpdate: forceUpdate,
        updateMessage: updateMessage,
        playStoreUrl: playStoreUrl,
        appStoreUrl: appStoreUrl,
      );
    } catch (e) {
      _logger.e('Error checking for updates: $e');
      // In case of error, don't block the app
      return UpdateInfo(
        isUpdateRequired: false,
        isUpdateAvailable: false,
        currentVersion: 'Unknown',
        currentBuildNumber: 0,
      );
    }
  }

  /// Create or update version control document in Firebase
  Future<void> createVersionControlDocument() async {
    try {
      final versionControlRef = _firestore
          .collection('app_config')
          .doc('version_control');

      // Check if document exists
      final doc = await versionControlRef.get();
      
      if (!doc.exists) {
        // Create initial version control document
        await versionControlRef.set({
          'min_required_version': '1.0.0',
          'min_required_build_number': 1,
          'latest_version': '1.4.0',
          'latest_build_number': 15,
          'force_update': false,
          'update_message': 'A new version of Cloud Ironing is available with improved features and bug fixes.',
          'play_store_url': 'https://play.google.com/store/apps/details?id=com.cloudironingfactory.customer',
          'app_store_url': 'https://apps.apple.com/app/cloud-ironing/id123456789',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        _logger.i('Version control document created successfully');
      } else {
        _logger.i('Version control document already exists');
      }
    } catch (e) {
      _logger.e('Error creating version control document: $e');
    }
  }

  /// Update minimum required version (for admin use)
  Future<void> updateMinimumRequiredVersion({
    required String version,
    required int buildNumber,
    bool forceUpdate = false,
    String? updateMessage,
  }) async {
    try {
      await _firestore
          .collection('app_config')
          .doc('version_control')
          .update({
        'min_required_version': version,
        'min_required_build_number': buildNumber,
        'force_update': forceUpdate,
        'update_message': updateMessage ?? 'Please update to the latest version to continue using the app.',
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      _logger.i('Minimum required version updated: $version ($buildNumber)');
    } catch (e) {
      _logger.e('Error updating minimum required version: $e');
      rethrow;
    }
  }

  /// Compare version strings (e.g., "1.2.3" vs "1.2.4")
  int compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    
    for (int i = 0; i < maxLength; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1Part < v2Part) return -1;
      if (v1Part > v2Part) return 1;
    }
    
    return 0;
  }
}

class UpdateInfo {
  final bool isUpdateRequired;
  final bool isUpdateAvailable;
  final String currentVersion;
  final int currentBuildNumber;
  final String? minRequiredVersion;
  final int? minRequiredBuildNumber;
  final String? latestVersion;
  final int? latestBuildNumber;
  final bool forceUpdate;
  final String? updateMessage;
  final String? playStoreUrl;
  final String? appStoreUrl;

  UpdateInfo({
    required this.isUpdateRequired,
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.currentBuildNumber,
    this.minRequiredVersion,
    this.minRequiredBuildNumber,
    this.latestVersion,
    this.latestBuildNumber,
    this.forceUpdate = false,
    this.updateMessage,
    this.playStoreUrl,
    this.appStoreUrl,
  });

  @override
  String toString() {
    return 'UpdateInfo(isUpdateRequired: $isUpdateRequired, '
           'isUpdateAvailable: $isUpdateAvailable, '
           'currentVersion: $currentVersion, '
           'currentBuildNumber: $currentBuildNumber, '
           'minRequiredVersion: $minRequiredVersion, '
           'forceUpdate: $forceUpdate)';
  }
}

