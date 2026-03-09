import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../utils/ui_utils.dart';
import '../../services/database_service.dart';
import '../../services/player_service.dart';
import '../../services/download_service.dart';
import '../../widgets/song_options.dart';
import '../../widgets/cached_image.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final String playlistName;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? playlistId;
  final bool isLikedSongs;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlistName,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.playlistId,
    this.isLikedSongs = false,
  });

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  final DatabaseService _db = DatabaseService();
  final PlayerService _player = PlayerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Recently Added'; // recently_added, title, artist

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSongsSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSongsBottomSheet(
        playlistId: widget.playlistId,
        onSongAdded: (song) {
          // Song is already added via DatabaseService in the bottom sheet
        },
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort by',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Recently Added'),
              _buildSortOption('Title'),
              _buildSortOption('Artist'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title) {
    final bool isSelected = _sortBy == title;
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = title;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLikedSongs) {
      return _buildSpotifyLikedSongsLayout();
    }

    final double headerHeight = 300;
    final Color dominantColor = widget.color;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Spotify-style Header
          SliverAppBar(
            expandedHeight: headerHeight,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: const Color(0xFF080C14),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              title: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double top = constraints.biggest.height;
                  // Show title only when collapsed
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: top < 120 ? 1.0 : 0.0,
                    child: Text(
                      widget.playlistName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Immersive Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          dominantColor.withValues(alpha: 0.8),
                          dominantColor.withValues(alpha: 0.2),
                          const Color(0xFF080C14),
                        ],
                      ),
                    ),
                  ),
                  // Header Content
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Playlist Art
                        Hero(
                          tag: 'playlist_art_${widget.playlistName}',
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: dominantColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 80,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.playlistName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'MoodCast',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '•',
                              style: TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Bar (Play, Like, Shuffle)
          StreamBuilder<List<SongInfo>>(
            stream: _db.getPlaylistSongs(widget.playlistId!),
            builder: (context, snapshot) {
              final songs = snapshot.data ?? [];
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          UIUtils.showSnackBar(
                            context,
                            'Playlist added to favorites',
                          );
                        },
                        icon: const Icon(
                          Icons.favorite_border,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          UIUtils.showSnackBar(
                            context,
                            'Downloading for offline use...',
                          );
                        },
                        icon: const Icon(
                          Icons.download_for_offline_outlined,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.person_add_alt_1_outlined,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.more_horiz,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      // Large Play Button with feedback
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (songs.isNotEmpty) {
                              _player.playQueue(songs, initialIndex: 0);
                            } else {
                              UIUtils.showSnackBar(
                                context,
                                'Playlist is empty',
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Ink(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Songs List
          StreamBuilder<List<SongInfo>>(
            stream: _db.getPlaylistSongs(widget.playlistId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: Colors.white10,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your playlist is empty',
                        style: TextStyle(color: Colors.white38, fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: _showAddSongsSearch,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Add Songs'),
                      ),
                    ],
                  ),
                );
              }

              final songs = snapshot.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == songs.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: OutlinedButton(
                        onPressed: _showAddSongsSearch,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add Songs'),
                      ),
                    );
                  }
                  final song = songs[index];
                  return _buildSongItem(song, index, songs);
                }, childCount: songs.length + 1),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSpotifyLikedSongsLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: StreamBuilder<List<SongInfo>>(
        stream: _db.getLikedSongs(),
        builder: (context, snapshot) {
          final songs = snapshot.data ?? [];
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header with Search and Sort
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFF3F51B5).withValues(alpha: 0.8),
                expandedHeight: 200,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3F51B5), Color(0xFF121212)],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar Row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value.toLowerCase();
                                      });
                                    },
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      hintText: 'Find in Liked Songs',
                                      hintStyle: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                color: Colors.white70,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchQuery = '';
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: _showSortOptions,
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _sortBy == 'Recently Added'
                                        ? 'Sort'
                                        : _sortBy,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Liked Songs',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${songs.length} song${songs.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Action Buttons Row (Download, Shuffle, Play)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Download Icon
                      ValueListenableBuilder<List<SongInfo>>(
                        valueListenable: DownloadService().downloadedSongs,
                        builder: (context, downloadedSongs, _) {
                          // Check if all songs in this snapshot are downloaded
                          // For simplicity, we just show if it's "downloading" or "downloaded"
                          return IconButton(
                            onPressed: () {
                              if (songs.isEmpty) return;
                              for (var s in songs) {
                                DownloadService().downloadSong(s);
                              }
                              UIUtils.showSnackBar(
                                context,
                                'Starting downloads for ${songs.length} songs...',
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white38,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_downward,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Spacer(),
                      // Shuffle Icon
                      ValueListenableBuilder<bool>(
                        valueListenable: _player.isShuffled,
                        builder: (context, isShuffled, _) {
                          return IconButton(
                            onPressed: () {
                              _player.toggleShuffle();
                              UIUtils.showSnackBar(
                                context,
                                isShuffled
                                    ? 'Shuffle turned off'
                                    : 'Shuffle turned on',
                              );
                            },
                            icon: Icon(
                              Icons.shuffle,
                              color: isShuffled
                                  ? AppTheme.primary
                                  : Colors.white54,
                              size: 28,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Spotify Green Play Button
                      GestureDetector(
                        onTap: () {
                          if (songs.isNotEmpty) {
                            _player.playQueue(songs, initialIndex: 0);
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DB954), // Spotify Green
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // "Add songs" Button
              SliverToBoxAdapter(
                child: InkWell(
                  onTap: _showAddSongsSearch,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Add songs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Songs List
              snapshot.hasData && snapshot.data!.isNotEmpty
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          List<SongInfo> filteredSongs = songs
                              .where(
                                (s) =>
                                    s.title.toLowerCase().contains(
                                      _searchQuery,
                                    ) ||
                                    s.artist.toLowerCase().contains(
                                      _searchQuery,
                                    ),
                              )
                              .toList();

                          // Apply Sorting
                          if (_sortBy == 'Title') {
                            filteredSongs.sort(
                              (a, b) => a.title.toLowerCase().compareTo(
                                b.title.toLowerCase(),
                              ),
                            );
                          } else if (_sortBy == 'Artist') {
                            filteredSongs.sort(
                              (a, b) => a.artist.toLowerCase().compareTo(
                                b.artist.toLowerCase(),
                              ),
                            );
                          }

                          if (index >= filteredSongs.length) return null;
                          final song = filteredSongs[index];
                          return _buildSongItem(song, index, filteredSongs);
                        },
                        childCount: songs
                            .where(
                              (s) =>
                                  s.title.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  s.artist.toLowerCase().contains(_searchQuery),
                            )
                            .length,
                      ),
                    )
                  : const SliverFillRemaining(child: SizedBox.shrink()),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSongItem(SongInfo song, int index, List<SongInfo> queue) {
    return InkWell(
      onTap: () {
        _player.playQueue(queue, initialIndex: index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Track Art
            CachedImage(
              imageUrl: song.coverUrl,
              width: 50,
              height: 50,
              borderRadius: BorderRadius.circular(4),
              errorWidget: const Center(
                child: Icon(Icons.music_note, color: Colors.white38, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            // Title & Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'LYRICS',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Download Status Indicator
                  if (song.videoId != null)
                    ValueListenableBuilder<Map<String, double>>(
                      valueListenable: DownloadService().downloadProgress,
                      builder: (context, progressMap, _) {
                        final progress = progressMap[song.videoId];
                        if (progress != null) {
                          return Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }
                        return ValueListenableBuilder<List<SongInfo>>(
                          valueListenable: DownloadService().downloadedSongs,
                          builder: (context, downloadedSongs, _) {
                            final isDownloaded = downloadedSongs.any(
                              (s) => s.videoId == song.videoId,
                            );
                            if (isDownloaded) {
                              return const Row(
                                children: [
                                  Icon(
                                    Icons.download_done,
                                    color: AppTheme.primary,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Downloaded',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => SongOptionsBottomSheet(song: song),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSongsBottomSheet extends StatefulWidget {
  final String? playlistId;
  final Function(SongInfo) onSongAdded;

  const _AddSongsBottomSheet({this.playlistId, required this.onSongAdded});

  @override
  State<_AddSongsBottomSheet> createState() => _AddSongsBottomSheetState();
}

class _AddSongsBottomSheetState extends State<_AddSongsBottomSheet> {
  final DatabaseService _db = DatabaseService();
  final List<SongInfo> _allSongs = [
    SongInfo(
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      coverUrl:
          'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=100',
    ),
    SongInfo(
      title: 'Starboy',
      artist: 'The Weeknd',
      coverUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=100',
    ),
    SongInfo(
      title: 'Save Your Tears',
      artist: 'The Weeknd',
      coverUrl:
          'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=100',
    ),
    SongInfo(title: 'Nightcall', artist: 'Kavinsky'),
    SongInfo(title: 'Midnight City', artist: 'M83'),
    SongInfo(title: 'Ocean Drive', artist: 'Duke Dumont'),
    SongInfo(title: 'Resonance', artist: 'Home'),
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredSongs = _allSongs
        .where(
          (song) =>
              song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              song.artist.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                hintText: 'Search songs or artists',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSongs.length,
              itemBuilder: (context, index) {
                final song = filteredSongs[index];
                return ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.white38),
                  title: Text(
                    song.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primary,
                    ),
                    onPressed: () {
                      if (widget.playlistId != null) {
                        _db.addSongToPlaylist(widget.playlistId!, song);
                      } else {
                        _db.toggleLikedSong(song);
                      }
                      widget.onSongAdded(song);
                      UIUtils.showSnackBar(
                        context,
                        '${song.title} added',
                        duration: const Duration(seconds: 1),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
