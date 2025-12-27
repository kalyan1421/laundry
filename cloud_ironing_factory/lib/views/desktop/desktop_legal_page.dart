// views/desktop/desktop_legal_page.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/legal_content.dart';
import 'desktop_footer.dart';

class DesktopLegalPage extends StatefulWidget {
  final LegalPageContent content;

  const DesktopLegalPage({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  State<DesktopLegalPage> createState() => _DesktopLegalPageState();
}

class _DesktopLegalPageState extends State<DesktopLegalPage> {
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
                  child: Column(
                    children: [
                      // Content Card
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 900),
                          margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                              
                              // Content
                              _buildContent(),
                            ],
                          ),
                        ),
                      ),
                      
                      // Footer
                      const DesktopFooter(),
                    ],
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
                widget.content.pageTitle,
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
          
          // Home Button
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
            icon: const Icon(Icons.home_outlined, color: Colors.white70),
            label: Text(
              'Back to Home',
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
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
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
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getIconForPage(),
              size: 40,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            widget.content.pageTitle,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            widget.content.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 16,
              color: AppTheme.warmGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          
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
                  'Last Updated: ${widget.content.lastUpdated}',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    fontSize: 13,
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
    if (widget.content.pageTitle.contains('Terms')) {
      return Icons.description_outlined;
    } else if (widget.content.pageTitle.contains('Cancellation')) {
      return Icons.receipt_long_outlined;
    } else if (widget.content.pageTitle.contains('Privacy')) {
      return Icons.privacy_tip_outlined;
    }
    return Icons.article_outlined;
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro Text
          if (widget.content.introText != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryNavy.withOpacity(0.1),
                ),
              ),
              child: Text(
                widget.content.introText!,
                style: TextStyle(
                  fontFamily: AppTheme.primaryFont,
                  fontSize: 16,
                  color: AppTheme.darkGray,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
          
          // Sections
          ...widget.content.sections.map((section) => _buildSection(section)).toList(),
        ],
      ),
    );
  }

  Widget _buildSection(LegalSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number Badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${section.number}',
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 16,
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
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Content
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Regular content
                ...section.content.map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 16,
                      color: AppTheme.darkGray,
                      height: 1.8,
                    ),
                  ),
                )).toList(),
                
                // Bullet points if any
                if (section.bulletPoints != null)
                  ...section.bulletPoints!.map((point) {
                    if (point.isEmpty) {
                      return const SizedBox(height: 14);
                    }
                    
                    final isSubPoint = point.startsWith('•') || point.startsWith('→');
                    final isHeader = point.endsWith(':') && !point.startsWith('•') && !point.startsWith('→');
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: 8,
                        left: isSubPoint ? 20 : 0,
                      ),
                      child: Text(
                        point,
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFont,
                          fontSize: 16,
                          color: isHeader ? AppTheme.primaryNavy : AppTheme.darkGray,
                          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                          height: 1.7,
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

