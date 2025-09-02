// screens/profile/profile_screen.dart - Profile Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_partner_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_bottom_navigation.dart';

class ProfileScreen extends StatefulWidget {
  final DeliveryPartnerModel deliveryPartner;

  const ProfileScreen({
    super.key,
    required this.deliveryPartner,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final orderProvider = context.read<OrderProvider>();
    final stats = await orderProvider.getDeliveryPartnerStats(widget.deliveryPartner.id);
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom header
          _buildModernHeader(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile card
                  _buildProfileCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Stats cards
                  _buildStatsSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Contact details
                  _buildContactDetails(),
                  
                  const SizedBox(height: 30),
                  
                  // App settings
                  _buildAppSettings(),
                ],
              ),
            ),
          ),
          
          // Enhanced Bottom navigation
          EnhancedBottomNavigation(
            currentIndex: 2,
            deliveryPartner: widget.deliveryPartner,
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF87CEEB), Color(0xFFB8E6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with back and notifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1E3A8A),
                    size: 20,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1E3A8A),
                  size: 20,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Page title
          Text(
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.person,
              color: Color(0xFF9E9E9E),
              size: 40,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            widget.deliveryPartner.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFC8E6C9), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'This Week',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.trending_up,
                      color: Color(0xFF2E7D32),
                      size: 16,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _stats['weekCompleted']?.toString() ?? '0',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
                Text(
                  'Completed',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF90CAF9), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'This Month',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.calendar_month,
                      color: Color(0xFF1976D2),
                      size: 16,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _stats['monthCompleted']?.toString() ?? '0',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
                Text(
                  'Completed',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontSize: 12,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildContactItem(
            'Phone :',
            widget.deliveryPartner.phoneNumber,
          ),
          const SizedBox(height: 12),
          
          _buildContactItem(
            'Email :',
            widget.deliveryPartner.email,
          ),
          const SizedBox(height: 12),
          
          _buildContactItem(
            'License :',
            widget.deliveryPartner.licenseNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              // Navigate to notification settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              // Navigate to language settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: () {
              // Navigate to help section
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help section coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              // Show about dialog
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00BFFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Laundry Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 1.1.0'),
            const SizedBox(height: 8),
            const Text('Delivery Partner App'),
            const SizedBox(height: 8),
            const Text('© 2024 Laundry Service'),
            const SizedBox(height: 16),
            const Text('For support and feedback, please contact our team.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }


}
