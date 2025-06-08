import 'package:admin_panel/firebase_options.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/screens/login/login_screen.dart';
import 'package:admin_panel/screens/admin/first_admin_signup_screen.dart';
import 'package:admin_panel/screens/login/otp_verification_screen.dart';
import 'package:admin_panel/screens/admin/admin_home.dart';
import 'package:admin_panel/screens/delivery/delivery_home.dart';
import 'package:admin_panel/services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/item_provider.dart';
import 'providers/order_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/offer_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/user_provider.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set the background messaging handler from FcmService
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Laundry Management Admin Panel',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          // '/admin-signup': (context) => const FirstAdminSignupScreen(),
          '/admin-home': (context) => const AdminHome(),
          '/delivery-home': (context) => const DeliveryHome(),
          '/admin_order_details': (context) {
            final String? orderId = ModalRoute.of(context)?.settings.arguments as String?;
            if (orderId != null) {
              return AdminOrderDetailsScreen(orderId: orderId);
            }            
            return const Scaffold(body: Center(child: Text('Error: Order ID missing')));
          },
        },
        onGenerateRoute: (settings) {
          // Handle dynamic routes like OTP verification
          if (settings.name == '/otp-verification') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return MaterialPageRoute(
                builder: (context) => OTPVerificationScreen(
                  phoneNumber: args['phoneNumber'] as String,
                  expectedRole: args['expectedRole'] as UserRole,
                  // registrationDetails: args['registrationDetails'] as Map<String, dynamic>?,
                ),
              );
            }
          }
          return null;
        },
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
        if (authProvider.authStatus == AuthStatus.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authProvider.isAuthenticated && authProvider.userRole != null) {
          final role = authProvider.userRole!;
          switch (role) {
            case UserRole.admin:
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FcmService().initialize(context);
              });
              return const AdminHome();
            case UserRole.delivery:
              return const DeliveryHome();
          }
        }
        
        // If not authenticated, always show LoginScreen.
        // LoginScreen has its own logic to handle the first admin case.
        return const LoginScreen();
      },
    );
  }
}

class AdminOrderDetailsScreen extends StatelessWidget {
  final String orderId;
  const AdminOrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: $orderId',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Order details implementation pending...',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}