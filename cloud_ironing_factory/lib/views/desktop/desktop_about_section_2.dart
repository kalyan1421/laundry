// widgets/desktop/desktop_about_section.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DesktopAboutSection2 extends StatelessWidget {
  const DesktopAboutSection2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 40.0),
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
                  'Journey starts from..',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Banking to Busting Wrinkles:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textGrey,
                    height: 1.8,
                    fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.justify,
                ),
                Text(
                  'A meticulous finance pro trades spreadsheets for steam, revolutionizing the ironing industry with detail-oriented precision and unparalleled customer care. (This emphasizes the unexpected career change and highlights the core skills coming from banking.)\n\nHe spent 20 years ironing out banking errors; now, He\'s ironing clothes to perfection. Driven by a passion for excellence, He\'s building an ironing empire, one flawlessly pressed garment at a time. (This plays on the double meaning of "ironing out" and creates a narrative of ambition and high standards.)\n\nTired of overlooked wrinkles, she left the corporate world to create a flawless finish. Armed with banking precision and a customer-first attitude, she\'s pressing the ironing industry into a new era of quality and convenience. (This emphasizes the problem she\'s solving and positions her as an innovator and champion of the customer.)',
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
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'Book a Service',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
                'assets/images/about_us_2.png',
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
                        Icon(
                          Icons.business,
                          size: 80,
                          color: AppTheme.white,
                        ),
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
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 16,
                          ),
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