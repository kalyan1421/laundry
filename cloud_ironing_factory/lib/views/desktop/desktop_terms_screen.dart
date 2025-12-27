// views/desktop/desktop_terms_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/terms_content.dart';

class DesktopTermsScreen extends StatefulWidget {
  const DesktopTermsScreen({Key? key}) : super(key: key);

  @override
  State<DesktopTermsScreen> createState() => _DesktopTermsScreenState();
}

class _DesktopTermsScreenState extends State<DesktopTermsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _showBackToTop = _scrollController.offset > 300;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: Stack(
        children: [
          Column(
            children: [
              // App Bar
              _buildAppBar(),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      margin: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryNavy.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
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
                  ),
                ),
              ),
            ],
          ),
          
          // Back to Top Button
          if (_showBackToTop)
            Positioned(
              bottom: 30,
              right: 30,
              child: FloatingActionButton(
                onPressed: _scrollToTop,
                backgroundColor: AppTheme.accentAzure,
                child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button & Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 16),
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontFamily: AppTheme.primaryFont,
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          
          // Download Button
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF download coming soon!'),
                  backgroundColor: AppTheme.accentAzure,
                ),
              );
            },
            icon: const Icon(Icons.download_outlined, color: Colors.white70),
            label: Text(
              'Download PDF',
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.cloud_outlined,
              size: 40,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Cloud Ironing Factory',
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            'Please read these terms carefully before using our services. Your trust is our priority.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 16,
              color: AppTheme.warmGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          // Last Updated Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.warmGray,
                ),
                const SizedBox(width: 8),
                Text(
                  'LAST UPDATED: ${TermsContent.lastUpdated}',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
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
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Number Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${section.number}',
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Title
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
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
      padding: const EdgeInsets.only(left: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: section.content.map((content) {
          final bool isBulletPoint = section.content.length > 1;
          
          if (isBulletPoint) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 9),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.accentAzure,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      content,
                      style: TextStyle(
                        fontFamily: AppTheme.primaryFont,
                        fontSize: 16,
                        color: AppTheme.darkGray,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              content,
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                fontSize: 16,
                color: AppTheme.darkGray,
                height: 1.7,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHighlightedContent(TermsSection section) {
    return Container(
      margin: const EdgeInsets.only(left: 44),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryNavy.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: section.content.map((content) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              content,
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                fontSize: 16,
                color: AppTheme.darkGray,
                height: 1.7,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactContent(TermsSection section) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.content.first,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 16,
              color: AppTheme.darkGray,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 20),
          
          // Contact Items Row
          Row(
            children: [
              // Phone
              _buildContactItem(
                Icons.phone_outlined,
                TermsContent.phone,
              ),
              const SizedBox(width: 32),
              
              // Email
              _buildContactItem(
                Icons.email_outlined,
                TermsContent.email,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentAzure.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.accentAzure,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppTheme.primaryFont,
            fontSize: 15,
            color: AppTheme.accentAzure,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 60),
            color: AppTheme.mediumGray.withOpacity(0.3),
          ),
          const SizedBox(height: 32),
          
          // Logo Icon
          Icon(
            Icons.cloud_outlined,
            size: 36,
            color: AppTheme.primaryNavy,
          ),
          const SizedBox(height: 12),
          
          // Company Name
          Text(
            'Cloud Ironing Factory',
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          
          // Copyright
          Text(
            '© 2025 Cloud Ironing Factory Pvt Ltd.',
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 13,
              color: AppTheme.warmGray,
            ),
          ),
          const SizedBox(height: 12),
          
          // Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    fontSize: 14,
                    color: AppTheme.accentAzure,
                  ),
                ),
              ),
              Text(
                '|',
                style: TextStyle(
                  color: AppTheme.mediumGray,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Help Centre',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    fontSize: 14,
                    color: AppTheme.accentAzure,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  }
