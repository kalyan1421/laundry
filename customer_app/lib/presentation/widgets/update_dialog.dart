import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import '../../services/version_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onUpdatePressed;
  final bool canDismiss;

  const UpdateDialog({
    Key? key,
    required this.updateInfo,
    this.onUpdatePressed,
    this.canDismiss = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => canDismiss,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with animation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: updateInfo.isUpdateRequired
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Update icon animation
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: updateInfo.isUpdateRequired
                          ? Icon(
                              Icons.system_security_update_warning,
                              size: 40,
                              color: Colors.white,
                            )
                          : Icon(
                              Icons.system_security_update_good,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      updateInfo.isUpdateRequired
                          ? 'Update Required'
                          : 'Update Available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      updateInfo.isUpdateRequired
                          ? 'This update is mandatory'
                          : 'New features available',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Update message
                    Text(
                      updateInfo.updateMessage ??
                          'A new version of Cloud Ironing is available with improved features and bug fixes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Version info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Version:',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${updateInfo.currentVersion} (${updateInfo.currentBuildNumber})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (updateInfo.latestVersion != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Latest Version:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${updateInfo.latestVersion} (${updateInfo.latestBuildNumber})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Column(
                      children: [
                        // Update button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _handleUpdatePressed(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: updateInfo.isUpdateRequired
                                  ? Colors.red[600]
                                  : Colors.blue[600],
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: updateInfo.isUpdateRequired
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Platform.isAndroid
                                      ? Icons.shop
                                      : Icons.storefront,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  updateInfo.isUpdateRequired
                                      ? 'Update Now'
                                      : 'Update App',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Later button (only for optional updates)
                        if (!updateInfo.isUpdateRequired && canDismiss) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Maybe Later',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        // Exit app button (for mandatory updates)
                        if (updateInfo.isUpdateRequired) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              onPressed: () => _exitApp(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Exit App',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUpdatePressed(BuildContext context) async {
    if (onUpdatePressed != null) {
      onUpdatePressed!();
    } else {
      await _openStore();
    }
  }

  Future<void> _openStore() async {
    try {
      String? storeUrl;
      
      if (Platform.isAndroid) {
        storeUrl = updateInfo.playStoreUrl;
      } else if (Platform.isIOS) {
        storeUrl = updateInfo.appStoreUrl;
      }
      
      if (storeUrl != null) {
        final uri = Uri.parse(storeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to generic store URLs
          final fallbackUrl = Platform.isAndroid
              ? 'market://details?id=com.cloudironingfactory.customer'
              : 'https://apps.apple.com/app/cloud-ironing/id123456789';
          
          final fallbackUri = Uri.parse(fallbackUrl);
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error opening store: $e');
    }
  }

  void _exitApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}

// Helper function to show update dialog
Future<bool?> showUpdateDialog(
  BuildContext context,
  UpdateInfo updateInfo, {
  bool barrierDismissible = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible && !updateInfo.isUpdateRequired,
    builder: (context) => UpdateDialog(
      updateInfo: updateInfo,
      canDismiss: barrierDismissible && !updateInfo.isUpdateRequired,
    ),
  );
}
