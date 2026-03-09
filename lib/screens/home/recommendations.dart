import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/player_service.dart';
import '../../services/youtube_music_service.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/song_options.dart';

class RecommendationsScreen extends StatefulWidget {
  final String? mood;
  const RecommendationsScreen({super.key, this.mood});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  List<YouTubeMusicMetadata> _tracks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mood = widget.mood ?? 'Happy'; // Fallback
      final tracks = await _ytmService.getRecommendationsByMood(mood);

      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load recommendations. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayMood = widget.mood ?? 'Personalized';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        children: [
          // Background Blobs for premium feel
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                AppBar(
                  title: Text(
                    '$displayMood Vibes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  centerTitle: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    if (!_isLoading)
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        onPressed: _fetchRecommendations,
                      ),
                  ],
                ),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: 8,
        itemBuilder: (context, index) => const TrackSkeleton(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchRecommendations,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tracks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text(
              'No songs found for this vibe.',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildSongTile(context, track, index),
        );
      },
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    YouTubeMusicMetadata track,
    int index,
  ) {
    final albumArt = track.artworkUrl;
    final artistName = track.artist;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          final queue = _tracks.map((t) {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: albumArt != null
                      ? Image.network(
                          albumArt,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.music_note,
                                color: Colors.white24,
                              ),
                        )
                      : const Icon(Icons.music_note, color: Colors.white24),
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
                    const SizedBox(height: 4),
                    Text(
                      artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SongOptionsBottomSheet(
                      song: SongInfo(
                        title: track.title,
                        artist: track.artist,
                        coverUrl: track.artworkUrl,
                        videoId: track.videoId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
