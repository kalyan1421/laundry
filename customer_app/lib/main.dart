// lib/main.dart
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/screens/auth/login_screen.dart';
import 'package:customer_app/presentation/screens/auth/welcome_screen.dart';
import 'package:customer_app/presentation/screens/home/home_screen.dart';
import 'package:customer_app/presentation/screens/main/main_wrapper.dart';
import 'package:customer_app/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/presentation/providers/address_provider.dart';
import 'package:customer_app/presentation/providers/banner_provider.dart';
import 'package:customer_app/presentation/providers/special_offer_provider.dart';
import 'package:customer_app/presentation/providers/item_provider.dart';
import 'package:customer_app/presentation/providers/home_provider.dart';

// Services
import 'services/firebase_service.dart';

// Routes
import 'core/routes/app_routes.dart';

// Theme
import 'core/theme/app_typography.dart';
import 'core/constants/font_constants.dart';
import 'core/theme/app_theme.dart';

// Firebase Options (auto-generated)
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(const CloudIroningApp());
}

class CloudIroningApp extends StatelessWidget {
  const CloudIroningApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => SpecialOfferProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),

        // Add more providers here as needed
        // ChangeNotifierProvider(create: (_) => CartProvider()),
        // ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Cloud Ironing',
            debugShowCheckedModeBanner: false,
            theme: _buildAppTheme(),

            // Handle initial route based on auth state
            home: _getInitialScreen(authProvider),

            // Use the route generator
            onGenerateRoute: AppRoutes.generateRoute,

            // Unknown route handler
            onUnknownRoute: (settings) => AppRoutes.generateRoute(settings),
          );
        },
      ),
    );
  }

  // Determine initial screen based on auth state
  Widget _getInitialScreen(AuthProvider authProvider) {
    switch (authProvider.authStatus) {
      case AuthStatus.authenticated:
        // User is logged in, show the main app content.
        return const MainWrapper();

      case AuthStatus.unauthenticated:
        // User is logged out, show the login screen.
        return const LoginScreen();
        
      case AuthStatus.unknown:
      case AuthStatus.authenticating:
      default:
        // While checking auth state, show a splash screen.
        // This prevents a flash of the login screen on app start.
        return const SplashScreen();
    }
  }

  // App theme configuration with SF Pro Display
  ThemeData _buildAppTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: FontConstants.sfProDisplay,
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF4299E1),
      scaffoldBackgroundColor: Colors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Typography with SF Pro Display
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: const Color(0xFF2D3748),
          fontWeight: FontConstants.semibold,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        centerTitle: true,
      ),

      // ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A5568),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.button,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // TextButton theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontConstants.medium,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4299E1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: const Color(0xFFA0AEC0),
          fontWeight: FontConstants.regular,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: const Color(0xFF4A5568),
          fontWeight: FontConstants.medium,
        ),
      ),

      // SnackBar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontConstants.medium,
        ),
        backgroundColor: const Color(0xFF2D3748),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey[200],
        thickness: 1,
        space: 1,
      ),

      // ListTile theme
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTypography.bodyLarge.copyWith(
          color: const Color(0xFF2D3748),
        ),
        subtitleTextStyle: AppTypography.bodyMedium.copyWith(
          color: const Color(0xFF718096),
        ),
      ),

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4299E1),
        secondary: Color(0xFF4A5568),
        tertiary: Color(0xFF38B2AC),
        surface: Colors.white,
        background: Colors.white,
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF2D3748),
        onBackground: Color(0xFF2D3748),
        onError: Colors.white,
      ),
    );
  }
}

// Splash Screen with Auth State Handling
class AuthAwareSplashScreen extends StatefulWidget {
  const AuthAwareSplashScreen({Key? key}) : super(key: key);

  @override
  State<AuthAwareSplashScreen> createState() => _AuthAwareSplashScreenState();
}

class _AuthAwareSplashScreenState extends State<AuthAwareSplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleInitialNavigation();
  }

  Future<void> _handleInitialNavigation() async {
    // Wait for splash duration
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check auth state and navigate accordingly
    if (authProvider.authStatus == AuthStatus.authenticated) {
      if (authProvider.isNewUser || !authProvider.isProfileComplete) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      // Check if user has seen onboarding (you can store this in SharedPreferences)
      bool hasSeenOnboarding = await _checkOnboardingStatus();

      if (hasSeenOnboarding) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  Future<bool> _checkOnboardingStatus() async {
    // TODO: Implement SharedPreferences check
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // return prefs.getBool('has_seen_onboarding') ?? false;
    return false; // For now, always show onboarding
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

// 404 Screen for unknown routes
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page Not Found', style: AppTypography.headlineSmall),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: AppTypography.displaySmall.copyWith(
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: const Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// App State Wrapper for Global State Management
class AppStateWrapper extends StatelessWidget {
  final Widget child;

  const AppStateWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Handle global auth state changes
        if (authProvider.authStatus == AuthStatus.unauthenticated) {
          // User logged out, navigate to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          });
        }

        return child;
      },
    );
  }
}
