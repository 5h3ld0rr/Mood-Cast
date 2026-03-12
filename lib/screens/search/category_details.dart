import 'package:flutter/material.dart';
import '../../services/youtube_music_service.dart';
import '../../services/player_service.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/cached_image.dart';

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
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.categoryColor.withValues(alpha: 0.2),
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
                          widget.categoryColor.withValues(alpha: 0.4),
                          Theme.of(context).canvasColor,
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
                        ..._tracks.asMap().entries.map(
                          (e) => _buildSongItem(e.value, e.key),
                        ),
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

  Widget _buildSongItem(YouTubeMusicMetadata track, int index) {
    return GestureDetector(
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
        _playerService.playQueue(queue, initialIndex: index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CachedImage(
              imageUrl: track.artworkUrl,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(8),
              errorWidget: Icon(Icons.music_note, color: widget.categoryColor),
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
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill,
              color: Theme.of(context).primaryColor,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}
