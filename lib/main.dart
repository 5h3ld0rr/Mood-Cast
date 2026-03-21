import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'theme.dart';
import 'screens/splash.dart';

import 'services/notification_service.dart';
import 'services/weather_service.dart';
import 'services/download_service.dart';
import 'services/connectivity_service.dart';
import 'services/mood_service.dart';
import 'services/player_service.dart';
import 'widgets/mood_background.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Audio & Player
  await PlayerService().init();

  // Initialize Google Sign In (Required for 7.0.0+)
  try {
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    debugPrint("Google Sign In initialization failed: $e");
    // We continue so the app can still boot for other features
  }

  // Initialize Notifications
  await NotificationService().initialize();

  // Initialize Downloads
  await DownloadService().init();

  // Initialize Connectivity Monitoring
  ConnectivityService().initialize();

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
    return ValueListenableBuilder<String>(
      valueListenable: MoodService().currentMood,
      builder: (context, mood, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'MoodCast',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getThemeForMood(
            FirebaseAuth.instance.currentUser == null ? 'Sad' : mood,
          ),
          builder: (context, child) {
            return MoodBackground(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  physics: const BouncingScrollPhysics(),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
