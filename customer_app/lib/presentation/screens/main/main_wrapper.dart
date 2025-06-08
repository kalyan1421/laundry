// screens/main/main_wrapper.dart
import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/presentation/screens/profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/presentation/screens/orders/order_tracking_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/profile_setup_screen.dart';
import 'bottom_navigation.dart';
import '../home/home_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Define screen titles for the AppBar
  static const List<String> _screenTitles = [
    'Cloud Ironing', // For HomeScreen
    'My Orders',     // For OrdersScreen
    'Track Order',   // For TrackOrderScreen
    'My Profile',    // For ProfileScreen
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const OrdersScreen(),
    const TrackOrdersScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print("MainWrapper: Building. AuthStatus: ${authProvider.authStatus}, isProfileComplete: ${authProvider.isProfileComplete}, UserID: ${authProvider.firebaseUser?.uid}, UserModel: ${authProvider.userModel?.toJson()}");

        // If AuthProvider is still figuring out the auth state, show loading.
        if (authProvider.authStatus == AuthStatus.unknown) {
          print("MainWrapper: AuthStatus is Unknown. Showing initial loading indicator.");
          return const Scaffold(body: Center(child: CircularProgressIndicator(key: ValueKey("MainWrapperInitialLoading"))));
        }

        // If authenticated but profile is not complete, redirect to ProfileSetupScreen.
        if (authProvider.authStatus == AuthStatus.authenticated && 
            !authProvider.isProfileComplete) { 
          print("MainWrapper: Condition MET - Authenticated AND profile NOT complete. Redirecting to ProfileSetupScreen.");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ModalRoute.of(context)?.settings.name != AppRoutes.profileSetup) {
                 print("MainWrapper: Navigating to ProfileSetupScreen via addPostFrameCallback.");
                 Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profileSetup, (route) => false);
            }
          });
          // Return a loading indicator or placeholder while redirecting to avoid flicker
          return const Scaffold(body: Center(child: CircularProgressIndicator(key: ValueKey("MainWrapperRedirectLoading"))));
        }
        
        print("MainWrapper: Condition NOT MET or passed. Proceeding to show main content.");
        return Scaffold(
          appBar: AppBar(
        
        backgroundColor: Colors.white,
        elevation: 0.5,
        
        title:  Text(
          _screenTitles[_selectedIndex],
          style: TextStyle(
            color: Color(0xFF0F3057),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF0F3057)),
            onPressed: () {
              print('Notifications tapped');
            },
            
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF0F3057)),
            onPressed: () {
              print('Profile tapped');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigation(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        );
      },
    );
  }
}