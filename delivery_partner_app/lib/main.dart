// main.dart - Delivery Partner App
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/fcm_service.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM service
  final fcmService = FcmService();
  await fcmService.initialize(null);

  runApp(const DeliveryPartnerApp());
}

class DeliveryPartnerApp extends StatelessWidget {
  const DeliveryPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Delivery Partner - Cloud Ironing Factory',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'SFProDisplay',
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A),
          ).copyWith(
            primary: const Color(0xFF1E3A8A),
            secondary: const Color(0xFF3B82F6),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        print('🚚 AuthWrapper: Status=${authProvider.authStatus}');

        // Show loading
        if (authProvider.authStatus == AuthStatus.loading) {
          return const Scaffold(
            backgroundColor: Color(0xFF1E3A8A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                  ),
                  SizedBox(height: 24),
            Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'SFProDisplay',
                    ),
            ),
          ],
        ),
      ),
          );
        }

        // If authenticated, show dashboard
        if (authProvider.isAuthenticated && authProvider.deliveryPartner != null) {
          print('🚚 AuthWrapper: Authenticated delivery partner: ${authProvider.deliveryPartner!.name}');
          
          // Ensure FCM token is saved for delivery partner
          _ensureDeliveryFCMToken(authProvider, context);
          
          return DashboardScreen(deliveryPartner: authProvider.deliveryPartner!);
        }

        // Show login screen
        print('🚚 AuthWrapper: Not authenticated, showing LoginScreen');
        return const LoginScreen();
      },
    );
  }

  void _ensureDeliveryFCMToken(AuthProvider authProvider, BuildContext context) {
    // Run FCM token check after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final fcmService = FcmService();
        await fcmService.ensureDeliveryPartnerTokenSaved(context);
        print('🚚 Delivery FCM token check completed');
      } catch (e) {
        print('🚚 Error ensuring delivery FCM token: $e');
      }
    });
  }
}
