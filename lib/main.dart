import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme.dart';
import 'screens/splash.dart';

import 'services/notification_service.dart';
import 'services/weather_service.dart';
import 'services/download_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Notifications
  await NotificationService().initialize();

  // Initialize Downloads
  await DownloadService().init();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Pre-fetch weather in background
  WeatherService().fetchWeather().catchError((e) {
    debugPrint("Weather fetch failed: $e");
    return WeatherData(
      condition: 'Unknown',
      temperature: 0,
      city: 'Unknown',
      country: '',
    );
  });

  runApp(const MoodCastApp());
}

class MoodCastApp extends StatelessWidget {
  const MoodCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MoodCast',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
