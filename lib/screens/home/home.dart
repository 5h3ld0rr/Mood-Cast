import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/skeleton.dart';
import '../../services/player_service.dart';
import '../../services/youtube_music_service.dart';
import '../../services/mood_service.dart';
import '../../services/database_service.dart';
import '../notifications/notification_list.dart';
import 'recommendations.dart';
import '../../widgets/cached_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  final MoodService _moodService = MoodService();
  final DatabaseService _dbService = DatabaseService();
  List<YouTubeMusicMetadata> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _moodService.currentMood.addListener(_onMoodChanged);
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _moodService.currentMood.removeListener(_onMoodChanged);
    super.dispose();
  }

  void _onMoodChanged() {
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Get Liked Songs
      final likedSongs = await _dbService.getLikedSongs().first;

      // 2. Get Weather Country
      final weather = WeatherService().currentWeather.value;
      final country = weather?.country;

      // 3. Get Smart Recommendations
      final tracks = await _ytmService.getSmartRecommendations(
        mood: _moodService.currentMood.value,
        likedSongs: likedSongs,
        country: country,
      );

      if (mounted) {
        setState(() {
          _recommendations = tracks.take(6).toList(); // Show top 6 on home
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching home recommendations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: Stack(
        children: [
          // Background Gradients
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
                              color: AppTheme.primary.withValues(alpha: 0.1),
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
                    physics: const BouncingScrollPhysics(),
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
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1,
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

                        // Current Mood Card
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primary.withValues(alpha: 0.15),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
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
                                    Text(
                                      _moodService.currentMood.value,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const SizedBox(height: 16),
                                    ValueListenableBuilder<String>(
                                      valueListenable: _moodService.currentMood,
                                      builder: (context, mood, _) {
                                        final tags = _getMoodTags(mood);
                                        return Row(
                                          children: tags.map((tag) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: _buildTag(tag),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 24,
                              right: 24,
                              child: ValueListenableBuilder<WeatherData?>(
                                valueListenable:
                                    WeatherService().currentWeather,
                                builder: (context, weather, _) {
                                  if (weather == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Icon(
                                    _getWeatherIcon(weather.condition),
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                    size: 32,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
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
                                    builder: (context) => RecommendationsScreen(
                                      mood: _moodService.currentMood.value,
                                    ),
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

                        if (_isLoading)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 6,
                            itemBuilder: (context, index) =>
                                const TrackSkeleton(),
                          )
                        else if (_recommendations.isEmpty)
                          const Center(
                            child: Text(
                              'No music recommendations found.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recommendations.length,
                            itemBuilder: (context, index) {
                              final track = _recommendations[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildTrackTile(context, track, index),
                              );
                            },
                          ),

                        const SizedBox(height: 100),
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

  List<String> _getMoodTags(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return ['Upbeat', 'Energetic', 'Sunny'];
      case 'calm':
        return ['Peaceful', 'Ambient', 'Zen'];
      case 'energetic':
        return ['Power', 'Bass', 'Fast'];
      case 'focused':
        return ['Lo-fi', 'Deep', 'Work'];
      case 'relaxing':
        return ['Acoustic', 'Soft', 'Chill'];
      case 'inspired':
        return ['Dreamy', 'Cloudy', 'Soul'];
      case 'sad':
        return ['Melodic', 'Slow', 'Emotional'];
      default:
        return ['Vibe', 'Music', 'Discovery'];
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
      case 'rainy':
        return Icons.cloudy_snowing;
      default:
        return Icons.cloud;
    }
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTrackTile(
    BuildContext context,
    YouTubeMusicMetadata track,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        final queue = _recommendations.map((t) {
          return SongInfo(
            title: t.title,
            artist: t.artist,
            coverUrl: t.artworkUrl,
            videoId: t.videoId,
            previewUrl: null,
          );
        }).toList();
        PlayerService().playQueue(queue, initialIndex: index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              child: CachedImage(
                imageUrl: track.artworkUrl,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.play_circle_fill,
              color: AppTheme.primary,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}
