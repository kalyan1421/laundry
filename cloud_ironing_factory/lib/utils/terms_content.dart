// utils/terms_content.dart
// Terms & Conditions content model and data

class TermsSection {
  final int number;
  final String title;
  final List<String> content;
  final bool isHighlighted;

  const TermsSection({
    required this.number,
    required this.title,
    required this.content,
    this.isHighlighted = false,
  });
}

class TermsContent {
  static const String lastUpdated = 'DEC 26, 2025';
  static const String companyName = 'Cloud Ironing Factory';
  static const String email = 'cloudironingfactory@gmail.com';
  static const String phone = '+91 9566654788';

  static const List<TermsSection> sections = [
    TermsSection(
      number: 1,
      title: 'Introduction',
      content: [
        'Welcome to Cloud Ironing Factory. By accessing our mobile application and using our laundry services, you acknowledge that you have read, understood, and agree to be bound by these Terms.',
      ],
    ),
    TermsSection(
      number: 2,
      title: 'Services Offered',
      content: [
        'Professional steam ironing, dry cleaning, and wash & fold.',
        'Doorstep pickup and delivery in designated zones.',
        'Specialized stain removal (subject to garment inspection).',
      ],
    ),
    TermsSection(
      number: 3,
      title: 'Orders & Payments',
      content: [
        'Orders can be placed seamlessly via our app. We accept major payment methods including UPI, Credit/Debit Cards, and Cash on Delivery.',
        'All prices are inclusive of GST.',
        'Payment is due upon delivery for COD orders.',
      ],
    ),
    TermsSection(
      number: 4,
      title: 'Pickup & Delivery',
      content: [
        'We strive to adhere to scheduled 60-minute slots. However, unforeseen delays due to traffic or weather are possible. Customers must ensure availability at the address provided to avoid rescheduling fees.',
      ],
    ),
    TermsSection(
      number: 5,
      title: 'Cancellation & Refunds',
      content: [
        'Free cancellation is available up to 2 hours before the scheduled pickup time. Refunds for prepaid orders are typically processed within 5-7 business days to the original payment source.',
      ],
    ),
    TermsSection(
      number: 6,
      title: 'Damage & Liability',
      content: [
        'We exercise utmost care with your garments. In the rare event of damage or loss, our liability is capped at 10 times the service charge for that specific item.',
        'We are not liable for natural wear and tear or pre-existing weaknesses in fabric.',
      ],
      isHighlighted: true,
    ),
    TermsSection(
      number: 7,
      title: 'Privacy Policy',
      content: [
        'We respect your privacy. Personal data (name, address, contact) is collected solely for service fulfillment and is protected under applicable laws. We do not sell or trade your data to third parties.',
      ],
    ),
    TermsSection(
      number: 8,
      title: 'User Responsibilities',
      content: [
        'Check pockets for valuables before handover.',
        'Separate items that are prone to color bleeding.',
        'Verify item count during pickup and delivery.',
      ],
    ),
    TermsSection(
      number: 9,
      title: 'Contact Us',
      content: [
        'For any queries, complaints, or feedback, please reach out to us:',
      ],
    ),
  ];
}
