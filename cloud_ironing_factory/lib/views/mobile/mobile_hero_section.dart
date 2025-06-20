// widgets/mobile/mobile_hero_section.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class MobileHeroSection extends StatelessWidget {
  const MobileHeroSection({Key? key}) : super(key: key);

  // Book Pickup Functionality
  Future<void> _bookPickup() async {
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/919566654788?text=Hi! I would like to book a pickup for ironing services. Please let me know the available slots.',
    );
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to phone call
        final Uri phoneUri = Uri(scheme: 'tel', path: '9566654788');
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        }
      }
    } catch (e) {
      print('Error booking pickup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Hero Title
            _buildHeroTitle(context),
            const SizedBox(height: 24),
            
            // Hero Image
            Center(
              child: Image.asset(
                'assets/images/hero_ironing.jpg',
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.dry_cleaning,
                          size: 80,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Professional Ironing Services',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Subtitle
            Text(
              'Convenient Door-To-Door Ironing\nServices That Save You Time.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w400,
                height: 1.5,
                fontFamily: AppTheme.primaryFont,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // CTA Button
            ElevatedButton(
              onPressed: () {
                _bookPickup();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Book a Pickup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.primaryFont,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroTitle(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust font size for mobile
        double fontSize = 35;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // First line: "We Pick Up"
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: fontSize,
                  height: 1.2,
                  fontFamily: AppTheme.primaryFont,
                ),
                children: const [
                  TextSpan(
                    text: 'We ',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextSpan(
                    text: 'Pick Up',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Second line: "We Iron" with logo
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16.0,
              runSpacing: 10.0,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: fontSize,
                      height: 1.2,
                      fontFamily: AppTheme.primaryFont,
                    ),
                    children: const [
                      TextSpan(
                        text: 'We ',
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: 'Iron',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Logo Image
                Container(
                  width: fontSize + 20, // Scale logo with font size
                  height: fontSize + 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryBlue,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.iron,
                            size: 20,
                            color: AppTheme.primaryBlue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            // Third line: "We Deliver"
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: fontSize,
                  height: 1.2,
                  fontFamily: AppTheme.primaryFont,
                ),
                children: const [
                  TextSpan(
                    text: 'We ',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextSpan(
                    text: 'Deliver',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}