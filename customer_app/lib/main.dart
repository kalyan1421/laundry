// lib/main.dart
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/screens/auth/login_screen.dart';
import 'package:customer_app/presentation/screens/auth/profile_setup_screen.dart';
import 'package:customer_app/presentation/screens/auth/merged_registration_screen.dart';
import 'package:customer_app/presentation/screens/main/main_wrapper.dart';
import 'package:customer_app/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:customer_app/services/notification_service.dart';
import 'package:customer_app/services/order_notification_service.dart';
import 'package:customer_app/presentation/providers/address_provider.dart';
import 'package:customer_app/presentation/providers/banner_provider.dart';
import 'package:customer_app/presentation/providers/home_provider.dart';
import 'package:customer_app/presentation/providers/item_provider.dart';
import 'package:customer_app/presentation/providers/allied_service_provider.dart';
import 'package:customer_app/presentation/providers/order_provider.dart';
import 'package:customer_app/presentation/providers/special_offer_provider.dart';
import 'package:customer_app/presentation/providers/payment_provider.dart';
import 'package:customer_app/presentation/providers/theme_provider.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Notification Service
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => AlliedServiceProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SpecialOfferProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Cloud Ironing Factory',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            navigatorKey: navigatorKey, // Set the navigator key
            home: const ThemeInitializer(), // Initialize theme before showing main app
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}

class ThemeInitializer extends StatefulWidget {
  const ThemeInitializer({super.key});

  @override
  State<ThemeInitializer> createState() => _ThemeInitializerState();
}

class _ThemeInitializerState extends State<ThemeInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.initializeTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (!themeProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return const AuthWrapper();
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppUpdateWrapper();
  }
}

class AppUpdateWrapper extends StatefulWidget {
  const AppUpdateWrapper({super.key});

  @override
  State<AppUpdateWrapper> createState() => _AppUpdateWrapperState();
}

class _AppUpdateWrapperState extends State<AppUpdateWrapper> {
  @override
  void initState() {
    super.initState();
    // Check for updates when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    // Version service removed - no longer checking for updates
    print('Version service disabled - app update checks removed');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show appropriate screen based on auth status
        switch (authProvider.authStatus) {
          case AuthStatus.authenticating:
          case AuthStatus.unknown:
            return const SplashScreen();
          case AuthStatus.unauthenticated:
          case AuthStatus.failed:
            return const LoginScreen();
          case AuthStatus.authenticated:
            if (authProvider.isProfileComplete) {
              return const MainWrapper();
            } else {
              return const MergedRegistrationScreen();
            }
        }
      },
    );
  }


}

// Helper methods for showing snackbars (optional, can be moved to a utility file)
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}
