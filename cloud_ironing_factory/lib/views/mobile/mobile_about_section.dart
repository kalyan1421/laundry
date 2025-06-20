// widgets/mobile/mobile_about_section.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MobileAboutSection extends StatelessWidget {
  const MobileAboutSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'About Us..',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 24),
          
          // Image
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/about_us.png',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.business,
                          size: 60,
                          color: AppTheme.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Professional Team',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Expert Ironing Services',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Description
          Text(
            'Cloud Ironing Factory is a premium laundry and ironing service provider specializing in quality, fast turnaround times, top-notch customer service, and convenient pick-up and drop-off options. We\'ve got everything from your everyday clothes to your special occasion garments covered.\n\nOur experienced team uses state-of-the-art equipment and eco-friendly processes to ensure your clothes look their absolute best. We understand that your time is valuable, which is why we offer flexible scheduling and reliable door-to-door service.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textGrey,
              height: 1.8,
              fontSize: 16,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 30),
          
          // CTA Button
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Handle book service
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Book a Service',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}