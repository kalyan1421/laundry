// widgets/mobile/mobile_services_section.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MobileServicesSection extends StatelessWidget {
  const MobileServicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Column(
        children: [
          // Section Title
          _buildSectionTitle(context),
          const SizedBox(height: 40),

          // Service Workflow Cards
          _buildServiceWorkflow(context),
          const SizedBox(height: 40),

          // Service Categories
          _buildServiceCategories(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.1416),
            child: Image.asset('images/air_symbol.png', width: 30, height: 30),
          ),
          SizedBox(width: 10),
          Text(
            'What We Offer',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(width: 10),
          Image.asset('images/air_symbol.png', width: 30, height: 30),
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
        'image': 'assets/images/delivery.jpeg',
        'fallbackIcon': Icons.delivery_dining,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryBlue,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // First row
          Row(
            children: [
              Expanded(child: _buildWorkflowCard(context, services[0])),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              Expanded(child: _buildWorkflowCard(context, services[1])),
            ],
          ),
          const SizedBox(height: 16),
          // Arrow down
          Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(height: 16),
          // Second row
          Row(
            children: [
              Expanded(child: _buildWorkflowCard(context, services[3])),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_back,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              Expanded(child: _buildWorkflowCard(context, services[2])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowCard(
    BuildContext context,
    Map<String, dynamic> service,
  ) {
    return Container(
      height: 150,
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
            // Background Image
            Image.asset(
              service['image'] as String,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Icon(
                    service['fallbackIcon'] as IconData,
                    size: 40,
                    color: AppTheme.primaryBlue.withOpacity(0.5),
                  ),
                );
              },
            ),

            // Overlay

            // Title
            Expanded(
              child: Container(
                color: AppTheme.white,
                width: double.infinity,
                child: Text(
                  service['title'] as String,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryBlue,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Professional Ironing Services
          _buildServiceCategory(context, 'Professional', 'Ironing Services', [
            {
              'image': 'assets/images/steam_ironing.png',
              'fallbackIcon': Icons.iron,
              'text': 'Steam Ironing for all types of clothes',
            },
            {
              'image': 'assets/images/traditional_wear.png',
              'fallbackIcon': Icons.checkroom,
              'text': 'Saree/Traditional Wear Ironing',
            },
          ], AppTheme.primaryBlue),

          const SizedBox(height: 30),

          // Divider
          Container(
            height: 2,
            width: double.infinity,
            color: AppTheme.primaryBlue,
          ),

          const SizedBox(height: 30),

          // Allied Services
          _buildServiceCategory(context, 'Allied', 'Services', [
            {
              'image': 'assets/images/bed_sheets.png',
              'fallbackIcon': Icons.bed,
              'text': 'Bed Sheets And Pillow Cover Washing And Ironing',
            },
            {
              'image': 'assets/images/stain_removal.png',
              'fallbackIcon': Icons.cleaning_services,
              'text': 'Stain Removal Services On Clothes',
            },
          ], AppTheme.primaryBlue),
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
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: title2,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.textDark,
                  fontSize: 18,
                  fontFamily: AppTheme.primaryFont,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

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
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                service['image'] as String,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    service['fallbackIcon'] as IconData,
                    color: color,
                    size: 24,
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Service Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                service['text'] as String,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textDark,
                  fontFamily: AppTheme.primaryFont,
                  fontSize: 16,
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
