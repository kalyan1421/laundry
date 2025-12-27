// views/responsive_terms_view.dart
import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import 'mobile/mobile_terms_screen.dart';
import 'desktop/desktop_terms_screen.dart';

class ResponsiveTermsView extends StatelessWidget {
  const ResponsiveTermsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWidget(
        mobile: const MobileTermsScreen(),
        tablet: const DesktopTermsScreen(), // Use desktop layout for tablet
        desktop: const DesktopTermsScreen(),
      ),
    );
  }
}

