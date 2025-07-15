// widgets/desktop/desktop_about_section.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DesktopAboutSection extends StatelessWidget {
  const DesktopAboutSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 80.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Content
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Us..',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Cloud Ironing Factory is a premium ironing service provider specializing in quality, fast turnaround times, top-notch customer service, and convenient pick-up and drop-off options. We\'ve got everything from your everyday clothes to your special occasion garments covered.\n\nOur experienced team uses state-of-the-art equipment and eco-friendly processes to ensure your clothes look their absolute best. We understand that your time is valuable, which is why we offer flexible scheduling and reliable door-to-door service.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textGrey,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () {
                    // Handle book service
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                  child: const Text(
                    'Book a Service',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 60),

          // Right Image
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                                  'assets/images/about_us.jpeg',
                height: 400,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 400,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.business, size: 80, color: AppTheme.white),
                        SizedBox(height: 16),
                        Text(
                          'Professional Team',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Expert Ironing Services',
                          style: TextStyle(color: AppTheme.white, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
