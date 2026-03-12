import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/youtube_music_service.dart';
import '../../services/player_service.dart';
import '../../services/search_history_service.dart';
import 'artist_details.dart';
import 'category_details.dart';
import '../library/playlist_details.dart';
import '../../services/database_service.dart';
import '../home/discover_artists.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/song_options.dart';
import '../../widgets/cached_image.dart';
import '../../services/connectivity_service.dart';

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
  final DatabaseService _dbService = DatabaseService();

  List<YouTubeMusicMetadata> _searchResults = [];
  List<YouTubeArtistMetadata> _artistResults = [];
  List<Map<String, dynamic>> _playlistResults = [];
  List<YouTubeArtistMetadata> _suggestedArtists = [];
  bool _isLoading = false;
  bool _isArtistsLoading = false;
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
    ConnectivityService().isOnline.addListener(_onConnectivityChanged);
    _fetchSuggestedArtists();
  }

  Future<void> _fetchSuggestedArtists() async {
    if (mounted) setState(() => _isArtistsLoading = true);
    try {
      final artists = await _ytmService.searchArtists(
        'Top 2024 Popular Artists',
      );
      if (mounted) {
        setState(() {
          _suggestedArtists = artists.take(10).toList();
          _isArtistsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isArtistsLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    ConnectivityService().isOnline.removeListener(_onConnectivityChanged);
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

  void _onConnectivityChanged() {
    if (ConnectivityService().isOnline.value &&
        _searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
    if (mounted) setState(() {});
  }

  Future<void> _performSearch(
    String query, {
    bool saveToHistory = false,
  }) async {
    setState(() => _isLoading = true);

    try {
      // Fetch both tracks and artist details concurrently
      final tracksFuture = _ytmService.searchTracks(query);
      final artistsFuture = _ytmService.searchArtists(query);
      final playlistsFuture = _dbService.searchPublicPlaylists(query);

      final results = await tracksFuture;
      final artists = await artistsFuture;
      final playlists = await playlistsFuture;

      if (mounted) {
        // filter artists based on matching similar to how we filter songs
        final matchedArtists = artists
            .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

        setState(() {
          _searchResults = results;
          // Only take the first matched artist as a "Top Result"
          _artistResults = matchedArtists.take(1).toList();
          _playlistResults = playlists; // all matched playlists
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
      backgroundColor: Colors.transparent,
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
              child: ValueListenableBuilder<bool>(
                valueListenable: ConnectivityService().isOnline,
                builder: (context, isOnline, _) {
                  if (!isOnline &&
                      _searchResults.isEmpty &&
                      _artistResults.isEmpty &&
                      _playlistResults.isEmpty) {
                    return _buildOfflineState();
                  }

                  return _isLoading
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: 10,
                          itemBuilder: (context, index) =>
                              const TrackSkeleton(),
                        )
                      : _searchController.text.isEmpty
                      ? (_isFocused
                            ? _buildInitialContent()
                            : _buildBrowseAll())
                      : _buildSearchResults();
                },
              ),
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
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildSuggestedArtistsSection(),
              const SizedBox(height: 100), // Padding for bottom
            ],
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
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
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
                    errorBuilder: (_, _, _) => const SizedBox(),
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
    if (_searchResults.isEmpty &&
        _artistResults.isEmpty &&
        _playlistResults.isEmpty &&
        !_isLoading) {
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

    final int itemCount =
        _searchResults.length + _artistResults.length + _playlistResults.length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < _artistResults.length) {
          return _buildArtistCard(_artistResults[index]);
        }

        final playlistIndex = index - _artistResults.length;
        if (playlistIndex < _playlistResults.length) {
          return _buildPlaylistCard(_playlistResults[playlistIndex]);
        }

        final itemIndex = playlistIndex - _playlistResults.length;
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
            leading: CachedImage(
              imageUrl: albumArt,
              width: 52,
              height: 52,
              borderRadius: BorderRadius.circular(6),
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
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppTheme.textMuted,
                fontSize: 12,
              ),
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
        leading: CachedImage(
          imageUrl: artist.artworkUrl,
          width: 52,
          height: 52,
          isCircle: true,
          errorWidget: const Icon(Icons.person, color: Colors.white24),
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
        subtitle: Text(
          'Artist',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailsScreen(
                playlistId: playlist['id'],
                playlistName: playlist['name'] ?? 'Playlist',
                isPublic: playlist['isPublic'] ?? false,
                subtitle:
                    '${(playlist['isPublic'] == true) ? 'Public Playlist' : 'Playlist'} • ${playlist['songCount'] ?? 0} songs',
                icon: Icons.queue_music,
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        },
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: playlist['coverUrl'] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    playlist['coverUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.queue_music,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                )
              : Icon(Icons.queue_music, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          playlist['name'] ?? 'Playlist',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '${(playlist['isPublic'] == true) ? 'Public Playlist' : 'Playlist'} • ${playlist['songCount'] ?? 0} songs',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }

  Widget _buildSuggestedArtistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Suggested Artists',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiscoverArtistsScreen(
                        mood:
                            'Natural', // Search suggestions are generally natural/popular
                        initialArtists: _suggestedArtists,
                      ),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: _isArtistsLoading
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (context, index) => Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _suggestedArtists.length,
                  itemBuilder: (context, index) {
                    final artist = _suggestedArtists[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ArtistDetailsScreen(artist: artist),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            CachedImage(
                              imageUrl: artist.artworkUrl,
                              width: 80,
                              height: 80,
                              isCircle: true,
                              errorWidget: const Icon(
                                Icons.person,
                                color: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              artist.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: Colors.white.withValues(alpha: 0.1),
              size: 100,
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'re Offline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check your connection to search for music.',
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppTheme.textMuted,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (ConnectivityService().isOnline.value &&
                    _searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
