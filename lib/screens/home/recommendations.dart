import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/player_service.dart';
import '../../services/youtube_music_service.dart';
import '../../widgets/skeleton.dart';

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
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        title: Text(
          '$displayMood Vibes',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 8,
        itemBuilder: (context, index) => const TrackSkeleton(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRecommendations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tracks.isEmpty) {
      return const Center(
        child: Text(
          'No songs found for this vibe.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildSongTile(context, track),
        );
      },
    );
  }

  Widget _buildSongTile(BuildContext context, YouTubeMusicMetadata track) {
    final albumArt = track.artworkUrl;
    final artistName = track.artist;

    return GestureDetector(
      onTap: () {
        PlayerService().play(
          SongInfo(
            title: track.title,
            artist: artistName,
            coverUrl: albumArt,
            videoId: track.videoId,
            previewUrl: null,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                image: albumArt != null
                    ? DecorationImage(
                        image: NetworkImage(albumArt),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: albumArt == null
                  ? const Icon(Icons.music_note, color: Colors.white54)
                  : null,
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
            const Icon(
              Icons.play_circle_filled_rounded,
              color: AppTheme.primary,
              size: 36,
            ),
          ],
        ),
      ),
    );
  }
}
