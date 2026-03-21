import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../theme.dart';
import 'auth/login.dart';
import 'main_screen.dart';
import '../services/weather_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _infiniteController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _infiniteController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _infiniteController, curve: Curves.easeInOutSine),
    );

    _infiniteController.repeat(reverse: true);

    _startInitialization();
  }

  Future<void> _startInitialization() async {
    await _animationController.forward();
    if (!mounted) return;

    await _checkLocationRequirements();
  }

  Future<void> _checkLocationRequirements() async {
    final User? user = FirebaseAuth.instance.currentUser;

    bool isLocationReady = false;
    while (!isLocationReady) {
      if (!mounted) return;
      try {
        await WeatherService().fetchWeather();
        isLocationReady = true;
      } catch (e) {
        if (e is AppLocationServiceDisabledException ||
            e is AppLocationPermissionDeniedException ||
            e is AppLocationPermissionPermanentlyDeniedException) {
          await _showLocationRequiredDialog(e.toString());
        } else {
          // Non-location errors (like network) don't block the app
          debugPrint("Splash: Potential network error, proceeding anyway. $e");
          isLocationReady = true;
        }
      }
    }

    if (mounted) {
      final Widget nextScreen =
          user != null ? const MainScreen() : const LoginScreen();

      await _animationController.reverse();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final curve = Curves.easeInOutQuart;
              final fadeAnimation = CurvedAnimation(
                parent: animation,
                curve: curve,
              );
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(fadeAnimation);

              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
          ),
        );
      }
    }
  }

  Future<void> _showLocationRequiredDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF151921),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.orangeAccent),
              SizedBox(width: 12),
              Text('Location Required', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'MoodCast uses your location to tailor your emotional soundscape to your environment. Please enable location services to continue.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _infiniteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.getThemeForMood('Sad'),
      child: Scaffold(
        backgroundColor: const Color(0xFF080C14),
        body: Stack(
          children: [
            // Background Glow Top Right
            Positioned(
              top: -150,
              right: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF1A3A5F), Colors.transparent],
                    stops: [0.0, 0.6],
                  ),
                ),
              ),
            ),
            // Background Glow Bottom Left
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF0D1526), Colors.transparent],
                    stops: [0.0, 0.6],
                  ),
                ),
              ),
            ),
            // Centered Animated Content
            Center(
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo with glowing shadow and infinite pulse
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor
                                            .withValues(
                                              alpha:
                                                  0.4 * _pulseAnimation.value,
                                            ),
                                        blurRadius: 60 * _pulseAnimation.value,
                                        spreadRadius: -10,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: Theme.of(context).primaryColor,
                                    size: 80,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 48),
                          // App Name
                          const Text(
                            'MoodCast',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Subtitle
                          const Text(
                            'Your adaptive emotional soundscape',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 16,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
