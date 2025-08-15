// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Iron icon with steam
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                // border: Border.all(color: Colors.grey[300]!),
              ),
              child: _buildThemeLogo(),
            ),
            const SizedBox(height: 30),
            // App title
            Text(
              'CLOUD IRONING FACTORY',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '.FACTORY.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ironing Service',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeLogo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark ? 'assets/icons/logo_dark.svg' : 'assets/icons/logo_light.svg';
    return SvgPicture.asset(
      asset,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSteamLine() {
    return Container(
      width: 15,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
