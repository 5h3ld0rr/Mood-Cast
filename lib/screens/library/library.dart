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

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String selectedFilter = 'Playlists';
  final List<String> filters = ['Playlists', 'Artists', 'Albums', 'Downloads'];

  final DatabaseService _db = DatabaseService();

  // Artist search state within Library
  String _artistSearchQuery = '';

  @override
  void dispose() {
    super.dispose();
  }

  void _onArtistSearchChanged(String query) {
    setState(() {
      _artistSearchQuery = query;
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
                  if (selectedFilter != 'Artists')
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
                                    artist.browseId,
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
                        artist.browseId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      case 'Albums':
        return StreamBuilder<List<YouTubeMusicMetadata>>(
          stream: _db.getLikedAlbums(),
          builder: (context, albumSnapshot) {
            final likedAlbums = albumSnapshot.data ?? [];

            if (likedAlbums.isEmpty &&
                albumSnapshot.connectionState != ConnectionState.waiting) {
              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.album_outlined,
                          size: 64,
                          color: Colors.white10,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No saved albums yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Save albums from search to see them here.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Suggested Albums',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<YouTubeMusicMetadata>>(
                    future: YouTubeMusicService().searchTracks(
                      'Top Global Albums',
                    ),
                    builder: (context, suggestedSnapshot) {
                      if (suggestedSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 2,
                          ),
                        );
                      }

                      final suggestions = suggestedSnapshot.data ?? [];
                      return Column(
                        children: suggestions.take(5).map((album) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildLibraryItem(
                              album.title,
                              album.artist,
                              Icons.album,
                              AppTheme.primary,
                              imageUrl: album.artworkUrl,
                              onTap: () {
                                // Navigate to album details or search
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: likedAlbums.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final album = likedAlbums[index];
                return _buildLibraryItem(
                  album.title,
                  album.artist,
                  Icons.album,
                  AppTheme.primary,
                  imageUrl: album.artworkUrl,
                );
              },
            );
          },
        );
      case 'Downloads':
        return ValueListenableBuilder<List<SongInfo>>(
          valueListenable: DownloadService().downloadedSongs,
          builder: (context, songs, _) {
            if (songs.isEmpty) {
              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildLibraryItem(
                    'Your Downloads',
                    'Playlist • 0 songs',
                    Icons.download_done,
                    Colors.green,
                    isDownloaded: true,
                    onTap: () {
                      UIUtils.showSnackBar(context, 'No downloaded songs yet!');
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
              );
            }

            return ListView.separated(
              itemCount: songs.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == songs.length) {
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

                final song = songs[index];
                return InkWell(
                  onTap: () {
                    PlayerService().play(song);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                          image: song.coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(song.coverUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: song.coverUrl == null
                            ? const Icon(
                                Icons.music_note,
                                color: Colors.white30,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
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
                      const Icon(
                        Icons.download_done,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      case 'Playlists':
      default:
        return Column(
          children: [
            // User Liked Songs Playlist (Static position)
            StreamBuilder<List<SongInfo>>(
              stream: _db.getLikedSongs(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.length : 0;
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
                          builder: (context) => const PlaylistDetailsScreen(
                            playlistName: 'Liked Songs',
                            subtitle: 'Your Liked Songs',
                            icon: Icons.favorite,
                            color: Colors.pink,
                            isLikedSongs: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Firestore Data Playlists
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.getPlaylists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No playlists yet',
                        style: TextStyle(color: Colors.white60),
                      ),
                    );
                  }

                  final playlists = snapshot.data!;
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ...playlists.map(
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
    VoidCallback? onTap,
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
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? isLikedSongs
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
                        : Icon(icon, color: color, size: 28)
                  : null,
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
                      if (isLikedSongs)
                        const Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Icons.push_pin,
                            color: AppTheme.primary,
                            size: 12,
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
          ],
        ),
      ),
    );
  }

  Widget _buildArtistItem(
    String name,
    String followers,
    String imageUrl, [
    String? browseId,
  ]) {
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white10,
                          backgroundImage: artist.artworkUrl != null
                              ? NetworkImage(artist.artworkUrl!)
                              : null,
                          child: artist.artworkUrl == null
                              ? const Icon(Icons.person, color: Colors.white24)
                              : null,
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
                  ),
          ),
        ],
      ),
    );
  }
}
