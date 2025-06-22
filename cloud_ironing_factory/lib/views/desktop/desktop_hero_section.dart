// widgets/desktop/desktop_hero_section.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class DesktopHeroSection extends StatelessWidget {
  const DesktopHeroSection({Key? key}) : super(key: key);

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

  Future<void> _DownloadApp() async {
    final Uri _DownloadApp = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.cloudironingfactory.customer',
    );
    try {
      if (await canLaunchUrl(_DownloadApp)) {
        await launchUrl(_DownloadApp, mode: LaunchMode.externalApplication);
      } else {}
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
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
        // padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 50),
            // Left Content
            Expanded(
              child: Column(
                spacing: 40.0, // Increased spacing
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with colored words and logo
                  _buildHeroTitle(context),

                  // Subtitle
                  Text(
                    'Convenient Door-To-Door Ironing\nServices That Save You Time.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      fontFamily: AppTheme.primaryFont,
                    ),
                  ),

                  // CTA Button
                  Wrap(
                    runSpacing: 10,
                    spacing: 10,
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _bookPickup();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Book a Pickup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.primaryFont,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _DownloadApp();
                        },
                        style: ElevatedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                          backgroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Download App',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.primaryFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Image
            Expanded(
              // flex: 4,
              child: Container(
                width: 400,
                height: 500,
                margin: const EdgeInsets.only(top: 50),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage('images/hero-image.png'),
                    fit: BoxFit.cover,
                  ),
                ),

                // child: Image.asset(
                //   width: 400,
                //   'images/hero-image.png',
                //   height: 400,
                //   fit: BoxFit.contain,
                //   errorBuilder: (context, error, stackTrace) {
                //     return Container(
                //       height: 500,
                //       decoration: BoxDecoration(
                //         gradient: const LinearGradient(
                //           colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                //         ),
                //         borderRadius: BorderRadius.circular(20),
                //       ),
                //       child: Column(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: const [
                //           Icon(Icons.business, size: 80, color: AppTheme.white),
                //           SizedBox(height: 16),
                //           Text(
                //             'Professional Team',
                //             style: TextStyle(
                //               color: AppTheme.white,
                //               fontSize: 24,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //           SizedBox(height: 8),
                //           Text(
                //             'Expert Ironing Services',
                //             style: TextStyle(
                //               color: AppTheme.white,
                //               fontSize: 16,
                //             ),
                //           ),
                //         ],
                //       ),
                //     );
                //   },
                // ),
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
        // Adjust font size based on available width
        double fontSize = constraints.maxWidth > 600 ? 65 : 45;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            // First line: "We Pick Up"
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
                      color: AppTheme.primaryNavy,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppTheme.primaryFont,
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
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.w500,
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
                  width: fontSize + 35, // Scale logo with font size
                  height: fontSize + 35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
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
                            size: 24,
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
                      color: AppTheme.primaryNavy,
                      fontWeight: FontWeight.w500,
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
