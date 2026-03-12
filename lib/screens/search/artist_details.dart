import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/youtube_music_service.dart';
import '../../services/player_service.dart';
import '../../services/database_service.dart';
import '../../widgets/cached_image.dart';

class ArtistDetailsScreen extends StatefulWidget {
  final YouTubeArtistMetadata artist;

  const ArtistDetailsScreen({super.key, required this.artist});

  @override
  State<ArtistDetailsScreen> createState() => _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends State<ArtistDetailsScreen> {
  final PlayerService _playerService = PlayerService();
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  final DatabaseService _db = DatabaseService();
  YouTubeArtistMetadata? _fullArtist;
  bool _isLoading = false;
  bool _isFollowed = false;

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
      final isFollowed = await _db.isArtistFollowed(widget.artist.browseId);
      final details = await _ytmService.getArtistDetails(
        widget.artist.browseId,
      );
      if (mounted) {
        setState(() {
          _isFollowed = isFollowed;
          if (details != null) _fullArtist = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final artist = _fullArtist ?? widget.artist;
    await _db.toggleFollowArtist(artist);
    if (mounted) {
      setState(() {
        _isFollowed = !_isFollowed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _fullArtist == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    // Fallback to widget artist for title/image while loading if needed
    final artist = _fullArtist ?? widget.artist;
    final topSongs = artist.topSongs ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).canvasColor,
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
                  CachedImage(imageUrl: artist.artworkUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).canvasColor,
                        ],
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
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowed
                              ? Colors.transparent
                              : Theme.of(context).primaryColor,
                          foregroundColor: _isFollowed
                              ? Colors.white
                              : Colors.black,
                          side: _isFollowed
                              ? const BorderSide(color: Colors.white30)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                        ),
                        child: Text(_isFollowed ? 'Following' : 'Follow'),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Check out ${artist.name} on MoodCast! https://music.youtube.com/channel/${artist.browseId}',
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                  leading: CachedImage(
                    imageUrl: track.artworkUrl,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(6),
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
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
