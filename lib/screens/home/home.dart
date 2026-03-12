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
import 'discover_artists.dart';
import '../../widgets/cached_image.dart';
import '../../services/connectivity_service.dart';
import '../search/artist_details.dart' as artist_details;

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
  List<YouTubeArtistMetadata> _suggestedArtists = [];
  bool _isLoading = true;
  bool _isArtistsLoading = true;

  @override
  void initState() {
    super.initState();
    _moodService.currentMood.addListener(_onMoodChanged);
    ConnectivityService().isOnline.addListener(_onConnectivityChanged);
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _moodService.currentMood.removeListener(_onMoodChanged);
    ConnectivityService().isOnline.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onMoodChanged() {
    _fetchRecommendations();
  }

  void _onConnectivityChanged() {
    if (ConnectivityService().isOnline.value) {
      // Refresh everything when we come back online
      WeatherService().fetchWeather();
      _fetchRecommendations();
    }
  }

  Future<void> _fetchRecommendations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isArtistsLoading = true;
    });

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

      // 4. Get Recommended Artists
      final artistQuery = _getArtistQueryForMood(_moodService.currentMood.value);
      final artists = await _ytmService.searchArtists(artistQuery);

      if (mounted) {
        setState(() {
          _recommendations = tracks.take(6).toList();
          _suggestedArtists = artists.take(8).toList();
          _isLoading = false;
          _isArtistsLoading = false;
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: Theme.of(context).primaryColor,
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
                        Text(
                          'How are you feeling today?',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color ??
                                AppTheme.textMuted,
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
                                    Theme.of(context).primaryColor.withValues(alpha: 0.15),
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
                                    ValueListenableBuilder<String>(
                                      valueListenable: _moodService.currentMood,
                                      builder: (context, mood, _) {
                                        return Text(
                                          'CURRENT MOOD',
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    ValueListenableBuilder<String>(
                                      valueListenable: _moodService.currentMood,
                                      builder: (context, mood, _) {
                                        return Text(
                                          mood.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
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
                                    color: Theme.of(context).primaryColor.withValues(
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

                        // Suggested Artists Section
                        _buildSectionHeader(
                          context,
                          'Artists You Might Like',
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DiscoverArtistsScreen(
                                  mood: _moodService.currentMood.value,
                                  initialArtists: _suggestedArtists,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: _isArtistsLoading
                              ? ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 5,
                                  itemBuilder: (context, index) => Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _suggestedArtists.length,
                                  itemBuilder: (context, index) {
                                    final artist = _suggestedArtists[index];
                                    return _buildArtistItem(context, artist);
                                  },
                                ),
                        ),
                        const SizedBox(height: 32),

                        // Recommended Section
                        _buildSectionHeader(
                          context,
                          'Recommended for you',
                          onSeeAll: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RecommendationsScreen(
                                  mood: _moodService.currentMood.value,
                                ),
                              ),
                            );
                          },
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
      case 'angry':
        return ['Metal', 'Hard Rock', 'Aggressive'];
      case 'natural':
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

  String _getArtistQueryForMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return 'Uplifting Pop Artists';
      case 'sad':
        return 'Soulful Indie Artists';
      case 'energetic':
        return 'Electronic Dance Artists';
      case 'calm':
        return 'Ambient Piano Artists';
      case 'focused':
        return 'Lo-Fi Chill Artists';
      case 'relaxing':
        return 'Acoustic Folk Artists';
      case 'inspired':
        return 'Cinematic Instrumental Artists';
      case 'angry':
        return 'Alternative Rock Bands';
      default:
        return 'Top Global Artists';
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color ??
                AppTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildArtistItem(BuildContext context, YouTubeArtistMetadata artist) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                artist_details.ArtistDetailsScreen(artist: artist),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CachedImage(
                imageUrl: artist.artworkUrl,
                isCircle: true,
                errorWidget: const Icon(Icons.person, color: Colors.white24),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
            SizedBox(
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
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                          AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill,
              color: Theme.of(context).primaryColor,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}
