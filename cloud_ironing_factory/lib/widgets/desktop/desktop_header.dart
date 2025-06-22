// widgets/responsive_header.dart
import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';
import '../../theme/app_theme.dart';

class ResponsiveHeader extends StatefulWidget {
  final Function(double) onNavigate;

  const ResponsiveHeader({Key? key, required this.onNavigate})
    : super(key: key);

  @override
  State<ResponsiveHeader> createState() => _ResponsiveHeaderState();
}

class _ResponsiveHeaderState extends State<ResponsiveHeader> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildMobileHeader(),
      tablet: _buildTabletHeader(),
      desktop: _buildDesktopHeader(),
    );
  }

  // Desktop Header - Clean layout without Stack positioning issues
  Widget _buildDesktopHeader() {
    return ResponsiveContainer(
      desktopMaxWidth: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        desktop: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main pill-shaped container
          Container(
            width: double.infinity,
            height: ResponsiveHelper.getResponsiveValue(
              context,
              mobile: 50.0,
              tablet: 60.0,
              desktop: 80.0,
            ),

            decoration: BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                desktop: const EdgeInsets.symmetric(horizontal: 80),
                tablet: const EdgeInsets.symmetric(horizontal: 30),
                mobile: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Row(
                children: [
                  // Company name
                  Expanded(
                    flex: 3,
                    child: ResponsiveText(
                      'Cloud Ironing Factory',
                      mobileSize: 16,
                      tabletSize: 20,
                      desktopSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: AppTheme.primaryFont,
                    ),
                  ),

                  // Spacer for center logo
                  Spacer(),

                  // Navigation links - only show on larger screens
                  if (ResponsiveHelper.isDesktop(context)) ...[
                    const Spacer(),
                    _buildDesktopNavLink('Home', 0.0),
                    const SizedBox(width: 24),
                    _buildDesktopNavLink('About Us', 600.0),
                    const SizedBox(width: 24),
                    _buildDesktopNavLink('Services', 3900.0),
                    const SizedBox(width: 24),
                    _buildDesktopNavLink('Contact Us', 6200.0),
                  ],
                ],
              ),
            ),
          ),

          // Half-circle logo container positioned on top center
          Positioned(
            left: 0,
            right: 0,
            top: 0, // Position to create half-circle effect
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.5, // Show only bottom 50% to create half-circle
                child: Container(
                  clipBehavior: Clip.none,
                  width: ResponsiveHelper.getResponsiveValue(
                    context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 200.0,
                  ),
                  height: ResponsiveHelper.getResponsiveValue(
                    context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 180.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentAzure.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 70, // Adjusted for better visibility
                      ), // Position logo in visible half
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: ResponsiveHelper.getResponsiveValue(
                          context,
                          mobile: 40.0,
                          tablet: 50.0,
                          desktop: 100.0,
                        ),
                        height: ResponsiveHelper.getResponsiveValue(
                          context,
                          mobile: 40.0,
                          tablet: 50.0,
                          desktop: 100.0,
                        ),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.iron,
                            color: AppTheme.accentAzure,
                            size: ResponsiveHelper.getResponsiveValue(
                              context,
                              mobile: 35.0,
                              tablet: 40.0,
                              desktop: 50.0,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tablet Header - Simplified version
  Widget _buildTabletHeader() {
    return ResponsiveContainer(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        tablet: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Main pill-shaped container
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      const Expanded(
                        child: ResponsiveText(
                          'Cloud Ironing Factory',
                          mobileSize: 16,
                          tabletSize: 18,
                          desktopSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: AppTheme.primaryFont,
                        ),
                      ),

                      // Spacer for center logo
                      const SizedBox(width: 100),

                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isMenuOpen = !_isMenuOpen;
                          });
                        },
                        icon: Icon(
                          _isMenuOpen ? Icons.close : Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Half-circle logo container positioned on top center
              Positioned(
                left: 0,
                right: 0,
                top: 0, // Position to create half-circle effect
                child: Center(
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor:
                          0.5, // Show only bottom 50% to create half-circle
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentAzure.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 25,
                            ), // Position logo in visible half
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: ResponsiveHelper.getResponsiveValue(
                                context,
                                mobile: 40.0,
                                tablet: 80.0,
                                desktop: 100.0,
                              ),
                              height: ResponsiveHelper.getResponsiveValue(
                                context,
                                mobile: 40.0,
                                tablet: 80.0,
                                desktop: 100.0,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.iron,
                                  color: AppTheme.accentAzure,
                                  size: ResponsiveHelper.getResponsiveValue(
                                    context,
                                    mobile: 35.0,
                                    tablet: 65.0,
                                    desktop: 85.0,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Expandable menu for tablet
          if (_isMenuOpen) _buildExpandableMenu(),
        ],
      ),
    );
  }

  // Mobile Header - Existing mobile design with responsive improvements
  Widget _buildMobileHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Main Header Row
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                mobile: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              child: Row(
                children: [
                  // Logo and Brand
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.iron,
                                  color: Colors.white,
                                  size: 24,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: ResponsiveText(
                            'Cloud Ironing Factory',
                            mobileSize: 16,
                            tabletSize: 18,
                            desktopSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                            fontFamily: AppTheme.primaryFont,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hamburger Menu Icon
                  Container(
                    decoration: BoxDecoration(
                      color:
                          _isMenuOpen
                              ? AppTheme.accentAzure.withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _isMenuOpen = !_isMenuOpen;
                        });
                      },
                      icon: Icon(
                        _isMenuOpen ? Icons.close : Icons.menu,
                        color: const Color(0xFF1E3A8A),
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expandable Menu
            if (_isMenuOpen) _buildExpandableMenu(),
          ],
        ),
      ),
    );
  }

  // Expandable menu for mobile and tablet
  Widget _buildExpandableMenu() {
    return Container(
      margin: ResponsiveHelper.getResponsiveMargin(
        context,
        mobile: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        tablet: const EdgeInsets.fromLTRB(30, 10, 30, 20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildMobileNavLink('Home', 0.0, Icons.home_outlined),
          _buildDivider(),
          _buildMobileNavLink('About Us', 600.0, Icons.info_outline),
          _buildDivider(),
          _buildMobileNavLink(
            'Services',
            2000.0,
            Icons.cleaning_services_outlined,
          ),
          _buildDivider(),
          _buildMobileNavLink('Contact Us', 300.0, Icons.headset_mic_outlined),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Desktop Navigation Link Helper
  Widget _buildDesktopNavLink(String title, double offset) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onNavigate(offset),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ResponsiveText(
            title,
            mobileSize: 14,
            tabletSize: 16,
            desktopSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: AppTheme.primaryFont,
          ),
        ),
      ),
    );
  }

  // Mobile Navigation Link Helper
  Widget _buildMobileNavLink(String title, double offset, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onNavigate(offset);
          setState(() {
            _isMenuOpen = false;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            mobile: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            tablet: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
              const SizedBox(width: 16),
              ResponsiveText(
                title,
                mobileSize: 16,
                tabletSize: 17,
                desktopSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E3A8A),
                fontFamily: AppTheme.primaryFont,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Divider Helper
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: ResponsiveHelper.getResponsiveMargin(
        context,
        mobile: const EdgeInsets.symmetric(horizontal: 24),
        tablet: const EdgeInsets.symmetric(horizontal: 30),
      ),
      color: const Color(0xFF1E3A8A).withOpacity(0.1),
    );
  }
}
