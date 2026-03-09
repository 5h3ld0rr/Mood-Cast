import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/youtube_music_service.dart';
import '../../services/player_service.dart';
import '../../services/search_history_service.dart';
import 'artist_details.dart';
import 'category_details.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/song_options.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  final PlayerService _playerService = PlayerService();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();

  List<YouTubeMusicMetadata> _searchResults = [];
  List<YouTubeArtistMetadata> _artistResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Pop',
      'image': 'assets/images/cat_pop.png',
      'color': const Color(0xFFE91E63),
    },
    {
      'name': 'Chill',
      'image': 'assets/images/cat_chill.png',
      'color': const Color(0xFF2196F3),
    },
    {
      'name': 'Rock',
      'image': 'assets/images/cat_rock.png',
      'color': const Color(0xFFFF5722),
    },
    {
      'name': 'Electronic',
      'image': 'assets/images/cat_electronic.png',
      'color': const Color(0xFF9C27B0),
    },
    {
      'name': 'Indie',
      'image': 'assets/images/cat_indie.png',
      'color': const Color(0xFF4CAF50),
    },
    {
      'name': 'Jazz',
      'image': 'assets/images/cat_chill.png',
      'color': const Color(0xFF795548),
    },
    {
      'name': 'Hip-Hop',
      'image': 'assets/images/cat_electronic.png',
      'color': const Color(0xFFFF9800),
    },
    {
      'name': 'Classical',
      'image': 'assets/images/cat_indie.png',
      'color': const Color(0xFF607D8B),
    },
    {
      'name': 'R&B',
      'image': 'assets/images/cat_pop.png',
      'color': const Color(0xFFAD1457),
    },
    {
      'name': 'K-Pop',
      'image': 'assets/images/cat_chill.png',
      'color': const Color(0xFF00BCD4),
    },
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _artistResults = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _performSearch(
    String query, {
    bool saveToHistory = false,
  }) async {
    setState(() => _isLoading = true);

    try {
      // Fetch both tracks and artist details concurrently
      final tracksFuture = _ytmService.searchTracks(query);
      final artistsFuture = _ytmService.searchArtists(
        query,
      ); // Changed to searchArtists

      final results = await tracksFuture;
      final artists = await artistsFuture; // Changed to artists

      if (mounted) {
        // filter artists based on matching similar to how we filter songs
        final matchedArtists = artists
            .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

        setState(() {
          _searchResults = results;
          // Only take the first matched artist as a "Top Result"
          _artistResults = matchedArtists.take(1).toList();
          _isLoading = false;
          // Save the successful query to history only if requested (e.g., pressed Enter)
          if (saveToHistory) {
            _searchHistoryService.addSearch(query);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isFocused ? '' : 'Search',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  onSubmitted: (query) {
                    if (query.isNotEmpty) {
                      _performSearch(query, saveToHistory: true);
                    }
                  },
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: InputDecoration(
                    prefixIcon: _isFocused
                        ? IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black54,
                            ),
                            onPressed: () {
                              _focusNode.unfocus();
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : const Icon(
                            Icons.search,
                            color: Colors.black54,
                            size: 24,
                          ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black54,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    hintText: 'What do you want to listen to?',
                    hintStyle: const TextStyle(
                      color: Colors.black45,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── Body Content ──
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 10,
                      itemBuilder: (context, index) => const TrackSkeleton(),
                    )
                  : _searchController.text.isEmpty
                  ? (_isFocused ? _buildInitialContent() : _buildBrowseAll())
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Browse All (default view) ──
  Widget _buildBrowseAll() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(
            child: const Text(
              'Browse all',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCategoryCard(_categories[index]),
              childCount: _categories.length,
            ),
          ),
        ),
      ],
    );
  }

  // Show recent search history when the query is empty.
  Widget _buildInitialContent() {
    return FutureBuilder<List<String>>(
      future: _searchHistoryService.getHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          // Fallback to browse all if no history.
          return _buildBrowseAll();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Recent searches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final term = history[index];
                  return ListTile(
                    leading: const Icon(Icons.history, color: Colors.white70),
                    title: Text(
                      term,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () async {
                        await _searchHistoryService.deleteTerm(term);
                        setState(() {}); // Refresh the view
                      },
                    ),
                    onTap: () {
                      _searchController.text = term;
                      _performSearch(term, saveToHistory: true);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailsScreen(
              categoryName: cat['name'],
              categoryColor: cat['color'],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (cat['color'] as Color).withValues(alpha: 0.9),
                    (cat['color'] as Color).withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Artist / genre image (bottom right, tilted)
            Positioned(
              right: -12,
              bottom: -12,
              child: Transform.rotate(
                angle: 0.3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    cat['image'] as String,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                cat['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _artistResults.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Colors.white24,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final int itemCount = _searchResults.length + _artistResults.length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < _artistResults.length) {
          return _buildArtistCard(_artistResults[index]);
        }

        final itemIndex = index - _artistResults.length;
        final track = _searchResults[itemIndex];
        final albumArt = track.artworkUrl;
        final artistName = track.artist;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            onTap: () {
              final queue = _searchResults.map((t) {
                return SongInfo(
                  title: t.title,
                  artist: t.artist,
                  coverUrl: t.artworkUrl,
                  videoId: t.videoId,
                  previewUrl: null,
                );
              }).toList();
              _playerService.playQueue(queue, initialIndex: itemIndex);
            },
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 52,
                height: 52,
                color: Colors.white10,
                child: albumArt != null
                    ? Image.network(
                        albumArt,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.music_note, color: Colors.white24),
                      )
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
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            trailing: IconButton(
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
          ),
        );
      },
    );
  }

  Widget _buildArtistCard(YouTubeArtistMetadata artist) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistDetailsScreen(artist: artist),
            ),
          );
        },
        contentPadding: EdgeInsets.zero,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(52), // Circular for artists
          child: Container(
            width: 52,
            height: 52,
            color: Colors.white10,
            child: artist.artworkUrl != null
                ? Image.network(
                    artist.artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.white24),
                  )
                : const Icon(Icons.person, color: Colors.white24),
          ),
        ),
        title: Text(
          artist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: const Text(
          'Artist',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }
}
