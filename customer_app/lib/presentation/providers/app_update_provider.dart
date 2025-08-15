import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../services/version_service.dart';

enum UpdateStatus {
  checking,
  noUpdateNeeded,
  updateAvailable,
  updateRequired,
  error,
}

class AppUpdateProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final VersionService _versionService = VersionService();

  UpdateStatus _updateStatus = UpdateStatus.checking;
  UpdateInfo? _updateInfo;
  String? _errorMessage;
  bool _hasShownDialog = false;

  // Getters
  UpdateStatus get updateStatus => _updateStatus;
  UpdateInfo? get updateInfo => _updateInfo;
  String? get errorMessage => _errorMessage;
  bool get hasShownDialog => _hasShownDialog;
  bool get isUpdateRequired => _updateInfo?.isUpdateRequired ?? false;
  bool get isUpdateAvailable => _updateInfo?.isUpdateAvailable ?? false;

  /// Check for app updates
  Future<void> checkForUpdates({bool showLoading = true}) async {
    try {
      if (showLoading) {
        _updateStatus = UpdateStatus.checking;
        notifyListeners();
      }

      _logger.i('Checking for app updates...');
      
      // Get update information
      _updateInfo = await _versionService.checkForUpdate();
      
      _logger.i('Update check result: $_updateInfo');

      // Determine update status
      if (_updateInfo!.isUpdateRequired) {
        _updateStatus = UpdateStatus.updateRequired;
        _logger.w('App update is required');
      } else if (_updateInfo!.isUpdateAvailable) {
        _updateStatus = UpdateStatus.updateAvailable;
        _logger.i('App update is available');
      } else {
        _updateStatus = UpdateStatus.noUpdateNeeded;
        _logger.i('No app update needed');
      }

      _errorMessage = null;
      notifyListeners();

    } catch (e) {
      _logger.e('Error checking for updates: $e');
      _updateStatus = UpdateStatus.error;
      _errorMessage = 'Failed to check for updates: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Mark that update dialog has been shown
  void markDialogShown() {
    _hasShownDialog = true;
    notifyListeners();
  }

  /// Reset dialog shown status
  void resetDialogShown() {
    _hasShownDialog = false;
    notifyListeners();
  }

  /// Force refresh update check
  Future<void> refreshUpdateCheck() async {
    _hasShownDialog = false;
    await checkForUpdates();
  }

  /// Initialize version control document (for first-time setup)
  Future<void> initializeVersionControl() async {
    try {
      await _versionService.createVersionControlDocument();
      _logger.i('Version control initialized');
    } catch (e) {
      _logger.e('Error initializing version control: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _updateStatus = UpdateStatus.checking;
    _updateInfo = null;
    _errorMessage = null;
    _hasShownDialog = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

