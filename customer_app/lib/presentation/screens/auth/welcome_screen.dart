// lib/screens/auth/welcome_screen.dart
import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.userModel?.name ?? 'Valued Customer';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 100,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome, $userName!',
                style: AppTextTheme.headlineMedium.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your profile and address have been set up successfully.',
                style: AppTextTheme.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Let\'s Go to Homepage',
                onPressed: () {
                  AppRoutes.navigateToHome(context);
                },
                icon: Icons.home_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}