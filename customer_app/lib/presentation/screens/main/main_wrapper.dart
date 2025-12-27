// screens/main/main_wrapper.dart
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/screens/home/home_screen.dart';
import 'package:customer_app/presentation/screens/orders/orders_screen.dart';
import 'package:customer_app/presentation/screens/orders/track_order_screen.dart';
import 'package:customer_app/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/core/utils/auth_validator.dart';

import 'bottom_navigation.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with AuthValidationMixin {
  int _currentIndex = 0;
  final Logger _logger = Logger();

  final List<Widget> _screens = [
    const HomeScreen(),
    const OrdersScreen(),
    const TrackOrderScreen(),
    const ProfileScreen(),
  ];

  final List<String> _screenTitles = [
    'Home',
    'My Orders',
    'Track Order',
    'Profile',
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
    _loadUserAddresses();
  }

  void _checkUserProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _logger.d(
        'Checking user profile. Profile complete: ${authProvider.isProfileComplete}');
    if (!authProvider.isProfileComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _logger.i('User profile is not complete. Navigating to setup.');
        Navigator.pushReplacementNamed(context, AppRoutes.mergedRegistration);
      });
    } else {
      _logger.d('User profile is complete. No navigation needed.');
    }
  }

  // Load user addresses on app launch to fix address not showing issue
  void _loadUserAddresses() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        // Refresh user data to ensure addresses are loaded on app launch
        _logger.d('Refreshing user data to load addresses...');
        await authProvider.refreshUserData();
        _logger.d('User data refreshed. Addresses count: ${authProvider.userModel?.addresses.length ?? 0}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _currentIndex!=0? AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: context.backgroundColor, centerTitle: true,
        // AppBar theme is now handled by the theme system
        title: Text(
          'Cloud  Ironing  Factory',
          style: theme.textTheme.headlineSmall?.copyWith(
           
            fontSize: 22,
              color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
        ),
        // All other AppBar properties are handled by theme
      ):null,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _currentIndex,
        onItemTapped: _onTap,
      ),
    );
  }
}
