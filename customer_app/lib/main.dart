
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/screens/auth/welcome_screen.dart';
import 'package:customer_app/presentation/screens/home/home_screen.dart';
import 'package:customer_app/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Services
import 'services/firebase_service.dart';

// Routes
import 'core/routes/app_routes.dart';


// Firebase Options (auto-generated)
// import 'firebase_options.dart';

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
      // options: DefaultFirebaseOptions.currentPlatform,
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
      case AuthStatus.unknown:
        return const SplashScreen();
      
      case AuthStatus.authenticated:
        // User is authenticated, check if profile is complete
        if (authProvider.isNewUser || !authProvider.isProfileComplete) {
          return const WelcomeScreen();
        }
        return const HomeScreen();
      
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
      default:
        return const SplashScreen(); // Will navigate to onboarding/login
    }
  }

  // App theme configuration
  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF4299E1),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2D3748)),
        titleTextStyle: TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      
      // ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A5568),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          minimumSize: const Size(double.infinity, 50),
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
          borderSide: const BorderSide(color: Color(0xFF4299E1)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFA0AEC0),
          fontWeight: FontWeight.normal,
        ),
      ),
      
      // SnackBar theme
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey[200],
        thickness: 1,
        space: 1,
      ),
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4299E1),
        secondary: Color(0xFF4A5568),
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
        Navigator.pushReplacementNamed(context, '/home');
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