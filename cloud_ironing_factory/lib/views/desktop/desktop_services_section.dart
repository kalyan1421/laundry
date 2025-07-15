// widgets/desktop/desktop_services_section.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DesktopServicesSection extends StatelessWidget {
  const DesktopServicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 80.0),
      child: Column(
        children: [
          // Section Title with decorative border
          _buildSectionTitle(context),
          const SizedBox(height: 60),

          // Service Workflow Cards
          _buildServiceWorkflow(context),
          const SizedBox(height: 80),

          // Service Categories
          _buildServiceCategories(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.1416),
                                    child: Image.asset('assets/images/air_symbol.png', width: 50, height: 50),
          ),
          const SizedBox(width: 16),
          Text(
            'What We Offer',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
                          Image.asset('assets/images/air_symbol.png', width: 50, height: 50),
        ],
      ),
    );
  }

  Widget _buildServiceWorkflow(BuildContext context) {
    final services = [
      {
        'title': 'Order',
        'image': 'assets/images/order.png',
        'fallbackIcon': Icons.shopping_cart,
      },
      {
        'title': 'Pickup',
        'image': 'assets/images/pickup.jpeg',
        'fallbackIcon': Icons.local_shipping,
      },
      {
        'title': 'Ironing',
        'image': 'assets/images/ironing.png',
        'fallbackIcon': Icons.iron,
      },
      {
        'title': 'Delivery',
        'image': 'assets/images/hero_ironing.jpg',
        'fallbackIcon': Icons.delivery_dining,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryBlue,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children:
            services.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> service = entry.value;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildWorkflowCard(context, service)),
                    if (index <
                        services.length - 1) // Don't add arrow after last item
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.arrow_forward,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildWorkflowCard(
    BuildContext context,
    Map<String, dynamic> service,
  ) {
    return Container(
      height: 250,

      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Image.asset(
              service['image'] as String,
              width: double.infinity,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Icon(
                    service['fallbackIcon'] as IconData,
                    size: 80,
                    color: AppTheme.primaryBlue.withOpacity(0.5),
                  ),
                );
              },
            ),
            Expanded(
              child: Container(
                color: AppTheme.white,
                width: double.infinity,

                child: Text(
                  service['title'] as String,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryBlue,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Professional Ironing Services
          Expanded(
            child: _buildServiceCategory(
              context,
              'Professional',
              'Ironing Services',
              [
                {
                  'image':
                      'assets/images/steam_ironing.png', // Image instead of icon
                  'fallbackIcon': Icons.iron,
                  'text': 'Steam Ironing for all types of clothes',
                },
                {
                  'image':
                      'assets/images/traditional_wear.png', // Image instead of icon
                  'fallbackIcon': Icons.checkroom,
                  'text': 'Saree/Traditional Wear Ironing',
                },
              ],
              AppTheme.primaryBlue,
            ),
          ),

          // Vertical Divider
          Container(
            width: 2,
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            color: AppTheme.primaryBlue,
          ),

          // Allied Services
          Expanded(
            child: _buildServiceCategory(context, 'Allied', 'Services', [
              {
                'image':
                    'assets/images/bed_sheets.png', // Image instead of icon
                'fallbackIcon': Icons.bed,
                'text': 'Bed Sheets And Pillow Cover Washing And Ironing',
              },
              {
                'image':
                    'assets/images/stain_removal.png', // Image instead of icon
                'fallbackIcon': Icons.cleaning_services,
                'text': 'Stain Removal Services On Clothes',
              },
            ], AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategory(
    BuildContext context,
    String title1,
    String title2,
    List<Map<String, dynamic>> services,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$title1 ',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: color,
                  fontFamily: AppTheme.primaryFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: title2,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.textDark,
                  fontSize: 20,
                  fontFamily: AppTheme.primaryFont,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Services List
        ...services
            .map((service) => _buildServiceItem(context, service, color))
            .toList(),
      ],
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    Map<String, dynamic> service,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container (instead of Icon Container)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                10,
              ), // Slightly smaller to account for border
              child: Image.asset(
                service['image'] as String,
                width: 56, // Accounting for border
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails to load
                  return Icon(
                    service['fallbackIcon'] as IconData,
                    color: color,
                    size: 28,
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Service Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                service['text'] as String,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textDark,
                  fontFamily: AppTheme.primaryFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
