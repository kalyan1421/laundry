// views/responsive_legal_page.dart
import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import '../utils/legal_content.dart';
import 'mobile/mobile_legal_page.dart';
import 'desktop/desktop_legal_page.dart';

enum LegalPageType {
  terms,
  cancellation,
  privacy,
}

class ResponsiveLegalPage extends StatelessWidget {
  final LegalPageType pageType;

  const ResponsiveLegalPage({
    Key? key,
    required this.pageType,
  }) : super(key: key);

  LegalPageContent get _content {
    switch (pageType) {
      case LegalPageType.terms:
        return LegalContent.termsAndConditions;
      case LegalPageType.cancellation:
        return LegalContent.cancellationPolicy;
      case LegalPageType.privacy:
        return LegalContent.privacyPolicy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWidget(
        mobile: MobileLegalPage(content: _content),
        tablet: DesktopLegalPage(content: _content),
        desktop: DesktopLegalPage(content: _content),
      ),
    );
  }
}

// Convenience widgets for direct routing
class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLegalPage(pageType: LegalPageType.terms);
  }
}

class CancellationRefundPage extends StatelessWidget {
  const CancellationRefundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLegalPage(pageType: LegalPageType.cancellation);
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLegalPage(pageType: LegalPageType.privacy);
  }
}

