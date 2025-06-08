import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/screens/auth/login_screen.dart';
import 'package:customer_app/presentation/screens/auth/otp_verification_screen.dart';
import 'package:customer_app/presentation/screens/auth/profile_setup_screen.dart';
import 'package:customer_app/presentation/screens/auth/welcome_screen.dart';
import 'package:customer_app/presentation/screens/main/main_wrapper.dart';
import 'package:customer_app/presentation/screens/profile/edit_profile_screen.dart';
import 'package:customer_app/presentation/screens/profile/manage_addresses_screen.dart';
import 'package:customer_app/presentation/screens/splash/splash_screen.dart';
import 'package:customer_app/presentation/screens/address/add_address_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otpVerification = '/otp-verification';
  static const String profileSetup = '/profile-setup';
  static const String addAddress = '/add-address';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String trackOrder = '/track-order';
  static const String profile = '/profile';

  // New routes for profile section
  static const String editProfile = '/edit-profile';
  static const String manageAddresses = '/manage-addresses';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        otpVerification: (context) => OTPVerificationScreen(phoneNumber: ModalRoute.of(context)?.settings.arguments as String? ?? ''),
        profileSetup: (context) => const ProfileSetupScreen(),
        addAddress: (context) => const AddAddressScreen(),
        welcome: (context) => const WelcomeScreen(),
        home: (context) => const MainWrapper(),
      };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case otpVerification:
        final args = settings.arguments;
        String phoneNumber = '';
        if (args is Map<String, dynamic>) {
          phoneNumber = args['phoneNumber'] as String? ?? '';
        }
        return MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            phoneNumber: phoneNumber,
          ),
        );
      
      case profileSetup:
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      
      case addAddress:
        return MaterialPageRoute(builder: (_) => const AddAddressScreen());

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
        
      case home:
        return MaterialPageRoute(builder: (_) => const MainWrapper());
      
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case manageAddresses:
        return MaterialPageRoute(builder: (_) => const ManageAddressesScreen());

      default:
        print("Unhandled route: ${settings.name}");
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Helper method to navigate to OTP screen
  static void navigateToOTP(BuildContext context, String phoneNumber) {
    Navigator.pushNamed(
      context,
      otpVerification,
      arguments: {'phoneNumber': phoneNumber},
    );
  }
 

  // Helper method to navigate to home and clear stack
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
    );
  }

  // Helper method to navigate to profile setup
  static void navigateToProfileSetup(BuildContext context) {
    Navigator.pushReplacementNamed(context, profileSetup);
  }

  static void navigateToAddAddress(BuildContext context) {
    Navigator.pushReplacementNamed(context, addAddress);
  }

  static void navigateToWelcome(BuildContext context) {
    Navigator.pushReplacementNamed(context, welcome);
  }
}

// Profile Completion Check Widget
// This can be used to wrap screens that require complete profile

class ProfileCompleteGuard extends StatelessWidget {
  final Widget child;

  const ProfileCompleteGuard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!context.mounted) {
          return const SizedBox.shrink();
        }

        if (authProvider.authStatus == AuthStatus.authenticated &&
            !authProvider.isProfileComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
            }
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return child;
      },
    );
  }
}