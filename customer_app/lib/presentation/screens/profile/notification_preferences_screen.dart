import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  // Notification Settings
  bool _orderUpdates = true;
  bool _promotionalOffers = false;
  bool _pickupReminders = true;
  bool _deliveryUpdates = true;
  bool _weeklyDigest = false;
  bool _newServiceAlerts = true;
  bool _priceDropAlerts = false;
  bool _loyaltyRewards = true;
  
  // Delivery method preferences
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  
  // Time preferences
  String _quietHours = 'Do not disturb: 10 PM - 8 AM';
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderUpdates = prefs.getBool('notif_order_updates') ?? true;
      _promotionalOffers = prefs.getBool('notif_promotional_offers') ?? false;
      _pickupReminders = prefs.getBool('notif_pickup_reminders') ?? true;
      _deliveryUpdates = prefs.getBool('notif_delivery_updates') ?? true;
      _weeklyDigest = prefs.getBool('notif_weekly_digest') ?? false;
      _newServiceAlerts = prefs.getBool('notif_new_service_alerts') ?? true;
      _priceDropAlerts = prefs.getBool('notif_price_drop_alerts') ?? false;
      _loyaltyRewards = prefs.getBool('notif_loyalty_rewards') ?? true;
      _pushNotifications = prefs.getBool('notif_push_enabled') ?? true;
      _emailNotifications = prefs.getBool('notif_email_enabled') ?? true;
      _smsNotifications = prefs.getBool('notif_sms_enabled') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order & Service Notifications
            _buildSection(
              'Order & Service Updates',
              [
                _buildSwitchTile(
                  'Order Status Updates',
                  'Get notified when your order status changes',
                  Icons.local_shipping,
                  _orderUpdates,
                  (value) {
                    setState(() => _orderUpdates = value);
                    _savePreference('notif_order_updates', value);
                  },
                ),
                _buildSwitchTile(
                  'Pickup Reminders',
                  'Reminders for scheduled pickups',
                  Icons.schedule,
                  _pickupReminders,
                  (value) {
                    setState(() => _pickupReminders = value);
                    _savePreference('notif_pickup_reminders', value);
                  },
                ),
                _buildSwitchTile(
                  'Delivery Updates',
                  'When your order is out for delivery',
                  Icons.delivery_dining,
                  _deliveryUpdates,
                  (value) {
                    setState(() => _deliveryUpdates = value);
                    _savePreference('notif_delivery_updates', value);
                  },
                ),
                _buildSwitchTile(
                  'New Service Alerts',
                  'Be the first to know about new services',
                  Icons.new_releases,
                  _newServiceAlerts,
                  (value) {
                    setState(() => _newServiceAlerts = value);
                    _savePreference('notif_new_service_alerts', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Marketing & Promotional
            _buildSection(
              'Marketing & Promotions',
              [
                _buildSwitchTile(
                  'Promotional Offers',
                  'Deals, discounts, and special offers',
                  Icons.local_offer,
                  _promotionalOffers,
                  (value) {
                    setState(() => _promotionalOffers = value);
                    _savePreference('notif_promotional_offers', value);
                  },
                ),
                _buildSwitchTile(
                  'Price Drop Alerts',
                  'When prices drop on your favorite services',
                  Icons.trending_down,
                  _priceDropAlerts,
                  (value) {
                    setState(() => _priceDropAlerts = value);
                    _savePreference('notif_price_drop_alerts', value);
                  },
                ),
                _buildSwitchTile(
                  'Weekly Digest',
                  'Weekly summary of offers and updates',
                  Icons.email,
                  _weeklyDigest,
                  (value) {
                    setState(() => _weeklyDigest = value);
                    _savePreference('notif_weekly_digest', value);
                  },
                ),
                _buildSwitchTile(
                  'Loyalty Rewards',
                  'Points, rewards, and cashback updates',
                  Icons.card_giftcard,
                  _loyaltyRewards,
                  (value) {
                    setState(() => _loyaltyRewards = value);
                    _savePreference('notif_loyalty_rewards', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Delivery Methods
            _buildSection(
              'Notification Methods',
              [
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive notifications on your device',
                  Icons.notifications,
                  _pushNotifications,
                  (value) {
                    setState(() => _pushNotifications = value);
                    _savePreference('notif_push_enabled', value);
                  },
                ),
                _buildSwitchTile(
                  'Email Notifications',
                  'Receive notifications via email',
                  Icons.email,
                  _emailNotifications,
                  (value) {
                    setState(() => _emailNotifications = value);
                    _savePreference('notif_email_enabled', value);
                  },
                ),
                _buildSwitchTile(
                  'SMS Notifications',
                  'Receive critical updates via SMS',
                  Icons.sms,
                  _smsNotifications,
                  (value) {
                    setState(() => _smsNotifications = value);
                    _savePreference('notif_sms_enabled', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Timing & Frequency
            _buildSection(
              'Timing & Frequency',
              [
                _buildActionTile(
                  'Quiet Hours',
                  _quietHours,
                  Icons.nights_stay,
                  () => _showQuietHoursDialog(),
                ),
                _buildActionTile(
                  'Notification Sound',
                  'Default notification sound',
                  Icons.volume_up,
                  () => _showSoundDialog(),
                ),
                _buildActionTile(
                  'Frequency Settings',
                  'Manage how often you receive notifications',
                  Icons.tune,
                  () => _showFrequencyDialog(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick Actions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3057),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _enableAll,
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('Enable All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3057),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _disableAll,
                          icon: const Icon(Icons.notifications_off),
                          label: const Text('Disable All'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiet Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select quiet hours when you don\'t want to receive notifications:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Do not disturb: 10 PM - 8 AM'),
              trailing: Radio<String>(
                value: 'Do not disturb: 10 PM - 8 AM',
                groupValue: _quietHours,
                onChanged: (value) {
                  setState(() => _quietHours = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Do not disturb: 11 PM - 7 AM'),
              trailing: Radio<String>(
                value: 'Do not disturb: 11 PM - 7 AM',
                groupValue: _quietHours,
                onChanged: (value) {
                  setState(() => _quietHours = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('No quiet hours'),
              trailing: Radio<String>(
                value: 'No quiet hours',
                groupValue: _quietHours,
                onChanged: (value) {
                  setState(() => _quietHours = value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Sound'),
        content: const Text('Notification sound settings will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequency Settings'),
        content: const Text('Advanced frequency settings will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _enableAll() {
    setState(() {
      _orderUpdates = true;
      _promotionalOffers = true;
      _pickupReminders = true;
      _deliveryUpdates = true;
      _weeklyDigest = true;
      _newServiceAlerts = true;
      _priceDropAlerts = true;
      _loyaltyRewards = true;
      _pushNotifications = true;
      _emailNotifications = true;
    });
    
    // Save all preferences
    _savePreference('notif_order_updates', true);
    _savePreference('notif_promotional_offers', true);
    _savePreference('notif_pickup_reminders', true);
    _savePreference('notif_delivery_updates', true);
    _savePreference('notif_weekly_digest', true);
    _savePreference('notif_new_service_alerts', true);
    _savePreference('notif_price_drop_alerts', true);
    _savePreference('notif_loyalty_rewards', true);
    _savePreference('notif_push_enabled', true);
    _savePreference('notif_email_enabled', true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications enabled')),
    );
  }

  void _disableAll() {
    setState(() {
      _orderUpdates = false;
      _promotionalOffers = false;
      _pickupReminders = false;
      _deliveryUpdates = false;
      _weeklyDigest = false;
      _newServiceAlerts = false;
      _priceDropAlerts = false;
      _loyaltyRewards = false;
      _pushNotifications = false;
      _emailNotifications = false;
      _smsNotifications = false;
    });
    
    // Save all preferences
    _savePreference('notif_order_updates', false);
    _savePreference('notif_promotional_offers', false);
    _savePreference('notif_pickup_reminders', false);
    _savePreference('notif_delivery_updates', false);
    _savePreference('notif_weekly_digest', false);
    _savePreference('notif_new_service_alerts', false);
    _savePreference('notif_price_drop_alerts', false);
    _savePreference('notif_loyalty_rewards', false);
    _savePreference('notif_push_enabled', false);
    _savePreference('notif_email_enabled', false);
    _savePreference('notif_sms_enabled', false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications disabled')),
    );
  }
} 