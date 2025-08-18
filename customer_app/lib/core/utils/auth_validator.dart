import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/auth_provider.dart';

/// Utility class for validating authentication state across the app
class AuthValidator {
  
  /// Validates authentication state and handles inconsistencies
  /// Should be called when screens load or when auth-related errors occur
  static Future<void> validateAndHandle(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.validateAuthenticationState();
    } catch (e) {
      debugPrint('Error validating authentication state: $e');
    }
  }
  
  /// Widget wrapper that automatically validates auth state when built
  static Widget wrap({
    required Widget child,
    required BuildContext context,
  }) {
    return FutureBuilder<void>(
      future: validateAndHandle(context),
      builder: (context, snapshot) {
        // Always show the child, validation happens in background
        return child;
      },
    );
  }
}

/// Mixin that can be added to StatefulWidgets to automatically validate auth state
mixin AuthValidationMixin<T extends StatefulWidget> on State<T> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateAuthState();
    });
  }
  
  Future<void> _validateAuthState() async {
    if (mounted) {
      await AuthValidator.validateAndHandle(context);
    }
  }
  
  /// Call this method when encountering auth-related errors
  Future<void> handleAuthError() async {
    if (mounted) {
      await AuthValidator.validateAndHandle(context);
    }
  }
}

/// Widget that shows when authentication is being validated/fixed
class AuthValidationScreen extends StatelessWidget {
  final String message;
  
  const AuthValidationScreen({
    super.key,
    this.message = 'Validating authentication...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
