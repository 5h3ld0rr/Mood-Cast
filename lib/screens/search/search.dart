import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/youtube_music_service.dart';
import '../../services/player_service.dart';
import 'category_details.dart';
import '../../widgets/skeleton.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  final PlayerService _playerService = PlayerService();

  List<YouTubeMusicMetadata> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _isFocused = false;

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
  void dispose() {
    _searchController.dispose();
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
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    try {
      final results = await _ytmService.searchTracks(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
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
                  if (!_isFocused)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Focus(
                onFocusChange: (focused) =>
                    setState(() => _isFocused = focused),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
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
                  ? _buildBrowseAll()
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
                    (cat['color'] as Color).withOpacity(0.9),
                    (cat['color'] as Color).withOpacity(0.5),
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

  // ── Search Results ──
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isLoading) {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        final albumArt = track.artworkUrl;
        final artistName = track.artist;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            onTap: () {
              _playerService.play(
                SongInfo(
                  title: track.title,
                  artist: artistName,
                  coverUrl: albumArt,
                  videoId: track.videoId,
                  previewUrl: null,
                ),
              );
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
            trailing: const Icon(Icons.more_vert, color: Colors.white54),
          ),
        );
      },
    );
  }
}
