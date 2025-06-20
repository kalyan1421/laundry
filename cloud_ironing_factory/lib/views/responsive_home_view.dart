// views/responsive_home_view.dart
import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import 'mobile/mobile_home_view.dart';
import 'desktop/desktop_home_view.dart';

class ResponsiveHomeView extends StatelessWidget {
  const ResponsiveHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWidget(
        mobile: const MobileHomeView(),
        tablet: const DesktopHomeView(), // Use desktop layout for tablet
        desktop: const DesktopHomeView(),
      ),
    );
  }
}