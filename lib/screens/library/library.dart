import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/database_service.dart';
import '../../services/player_service.dart';
import '../../services/youtube_music_service.dart';
import 'playlist_details.dart';
import 'package:mood_cast/screens/search/artist_details.dart';
import '../../utils/ui_utils.dart';
import '../../services/download_service.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/playlist_options.dart';
import '../../widgets/song_options.dart';
import '../../services/connectivity_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String selectedFilter = 'Playlists';
  final List<String> filters = ['Playlists', 'Artists', 'Downloads'];

  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    ConnectivityService().isOnline.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (mounted) setState(() {});
  }

  // Search state within Library
  String _artistSearchQuery = '';
  String _playlistSearchQuery = '';
  String _downloadSearchQuery = '';

  @override
  void dispose() {
    ConnectivityService().isOnline.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onArtistSearchChanged(String query) {
    setState(() {
      _artistSearchQuery = query;
    });
  }

  void _onPlaylistSearchChanged(String query) {
    setState(() {
      _playlistSearchQuery = query;
    });
  }

  void _onDownloadSearchChanged(String query) {
    setState(() {
      _downloadSearchQuery = query;
    });
  }

  void _showCreatePlaylistDialog() {
    String playlistName = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Give your playlist a name',
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
              onChanged: (value) => playlistName = value,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (playlistName.isNotEmpty) {
                      _db.createPlaylist(playlistName);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('CREATE'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showArtistSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ArtistSearchBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  const Text(
                    'Your Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (selectedFilter != 'Artists' &&
                      selectedFilter != 'Playlists' &&
                      selectedFilter != 'Downloads')
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        UIUtils.showSnackBar(
                          context,
                          'Use the Search tab to find everything!',
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                    onPressed: () {
                      if (selectedFilter == 'Artists') {
                        _showArtistSearch();
                      } else {
                        _showCreatePlaylistDialog();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Chips for filtering
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildFilterChip(filter, selectedFilter == filter),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLibraryContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryContent() {
    switch (selectedFilter) {
      case 'Artists':
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                onChanged: _onArtistSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search followed artists',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _artistSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _artistSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<YouTubeArtistMetadata>>(
                stream: _db.getFollowedArtists(),
                builder: (context, snapshot) {
                  final followedArtists = snapshot.data ?? [];

                  // Filter local artists list based on search query
                  final filteredArtists = followedArtists.where((artist) {
                    return artist.name.toLowerCase().contains(
                      _artistSearchQuery.toLowerCase(),
                    );
                  }).toList();

                  if (followedArtists.isEmpty &&
                      snapshot.connectionState != ConnectionState.waiting) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.person_add_outlined,
                                size: 64,
                                color: Colors.white10,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No followed artists yet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Follow your favorite artists to see them here.',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _showArtistSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Add Artists',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Suggested Artists',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<YouTubeArtistMetadata>>(
                          future: YouTubeMusicService().searchArtists(
                            'Top Global Artists',
                          ),
                          builder: (context, artistSnapshot) {
                            if (artistSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final suggestions = artistSnapshot.data ?? [];
                            if (suggestions.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              children: suggestions.take(5).map((artist) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildArtistItem(
                                    artist.name,
                                    'Artist',
                                    artist.artworkUrl ??
                                        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200',
                                    browseId: artist.browseId,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  }

                  if (filteredArtists.isEmpty &&
                      _artistSearchQuery.isNotEmpty) {
                    return const Center(
                      child: Text(
                        'No matching artists found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredArtists.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final artist = filteredArtists[index];
                      return _buildArtistItem(
                        artist.name,
                        'Artist',
                        artist.artworkUrl ??
                            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200',
                        browseId: artist.browseId,
                        isPinned: artist.isPinned,
                        onMoreTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: const BoxDecoration(
                                color: Color(0xFF161B22),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.person,
                                      color: AppTheme.primary,
                                    ),
                                    title: Text(
                                      artist.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Artist Options',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                  const Divider(color: Colors.white10),
                                  ListTile(
                                    leading: Icon(
                                      artist.isPinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined,
                                      color: Colors.white70,
                                    ),
                                    title: Text(
                                      artist.isPinned
                                          ? 'Unpin Artist'
                                          : 'Pin Artist',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    onTap: () async {
                                      await _db.togglePinArtist(
                                        artist.browseId,
                                        artist.isPinned,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        UIUtils.showSnackBar(
                                          context,
                                          artist.isPinned
                                              ? 'Artist unpinned'
                                              : 'Artist pinned',
                                        );
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.person_remove_outlined,
                                      color: Colors.redAccent,
                                    ),
                                    title: const Text(
                                      'Unfollow Artist',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onTap: () async {
                                      await _db.toggleFollowArtist(artist);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        UIUtils.showSnackBar(
                                          context,
                                          'Unfollowed ${artist.name}',
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      case 'Downloads':
        return ValueListenableBuilder<List<SongInfo>>(
          valueListenable: DownloadService().downloadedSongs,
          builder: (context, songs, _) {
            final filteredSongs = songs.where((song) {
              return song.title.toLowerCase().contains(
                    _downloadSearchQuery.toLowerCase(),
                  ) ||
                  song.artist.toLowerCase().contains(
                    _downloadSearchQuery.toLowerCase(),
                  );
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    onChanged: _onDownloadSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search downloads',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      suffixIcon: _downloadSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _downloadSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredSongs.isEmpty && songs.isNotEmpty
                      ? const Center(
                          child: Text(
                            'No matching downloads found',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : songs.isEmpty
                      ? ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildLibraryItem(
                              'Your Downloads',
                              'Playlist • 0 songs',
                              Icons.download_done,
                              Colors.green,
                              isDownloaded: true,
                              onTap: () {
                                UIUtils.showSnackBar(
                                  context,
                                  'No downloaded songs yet!',
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildLibraryItem(
                              'Local Files',
                              'Songs from this device',
                              Icons.folder_open,
                              Colors.grey,
                              onTap: () {
                                UIUtils.showSnackBar(
                                  context,
                                  'Local files feature coming soon!',
                                );
                              },
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount:
                              filteredSongs.length +
                              (_downloadSearchQuery.isEmpty ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (_downloadSearchQuery.isEmpty &&
                                index == filteredSongs.length) {
                              return _buildLibraryItem(
                                'Local Files',
                                'Songs from this device',
                                Icons.folder_open,
                                Colors.grey,
                                onTap: () {
                                  UIUtils.showSnackBar(
                                    context,
                                    'Local files feature coming soon!',
                                  );
                                },
                              );
                            }

                            final song = filteredSongs[index];
                            return InkWell(
                              onTap: () {
                                PlayerService().play(song);
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    child: CachedImage(
                                      imageUrl: song.coverUrl,
                                      borderRadius: BorderRadius.circular(4),
                                      errorWidget: const Icon(
                                        Icons.music_note,
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          song.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (song.isPinned)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(
                                        Icons.push_pin,
                                        color: AppTheme.primary,
                                        size: 14,
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white38,
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            SongOptionsBottomSheet(song: song),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      case 'Playlists':
      default:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                onChanged: _onPlaylistSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search playlists',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _playlistSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _playlistSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.getPlaylists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  final playlists = snapshot.data ?? [];
                  final filteredPlaylists = playlists.where((p) {
                    final name = (p['name'] as String).toLowerCase();
                    return name.contains(_playlistSearchQuery.toLowerCase());
                  }).toList();

                  final showLikedSongs =
                      _playlistSearchQuery.isEmpty ||
                      'liked songs'.contains(
                        _playlistSearchQuery.toLowerCase(),
                      );

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (showLikedSongs)
                        StreamBuilder<List<SongInfo>>(
                          stream: _db.getLikedSongs(),
                          builder: (context, likedSnapshot) {
                            final count = likedSnapshot.hasData
                                ? likedSnapshot.data!.length
                                : 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildLibraryItem(
                                'Liked Songs',
                                'Playlist • $count songs',
                                Icons.favorite,
                                Colors.pink,
                                isLikedSongs: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PlaylistDetailsScreen(
                                            playlistName: 'Liked Songs',
                                            subtitle: 'Your Liked Songs',
                                            icon: Icons.favorite,
                                            color: Colors.pink,
                                            isLikedSongs: true,
                                          ),
                                    ),
                                  );
                                },
                                onMoreTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        PlaylistOptionsBottomSheet(
                                          playlistId: 'liked_songs',
                                          playlistName: 'Liked Songs',
                                          isLikedSongs: true,
                                        ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      if (filteredPlaylists.isEmpty && !showLikedSongs)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No matching playlists found',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        ),
                      ...filteredPlaylists.map(
                        (playlist) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildLibraryItem(
                            playlist['name'] as String,
                            'Playlist • ${playlist['songCount']} songs',
                            Icons.queue_music,
                            AppTheme.primary,
                            imageUrl: playlist['coverUrl'],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlaylistDetailsScreen(
                                    playlistName: playlist['name'] as String,
                                    subtitle:
                                        'Playlist • ${playlist['songCount']} songs',
                                    icon: Icons.queue_music,
                                    color: AppTheme.primary,
                                    playlistId: playlist['id'] as String,
                                  ),
                                ),
                              );
                            },
                            onMoreTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    PlaylistOptionsBottomSheet(
                                      playlistId: playlist['id'] as String,
                                      playlistName: playlist['name'] as String,
                                      isLikedSongs: false,
                                    ),
                              );
                            },
                            isPinned: playlist['isPinned'] ?? false,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
    }
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryItem(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    String? imageUrl,
    bool isLikedSongs = false,
    bool isDownloaded = false,
    bool isPinned = false,
    VoidCallback? onTap,
    VoidCallback? onMoreTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (isLikedSongs || isDownloaded)
                    ? null
                    : color.withValues(alpha: 0.1),
                gradient: isLikedSongs
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF450af5), Color(0xFFc4efd9)],
                      )
                    : isDownloaded
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF006400), Color(0xFF1DB954)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? CachedImage(
                      imageUrl: imageUrl,
                      borderRadius: BorderRadius.circular(4),
                    )
                  : isLikedSongs
                  ? const Center(
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 28,
                      ),
                    )
                  : isDownloaded
                  ? const Center(
                      child: Icon(
                        Icons.download_done,
                        color: Colors.white,
                        size: 28,
                      ),
                    )
                  : Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isLikedSongs || isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 6.0),
                          child: Icon(
                            Icons.push_pin,
                            color: AppTheme.primary,
                            size: 14,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          subtitle,
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
                ],
              ),
            ),
            if (onMoreTap != null)
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onPressed: onMoreTap,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistItem(
    String name,
    String followers,
    String imageUrl, {
    String? browseId,
    bool isPinned = false,
    VoidCallback? onMoreTap,
  }) {
    return InkWell(
      onTap: () {
        if (browseId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistDetailsScreen(
                artist: YouTubeArtistMetadata(
                  name: name,
                  browseId: browseId,
                  artworkUrl: imageUrl,
                  isPinned: isPinned,
                ),
              ),
            ),
          );
        } else {
          UIUtils.showSnackBar(context, 'Artist details not available');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              child: CachedImage(
                imageUrl: imageUrl,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 6.0),
                          child: Icon(
                            Icons.push_pin,
                            color: AppTheme.primary,
                            size: 14,
                          ),
                        ),
                      Text(
                        followers,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onMoreTap != null)
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onPressed: onMoreTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _ArtistSearchBottomSheet extends StatefulWidget {
  const _ArtistSearchBottomSheet();

  @override
  State<_ArtistSearchBottomSheet> createState() =>
      _ArtistSearchBottomSheetState();
}

class _ArtistSearchBottomSheetState extends State<_ArtistSearchBottomSheet> {
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  final TextEditingController _controller = TextEditingController();
  List<YouTubeArtistMetadata> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    ConnectivityService().isOnline.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchArtists(query);
      } else {
        setState(() => _results = []);
      }
    });
  }

  Future<void> _searchArtists(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await _ytmService.searchArtists(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    ConnectivityService().isOnline.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for new artists...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: ConnectivityService().isOnline,
              builder: (context, isOnline, _) {
                if (!isOnline) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white24, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'You\'re Offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please check your internet connection.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  );
                }

                return _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : _results.isEmpty && _controller.text.isNotEmpty
                    ? const Center(
                        child: Text(
                          'No artists found',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final artist = _results[index];
                          return ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ArtistDetailsScreen(artist: artist),
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            leading: CachedImage(
                              imageUrl: artist.artworkUrl,
                              width: 60,
                              height: 60,
                              borderRadius: BorderRadius.circular(30),
                              errorWidget: const Icon(
                                Icons.person,
                                color: Colors.white24,
                              ),
                            ),
                            title: Text(
                              artist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              'Artist',
                              style: TextStyle(color: Colors.white38),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.white24,
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
