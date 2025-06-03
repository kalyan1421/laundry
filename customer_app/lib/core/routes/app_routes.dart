// lib/core/routes/app_routes.dart
import 'package:customer_app/presentation/screens/auth/login_screen.dart';
import 'package:customer_app/presentation/screens/auth/otp_verification_screen.dart';
import 'package:customer_app/presentation/screens/auth/welcome_screen.dart';
import 'package:customer_app/presentation/screens/home/home_screen.dart';
import 'package:customer_app/presentation/screens/splash/onboarding_screen.dart';
import 'package:customer_app/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otpVerification = '/otp-verification';
  static const String welcome = '/welcome';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
          settings: settings,
        );

      case onboarding:
        return MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
          settings: settings,
        );

      case otpVerification:
        // Extract phone number from arguments
        final phoneNumber = settings.arguments as String?;
        
        if (phoneNumber == null || phoneNumber.isEmpty) {
          // If no phone number provided, redirect to login
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
            settings: settings,
          );
        }
        
        return MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            phoneNumber: phoneNumber,
          ),
          settings: settings,
        );

      case welcome:
        return MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (context) => const NotFoundScreen(),
          settings: settings,
        );
    }
  }

  // Helper methods for navigation
  static void navigateToOTP(BuildContext context, String phoneNumber) {
    Navigator.pushNamed(
      context,
      otpVerification,
      arguments: phoneNumber,
    );
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      login,
      (route) => false,
    );
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
    );
  }

  static void navigateToWelcome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      welcome,
      (route) => false,
    );
  }
}

// 404 Screen for unknown routes
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The page you are looking for does not exist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                AppRoutes.navigateToHome(context);
              },
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}