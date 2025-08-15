// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'dart:async';

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
              // decoration: BoxDecoration(
              //   color: Colors.grey[100],
              //   borderRadius: BorderRadius.circular(20),
              // ),
              child: Image.asset("assets/icons/icon.png", fit: BoxFit.cover),
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
