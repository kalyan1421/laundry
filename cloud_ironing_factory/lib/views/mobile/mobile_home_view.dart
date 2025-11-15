// views/mobile/mobile_home_view.dart
import 'package:cloud_ironing_factory/widgets/mobile/mobile_header.dart';
import 'package:cloud_ironing_factory/views/mobile/mobile_about_section.dart';
import 'package:cloud_ironing_factory/views/mobile/mobile_about_section_2.dart';
import 'package:cloud_ironing_factory/views/mobile/mobile_contact_section.dart';
import 'package:cloud_ironing_factory/views/mobile/mobile_footer.dart';
import 'package:cloud_ironing_factory/views/mobile/mobile_hero_section.dart';
import 'package:cloud_ironing_factory/views/mobile/mobile_services_section.dart';
import 'package:cloud_ironing_factory/views/mobile/mobile_special_services_section.dart';
import 'package:cloud_ironing_factory/views/mobile/mobile_why_choose_us_section.dart';
import 'package:flutter/material.dart';

class MobileHomeView extends StatefulWidget {
  const MobileHomeView({Key? key}) : super(key: key);

  @override
  State<MobileHomeView> createState() => _MobileHomeViewState();
}

class _MobileHomeViewState extends State<MobileHomeView> {
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
                SizedBox(height: 80), // Space for fixed header
                MobileHeroSection(),
                MobileAboutSection(),
                // MobileAboutSection2(),
                MobileWhyChooseUsSection(),
                MobileServicesSection(),
                MobileSpecialServicesSection(),
                MobileContactSection(),
                MobileFooter(),
              ],
            ),
          ),

          // Fixed Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MobileHeader(onNavigate: _scrollToSection),
          ),
        ],
      ),
    );
  }
}
