// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  _navigateToOnboarding() {
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Iron icon with steam
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Iron body
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7B8A),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A6B7A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  // Iron handle
                  Positioned(
                    top: 25,
                    left: 35,
                    child: Container(
                      width: 50,
                      height: 25,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7B8A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // Steam lines
                  Positioned(
                    top: 15,
                    left: 25,
                    child: Column(
                      children: [
                        _buildSteamLine(),
                        const SizedBox(height: 3),
                        _buildSteamLine(),
                        const SizedBox(height: 3),
                        _buildSteamLine(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // App title
            const Text(
              'CLOUD IRONING',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '.FACTORY.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ironing Service',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                fontWeight: FontWeight.w400,
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