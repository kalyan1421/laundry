// views/mobile/mobile_legal_page.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/legal_content.dart';
import 'mobile_footer.dart';

class MobileLegalPage extends StatelessWidget {
  final LegalPageContent content;

  const MobileLegalPage({
    Key? key,
    required this.content,
  }) : super(key: key);

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
          content.pageTitle,
          style: TextStyle(
            fontFamily: AppTheme.primaryFont,
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(),
            
            // Content Sections
            _buildContent(),
            
            // Footer
            const MobileFooter(),
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
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIconForPage(),
              size: 32,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            content.pageTitle,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            content.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 14,
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
                  'Last Updated: ${content.lastUpdated}',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.warmGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForPage() {
    if (content.pageTitle.contains('Terms')) {
      return Icons.description_outlined;
    } else if (content.pageTitle.contains('Cancellation')) {
      return Icons.receipt_long_outlined;
    } else if (content.pageTitle.contains('Privacy')) {
      return Icons.privacy_tip_outlined;
    }
    return Icons.article_outlined;
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro Text
          if (content.introText != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryNavy.withOpacity(0.1),
                ),
              ),
              child: Text(
                content.introText!,
                style: TextStyle(
                  fontFamily: AppTheme.primaryFont,
                  fontSize: 14,
                  color: AppTheme.darkGray,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
          
          // Sections
          ...content.sections.map((section) => _buildSection(section)).toList(),
        ],
      ),
    );
  }

  Widget _buildSection(LegalSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
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
              const SizedBox(width: 12),
              
              // Title
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Content
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Regular content
                ...section.content.map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 14,
                      color: AppTheme.darkGray,
                      height: 1.7,
                    ),
                  ),
                )).toList(),
                
                // Bullet points if any
                if (section.bulletPoints != null)
                  ...section.bulletPoints!.map((point) {
                    if (point.isEmpty) {
                      return const SizedBox(height: 10);
                    }
                    
                    final isSubPoint = point.startsWith('•') || point.startsWith('→');
                    final isHeader = point.endsWith(':') && !point.startsWith('•') && !point.startsWith('→');
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: 6,
                        left: isSubPoint ? 16 : 0,
                      ),
                      child: Text(
                        point,
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFont,
                          fontSize: 14,
                          color: isHeader ? AppTheme.primaryNavy : AppTheme.darkGray,
                          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                          height: 1.6,
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

