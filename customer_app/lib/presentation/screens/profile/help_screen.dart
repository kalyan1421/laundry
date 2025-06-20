import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Quick Actions Section
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionButton(
                        context,
                        Icons.phone,
                        'Call Us',
                        'tel:+918888888888',
                      ),
                      _buildQuickActionButton(
                        context,
                        Icons.chat,
                        'Live Chat',
                        null,
                      ),
                      _buildQuickActionButton(
                        context,
                        Icons.email,
                        'Email',
                        'mailto:support@laundryapp.com',
                      ),
                      _buildQuickActionButton(
                        context,
                        Icons.messenger,
                        'WhatsApp',
                        'https://wa.me/918888888888',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // FAQ Section
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F3057),
                      ),
                    ),
                  ),
                  _buildFAQItem(
                    'How do I place an order?',
                    'You can place an order by selecting items from the home screen, adding them to cart, and choosing your pickup address and preferred time slot.',
                  ),
                  _buildFAQItem(
                    'What are the pickup timings?',
                    'We offer pickup between 8:00 AM to 8:00 PM. You can schedule pickup for the same day or next day based on availability.',
                  ),
                  _buildFAQItem(
                    'How long does it take to process my order?',
                    'Regular washing and ironing takes 24-48 hours. Express service is available for same-day delivery with additional charges.',
                  ),
                  _buildFAQItem(
                    'What if my clothes are damaged?',
                    'We take full responsibility for any damage during our service. Please report immediately and we will compensate as per our policy.',
                  ),
                  _buildFAQItem(
                    'How can I track my order?',
                    'You can track your order status in real-time from the Orders tab or by clicking on order details.',
                  ),
                  _buildFAQItem(
                    'What payment methods do you accept?',
                    'We accept UPI, debit/credit cards, net banking, and cash on delivery for your convenience.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Contact Information
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3057),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    Icons.phone,
                    'Customer Care',
                    '+91 88888 88888',
                    'Available 24/7',
                  ),
                  _buildContactItem(
                    Icons.email,
                    'Email Support',
                    'support@laundryapp.com',
                    'Response within 24 hours',
                  ),
                  _buildContactItem(
                    Icons.location_on,
                    'Head Office',
                    '123 Business District, City Name',
                    'Mon-Sat: 9 AM - 6 PM',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Other Options
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'More Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F3057),
                      ),
                    ),
                  ),
                  _buildMoreOption(
                    context,
                    Icons.rate_review,
                    'Rate Our App',
                    'Help us improve by rating our app',
                    () => _rateApp(),
                  ),
                  _buildMoreOption(
                    context,
                    Icons.share,
                    'Share App',
                    'Share with friends and family',
                    () => _shareApp(),
                  ),
                  _buildMoreOption(
                    context,
                    Icons.bug_report,
                    'Report a Bug',
                    'Found an issue? Let us know',
                    () => _reportBug(context),
                  ),
                  _buildMoreOption(
                    context,
                    Icons.description,
                    'Terms & Conditions',
                    'Read our terms and conditions',
                    () => _openTerms(),
                  ),
                  _buildMoreOption(
                    context,
                    Icons.privacy_tip,
                    'Privacy Policy',
                    'Read our privacy policy',
                    () => _openPrivacyPolicy(),
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

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    String? url,
  ) {
    return GestureDetector(
      onTap: () => _launchUrl(url, context),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0F3057).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: const Color(0xFF0F3057),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String title,
    String subtitle,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F3057).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF0F3057),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F3057),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchUrl(String? url, BuildContext context) async {
    if (url == null) {
      // For live chat, show a message since it's not implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live chat feature coming soon!'),
        ),
      );
      return;
    }

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
          ),
        );
      }
    }
  }

  void _rateApp() {
    // Implement rate app functionality
    print('Rate app tapped');
  }

  void _shareApp() {
    // Implement share app functionality
    print('Share app tapped');
  }

  void _reportBug(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text(
          'To report a bug, please contact us at support@laundryapp.com with details about the issue you encountered.',
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

  void _openTerms() {
    // Implement terms and conditions
    print('Terms tapped');
  }

  void _openPrivacyPolicy() {
    // Implement privacy policy
    print('Privacy policy tapped');
  }
}
