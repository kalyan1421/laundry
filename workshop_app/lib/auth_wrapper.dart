import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'widgets/loading_widget.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking authentication
        if (authProvider.isLoading) {
          return const Scaffold(
            body: LoadingWidget(
              message: 'Initializing...',
            ),
          );
        }

        // Show login screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Show loading while member data is being fetched
        if (authProvider.currentMember == null) {
          return const Scaffold(
            body: LoadingWidget(
              message: 'Loading member data...',
            ),
          );
        }

        // Show dashboard if authenticated and member data is available
        return const DashboardScreen();
      },
    );
  }
} 