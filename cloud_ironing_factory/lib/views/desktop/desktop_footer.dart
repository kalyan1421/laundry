// widgets/desktop/desktop_footer.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DesktopFooter extends StatelessWidget {
  const DesktopFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.darkBlue,
      padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 60.0),
      child: Column(
        children: [
          // Main Footer Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Info Section
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            border: Border.all(color: AppTheme.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          width: 50,
                          height: 50,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(width: 16),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Cloud Ironing Factory',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'CLOUD IRONING FACTORY PRIVATE LIMITED',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Professional ironing services that save you time and deliver perfect results every time.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Links
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Links',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFooterLink('Home'),
                    _buildFooterLink('About'),
                    _buildFooterLink('Services'),
                    _buildFooterLink('Contact Us'),
                  ],
                ),
              ),

              // Contact Info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildContactInfo(Icons.phone, '+91 6382654316'),
                    const SizedBox(height: 12),
                    _buildContactInfo(Icons.phone, '+91 9566654788'),
                    const SizedBox(height: 12),
                    _buildContactInfo(
                      Icons.email,
                      'cloudironingfactory@gmail.com',
                    ),
                    const SizedBox(height: 12),
                    _buildContactInfo(
                      Icons.location_on,
                      'B 10, 3rd street, Mogappair West Industrial Estate, Reddypalayam Road, Mogappair west, Chennai 600037.',
                    ),
                  ],
                ),
              ),

              // Download App
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Download App',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/qr_code.png',
                        height: 120,
                        width: 120,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.qr_code,
                            size: 120,
                            color: AppTheme.darkBlue,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan to download',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          const Divider(color: Colors.white30),
          const SizedBox(height: 20),

          // Bottom Bar - Made responsive with Wrap
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 20.0, // Spacing between rows in the wrap
            children: [
              const Text(
                '© 2024 Cloud Ironing Factory. All rights reserved.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 20), // Provide some spacing
              Row(
                mainAxisSize: MainAxisSize.min, // Row takes minimum space
                children: [
                  _buildSocialIcon(Icons.facebook, () {}),
                  const SizedBox(width: 16),
                  _buildSocialIcon(Icons.email, () {}),
                  const SizedBox(width: 16),
                  _buildSocialIcon(Icons.phone, () {}),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () {
          // Handle navigation
        },
        hoverColor: Colors.transparent,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppTheme.white, size: 20),
      ),
    );
  }
}
