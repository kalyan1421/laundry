// widgets/mobile/mobile_special_services_section.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MobileSpecialServicesSection extends StatelessWidget {
  const MobileSpecialServicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.lightBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Column(
        children: [
          // Section Title
          _buildSectionTitle(context),
          const SizedBox(height: 40),
          
          // Special Services Cards (Stacked vertically for mobile)
          _buildMobileServiceCard(
            context,
            'Perfumed',
            'Ironing',
            'Elevate Your Laundry Experience With Our Perfumed Ironing Service. We Infuse Your Clothes With A Delicate, Long-Lasting Fragrance, Leaving Them Fresh And Beautifully Scented. Choose From Our Selection Of Premium, Garment-Safe Perfumes For A Truly Luxurious Finish.',
            'assets/images/perfumed_ironing.jpeg',
            Icons.local_florist,
          ),
          const SizedBox(height: 30),
          
          _buildMobileServiceCard(
            context,
            'Stiff And Starch',
            'Ironing',
            'For Garments Requiring A Crisp, Sharp Finish, Our Stiff And Starch Ironing Service Is Ideal. Whether It\'s Formal Shirts, Traditional Wear, Or Linens, We Meticulously Apply Starch To Achieve The Perfect Level Of Stiffness And A Pristine, Professional Appearance.',
            'assets/images/starch_ironing.jpeg',
            Icons.straighten,
          ),
          const SizedBox(height: 30),
          
          _buildMobileServiceCard(
            context,
            'Instant',
            'Ironing',
            'In A Hurry? Our Express Ironing Service Ensures Your Garments Are Perfectly Pressed And Ready When You Need Them. With A Typical Turnaround Time Of Just 30 Minutes, This Service Is Perfect For Last-Minute Preparations. Terms And Conditions Apply.',
            'assets/images/instant_ironing.jpeg',
            Icons.flash_on,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Special ',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFont,
              fontSize: 28,
            ),
          ),
          TextSpan(
            text: 'Services',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFont,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileServiceCard(
    BuildContext context,
    String title1,
    String title2,
    String description,
    String imagePath,
    IconData fallbackIcon,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppTheme.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        fallbackIcon,
                        size: 60,
                        color: AppTheme.primaryBlue,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title1 ',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 22,
                    ),
                  ),
                  TextSpan(
                    text: title2,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textDark,
                fontFamily: AppTheme.primaryFont,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}