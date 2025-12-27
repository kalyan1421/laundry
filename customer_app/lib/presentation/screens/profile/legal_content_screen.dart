// lib/presentation/screens/profile/legal_content_screen.dart

import 'package:flutter/material.dart';
import 'package:customer_app/core/constants/legal_constants.dart';
import 'package:customer_app/core/theme/app_colors.dart';

class LegalContentScreen extends StatelessWidget {
  final LegalPageContent content;

  const LegalContentScreen({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          content.pageTitle,
          style: const TextStyle(
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
            _buildHeroSection(context),
            
            // Content Sections
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.3),
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIconForPage(),
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            content.pageTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            content.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Last Updated Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Last Updated: ${content.lastUpdated}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

  Widget _buildContent(BuildContext context) {
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
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              child: Text(
                content.introText!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
          
          // Sections
          ...content.sections.map((section) => _buildSection(context, section)).toList(),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, LegalSection section) {
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${section.number}',
                    style: const TextStyle(
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                      fontSize: 14,
                      color: Colors.grey[800],
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
                          fontSize: 14,
                          color: isHeader ? AppColors.primary : Colors.grey[800],
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
