// main.dart - Simplified version
import 'package:admin_panel/firebase_options.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/screens/login/login_screen.dart';
import 'package:admin_panel/screens/login/otp_verification_screen.dart';
import 'package:admin_panel/screens/admin/admin_home.dart';
import 'package:admin_panel/screens/admin/order_details_screen.dart';
import 'package:admin_panel/screens/admin/add_admin_screen.dart';
import 'package:admin_panel/screens/admin/manage_admins_screen.dart';
import 'package:admin_panel/screens/admin/manage_delivery_partners_screen.dart';
// Removed delivery screens - using phone+code auth now
import 'package:firebase_core/firebase_core.dart';
// Removed unused import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/item_provider.dart';
import 'providers/allied_service_provider.dart';
import 'providers/order_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/offer_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/user_provider.dart';
import 'services/fcm_service.dart';
import 'services/database_service.dart';
// Removed unused import
import 'services/order_notification_service.dart';
import 'services/customer_registration_service.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM service
  final fcmService = FcmService();
  await fcmService.initialize(null);

  // Initialize notification listeners
  OrderNotificationService.setupOrderListener();
  CustomerRegistrationService.setupCustomerRegistrationListener();

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
        ChangeNotifierProvider(create: (_) => AlliedServiceProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Laundry Management Admin Panel',
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
          '/admin-home': (context) => const AdminHome(),
          '/add-admin': (context) => const AddAdminScreen(),
          '/manage-admins': (context) => const ManageAdminsScreen(),
          '/manage-delivery-partners': (context) => const ManageDeliveryPartnersScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/otp-verification') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return MaterialPageRoute(
                builder:
                    (context) => OTPVerificationScreen(
                      phoneNumber: args['phoneNumber'] as String,
                      expectedRole: args['expectedRole'] as UserRole,
                    ),
              );
            }
          } else if (settings.name == '/order_details') {
            final orderId = settings.arguments as String?;
            if (orderId != null) {
              return MaterialPageRoute(
                builder: (context) => OrderDetailsScreen(orderId: orderId),
              );
            }
          }
          // Removed task details route - delivery partners use separate app
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
        print(
          '🔥 AuthWrapper: Status=${authProvider.authStatus}, Role=${authProvider.userRole}',
        );

        // Show loading
        if (authProvider.authStatus == AuthStatus.loading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Admin Panel...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we initialize your session',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // If authenticated, show appropriate home screen
        if (authProvider.isAuthenticated && authProvider.userRole != null) {
          final role = authProvider.userRole!;
          print('🔥 AuthWrapper: Authenticated user with role: $role');

          // Ensure FCM token is saved for delivery persons
          if (role == UserRole.delivery) {
            _ensureDeliveryFCMToken(authProvider);
          }

          switch (role) {
            case UserRole.admin:
            case UserRole.supervisor:
              return const AdminHome();
            case UserRole.delivery:
              // Delivery partners now use separate app with phone+code auth
              return const AdminHome(); // Fallback to admin home
          }
        }

        // Show login screen
        print('🔥 AuthWrapper: Not authenticated, showing LoginScreen');
        return const LoginScreen();
      },
    );
  }

  void _ensureDeliveryFCMToken(AuthProvider authProvider) {
    // Run FCM token check after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final fcmService = FcmService();
        await fcmService.ensureDeliveryPartnerTokenSaved();
        print('🔥 Delivery FCM token check completed');
      } catch (e) {
        print('🔥 Error ensuring delivery FCM token: $e');
      }
    });
  }
}

// Removed TaskDetailWrapper - delivery partners use separate app
