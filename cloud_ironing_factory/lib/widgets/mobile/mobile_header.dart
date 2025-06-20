// widgets/mobile/mobile_header.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MobileHeader extends StatefulWidget {
  final Function(double) onNavigate;

  const MobileHeader({Key? key, required this.onNavigate}) : super(key: key);

  @override
  State<MobileHeader> createState() => _MobileHeaderState();
}

class _MobileHeaderState extends State<MobileHeader> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white.withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Main Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Expanded(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 30,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.local_laundry_service,
                            size: 30,
                            color: AppTheme.darkBlue,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cloud Ironing Factory',
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFont,
                          color: AppTheme.darkBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Hamburger Menu Icon
              IconButton(
                onPressed: () {
                  setState(() {
                    _isMenuOpen = !_isMenuOpen;
                  });
                },
                icon: Icon(
                  _isMenuOpen ? Icons.close : Icons.menu,
                  color: AppTheme.darkBlue,
                  size: 28,
                ),
              ),
            ],
          ),

          // Expandable Menu
          if (_isMenuOpen) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Navigation Links
                  _navLink(context, 'Home', 0.0),
                  const Divider(height: 1, color: AppTheme.lightBackground),
                  _navLink(context, 'About Us', 600.0),
                  const Divider(height: 1, color: AppTheme.lightBackground),
                  _navLink(context, 'Services', 2000.0),
                  const Divider(height: 1, color: AppTheme.lightBackground),
                  _navLink(context, 'Contact Us', 2300.0),

                  const SizedBox(height: 16),

                  // Social Icons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialIcon(Icons.facebook),
                      const SizedBox(width: 20),
                      _socialIcon(Icons.email),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle contact
                        setState(() {
                          _isMenuOpen = false;
                        });
                        widget.onNavigate(300.0); // Navigate to contact section
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _navLink(BuildContext context, String title, double offset) {
    return InkWell(
      onTap: () {
        widget.onNavigate(offset);
        setState(() {
          _isMenuOpen = false; // Close menu after navigation
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.darkBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppTheme.darkBlue, size: 20),
    );
  }
}
