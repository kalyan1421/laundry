// widgets/desktop/desktop_special_services_section.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DesktopSpecialServicesSection extends StatelessWidget {
  const DesktopSpecialServicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.lightBackground,
      padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 80.0),
      child: Column(
        children: [
          // Section Title
          _buildSectionTitle(context),
          const SizedBox(height: 60),

          // Special Services Cards
          _buildSpecialServiceCard(
            context,
            'Perfumed',
            'Ironing',
            'Elevate Your Ironing Experience With Our Perfumed Ironing Service. We Infuse Your Clothes With A Delicate, Long-Lasting Fragrance, Leaving Them Fresh And Beautifully Scented. Choose From Our Selection Of Premium, Garment-Safe Perfumes For A Truly Luxurious Finish.',
            'assets/images/perfumed-ironoing.png',
            Icons.local_florist,
            isImageLeft: true,
          ),
          const SizedBox(height: 60),

          _buildSpecialServiceCard(
            context,
            'Stiff And Starch',
            'Ironing',
            'For Garments Requiring A Crisp, Sharp Finish, Our Stiff And Starch Ironing Service Is Ideal. Whether It\'s Formal Shirts, Traditional Wear, Or Linens, We Meticulously Apply Starch To Achieve The Perfect Level Of Stiffness And A Pristine, Professional Appearance.',
            'assets/images/starch_ironing.jpeg',
            Icons.straighten,
            isImageLeft: false,
          ),
          const SizedBox(height: 60),

          _buildSpecialServiceCard(
            context,
            'Instant',
            'Ironing',
            'In A Hurry? Our Express Ironing Service Ensures Your Garments Are Perfectly Pressed And Ready When You Need Them. With A Typical Turnaround Time Of Just 30 Minutes, This Service Is Perfect For Last-Minute Preparations. Terms And Conditions Apply.',
            'assets/images/instant_ironing.jpeg',
            Icons.flash_on,
            isImageLeft: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Special ',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFont,
            ),
          ),
          TextSpan(
            text: 'Services',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialServiceCard(
    BuildContext context,
    String title1,
    String title2,
    String description,
    String imagePath,
    IconData fallbackIcon, {
    required bool isImageLeft,
  }) {
    // Image Widget
    Widget imageWidget = Container(
      width: 320,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.9),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          17,
        ), // Slightly smaller to account for border
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(fallbackIcon, size: 80, color: AppTheme.primaryBlue),
            );
          },
        ),
      ),
    );

    // Content Widget
    Widget contentWidget = Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isImageLeft ? 40.0 : 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                      fontSize: 32,
                    ),
                  ),
                  TextSpan(
                    text: title2,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.primaryFont,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textDark,
                fontFamily: AppTheme.primaryFont,
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );

    // Main Row Layout
    return Container(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children:
            isImageLeft
                ? [imageWidget, contentWidget]
                : [contentWidget, imageWidget],
      ),
    );
  }
}

// For Mobile version (if you want to keep mobile responsive)
class MobileSpecialServicesSection extends StatelessWidget {
  const MobileSpecialServicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.lightBackground,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Section Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Special ',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFont,
                  ),
                ),
                TextSpan(
                  text: 'Services',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFont,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Mobile Cards (Stacked vertically)
          _buildMobileServiceCard(
            context,
            'Perfumed Ironing',
            'Elevate Your Ironing Experience With Our Perfumed Ironing Service. We Infuse Your Clothes With A Delicate, Long-Lasting Fragrance, Leaving Them Fresh And Beautifully Scented. Choose From Our Selection Of Premium, Garment-Safe Perfumes For A Truly Luxurious Finish.',
            'assets/images/perfumed_ironing.jpeg',
            Icons.local_florist,
          ),
          const SizedBox(height: 24),

          _buildMobileServiceCard(
            context,
            'Stiff And Starch Ironing',
            'For Garments Requiring A Crisp, Sharp Finish, Our Stiff And Starch Ironing Service Is Ideal. Whether It\'s Formal Shirts, Traditional Wear, Or Linens, We Meticulously Apply Starch To Achieve The Perfect Level Of Stiffness And A Pristine, Professional Appearance.',
            'assets/images/starch_ironing.jpeg',
            Icons.straighten,
          ),
          const SizedBox(height: 24),

          _buildMobileServiceCard(
            context,
            'Instant Ironing',
            'In A Hurry? Our Express Ironing Service Ensures Your Garments Are Perfectly Pressed And Ready When You Need Them. With A Typical Turnaround Time Of Just 30 Minutes, This Service Is Perfect For Last-Minute Preparations. Terms And Conditions Apply.',
            'assets/images/instant_ironing.jpeg',
            Icons.flash_on,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileServiceCard(
    BuildContext context,
    String title,
    String description,
    String imagePath,
    IconData fallbackIcon,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                // border: Border.all(
                //   color: AppTheme.primaryBlue,
                //   width: 2,
                // ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        fallbackIcon,
                        size: 40,
                        color: AppTheme.primaryBlue,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFont,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 14,
                height: 1.5,
                fontFamily: AppTheme.primaryFont,
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
