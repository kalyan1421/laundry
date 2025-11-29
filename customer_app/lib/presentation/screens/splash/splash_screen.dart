// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:customer_app/services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    // Request location permission when the splash screen is shown
    _requestInitialPermissions();
  }

  Future<void> _requestInitialPermissions() async {
    try {
      _logger.i("Requesting location permission from splash screen...");

      // Request location permission
      final locationStatus = await Permission.location.request();
      _logger.i("Location permission status: $locationStatus");

      if (locationStatus.isGranted) {
        _logger.i("Location permission granted. App can now fetch location.");
        // You can optionally pre-fetch the location here if needed
        // await LocationService.getCurrentLocation();
      } else {
        _logger
            .w("Location permission was not granted. Status: $locationStatus");
      }
    } catch (e) {
      _logger.e("Error requesting initial permissions: $e");
    }
  }

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

            const SizedBox(height: 8),
            Text(
              'Ironing & Laundry Service',
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
    final asset =
        isDark ? 'assets/icons/logo_dark.svg' : 'assets/icons/logo_light.svg';
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
