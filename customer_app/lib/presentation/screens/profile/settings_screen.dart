import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/providers/theme_provider.dart';
import 'package:customer_app/presentation/widgets/theme_selector_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification Settings
  bool _pushNotifications = true;
  bool _orderUpdates = true;
  bool _promotionalNotifications = false;
  bool _reminderNotifications = true;
  
  // App Settings
  String _language = 'English';
  String _currency = 'INR';
  bool _biometricAuth = false;
  
  // Privacy Settings
  bool _shareUsageData = false;
  bool _personalizedAds = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _orderUpdates = prefs.getBool('order_updates') ?? true;
      _promotionalNotifications = prefs.getBool('promotional_notifications') ?? false;
      _reminderNotifications = prefs.getBool('reminder_notifications') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _currency = prefs.getString('currency') ?? 'INR';
      _biometricAuth = prefs.getBool('biometric_auth') ?? false;
      _shareUsageData = prefs.getBool('share_usage_data') ?? false;
      _personalizedAds = prefs.getBool('personalized_ads') ?? false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Notifications Section
            _buildSection(
              'Notifications',
              [
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive notifications on your device',
                  Icons.notifications,
                  _pushNotifications,
                  (value) {
                    setState(() => _pushNotifications = value);
                    _saveSetting('push_notifications', value);
                  },
                ),
                _buildSwitchTile(
                  'Order Updates',
                  'Get notified about order status changes',
                  Icons.local_shipping,
                  _orderUpdates,
                  (value) {
                    setState(() => _orderUpdates = value);
                    _saveSetting('order_updates', value);
                  },
                ),
                _buildSwitchTile(
                  'Promotional Offers',
                  'Receive notifications about deals and offers',
                  Icons.local_offer,
                  _promotionalNotifications,
                  (value) {
                    setState(() => _promotionalNotifications = value);
                    _saveSetting('promotional_notifications', value);
                  },
                ),
                _buildSwitchTile(
                  'Pickup Reminders',
                  'Get reminded about upcoming pickups',
                  Icons.schedule,
                  _reminderNotifications,
                  (value) {
                    setState(() => _reminderNotifications = value);
                    _saveSetting('reminder_notifications', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // App Preferences Section
            _buildSection(
              'App Preferences',
              [
                // Theme Selection - Use the new theme selector widget
                _buildThemeSelectionTile(),
                _buildDropdownTile(
                  'Language',
                  'Select your preferred language',
                  Icons.language,
                  _language,
                  ['English', 'Hindi', 'Tamil', 'Telugu', 'Bengali'],
                  (value) {
                    setState(() => _language = value!);
                    _saveSetting('language', value!);
                  },
                ),
                _buildDropdownTile(
                  'Currency',
                  'Choose your currency preference',
                  Icons.currency_rupee,
                  _currency,
                  ['INR', 'USD', 'EUR'],
                  (value) {
                    setState(() => _currency = value!);
                    _saveSetting('currency', value!);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Security Section
            _buildSection(
              'Security',
              [
                _buildSwitchTile(
                  'Biometric Authentication',
                  'Use fingerprint or face unlock',
                  Icons.fingerprint,
                  _biometricAuth,
                  (value) {
                    setState(() => _biometricAuth = value);
                    _saveSetting('biometric_auth', value);
                    // TODO: Implement biometric auth
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Biometric authentication will be available in next update')),
                    );
                  },
                ),
                _buildActionTile(
                  'Change Password',
                  'Update your account password',
                  Icons.lock,
                  () => _showChangePasswordDialog(),
                ),
                _buildActionTile(
                  'Two-Factor Authentication',
                  'Add extra security to your account',
                  Icons.security,
                  () => _showTwoFactorDialog(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // // Privacy Section
            // _buildSection(
            //   'Privacy',
            //   [
            //     _buildSwitchTile(
            //       'Share Usage Data',
            //       'Help improve app experience',
            //       Icons.analytics,
            //       _shareUsageData,
            //       (value) {
            //         setState(() => _shareUsageData = value);
            //         _saveSetting('share_usage_data', value);
            //       },
            //     ),
            //     _buildSwitchTile(
            //       'Personalized Ads',
            //       'Show ads based on your preferences',
            //       Icons.ads_click,
            //       _personalizedAds,
            //       (value) {
            //         setState(() => _personalizedAds = value);
            //         _saveSetting('personalized_ads', value);
            //       },
            //     ),
            //     _buildActionTile(
            //       'Download My Data',
            //       'Get a copy of your personal data',
            //       Icons.download,
            //       () => _requestDataDownload(),
            //     ),
            //     _buildActionTile(
            //       'Delete Account',
            //       'Permanently delete your account',
            //       Icons.delete_forever,
            //       () => _showDeleteAccountDialog(),
            //       isDestructive: true,
            //     ),
            //   ],
            // ),

            const SizedBox(height: 12),

            // App Information Section
            _buildSection(
              'App Information',
              [
                _buildInfoTile(
                  'App Version',
                  '1.0.0',
                  Icons.info,
                ),
                _buildActionTile(
                  'Check for Updates',
                  'See if new version is available',
                  Icons.system_update,
                  () => _checkForUpdates(),
                ),
                _buildActionTile(
                  'Cache Settings',
                  'Manage stored data and cache',
                  Icons.storage,
                  () => _showCacheDialog(),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3057),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0F3057),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: DropdownButton<String>(
        value: value,
        underline: Container(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red[600] : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red[600] : null,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Text(
        value,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildThemeSelectionTile() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Colors.grey[700],
          ),
          title: const Text(
            'Theme',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            themeProvider.getThemeModeDescription(),
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                themeProvider.getThemeModeDisplayName(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
          onTap: () {
            ThemeSelectionBottomSheet.show(context);
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'Password change feature will be available in the next update. For now, please contact support if you need to change your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text(
          'Two-factor authentication adds an extra layer of security to your account. This feature will be available soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _requestDataDownload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download My Data'),
        content: const Text(
          'We will prepare your data and send it to your registered email address within 7 business days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data download request submitted')),
              );
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Type "DELETE" to confirm account deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion request submitted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You are using the latest version!')),
    );
  }

  void _showCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Clear Image Cache'),
              subtitle: const Text('Remove cached images'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image cache cleared')),
                );
              },
            ),
            ListTile(
              title: const Text('Clear All Cache'),
              subtitle: const Text('Remove all cached data'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All cache cleared')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
