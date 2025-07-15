import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/earnings_provider.dart';
import 'auth_wrapper.dart';
import 'utils/app_theme.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WorkshopApp());
}

class WorkshopApp extends StatelessWidget {
  const WorkshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
      ],
      child: MaterialApp(
        title: 'Workshop Management',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
          useMaterial3: true,
          textTheme: AppTheme.textTheme,
          appBarTheme: AppTheme.appBarTheme,
          elevatedButtonTheme: AppTheme.elevatedButtonTheme,
          outlinedButtonTheme: AppTheme.outlinedButtonTheme,
          inputDecorationTheme: AppTheme.inputDecorationTheme,
          cardTheme: AppTheme.cardTheme,
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}
