import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/youtube_music_service.dart';
import '../../services/player_service.dart';

class ArtistDetailsScreen extends StatefulWidget {
  final YouTubeArtistMetadata artist;

  const ArtistDetailsScreen({super.key, required this.artist});

  @override
  State<ArtistDetailsScreen> createState() => _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends State<ArtistDetailsScreen> {
  final PlayerService _playerService = PlayerService();
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  YouTubeArtistMetadata? _fullArtist;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArtistDetails();
  }

  Future<void> _loadArtistDetails() async {
    // If we already have full details (description and songs), don't fetch again
    if (widget.artist.description != null && widget.artist.topSongs != null) {
      _fullArtist = widget.artist;
      return;
    }

    setState(() => _isLoading = true);
    try {
      final details = await _ytmService.getArtistDetails(
        widget.artist.browseId,
      );
      if (mounted && details != null) {
        setState(() {
          _fullArtist = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _fullArtist == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // Fallback to widget artist for title/image while loading if needed
    final artist = _fullArtist ?? widget.artist;
    final topSongs = artist.topSongs ?? [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.backgroundDeep,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (artist.artworkUrl != null)
                    Image.network(artist.artworkUrl!, fit: BoxFit.cover)
                  else
                    Container(color: Colors.white10),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.backgroundDeep],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (artist.description != null &&
                      artist.description!.isNotEmpty) ...[
                    Text(
                      artist.description!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Songs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (topSongs.isEmpty && _isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final track = topSongs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Colors.white10,
                      child: track.artworkUrl != null
                          ? Image.network(track.artworkUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.music_note, color: Colors.white24),
                    ),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    track.artist,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    final queue = topSongs.map((t) {
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
                );
              }, childCount: topSongs.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
