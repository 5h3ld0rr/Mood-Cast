import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'screens/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MoodCastApp());
}

class MoodCastApp extends StatelessWidget {
  const MoodCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodCast AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // App is dark mode by default based on html
      home: const SplashScreen(),
    );
  }
}
