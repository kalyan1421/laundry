import 'package:flutter/material.dart';
import 'views/splash_screen.dart';
import 'views/responsive_home_view.dart';
import 'views/responsive_legal_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CloudIroningFactoryApp());
}

class CloudIroningFactoryApp extends StatelessWidget {
  const CloudIroningFactoryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Ironing Factory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const ResponsiveHomeView(),
        '/terms': (context) => const TermsConditionsPage(),
        '/cancellation': (context) => const CancellationRefundPage(),
        '/privacy': (context) => const PrivacyPolicyPage(),
      },
    );
  }
}
