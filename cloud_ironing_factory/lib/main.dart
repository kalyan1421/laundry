import 'package:flutter/material.dart';
import 'views/splash_screen.dart';
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
      home: const SplashScreen(),
    );
  }
}
