// widgets/mobile/mobile_why_choose_us_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_ironing_factory/theme/app_theme.dart';

class MobileWhyChooseUsSection extends StatelessWidget {
  const MobileWhyChooseUsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            
            // Main Content Section
            _buildMainContent(),
            
            // Why Choose Us Section
            _buildWhyChooseUs(),
            
            // Core Values Section
            _buildCoreValues(),
            
            // Call to Action Section
            _buildCallToAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        children: [
          // Logo and Title
          Image.asset(
            'assets/images/logo.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_laundry_service,
                  size: 30,
                  color: AppTheme.white,
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          
          const Text(
            'Cloud Ironing Factory Private Limited',
            style: TextStyle(
              fontSize: 24,
              fontFamily: AppTheme.primaryFont,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Elevating The Art Of Garment Care',
            style: TextStyle(
              fontSize: 18,
              fontFamily: AppTheme.primaryFont,
              color: AppTheme.primaryBlue,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        children: [
          // Main Description
          RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                fontFamily: AppTheme.primaryFont,
                color: AppTheme.textGrey,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Tired Of '),
                TextSpan(
                  text: 'Ironing',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: '? Cloud Ironing Factory Is Here To Reclaim Your Time And Elevate Your Wardrobe. We\'re Not Just Ironing; We\'re Crafting Perfectly Pressed Garments That Empower You To Look And Feel Your Best.',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Promise Section
          const Text(
            'Our Promise: Beyond Ironing, It\'s About Excellence',
            style: TextStyle(
              fontSize: 20,
              fontFamily: AppTheme.primaryFont,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppTheme.primaryBlue,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/Rectangle_1.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.iron,
                        size: 60,
                        color: AppTheme.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Features
          _buildFeatureItem(
            'Uncompromising Quality, Unbeatable Value:',
            'We Deliver Flawlessly Honest Garments Using Meticulous Techniques And State-Of-The-Art Equipment, All At Prices That Respect Your Budget. Expect Exceptional Results Without The Premium Price Tag.',
            AppTheme.primaryBlue,
          ),
          
          const SizedBox(height: 20),
          
          _buildFeatureItem(
            'Dedicated To Exceeding Expectations:',
            'Our Commitment Extends Beyond Simply Ironing Clothes; We Are Dedicated To Exceeding Expectations By Delivering Quality Beyond The Price.',
            AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseUs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        children: [
          const Text(
            'The Cloud Ironing Difference: Why Choose Us?',
            style: TextStyle(
              fontSize: 20,
              fontFamily: AppTheme.primaryFont,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Image
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppTheme.primaryBlue,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/Rectangle_2.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: AppTheme.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Features
          _buildFeatureItem(
            'Convenience Redefined:',
            'Our Seamless Door-To-Door Pickup And Drop-Off Service Eliminates The Hassle Of Traditional Ironing. Schedule Your Service With Ease And Let Us Handle The Rest.',
            AppTheme.primaryBlue,
          ),
          
          const SizedBox(height: 15),
          
          _buildFeatureItem(
            'Master Craftspeople:',
            'Our Highly Skilled Team Comprises Ironing Artisans Who Treat Each Garment With The Utmost Care And Precision. They Understand Fabrics, Employ Specialized Techniques, And Deliver Impeccable Results Every Time.',
            AppTheme.primaryBlue,
          ),
          
          const SizedBox(height: 15),
          
          _buildFeatureItem(
            'Driven By Innovation:',
            'We\'re Not Satisfied With The Status Quo. We\'re Constantly Innovating To Improve Our Processes, Enhance Our Services, And Deliver The Best Possible Customer Experience.',
            AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildCoreValues() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        children: [
          const Text(
            'Our Core Values: The Foundation Of Our Success',
            style: TextStyle(
              fontSize: 20,
              fontFamily: AppTheme.primaryFont,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Features
          _buildFeatureItem(
            'Customer Obsession:',
            'Your Satisfaction Is Our North Star. We Listen To Your Needs, Anticipate Your Expectations, And Strive To Create A Truly Exceptional Experience.',
            AppTheme.primaryBlue,
          ),
          
          const SizedBox(height: 20),
          
          _buildFeatureItem(
            'Precision & Perfection:',
            'We\'re Obsessed With Details. Every Crease, Every Fold, Every Garment Is Inspected To Ensure It Meets Our Rigorous Standards Of Perfection.',
            AppTheme.primaryBlue,
          ),
          
          const SizedBox(height: 20),
          
          _buildFeatureItem(
            'Integrity & Transparency:',
            'We Believe In Honest Communication And Transparent Pricing. You Can Trust Us To Deliver On Our Promises, Every Time.',
            AppTheme.primaryBlue,
          ),
          
          const SizedBox(height: 24),
          
          // Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppTheme.primaryBlue,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/Rectangle_3.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sentiment_very_satisfied,
                        size: 60,
                        color: AppTheme.white,
                      ),
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

  Widget _buildCallToAction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryBlue, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Join The Cloud Ironing Revolution!',
              style: TextStyle(
                fontSize: 16,
                fontFamily: AppTheme.primaryFont,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Cloud Ironing Factory Is More Than Just An Ironing Service; We\'re A Team Dedicated To Simplify Your Life While Helping You Present Your Best Self. Experience The Cloud Ironing Difference.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Get Started Today And Discover The Joy Of Effortlessly Impeccable Garments!',
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppTheme.primaryFont,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: () {
              // Handle book service action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Book A Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontFamily: AppTheme.primaryFont,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: AppTheme.primaryFont,
            color: Colors.black,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}