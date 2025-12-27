// utils/legal_content.dart
// Legal pages content - Terms, Cancellation & Refund, Privacy Policy

class LegalSection {
  final int number;
  final String title;
  final List<String> content;
  final List<String>? bulletPoints;

  const LegalSection({
    required this.number,
    required this.title,
    required this.content,
    this.bulletPoints,
  });
}

class LegalPageContent {
  final String pageTitle;
  final String subtitle;
  final String lastUpdated;
  final String? introText;
  final List<LegalSection> sections;

  const LegalPageContent({
    required this.pageTitle,
    required this.subtitle,
    required this.lastUpdated,
    this.introText,
    required this.sections,
  });
}

class LegalContent {
  static const String companyName = 'Cloud Ironing Factory Private Limited';
  static const String lastUpdated = 'December 2025';

  // ==================== TERMS & CONDITIONS ====================
  static const LegalPageContent termsAndConditions = LegalPageContent(
    pageTitle: 'Terms & Conditions',
    subtitle: 'Please read these terms carefully before using our services.',
    lastUpdated: 'December 2025',
    introText: 'These Terms & Conditions constitute a legally binding agreement between you ("Customer") and Cloud Ironing Factory Private Limited ("Company", "We", "Us"). By using our services (online or offline), you agree to comply with these terms.',
    sections: [
      LegalSection(
        number: 1,
        title: 'Services',
        content: [
          'Services are available only after the customer submits garments and pays applicable charges.',
          'Prices, turnaround times, delivery charges (if any), and additional services are displayed at the time of order confirmation.',
          'Standard service turnaround time is estimated (for example, 24–48 hours). Actual delivery time depends on service type, garment condition, and workload.',
          'Customers must accurately describe garments and mention any special instructions.',
          'We reserve the right to refuse items requiring specialist handling beyond our service scope.',
        ],
      ),
      LegalSection(
        number: 2,
        title: 'Garment Care & Liability',
        content: [
          'We exercise reasonable care while handling garments.',
        ],
        bulletPoints: [
          'Cloud Ironing Factory is not responsible for:',
          '• Pre-existing damage',
          '• Inherent fabric defects',
          '• Wear and tear',
          '',
          'Customers must inform us about:',
          '• Stains',
          '• Delicate fabrics',
          '• Expensive embellishments at the time of drop-off',
          '',
          'Any claims for damage or loss must be reported within 48 hours of delivery.',
          'We may inspect the garment and offer repair, replacement, or refund at our discretion.',
          'Maximum liability for loss or damage per item is capped at a mutually agreed value or market value of the garment.',
        ],
      ),
      LegalSection(
        number: 3,
        title: 'Acceptance of Terms',
        content: [
          'By using our services, you acknowledge that you have read, understood, and agreed to these Terms & Conditions.',
        ],
      ),
    ],
  );

  // ==================== CANCELLATION & REFUND POLICY ====================
  static const LegalPageContent cancellationPolicy = LegalPageContent(
    pageTitle: 'Cancellation & Refund Policy',
    subtitle: 'Clear guidelines for order cancellation and refunds.',
    lastUpdated: 'December 2025',
    introText: 'This policy explains the rules related to order cancellation and refunds at Cloud Ironing Factory Private Limited.',
    sections: [
      LegalSection(
        number: 1,
        title: 'Payment Terms',
        content: [
          'Full payment must be made before or at the time of delivery.',
        ],
        bulletPoints: [
          'Accepted payment methods include:',
          '• Online payments',
          '• UPI',
          '• Debit/Credit cards',
          '• Cash (as disclosed during order)',
        ],
      ),
      LegalSection(
        number: 2,
        title: 'Cancellation Policy',
        content: [],
        bulletPoints: [
          'Pre-processing cancellation (Before ironing/processing begins):',
          '→ Full refund of the service amount.',
          '',
          'Post-processing cancellation (After ironing/service has started):',
          '→ No refund will be provided.',
          '',
          'Same-day processing orders:',
          '→ Cannot be cancelled once accepted.',
        ],
      ),
      LegalSection(
        number: 3,
        title: 'Refund Policy',
        content: [],
        bulletPoints: [
          'Refunds are applicable only when:',
          '• Services are not rendered, or',
          '• As agreed during claim resolution',
          '',
          'Approved refunds will be processed within 7–14 business days.',
          'Refunds will be credited to the original payment method used.',
        ],
      ),
    ],
  );

  // ==================== PRIVACY POLICY ====================
  static const LegalPageContent privacyPolicy = LegalPageContent(
    pageTitle: 'Privacy Policy',
    subtitle: 'Your privacy is important to us.',
    lastUpdated: 'December 2025',
    introText: 'At Cloud Ironing Factory Private Limited, we value your privacy and are committed to protecting your personal information.',
    sections: [
      LegalSection(
        number: 1,
        title: 'Data Collection & Usage',
        content: [
          'Customer data is collected only for service delivery and communication purposes.',
          'Information is handled according to standard privacy practices.',
        ],
      ),
      LegalSection(
        number: 2,
        title: 'Data Protection',
        content: [
          'Sensitive customer information is protected with appropriate safeguards.',
          'We do not sell or misuse customer data.',
        ],
      ),
      LegalSection(
        number: 3,
        title: 'Governing Law',
        content: [
          'This agreement is governed by the laws of India.',
          'Chennai courts shall have exclusive jurisdiction for any disputes.',
        ],
      ),
    ],
  );
}

