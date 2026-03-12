import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/youtube_music_service.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/skeleton.dart';
import '../search/artist_details.dart';

class DiscoverArtistsScreen extends StatefulWidget {
  final String mood;
  final List<YouTubeArtistMetadata> initialArtists;

  const DiscoverArtistsScreen({
    super.key,
    required this.mood,
    required this.initialArtists,
  });

  @override
  State<DiscoverArtistsScreen> createState() => _DiscoverArtistsScreenState();
}

class _DiscoverArtistsScreenState extends State<DiscoverArtistsScreen> {
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  List<YouTubeArtistMetadata> _artists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _artists = widget.initialArtists;
    if (_artists.length < 20) {
      _fetchMoreArtists();
    }
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

  Future<void> _fetchMoreArtists() async {
    setState(() => _isLoading = true);
    try {
      final query = _getArtistQueryForMood(widget.mood);
      final results = await _ytmService.searchArtists(query);
      if (mounted) {
        setState(() {
          // Merge lists and remove duplicates based on browseId
          final existingIds = _artists.map((a) => a.browseId).toSet();
          final newArtists = results.where((a) => !existingIds.contains(a.browseId));
          _artists.addAll(newArtists);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Suggested Artists',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _artists.isEmpty && _isLoading
          ? _buildLoadingGrid()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.85,
              ),
              itemCount: _artists.length,
              itemBuilder: (context, index) {
                final artist = _artists[index];
                return _buildArtistCard(artist);
              },
            ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.85,
      ),
      itemCount: 10,
      itemBuilder: (context, index) => const ArtistSkeleton(),
    );
  }

  Widget _buildArtistCard(YouTubeArtistMetadata artist) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistDetailsScreen(artist: artist),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'artist_art_${artist.browseId}',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CachedImage(
                  imageUrl: artist.artworkUrl,
                  isCircle: true,
                  errorWidget: const Icon(Icons.person, color: Colors.white24, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Artist',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtistSkeleton extends StatelessWidget {
  const ArtistSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Skeleton(width: 120, height: 120, borderRadius: 60),
          const SizedBox(height: 16),
          const Skeleton(width: 80, height: 14),
          const SizedBox(height: 8),
          const Skeleton(width: 40, height: 10),
        ],
      ),
    );
  }
}
