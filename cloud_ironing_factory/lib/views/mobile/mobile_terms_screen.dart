// views/mobile/mobile_terms_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/terms_content.dart';

class MobileTermsScreen extends StatefulWidget {
  const MobileTermsScreen({Key? key}) : super(key: key);

  @override
  State<MobileTermsScreen> createState() => _MobileTermsScreenState();
}

class _MobileTermsScreenState extends State<MobileTermsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            fontFamily: AppTheme.primaryFont,
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF download coming soon!'),
                  backgroundColor: AppTheme.accentAzure,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(),
            
            // Terms Content
            _buildTermsContent(),
            
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.mediumGray.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Cloud Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.cloud_outlined,
              size: 32,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            'Cloud Ironing Factory',
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'Please read these terms carefully before using our services. Your trust is our priority.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 13,
              color: AppTheme.warmGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Last Updated Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppTheme.warmGray,
                ),
                const SizedBox(width: 6),
                Text(
                  'LAST UPDATED: ${TermsContent.lastUpdated}',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.warmGray,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: TermsContent.sections.map((section) {
          return _buildSection(section);
        }).toList(),
      ),
    );
  }

  Widget _buildSection(TermsSection section) {
    final bool isContactSection = section.number == 9;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Number Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number Badge
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${section.number}',
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Title
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content
          if (section.isHighlighted)
            _buildHighlightedContent(section)
          else if (isContactSection)
            _buildContactContent(section)
          else
            _buildNormalContent(section),
        ],
      ),
    );
  }

  Widget _buildNormalContent(TermsSection section) {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: section.content.map((content) {
          // Check if it's a bullet point (starts with specific keywords)
          final bool isBulletPoint = section.content.length > 1 || 
              content.startsWith('Professional') ||
              content.startsWith('Doorstep') ||
              content.startsWith('Specialized') ||
              content.startsWith('All prices') ||
              content.startsWith('Payment is') ||
              content.startsWith('Check pockets') ||
              content.startsWith('Separate items') ||
              content.startsWith('Verify item');
          
          if (isBulletPoint && section.content.length > 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.accentAzure,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      content,
                      style: TextStyle(
                        fontFamily: AppTheme.primaryFont,
                        fontSize: 14,
                        color: AppTheme.darkGray,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              content,
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                fontSize: 14,
                color: AppTheme.darkGray,
                height: 1.6,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHighlightedContent(TermsSection section) {
    return Container(
      margin: const EdgeInsets.only(left: 36),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryNavy.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: section.content.map((content) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              content,
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                fontSize: 14,
                color: AppTheme.darkGray,
                height: 1.6,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactContent(TermsSection section) {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.content.first,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 14,
              color: AppTheme.darkGray,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          
          // Phone
          _buildContactItem(
            Icons.phone_outlined,
            TermsContent.phone,
          ),
          const SizedBox(height: 12),
          
          // Email
          _buildContactItem(
            Icons.email_outlined,
            TermsContent.email,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.accentAzure.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.accentAzure,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppTheme.primaryFont,
            fontSize: 14,
            color: AppTheme.accentAzure,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            color: AppTheme.mediumGray.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          
          // Logo Icon
          Icon(
            Icons.cloud_outlined,
            size: 28,
            color: AppTheme.primaryNavy,
          ),
          const SizedBox(height: 8),
          
          // Company Name
          Text(
            'Cloud Ironing Factory',
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          
          // Copyright
          Text(
            '© 2024 Cloud Ironing Factory Pvt Ltd.',
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 11,
              color: AppTheme.warmGray,
            ),
          ),
          const SizedBox(height: 8),
          
          // Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontFamily: AppTheme.primaryFont,
                  fontSize: 12,
                  color: AppTheme.accentAzure,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '|',
                  style: TextStyle(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
              Text(
                'Help Centre',
                style: TextStyle(
                  fontFamily: AppTheme.primaryFont,
                  fontSize: 12,
                  color: AppTheme.accentAzure,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  }
