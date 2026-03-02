import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/weather_service.dart';
import '../player.dart';
import '../profile/notifications/notification_list.dart';
import 'recommendations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14), // #080c14
      body: Stack(
        children: [
          // Gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF1A3A5F), Colors.transparent],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF0D1526), Colors.transparent],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'MoodCast',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationListScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<User?>(
                          stream: AuthService().userChanges,
                          builder: (context, snapshot) {
                            final user =
                                snapshot.data ?? AuthService().currentUser;
                            final name =
                                user?.displayName?.split(' ').first ?? 'User';

                            // Determine time-based greeting
                            final hour = DateTime.now().hour;
                            String timeGreeting = 'Good Morning';
                            if (hour >= 12 && hour < 17) {
                              timeGreeting = 'Good Afternoon';
                            } else if (hour >= 17) {
                              timeGreeting = 'Good Evening';
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$timeGreeting, $name',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'How are you feeling today?',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Weather
                        FutureBuilder<WeatherData>(
                          future: WeatherService().fetchWeather(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(8),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              // If permission denied or other error, show a default state
                              return _buildWeatherPill(
                                Icons.cloud,
                                'Cloudy 26°C',
                              );
                            }

                            final weather = snapshot.data;
                            final condition = weather?.condition ?? 'Cloudy';
                            final temp = weather?.temperature.toInt() ?? 26;

                            IconData weatherIcon;
                            switch (condition.toLowerCase()) {
                              case 'clear':
                                weatherIcon = Icons.wb_sunny;
                                break;
                              case 'clouds':
                                weatherIcon = Icons.cloud;
                                break;
                              case 'rain':
                              case 'drizzle':
                              case 'rainy':
                                weatherIcon = Icons.cloudy_snowing;
                                break;
                              default:
                                weatherIcon = Icons.cloud;
                            }

                            return _buildWeatherPill(
                              weatherIcon,
                              '$condition $temp°C',
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Current Mood Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primary.withOpacity(0.2),
                                AppTheme.primary.withOpacity(0.05),
                              ],
                            ),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CURRENT MOOD',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Happy',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _buildTag('Upbeat'),
                                    const SizedBox(width: 8),
                                    _buildTag('Energetic'),
                                    const SizedBox(width: 8),
                                    _buildTag('Sunny Vibes'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        const SizedBox(height: 32),

                        // Recommended Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recommended for You',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RecommendationsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(color: AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _buildSongTile(
                          context,
                          'Happy Vibes',
                          'Sunshine Collective',
                          Icons.play_circle_fill,
                        ),
                        const SizedBox(height: 12),
                        _buildSongTile(
                          context,
                          'Summer Pop',
                          'Neon Horizon',
                          Icons.play_circle_fill,
                        ),
                        const SizedBox(height: 12),
                        _buildSongTile(
                          context,
                          'Golden Hour',
                          'The Midnight',
                          Icons.play_circle_fill,
                        ),
                        const SizedBox(height: 100), // padding for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b).withOpacity(0.3), // card background
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xff2b6cf0), size: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
      ),
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    String title,
    String artist,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: Colors.white54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    artist,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: AppTheme.primary, size: 40),
          ],
        ),
      ),
    );
  }
}
