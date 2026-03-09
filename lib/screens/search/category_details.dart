import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/youtube_music_service.dart';
import '../../services/player_service.dart';
import '../../widgets/skeleton.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;

  const CategoryDetailsScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  final PlayerService _playerService = PlayerService();
  List<YouTubeMusicMetadata> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategorySongs();
  }

  Future<void> _fetchCategorySongs() async {
    setState(() => _isLoading = true);
    try {
      final results = await _ytmService.searchTracks(
        '${widget.categoryName} music hits',
      );
      if (mounted) {
        setState(() {
          _tracks = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.categoryColor.withOpacity(0.2),
        elevation: 0,
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10,
              itemBuilder: (context, index) => const TrackSkeleton(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.categoryColor.withOpacity(0.4),
                          const Color(0xFF080C14),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Top ${widget.categoryName} Hits',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Featured Songs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._tracks
                            .map((track) => _buildSongItem(track))
                            .toList(),
                        if (_tracks.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text(
                                'No songs found for this category',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSongItem(YouTubeMusicMetadata track) {
    return GestureDetector(
      onTap: () {
        _playerService.play(
          SongInfo(
            title: track.title,
            artist: track.artist,
            coverUrl: track.artworkUrl,
            videoId: track.videoId,
            previewUrl: null,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                image: track.artworkUrl != null
                    ? DecorationImage(
                        image: NetworkImage(track.artworkUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: track.artworkUrl == null
                  ? Icon(Icons.music_note, color: widget.categoryColor)
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
                    track.artist,
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
              Icons.play_circle_fill,
              color: AppTheme.primary,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

