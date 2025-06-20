// widgets/mobile/mobile_footer.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MobileFooter extends StatelessWidget {
  const MobileFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.darkBlue,
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo and Company Name
            Column(
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.iron,
                            size: 40,
                            color: AppTheme.primaryBlue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cloud Ironing\nFactory',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFont,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Company Info Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLOUD IRONING FACTORY PRIVATE LIMITED',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFont,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Navigation Links
                Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildFooterLink('Home'),
                      _buildFooterLink('About'),
                      _buildFooterLink('Services'),
                      _buildFooterLink('Contact Us'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Contact Info
                _buildFooterContactItem(Icons.phone, '+91 9566654788'),
                _buildFooterContactItem(Icons.phone, '+91 6382654316'),
                _buildFooterContactItem(Icons.email, 'cloudironingfactory@gmail.com'),
                
                const SizedBox(height: 16),
                
                // Addresses
                _buildFooterContactItem(
                  Icons.location_on, 
                  'Registered Address: Tulip A5, Majestic Orchid, Ben Foundation, Jaswanth Nagar, Mogappair West, Chennai - 600037.'
                ),
                const SizedBox(height: 8),
                _buildFooterContactItem(
                  Icons.business, 
                  'Administrative Office Address: B-10, Mogappair West Industrial Estate, Reddypalayam Road, 3rd Street Mogappair West Estate, Chennai - 600037'
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // QR Code and Download App Section
            Column(
              children: [
                Text(
                  'Download App',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFont,
                  ),
                ),
                const SizedBox(height: 12),
                
                // QR Code
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/qr_code.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.qr_code,
                            size: 50,
                            color: AppTheme.primaryBlue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return GestureDetector(
      onTap: () {
        // Handle navigation
      },
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.white,
          fontSize: 12,
          fontFamily: AppTheme.primaryFont,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.white,
        ),
      ),
    );
  }

  Widget _buildFooterContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.white, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 11,
                fontFamily: AppTheme.primaryFont,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}