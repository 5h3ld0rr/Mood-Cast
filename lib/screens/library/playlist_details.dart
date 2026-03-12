import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../utils/ui_utils.dart';
import '../../services/database_service.dart';
import '../../services/player_service.dart';
import '../../services/download_service.dart';
import '../../widgets/song_options.dart';
import '../../widgets/playlist_options.dart';
import '../../widgets/cached_image.dart';
import '../../services/youtube_music_service.dart';
import 'dart:async';

class PlaylistDetailsScreen extends StatefulWidget {
  final String playlistName;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? playlistId;
  final bool isLikedSongs;
  final bool isPublic;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlistName,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.playlistId,
    this.isLikedSongs = false,
    this.isPublic = false,
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

  Future<void> _showPlaylistOptions() async {
    if (widget.playlistId == null && !widget.isLikedSongs) return;

    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaylistOptionsBottomSheet(
        playlistId: widget.playlistId ?? 'liked_songs',
        playlistName: widget.playlistName,
        isLikedSongs: widget.isLikedSongs,
      ),
    );

    if (result == 'deleted' && mounted) {
      Navigator.pop(context);
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Sort by',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),
              _buildSortOption('Recently Added', Icons.access_time),
              _buildSortOption('Title', Icons.sort_by_alpha),
              _buildSortOption('Artist', Icons.person_outline),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, IconData icon) {
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
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.white54,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.white24,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
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
      backgroundColor: Theme.of(context).canvasColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Spotify-style Header
          SliverAppBar(
            expandedHeight: headerHeight,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Theme.of(context).canvasColor,
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
                onPressed: _showPlaylistOptions,
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
                          Theme.of(context).canvasColor,
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
                            'Downloading for offline use...',
                          );
                        },
                        icon: const Icon(
                          Icons.download_for_offline_outlined,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
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
                                  ? Theme.of(context).primaryColor
                                  : Colors.white54,
                              size: 28,
                            ),
                          );
                        },
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
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
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
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
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
              return SliverMainAxisGroup(
                slivers: [
                  // Search and Sort
                  _buildSearchAndSortUI(
                    hintText: 'Find in ${widget.playlistName}',
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: _showAddSongsSearch,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add Songs'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  _buildFilteredSongList(songs),
                ],
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSpotifyLikedSongsLayout() {
    final double headerHeight = 300;
    final Color dominantColor = const Color(0xFF3F51B5);

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: StreamBuilder<List<SongInfo>>(
        stream: _db.getLikedSongs(),
        builder: (context, snapshot) {
          final songs = snapshot.data ?? [];
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Spotify-style Header
              SliverAppBar(
                expandedHeight: headerHeight,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: Theme.of(context).canvasColor,
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
                    onPressed: _showPlaylistOptions,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  title: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final double top = constraints.biggest.height;
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
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              dominantColor.withValues(alpha: 0.8),
                              dominantColor.withValues(alpha: 0.2),
                              Theme.of(context).canvasColor,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
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
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'MoodCast',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Your Liked Songs',
                                  style: TextStyle(
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
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
                        icon: const Icon(
                          Icons.download_for_offline_outlined,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
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
                                  ? Theme.of(context).primaryColor
                                  : Colors.white54,
                              size: 28,
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (songs.isNotEmpty) {
                              _player.playQueue(songs, initialIndex: 0);
                            } else {
                              UIUtils.showSnackBar(context, 'No liked songs');
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Ink(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
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
              ),

              // Search and Sort
              _buildSearchAndSortUI(hintText: 'Find in Liked Songs'),

              // Add Songs Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _showAddSongsSearch,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Songs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Filtered Songs List
              _buildFilteredSongList(songs),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndSortUI({required String hintText}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white38,
                      size: 20,
                    ),
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white38,
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _sortBy == 'Recently Added' ? 'Sort' : _sortBy,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredSongList(List<SongInfo> songs) {
    List<SongInfo> filteredSongs = songs
        .where(
          (s) =>
              s.title.toLowerCase().contains(_searchQuery) ||
              s.artist.toLowerCase().contains(_searchQuery),
        )
        .toList();

    // Apply Sorting
    if (_sortBy == 'Title') {
      filteredSongs.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else if (_sortBy == 'Artist') {
      filteredSongs.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
    }

    if (filteredSongs.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return const SliverFillRemaining(
          child: Center(
            child: Text(
              'No results found',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        );
      }
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = filteredSongs[index];
        return _buildSongItem(song, index, filteredSongs);
      }, childCount: filteredSongs.length),
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
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
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
                              return Row(
                                children: [
                                  Icon(
                                    Icons.download_done,
                                    color: Theme.of(context).primaryColor,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Downloaded',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
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
                  builder: (context) => SongOptionsBottomSheet(
                    song: song,
                    playlistId: widget.playlistId,
                    isLikedSongs: widget.isLikedSongs,
                  ),
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
  final List<YouTubeMusicMetadata> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  final String _searchQuery = '';

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _isSearching = true;
      });

      final results = await YouTubeMusicService().searchTracks(query);

      if (mounted) {
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(results);
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isSearching
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : _searchResults.isEmpty && _searchQuery.isNotEmpty
                ? const Center(
                    child: Text(
                      'No songs found',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final metadata = _searchResults[index];
                      final song = SongInfo(
                        title: metadata.title,
                        artist: metadata.artist,
                        coverUrl: metadata.artworkUrl,
                        videoId: metadata.videoId,
                      );
                      return ListTile(
                        leading: CachedImage(
                          imageUrl: song.coverUrl,
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(4),
                          errorWidget: const Icon(
                            Icons.music_note,
                            color: Colors.white24,
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          song.artist,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: Theme.of(context).primaryColor,
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
