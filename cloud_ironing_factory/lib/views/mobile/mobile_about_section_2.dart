// widgets/mobile/mobile_about_section_2.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MobileAboutSection2 extends StatelessWidget {
  const MobileAboutSection2({Key? key}) : super(key: key);

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
            'Journey starts from..',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppTheme.darkBlue,
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
                                    'assets/images/about_us_2.png',
                height: 350,
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
                        Icon(Icons.business, size: 60, color: AppTheme.white),
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
                          style: TextStyle(color: AppTheme.white, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Subtitle
          Text(
            'Corporate to Busting Wrinkles:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textGrey,
              height: 1.8,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'A meticulous finance pro trades spreadsheets for steam, revolutionizing the ironing industry with detail-oriented precision and unparalleled customer care. (This emphasizes the unexpected career change and highlights the core skills coming from banking.)\n\nShe spent 20 years ironing out banking errors; now, she\'s ironing clothes to perfection. Driven by a passion for excellence, she\'s building an ironing empire, one flawlessly pressed garment at a time. (This plays on the double meaning of "ironing out" and creates a narrative of ambition and high standards.)\n\nTired of overlooked wrinkles, she left the corporate world to create a flawless finish. Armed with banking precision and a customer-first attitude, she\'s pressing the ironing industry into a new era of quality and convenience. (This emphasizes the problem she\'s solving and positions her as an innovator and champion of the customer.)',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Book a Service',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
