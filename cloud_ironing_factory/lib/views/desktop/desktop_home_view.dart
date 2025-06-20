// views/desktop/desktop_home_view.dart
import 'package:cloud_ironing_factory/views/desktop/desktop_about_section.dart';
import 'package:cloud_ironing_factory/views/desktop/desktop_about_section_2.dart';
import 'package:cloud_ironing_factory/views/desktop/desktop_contact_section.dart';
import 'package:cloud_ironing_factory/views/desktop/desktop_footer.dart';
import 'package:cloud_ironing_factory/views/desktop/desktop_hero_section.dart';
import 'package:cloud_ironing_factory/views/desktop/desktop_services_section.dart';
import 'package:cloud_ironing_factory/views/desktop/desktop_special_services_section.dart';
import 'package:cloud_ironing_factory/views/desktop/desktop_why_choose_us_section.dart';
import 'package:flutter/material.dart';
import '../../widgets/desktop/desktop_header.dart';

class DesktopHomeView extends StatefulWidget {
  const DesktopHomeView({Key? key}) : super(key: key);

  @override
  State<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends State<DesktopHomeView> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(double offset) {
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 80), // Space for fixed header
                const DesktopHeroSection(),
                 const SizedBox(height: 40),
                const DesktopAboutSection(),
                const DesktopAboutSection2(),
                const DesktopWhyChooseUsSection(),
                const DesktopServicesSection(),
                const DesktopSpecialServicesSection(),
                const DesktopContactSection(),
                const DesktopFooter(),
              ],
            ),
          ),
          
          // Fixed Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ResponsiveHeader(
              onNavigate: _scrollToSection,
            ),
          ),
        ],
      ),
    );
  }
}